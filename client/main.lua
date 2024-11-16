local DisableControl = false

Citizen.CreateThread(function()
    while true do
        if DisableControl then
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 257, true) -- Attack 2
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 263, true) -- Melee Attack 1
            DisableControlAction(0, 21, true) -- Shift
            DisableControlAction(0, 22, true) -- Space
        end
        Wait(0)
    end
end)

InService = false

local Route
local Garage
local IsDutty = false
local BlipForBag
local InDutty
local HashBag = GetHashKey("WEAPON_GARBAGEBAG")
local BagProp
local IsInAction = false
local ClothesChanged = false

Vehicle = nil 

local RewardAmount = Shared.RewardAmount

local function IncreaseReward()
    RewardAmount = RewardAmount + Shared.RewardIncrease
    TriggerServerEvent("Garbage:Reward", RewardAmount, true)
end

function StartInService()
    InService = not InService
    if BlipForBag then
        RemoveBlip(BlipForBag)
    end
    if InService then 
        local model = "trash"
        if not ESX.Game.IsSpawnPointClear(Shared.SpawnVehicle, 3.0) then
            ESX.ShowNotification(Shared.Locale.VehicleNear)
        else
            ESX.Game.SpawnVehicle(model, Shared.SpawnVehicle, 270.0, function(vehicle)
                Vehicle = vehicle
                SetVehicleNumberPlateText(vehicle, 'GARB-'..math.random(0,2000))
            end)
        end
        InGarage = true 
    elseif not InService then
        InGarage = false
        RewardAmount = Shared.RewardAmount
        ClothesChanged = false
    end 
end

local function SetBag(entity, Aria)
    SetPedCanSwitchWeapon(entity, Aria)
    if not Aria then
        ESX.Streaming.RequestAnimDict('anim@heists@narcotics@trash', function()
            TaskPlayAnim(PlayerPedId(), 'anim@heists@narcotics@trash", "pickup_45_r', 2.0, 2.0, -1, 48, 0, false, false, false)
        end)
        DisableControl = true
        GiveDelayedWeaponToPed(entity, HashBag, 0, true)

        BagProp = CreateObject(GetHashKey("prop_cs_street_binbag_01"), 0, 0, 0, true, true, true)
        AttachEntityToEntity(BagProp, GetPlayerPed(-1), GetPedBoneIndex(GetPlayerPed(-1), 57005), 0.4, 0, 0, 0, 270.0, 60.0, true, true, false, true, 1, true)
        
        RemoveBlip(BlipForBag)
        InDutty = InDutty + 1 >= #Shared.GarbagePos and 1 or InDutty + 1
    else
        if HasPedGotWeapon(entity, HashBag) then
            RemoveWeaponFromPed(entity, HashBag)
            GiveDelayedWeaponToPed(entity, "WEAPON_UNARMED", 0, true)
        end
        Citizen.Wait(300)
        if BlipForBag then
            RemoveBlip(BlipForBag)
        end
    end
    IsDutty = not Aria
end

Citizen.CreateThread(function()
    while true do
        local Wait = 750
        
        if InService then
            Wait = 0
            local pPed, pCoords = GetPlayerPed(-1), GetEntityCoords(GetPlayerPed(-1), false)
            if not InDutty then
                if not Route then
                    Route = {}
                    Garage = {}
                    ESX.ShowNotification(Shared.Locale.Info)
                    if not ClothesChanged then
                        ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
                            if skin.sex == 0 then
                                TriggerEvent('skinchanger:loadClothes', skin, Shared.ClothesJob.men)
                            else
                                TriggerEvent('skinchanger:loadClothes', skin, Shared.ClothesJob.women)
                            end
                        end)
                        ClothesChanged = true
                    end
                    for i = 0, #Shared.GarbagePos, 25 do
                        if Shared.GarbagePos[i] then
                            Route[i] = CreateBlip(Shared.GarbagePos[i], 318, Shared.Blip.Colour, Shared.Blip.StringStart, nil, Shared.Blip.Scale)
                        end
                    end
                    for i = 0, #Shared.Garage, 1 do
                        if Shared.Garage[i] then
                            Garage[i] = CreateBlip(Shared.Garage[i], 357, Shared.Blip.Colour, Shared.Blip.StringGarage, nil, Shared.Blip.Scale)
                        end
                    end
                else
                    for bag, data in pairs(Route) do
                        if Shared.GarbagePos[bag] and GetDistanceBetweenCoords(pCoords, Shared.GarbagePos[bag], true) < 32 then
                            InDutty = bag
                            for i, blips in pairs(Route) do
                                RemoveBlip(blips)
                            end
                            Route = nil
                        end
                    end
                end
            elseif InDutty then
                local BagPos = Shared.GarbagePos[InDutty]
                if not DoesBlipExist(BlipForBag) then
                    BlipForBag = CreateBlip(BagPos, 128, Shared.Blip.Colour, Shared.Blip.StringBag, true, Shared.Blip.Scale)
                else
                    if not IsDutty then
                        local dist = GetDistanceBetweenCoords(pCoords, BagPos, true)
                        if dist < 64 then
                            DrawMarker(0, BagPos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.25, 0, 151, 168, 112, 0, 0, 2, 0,0, 0, 0)
                            if dist < 2 and not IsPedInAnyVehicle(pPed) then
                                DrawTopNotification(Shared.Locale.TakeBag)
                                if IsControlJustPressed(1, 51) then
                                    SetBag(pPed, false)
                                    
                                    Citizen.Wait(555)
                                    RequestAnimSet("clipset@move@trash_fast_turn")
                                    SetPedMovementClipset(pPed, "clipset@move@trash_fast_turn", true)
                                end
                            end
                        end
                    else
                        DrawTopNotification(Shared.Locale.DropBag)
                        if IsControlJustPressed(1, 51) and not IsInAction then
                            local vehicle = GetVehInSight()
                            if (GetDistanceBetweenCoords(pCoords, GetEntityCoords(vehicle) - GetEntityForwardVector(vehicle) * 5) < 2 or IsPedInAnyVehicle(pPed)) and GetEntityModel(vehicle) == 1917016601 then
                                IsInAction = true
                                Citizen.CreateThread(function()
                                    SetVehicleDoorOpen(vehicle, 5)
                                    TaskPlayAnim(pPed, 'anim@heists@narcotics@trash', 'throw_b', 1.0, -1.0,-1,2,0,0, 0,0)
                                    Citizen.Wait(1000)
                                    DeleteEntity(BagProp)
                                    ClearPedTasksImmediately(pPed)
                                    ResetPedMovementClipset(pPed)
                                    ResetPedWeaponMovementClipset(pPed)
                                    ResetPedStrafeClipset(pPed)
                                    SetVehicleDoorShut(vehicle, 5)
                                    IncreaseReward()
                                    ClearPedTasksImmediately(pPed)
                                    DeleteObject(BagProp)
                                    
                                    DisableControl = false
                                    SetBag(pPed, true)
                                    IsInAction = false
                                end)
                            end
                        end
                    end
                end
            end
        elseif InDutty or (IsDutty and GetSelectedPedWeapon(pPed) ~= HashBag) or Route then
            IsInAction = false
            
            ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
                TriggerEvent('skinchanger:loadSkin', skin)
            end)
            ClothesChanged = false
            if Route then
                for i, blip in pairs(Route) do
                    RemoveBlip(blip)
                end
                Route = nil
            end

            if Garage then
                for i, blip in pairs(Garage) do
                    RemoveBlip(blip)
                end
                Garage = nil
            end
        end
        Citizen.Wait(Wait)
    end
end)
