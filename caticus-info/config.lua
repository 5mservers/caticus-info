Config = {}

Config.Framework = 'qb' -- 'qb' or 'esx' or 'esx_legacy'
Config.ShowCommand = 'showinfo' -- Command to show info
Config.HideCommand = 'hideinfo' -- Command to hide info
Config.ShowSelf = true -- Show info above your own head
Config.DrawDistance = 15.0 -- How far to draw player info



-- Box Style Configuration
Config.Box = {
    width = '200px',
    height = '100px',
    background = 'rgba(27, 30, 39, 0.85)',
    border = '1px solid rgba(255, 255, 255, 0.1)',
    borderRadius = '8px',
    offsetY = -100 -- Offset above head in pixels
}

-- Text Style Configuration
Config.Text = {
    nameColor = '#ffffff',
    healthColor = '#32CD32',
    moneyColor = '#FFD700',
    discordColor = '#7289DA'
} 