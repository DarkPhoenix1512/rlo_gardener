local pickup, PickUpBlip, TreeCareBlip, DepotBlip = nil, nil, nil, nil
local jobExperience, jobLevel = nil, nil
local activeJob, isPlayerDriving, hasMowingVehicle = false, false, false 
local collectedPoints = 0

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then 
        CreateDepotBlip()
    end
end)

AddEventHandler('esx:playerLoaded', function()
    CreateDepotBlip()
end)

function CreateDepotBlip()
    DepotBlip = AddBlipForCoord(Config.Zones.ManageJob.Position)
    SetBlipSprite(DepotBlip, 357)
    SetBlipScale(DepotBlip, 1.0)
    SetBlipColour(DepotBlip, 2)
    SetBlipAsShortRange(DepotBlip, true)
    SetBlipRoute(DepotBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Gardener Depot')
    EndTextCommandSetBlipName(DepotBlip)
end

function CreateBlip(name, position)
    local blip = AddBlipForCoord(position)
    SetBlipSprite(blip, 1)
    SetBlipScale(blip, 1.0)
    SetBlipColour(blip, 2)
    SetBlipAsShortRange(blip, true)
    SetBlipRoute(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(name)
    EndTextCommandSetBlipName(blip)
    return blip
end

function StartJobWithCheck(jobFunction)
    if hasMowingVehicle then
        ESX.ShowNotification('Return the mower before starting a new job.')
    else
        ESX.TriggerServerCallback('rlo_gardening:callback:checkDailyTasks', function(canStart)
            if canStart then
                jobFunction()
            else
                ESX.ShowNotification('You have reached your daily task limit. Come back tomorrow!')
            end
        end)
    end
end

function StartPickupJob()
    StartJobWithCheck(function()
        ESX.UI.Menu.CloseAll()
        activeJob = true
        ESX.ShowNotification('Pull the ~g~weed~s~ out of the ground')
        pickup = Config.JobPickups[math.random(1, #Config.JobPickups)]
        PickUpBlip = CreateBlip('Weed', pickup)

        CreateThread(function()
            while pickup do
                local sleep = 1500
                local coords = GetEntityCoords(PlayerPedId())
                local distance = #(coords - vector3(pickup))

                if distance < Config.DrawDistance then
                    sleep = 0
                    DrawMarker(21, pickup.x, pickup.y, pickup.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, 1.0,
                    0.5, 85, 255, 0, 100, true, false, 2, true, nil, nil, false)
                end

                if distance < 1.0 then
                    ESX.ShowHelpNotification('Press ~INPUT_CONTEXT~ to pull out the weed')
                    if IsControlJustReleased(0, 38) then
                        local success = lib.skillCheck({'easy', 'easy', 'medium'})
                        if success and lib.progressCircle({ duration = 10000, position = 'bottom', anim = { scenario = 'WORLD_HUMAN_GARDENER_PLANT' } }) then
                            collectedPoints = collectedPoints + 1 
                            ESX.ShowNotification('You received ~g~x'..collectedPoints..' Garden Points')
                            RemoveBlip(PickUpBlip)
                            pickup = Config.JobPickups[math.random(1, #Config.JobPickups)]
                            PickUpBlip = CreateBlip('Weed', pickup)
                        else
                            ESX.ShowNotification('You did not pass the skill-check')
                        end
                    end
                end
                Wait(sleep)
            end
        end)
    end)
end

function StartTreeCareJob()
    StartJobWithCheck(function()
        ESX.UI.Menu.CloseAll()
        activeJob = true
        ESX.ShowNotification('Go and care about the trees.')
        treecare = Config.JobTrees[math.random(1, #Config.JobTrees)]
        TreeCareBlip = CreateBlip('Tree Care', treecare)

        CreateThread(function()
            while treecare do
                local sleep = 1500
                local coords = GetEntityCoords(PlayerPedId())
                local distance = #(coords - vector3(treecare))

                if distance < Config.DrawDistance then
                    sleep = 0
                    DrawMarker(21, treecare.x, treecare.y, treecare.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, 1.0, 0.5, 85, 255, 0, 100, true, false, 2, true, nil, nil, false)
                end

                if distance < 1.0 then
                    ESX.ShowHelpNotification('Press ~INPUT_CONTEXT~ to care about the tree')
                    if IsControlJustReleased(0, 38) then
                        local success = lib.skillCheck({'easy', 'medium'})
                        if success and lib.progressCircle({ duration = 5000, position = 'bottom', anim = { dict = 'anim@move_m@trash', clip = 'pickup' } }) then
                            collectedPoints = collectedPoints + 1
                            ESX.ShowNotification('You received ~g~x'..collectedPoints..' Garden Points')
                            RemoveBlip(TreeCareBlip)
                            treecare = Config.JobTrees[math.random(1, #Config.JobTrees)]
                            TreeCareBlip = CreateBlip('Tree Care', treecare)
                        else
                            ESX.ShowNotification('You did not pass the skill-check')
                        end
                    end
                end
                Wait(sleep)
            end
        end)
    end)
end

function StartMowingJob()
    StartJobWithCheck(function()
        ESX.UI.Menu.CloseAll()
        if not IsPositionOccupied(Config.VehicleSpawn.x, Config.VehicleSpawn.y, Config.VehicleSpawn.z, 10, false, true) then
            ESX.Game.SpawnVehicle(Config.Vehicle, Config.VehicleSpawn, Config.VehicleSpawn.w, function(spawnedVehicle)
                TaskWarpPedIntoVehicle(PlayerPedId(), spawnedVehicle, -1)
                activeJob, hasMowingVehicle = true, true
                ESX.ShowNotification('Have fun ~g~mowing~s~!')
            end)
        else 
            ESX.ShowNotification('The point is blocked. Try again later.')
        end

        CreateThread(function()
            while activeJob do 
                Wait(10000)
                if isPlayerDriving then 
                    collectedPoints = collectedPoints + 1 
                    ESX.ShowNotification('You received ~g~x'..collectedPoints..' Garden Points')
                end
            end
        end)

        CreateThread(function()
            while activeJob do 
                Wait(0)
                local playerVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                if IsVehicleModel(playerVehicle, GetHashKey(Config.Vehicle)) then
                    local vehicleSpeed = (GetEntitySpeed(playerVehicle) * 3.6)
                    isPlayerDriving = vehicleSpeed >= 5
                else
                    isPlayerDriving = false
                end
            end
        end)
    end)
end

function DeleteVehicle(vehicle)
    ESX.UI.Menu.CloseAll()
    if IsVehicleModel(vehicle, GetHashKey(Config.Vehicle)) then
        ESX.Game.DeleteVehicle(vehicle)
        hasMowingVehicle = false
        ESX.ShowNotification('You can redeem your Garden Points at the Depot now')
    else
        ESX.ShowNotification('Return the mower first')
    end 
end

function ManageJob()
    ESX.UI.Menu.CloseAll()
    ESX.TriggerServerCallback('rlo_gardening:callback:checkJobStatistics', function(experience)
        if experience == nil then
            ESX.ShowNotification("Welcome to the ~g~Gardener Depot~s~, we've created a profile for you")
            return
        end

        jobExperience = experience
        jobLevel = math.floor(experience / 1000)

        local menuElements = {
            {label = '🎖️ Show Job Statistics', name = 'job_level'},
            {label = '🌿 Start Weeding (Lvl. 0)', name = 'pickup'},
            {label = '🌳 Start Tree Care (Lvl. 1)', name = 'treecare'},
            {label = '🚜 Start Mowing (Lvl. 2)', name = 'mowing'},
            {label = '🎖️ Redeem Garden Points', name = 'redeem'}
        }

        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'gardening', {
            title    = 'Gardener Depot',
            align    = 'top-left',
            elements = menuElements
        }, function(data, menu)
            if data.current.name == 'job_level' then
                ESX.ShowNotification('You have ~b~' .. jobExperience .. '~s~ Experience and are on ~b~Level ' .. jobLevel)
            elseif data.current.name == 'pickup' and jobLevel >= 0 then
                StartPickupJob()
            elseif data.current.name == 'treecare' and jobLevel >= 1 then
                StartTreeCareJob()
            elseif data.current.name == 'mowing' and jobLevel >= 2 then
                StartMowingJob()
            elseif data.current.name == 'redeem' then
                RedeemPoints()
            else
                ESX.ShowNotification('You need to level up to start this job.')
            end
        end, function(data, menu)
            menu.close()
        end)
    end)
end

function RedeemPoints()
    if collectedPoints > 0 then
        TriggerServerEvent('rlo_gardening:server:redeemPoints', collectedPoints)
        collectedPoints = 0
    else
        ESX.ShowNotification('You do not have enough Garden Points.')
    end
end
