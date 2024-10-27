ESX = exports["es_extended"]:getSharedObject()

Citizen.CreateThread(function()
    local teleportLocations = Config.teleportLocations
    local vehicleSpawnLocations = Config.vehicleSpawnLocations
    local spawnedVehicles = {}
    local isMenuOpen = false

    for _, location in ipairs(vehicleSpawnLocations) do
        location.selectedModel = nil
        location.selectedDuplications = 1
    end

    local function TeleportEntity(entity, coords, heading)
        SetEntityCoords(entity, coords, false, false, false, true)
        SetEntityHeading(entity, heading)
    end

    local function SpawnVehicle(model, coords, heading)
        RequestModel(model)
        while not HasModelLoaded(model) do Citizen.Wait(10) end
        local vehicle = CreateVehicle(model, coords, heading, true, false)
        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleOnGroundProperly(vehicle)
        SetModelAsNoLongerNeeded(model)
        return vehicle
    end

    local function IsSpawnLocationOccupied(coords)
        return GetClosestVehicle(coords.x, coords.y, coords.z, 1.0, 0, 0) ~= 0
    end

    local function IsPlayerPolice()
        local playerData = ESX.GetPlayerData()
        return playerData.job and playerData.job.name == 'police'
    end

    local function OpenVehicleConfigMenu()
        if isMenuOpen then return end
        isMenuOpen = true
        SendNUIMessage({ action = "openMenu", locations = vehicleSpawnLocations })
        SetNuiFocus(true, true)
    end    

    Citizen.CreateThread(function()
        local configPoint = vector3(-1542.8490, -575.7241, 25.7078)
        while true do
            Citizen.Wait(0)
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            if #(playerCoords - configPoint) < 2.0 then
                ESX.ShowHelpNotification("Press ~INPUT_CONTEXT~ to configure vehicles")
                if IsControlJustPressed(1, 51) then
                    PlaySound(-1, "Sound_Name", "Sound_Set_Name", 0, 0, 1)
                    OpenVehicleConfigMenu()
                end
            end
        end
    end)

    function PlaySound(channel, sound, set, isLooped, isStreamed, volume)
        TriggerEvent('xsound:play', sound, volume, isLooped, isStreamed, set)
    end

    RegisterNUICallback('closeMenu', function()
        SetNuiFocus(false, false)
        isMenuOpen = false
    end)

    RegisterNUICallback('spawnVehicles', function(data, cb)
        local index = data.index
        local model = data.model
        local duplications = data.duplications

        if index and model and duplications then
            local location = vehicleSpawnLocations[index + 1]
            location.selectedModel = model
            location.selectedDuplications = duplications

            if spawnedVehicles[index + 1] then
                for _, vehicle in ipairs(spawnedVehicles[index + 1]) do
                    if DoesEntityExist(vehicle) then
                        DeleteEntity(vehicle)
                    end
                end
            end
            spawnedVehicles[index + 1] = {}

            for j = 0, duplications - 1 do
                local offsetCoords = vector3(
                    location.coords.x + math.cos(math.rad(location.heading)) * j * Config.spawnOffset,
                    location.coords.y + math.sin(math.rad(location.heading)) * j * Config.spawnOffset,
                    location.coords.z
                )
                if not IsSpawnLocationOccupied(offsetCoords) then
                    local vehicle = SpawnVehicle(model, offsetCoords, location.heading)
                    spawnedVehicles[index + 1][j + 1] = vehicle
                end
            end

            ESX.ShowNotification("Configured: " .. duplications .. " duplications of " .. model .. " in Zone " .. (index + 1))
        end

        cb('ok')
    end)

    RegisterNUICallback('deleteAllVehicles', function()
        local vehicles = GetGamePool('CVehicle')
        for _, vehicle in ipairs(vehicles) do
            if DoesEntityExist(vehicle) then
                DeleteEntity(vehicle)
            end
        end
    end)

    RegisterNUICallback('resetVehicles', function()
        TriggerEvent('deleteAllVehicles')
        for index, vehicles in pairs(spawnedVehicles) do
            local location = vehicleSpawnLocations[index]
            for _, vehicle in ipairs(vehicles) do
                if DoesEntityExist(vehicle) then
                    TriggerEvent('spawnVehicles')
                end
            end
        end
    end)    

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            for _, location in ipairs(teleportLocations) do
                if #(playerCoords - location.from) < Config.teleportDistance then
                    DrawMarker(2, location.from.x, location.from.y, location.from.z + 0.5, 0, 0, 0, 0, 0, 0, 0.2, 0.2, 0.2, 90, 0, 148, 255, false, true, 2, nil, nil, false)

                    if IsControlJustPressed(1, 51) and IsPlayerPolice() then
                        local playerVehicle = GetVehiclePedIsIn(playerPed, false)
                        local nearbyVehicle = GetClosestVehicle(location.to.x, location.to.y, location.to.z, 1.5, 0, 71)
                        if nearbyVehicle ~= 0 then
                            ESX.ShowNotification("This location is occupied")
                        else
                            if playerVehicle ~= 0 then
                                SetVehicleEngineHealth(playerVehicle, 1000.0)
                                SetVehicleBodyHealth(playerVehicle, 1000.0)
                                SetVehiclePetrolTankHealth(playerVehicle, 1000.0)
                                SetVehicleDirtLevel(playerVehicle, 0)
                                SetVehicleDeformationFixed(playerVehicle)
                                SetVehicleFixed(playerVehicle)
                            end
                            TeleportEntity(playerVehicle ~= 0 and playerVehicle or playerPed, location.to, location.heading)
                        end
                    elseif not IsPlayerPolice() then
                        ESX.ShowNotification("You are not a police officer")
                    end
                end
            end
            
            if #(playerCoords - Config.deletePoint) < Config.deleteRadius and IsControlJustReleased(0, Config.keyToDelete) and IsPlayerPolice() then
                local vehicle = GetVehiclePedIsIn(playerPed, false) or GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, Config.deleteRadius, 0, 71)
                if vehicle ~= 0 then
                    DeleteEntity(vehicle)
                    ESX.ShowNotification("Vehicle successfully deleted!")
                else
                    ESX.ShowNotification("No nearby vehicles to delete.")
                end
            end
        end
    end)
end)
