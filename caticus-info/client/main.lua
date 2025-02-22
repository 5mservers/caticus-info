local QBCore = nil
local ESX = nil
local showInfo = false
local playerData = {}
local mugshotCache = {}

-- Show command
RegisterCommand(Config.ShowCommand, function()
    showInfo = true
end)

-- Hide command
RegisterCommand(Config.HideCommand, function()
    showInfo = false
    -- Simple, direct cleanup
    SendNUIMessage({
        action = 'clearAll'
    })
    -- Clear local data
    playerData = {}
    mugshotCache = {}
end)

-- Add this helper function
function GetPlayerMugshot(ped)
    local mugshot = RegisterPedheadshot(ped)
    while not IsPedheadshotReady(mugshot) do
        Wait(0)
    end
    local txd = GetPedheadshotTxdString(mugshot)
    UnregisterPedheadshot(mugshot)
    return "https://nui-img/" .. txd .. "/" .. txd
end

-- Add this function to match your ID script's positioning
function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        local dist = GetDistanceBetweenCoords(GetGameplayCamCoords(), x, y, z, 1)
        local scale = 1 * (1 / dist) * (1 / GetGameplayCamFov()) * 100
        return _x, _y, scale
    end
    return nil, nil, nil
end

-- Add this function from your ID script
function GetNeareastPlayers()
    local playerPed = PlayerPedId()
    local players = {}
    
    if Config.Framework == 'qb' then
        players, _ = QBCore.Functions.GetPlayers(GetEntityCoords(playerPed), Config.DrawDistance)
    elseif Config.Framework == 'esx' then
        -- ESX way of getting nearby players
        local coords = GetEntityCoords(playerPed)
        for _, player in ipairs(GetActivePlayers()) do
            local targetPed = GetPlayerPed(player)
            local targetCoords = GetEntityCoords(targetPed)
            if #(coords - targetCoords) < Config.DrawDistance then
                table.insert(players, player)
            end
        end
    end

    local players_clean = {}
    for i = 1, #players, 1 do
        local targetPed = GetPlayerPed(players[i])
        table.insert(players_clean, { 
            playerName = GetPlayerName(players[i]), 
            playerId = GetPlayerServerId(players[i]), 
            coords = GetEntityCoords(targetPed),
            ped = targetPed
        })
    end
    return players_clean
end

-- Main thread
CreateThread(function()
    if Config.Framework == 'qb' then
        QBCore = exports['qb-core']:GetCoreObject()
    elseif Config.Framework == 'esx' then
        if GetResourceState('es_extended') ~= 'missing' then
            ESX = exports['es_extended']:getSharedObject() -- ESX Legacy support
        else
            while ESX == nil do -- Old ESX support
                TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
                Wait(0)
            end
        end
    end

    while true do
        Wait(0)
        if showInfo then
            local nearbyPlayers = GetNeareastPlayers()
            for _, player in pairs(nearbyPlayers) do
                local x, y, z = table.unpack(player.coords)
                -- Get bone coords for more precise head tracking
                local headCoords = GetPedBoneCoords(player.ped, 31086, 0.0, 0.0, 0.0) -- 31086 is the head bone
                local onScreen, _x, _y = World3dToScreen2d(headCoords.x, headCoords.y, headCoords.z + 0.5) -- Reduced offset for closer positioning
                
                if onScreen then
                    local dist = #(GetGameplayCamCoords() - headCoords)
                    -- Only show if within reasonable distance
                    if dist < 20.0 then
                        local serverId = player.playerId
                        local health = GetEntityHealth(player.ped)

                        -- Request player data if we don't have it
                        if not playerData[serverId] then
                            TriggerServerEvent('caticus-info:server:requestPlayerData', serverId)
                        end

                        SendNUIMessage({
                            action = 'updatePlayer',
                            data = {
                                serverId = serverId,
                                name = player.playerName,
                                charName = playerData[serverId] and playerData[serverId].charName or "Unknown",
                                steamName = player.playerName,
                                health = math.max(0, health - 100),
                                position = {
                                    x = (_x * 1920) + 180,
                                    y = (_y * 1080) + 50
                                },
                                playerData = playerData[serverId] or {},
                                mugshot = GetPlayerMugshot(player.ped)
                            }
                        })
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('caticus-info:client:receivePlayerData', function(serverId, data)
    playerData[serverId] = data
end)

-- Update resource stop handler
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
end) 