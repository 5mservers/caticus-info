local QBCore = nil
local ESX = nil
local showInfo = false
local playerData = {}


RegisterCommand(Config.Command, function()
    showInfo = not showInfo
    if not showInfo then

        SendNUIMessage({
            action = 'hideAll'
        })
    end
end)


function GetPlayerMugshot(ped)
    local mugshot = RegisterPedheadshot(ped)
    while not IsPedheadshotReady(mugshot) do
        Wait(0)
    end
    local txd = GetPedheadshotTxdString(mugshot)
    UnregisterPedheadshot(mugshot)
    return "https://nui-img/" .. txd .. "/" .. txd
end


function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        local dist = GetDistanceBetweenCoords(GetGameplayCamCoords(), x, y, z, 1)
        local scale = 1 * (1 / dist) * (1 / GetGameplayCamFov()) * 100
        return _x, _y, scale
    end
    return nil, nil, nil
end

function GetNeareastPlayers()
    local playerPed = PlayerPedId()
    local players = {}
    
    if Config.Framework == 'qb' then
        players, _ = QBCore.Functions.GetPlayers(GetEntityCoords(playerPed), Config.DrawDistance)
    elseif Config.Framework == 'esx' then

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


CreateThread(function()
    if Config.Framework == 'qb' then
        QBCore = exports['qb-core']:GetCoreObject()
    elseif Config.Framework == 'esx' then
        while ESX == nil do
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            Wait(0)
        end
    end

    while true do
        Wait(0)
        if showInfo then
            local nearbyPlayers = GetNeareastPlayers()
            for _, player in pairs(nearbyPlayers) do
                local x, y, z = table.unpack(player.coords)

                local headCoords = GetPedBoneCoords(player.ped, 31086, 0.0, 0.0, 0.0) 
                local onScreen, _x, _y = World3dToScreen2d(headCoords.x, headCoords.y, headCoords.z + 0.5) 
                
                if onScreen then
                    local dist = #(GetGameplayCamCoords() - headCoords)

                    if dist < 20.0 then
                        local serverId = player.playerId
                        local health = GetEntityHealth(player.ped)

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


AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    

    for _, data in pairs(mugshotCache) do
        if data.id then
            UnregisterPedheadshot(data.id)
        end
    end
end)


RegisterNetEvent('caticus-info:client:hideInfo', function()

    for _, data in pairs(mugshotCache) do
        if data.id then
            UnregisterPedheadshot(data.id)
        end
    end
    mugshotCache = {}
end) 