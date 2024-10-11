ESX.RegisterServerCallback('rlo_gardening:callback:checkJobStatistics', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local result = MySQL.single.await('SELECT experience FROM users WHERE identifier = ?', { xPlayer.getIdentifier() })
    cb(result and result.experience or nil)
end)

ESX.RegisterServerCallback('rlo_gardening:callback:checkDailyTasks', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local result = MySQL.single.await('SELECT tasks FROM daily_tasks WHERE identifier = ? AND date = CURDATE()', { xPlayer.getIdentifier() })
    cb(not result or result.tasks < Config.DailyTaskLimit)
end)

RegisterServerEvent('rlo_gardening:server:redeemPoints', function(points)
    local xPlayer = ESX.GetPlayerFromId(source)
    local currentExperience = MySQL.single.await('SELECT experience FROM users WHERE identifier = ?', { xPlayer.getIdentifier() }).experience or 0
    local newExperience = currentExperience + points * 50

    MySQL.update.await('UPDATE users SET experience = ? WHERE identifier = ?', { newExperience, xPlayer.getIdentifier() })
    xPlayer.addMoney(points * Config.Payout)

    local newLevel = math.floor(newExperience / 1000)
    if newLevel > math.floor(currentExperience / 1000) then
        xPlayer.showNotification('You reached ~b~Level ' .. newLevel .. '~s~! Keep up the good work!')
    end

    MySQL.update.await('INSERT INTO daily_tasks (identifier, date, tasks) VALUES (?, CURDATE(), 1) ON DUPLICATE KEY UPDATE tasks = tasks + 1', { xPlayer.getIdentifier() })
end)
