local ShowPlayerNames = false
local ShowEntityTags = false
local TagDrawDistance = 50

RegisterCommand('playernames', function(source, args, raw)
	ShowPlayerNames = not ShowPlayerNames
end, false)

RegisterCommand('entids', function(source, args, raw)
	ShowEntityTags = not ShowEntityTags
end, false)

TriggerEvent('chat:addSuggestion', '/playernames', 'Show/hide player names', {})
TriggerEvent('chat:addSuggestion', '/entids', 'Show/hide entity IDs', {})

local entityEnumerator = {
	__gc = function(enum)
		if enum.destructor and enum.handle then
			enum.destructor(enum.handle)
		end
		enum.destructor = nil
		enum.handle = nil
	end
}

function EnumerateEntities(firstFunc, nextFunc, endFunc)
	return coroutine.wrap(function()
		local iter, id = firstFunc()

		if not id or id == 0 then
			endFunc(iter)
			return
		end

		local enum = {handle = iter, destructor = endFunc}
		setmetatable(enum, entityEnumerator)

		local next = true
		repeat
			coroutine.yield(id)
			next, id = nextFunc(iter)
		until not next

		enum.destructor, enum.handle = nil, nil
		endFunc(iter)
	end)
end

function EnumerateObjects()
	return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
end

function EnumeratePeds()
	return EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
end

function EnumerateVehicles()
	return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end

function DrawText3D(x, y, z, text)
	local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(x, y, z)

	SetTextScale(0.35, 0.35)
	SetTextFontForCurrentCommand(1)
	SetTextColor(255, 255, 255, 255)
	SetTextCentre(1)
	DisplayText(CreateVarString(10, "LITERAL_STRING", text), screenX, screenY)
end

function DrawTags()
	local myPed = PlayerPedId()
	local x1, y1, z1 = table.unpack(GetEntityCoords(myPed))

	if ShowPlayerNames then
		for _, playerId in ipairs(GetActivePlayers()) do
			local ped = GetPlayerPed(playerId)
			local x2, y2, z2 = table.unpack(GetEntityCoords(ped))

			if GetDistanceBetweenCoords(x1, y1, z1, x2, y2, z2, true) <= TagDrawDistance then
				DrawText3D(x2, y2, z2 + 1, GetPlayerName(playerId))
			end
		end
	end

	if ShowEntityTags then
		for ped in EnumeratePeds() do
			if not IsPedAPlayer(ped) then
				local x2, y2, z2 = table.unpack(GetEntityCoords(ped))

				if GetDistanceBetweenCoords(x1, y1, z1, x2, y2, z2, true) <= TagDrawDistance then
					DrawText3D(x2, y2, z2 + 1, string.format('ped %x', ped))
				end
			end
		end

		for vehicle in EnumerateVehicles() do
			local x2, y2, z2 = table.unpack(GetEntityCoords(vehicle))

			if GetDistanceBetweenCoords(x1, y1, z1, x2, y2, z2, true) <= TagDrawDistance then
				DrawText3D(x2, y2, z2 + 1, string.format('veh %x', vehicle))
			end
		end

		for object in EnumerateObjects() do
			local x2, y2, z2 = table.unpack(GetEntityCoords(object))

			if GetDistanceBetweenCoords(x1, y1, z1, x2, y2, z2, true) <= TagDrawDistance then
				DrawText3D(x2, y2, z2 + 1, string.format('obj %x', object))
			end
		end
	end
end

CreateThread(function()
	while true do
		Wait(0)
		if ShowPlayerNames or ShowEntityTags then
			DrawTags()
		end
	end
end)
