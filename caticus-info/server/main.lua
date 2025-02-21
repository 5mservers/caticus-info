local QBCore = nil
local ESX = nil
local discordToken = 'YOUR_DISCORD_BOT_TOKEN'
local apiEndpoint = 'https://discord.com/api/v10/users/%s'
local discordCache = {}

-- Framework initialization
if Config.Framework == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
end

-- Function to update Discord cache
function UpdateDiscordCache(discordId)
    PerformHttpRequest(
        string.format("https://discordapp.com/api/users/%s", discordId),
        function(errorCode, resultData, resultHeaders)
            if errorCode == 200 then
                local userData = json.decode(resultData)
                if userData and userData.avatar then
                    discordCache[discordId] = {
                        name = userData.username,
                        avatar = userData.avatar,
                        timestamp = os.time()
                    }
                end
            end
        end,
        'GET',
        '',
        {['Content-Type'] = 'application/json'}
    )
end

-- Get Discord info (single implementation)
function GetDiscordInfo(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, identifier in pairs(identifiers) do
        if string.find(identifier, "discord:") then
            local discordId = string.gsub(identifier, "discord:", "")
            return {
                id = discordId,
                name = GetPlayerName(source),
                avatar = string.format('https://cdn.discordapp.com/avatars/%s/%s', discordId, discordId)
            }
        end
    end
    return nil
end

-- Get player data based on framework
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
                discord = GetDiscordInfo(serverId)
            }
        end
    elseif Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(serverId)
        if xPlayer then
            data = {
                charName = xPlayer.getName(),
                cash = xPlayer.getMoney(),
                bank = xPlayer.getAccount('bank').money,
                discord = GetDiscordInfo(serverId)
            }
        end
    end
    
    TriggerClientEvent('caticus-info:client:receivePlayerData', src, serverId, data)
end)