local QBCore = nil
local ESX = nil

if Config.Framework == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    if GetResourceState('es_extended') ~= 'missing' then
        ESX = exports['es_extended']:getSharedObject()
    else
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    end
end

RegisterNetEvent('caticus-info:server:requestPlayerData', function(serverId)
    local src = source
    local data = {}
    
    if Config.Framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(serverId)
        if Player then
            data = {
                charName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                cash = Player.PlayerData.money.cash,
                bank = Player.PlayerData.money.bank,
                job = Player.PlayerData.job.label
            }
        end
    elseif Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(serverId)
        if xPlayer then
            local charName = xPlayer.getName and xPlayer.getName() or xPlayer.name
            local cash = xPlayer.getMoney and xPlayer.getMoney() or xPlayer.money
            local bank = xPlayer.getAccount and xPlayer.getAccount('bank').money or xPlayer.bank
            local job = xPlayer.getJob and xPlayer.getJob().label or xPlayer.job.label
            
            data = {
                charName = charName,
                cash = cash,
                bank = bank,
                job = job
            }
        end
    end
    
    TriggerClientEvent('caticus-info:client:receivePlayerData', src, serverId, data)
end)