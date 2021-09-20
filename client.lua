local ShowPlayerNames = false
local ShowPedIds = false
local ShowVehIds = false
local ShowObjIds = false
local TagDrawDistance = 50
local HudIsRevealed = false
local ActivePlayers = {}
local MyCoords = vector3(0, 0, 0)

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

function VoiceChatIsPlayerSpeaking(player)
	return Citizen.InvokeNative(0xEF6F2A35FAAF2ED7, player)
end

function DrawTags()
	if ShowPlayerNames or HudIsRevealed then
		for _, playerId in ipairs(ActivePlayers) do
			local ped = GetPlayerPed(playerId)
			local pedCoords = GetEntityCoords(ped)

			if #(MyCoords - pedCoords) <= TagDrawDistance and not GetPedCrouchMovement(ped) then
				local text = GetPlayerName(playerId)

				if VoiceChatIsPlayerSpeaking(playerId) then
					text = "~d~Talking: ~s~" .. text
				end

				DrawText3D(pedCoords.x, pedCoords.y, pedCoords.z + 1, text)
			end
		end
	end

	if ShowPedIds then
		for ped in EnumeratePeds() do
			if not IsPedAPlayer(ped) then
				local pedCoords = GetEntityCoords(ped)

				if #(MyCoords - pedCoords) <= TagDrawDistance then
					DrawText3D(pedCoords.x, pedCoords.y, pedCoords.z + 1, string.format('ped %x', ped))
				end
			end
		end
	end

	if ShowVehIds then
		for vehicle in EnumerateVehicles() do
			local vehCoords = GetEntityCoords(vehicle)

			if #(MyCoords - vehCoords) <= TagDrawDistance then
				DrawText3D(vehCoords.x, vehCoords.y, vehCoords.z + 1, string.format('veh %x', vehicle))
			end
		end
	end

	if ShowObjIds then
		for object in EnumerateObjects() do
			local objCoords = GetEntityCoords(object)

			if #(MyCoords - objCoords) <= TagDrawDistance then
				DrawText3D(objCoords.x, objCoords.y, objCoords.z + 1, string.format('obj %x', object))
			end
		end
	end
end

Citizen.CreateThread(function()
	TriggerEvent('chat:addSuggestion', '/playernames', 'Show/hide player names')
	TriggerEvent('chat:addSuggestion', '/entids', 'Show/hide entity IDs')
	TriggerEvent('chat:addSuggestion', '/pedids', 'Show/hide ped IDs')
	TriggerEvent('chat:addSuggestion', '/vehids', 'Show/hide vehicle IDs')
	TriggerEvent('chat:addSuggestion', '/objids', 'Show/hide object IDs')
end)

Citizen.CreateThread(function()
	while true do
		if IsControlJustPressed(0, `INPUT_REVEAL_HUD`) then
			OnRevealHud()
		end

		DrawTags()

		Citizen.Wait(0)
	end
end)

Citizen.CreateThread(function()
	while true do
		ActivePlayers = GetActivePlayers()
		MyCoords = GetEntityCoords(PlayerPedId())
		Citizen.Wait(500)
	end
end)
