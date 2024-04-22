ESX = exports["es_extended"]:getSharedObject()

RegisterNetEvent("Garbage:Reward")
AddEventHandler("Garbage:Reward", function(Amount, Boolean)
    if Boolean then
        local Player = ESX.GetPlayerFromId(source)

        Player.addAccountMoney(Shared.AccountReward, Amount)
    end
end)