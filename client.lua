local ShowPlayerNames = false
local ShowPedIds = false
local ShowVehIds = false
local ShowObjIds = false
local TagDrawDistance = 50
local HudIsRevealed = false

RegisterCommand('playernames', function(source, args, raw)
	ShowPlayerNames = not ShowPlayerNames
end, false)

RegisterCommand('entids', function(source, args, raw)
	if ShowPedIds or ShowVehIds or ShowObjIds then
		ShowPedIds = false
		ShowVehIds = false
		ShowObjIds = false
	else
		ShowPedIds = true
		ShowVehIds = true
		ShowObjIds = true
	end
end, false)

RegisterCommand('pedids', function(source, args, raw)
	ShowPedIds = not ShowPedIds
end, false)

RegisterCommand('vehids', function(source, args, raw)
	ShowVehIds = not ShowVehIds
end, false)

RegisterCommand('objids', function(source, args, raw)
	ShowObjIds = not ShowObjIds
end, false)

TriggerEvent('chat:addSuggestion', '/playernames', 'Show/hide player names', {})
TriggerEvent('chat:addSuggestion', '/entids', 'Show/hide entity IDs', {})
TriggerEvent('chat:addSuggestion', '/pedids', 'Show/hide ped IDs', {})
TriggerEvent('chat:addSuggestion', '/vehids', 'Show/hide vehicle IDs', {})
TriggerEvent('chat:addSuggestion', '/objids', 'Show/hide object IDs', {})

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
	SetTextColor(255, 255, 255, 223)
	SetTextCentre(1)
	DisplayText(CreateVarString(10, "LITERAL_STRING", text), screenX, screenY)
end

function GetPedCrouchMovement(ped)
	return Citizen.InvokeNative(0xD5FE956C70FF370B, ped)
end

function OnRevealHud()
	HudIsRevealed = true
	SetTimeout(3000, function()
		HudIsRevealed = false
	end)
end

function DrawTags()
	local myPed = PlayerPedId()
	local x1, y1, z1 = table.unpack(GetEntityCoords(myPed))

	if ShowPlayerNames or HudIsRevealed then
		for _, playerId in ipairs(GetActivePlayers()) do
			local ped = GetPlayerPed(playerId)
			local x2, y2, z2 = table.unpack(GetEntityCoords(ped))

			if GetDistanceBetweenCoords(x1, y1, z1, x2, y2, z2, true) <= TagDrawDistance and not GetPedCrouchMovement(ped) then
				DrawText3D(x2, y2, z2 + 1, GetPlayerName(playerId))
			end
		end
	end

	if ShowPedIds then
		for ped in EnumeratePeds() do
			if not IsPedAPlayer(ped) then
				local x2, y2, z2 = table.unpack(GetEntityCoords(ped))

				if GetDistanceBetweenCoords(x1, y1, z1, x2, y2, z2, true) <= TagDrawDistance then
					DrawText3D(x2, y2, z2 + 1, string.format('ped %x', ped))
				end
			end
		end
	end

	if ShowVehIds then
		for vehicle in EnumerateVehicles() do
			local x2, y2, z2 = table.unpack(GetEntityCoords(vehicle))

			if GetDistanceBetweenCoords(x1, y1, z1, x2, y2, z2, true) <= TagDrawDistance then
				DrawText3D(x2, y2, z2 + 1, string.format('veh %x', vehicle))
			end
		end
	end

	if ShowObjIds then
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

		if IsControlJustPressed(0, 0xCF8A4ECA) then
			OnRevealHud()
		end

		if ShowPlayerNames or ShowPedIds or ShowVehIds or ShowObjIds or HudIsRevealed then
			DrawTags()
		end
	end
end)
