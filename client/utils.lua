ESX = exports["es_extended"]:getSharedObject()
PlayerData = ESX.GetPlayerData() 

Citizen.CreateThread(function()
    for _, v in ipairs(Shared.DuttyPos) do
        local blip = AddBlipForCoord(v)
        SetBlipSprite(blip, Shared.Blip.Sprite)
        SetBlipColour(blip, Shared.Blip.Colour)
        SetBlipScale(blip, Shared.Blip.Scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(Shared.Blip.String)
        EndTextCommandSetBlipName(blip)
    end
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)  
    PlayerData.job = job
end)

Citizen.CreateThread(function()
    local wait = 750
    while true do
        local pCoords = GetEntityCoords(PlayerPedId())
        for _, pos in ipairs(Shared.DuttyPos) do
            local dist = Vdist(pCoords, pos)
            if dist < 1.5 then 
                wait = 0
                local notificationMsg = InService and Shared.Locale.Stop or Shared.Locale.Start
                DrawTopNotification(notificationMsg)
                if IsControlJustPressed(1, 54) then
                    StartInService()
                end
                break
            end
        end
        Citizen.Wait(wait)
    end
end)

Citizen.CreateThread(function()
    local wait = 750
    while true do
        if InGarage then 
            local pCoords = GetEntityCoords(PlayerPedId())
            for _, pos in ipairs(Shared.Garage) do
                local dist = Vdist(pCoords, pos)
                if IsPedInAnyVehicle(PlayerPedId(), false) and dist <= 3.5 then
                    wait = 0
                    DrawTopNotification(Shared.Locale.Store)
                    if IsControlJustPressed(1, 38) then
                        if Vehicle == GetVehiclePedIsIn(PlayerPedId(), false) then
                            DeleteVehicle(GetVehiclePedIsIn(PlayerPedId(), false))
                        else
                            ESX.ShowNotification(Shared.Locale.InvalidVehicle)
                        end
                    end
                end
            end
        end
        Citizen.Wait(wait)
    end
end)