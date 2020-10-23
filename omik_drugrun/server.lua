-- Script: omik_drugrun
-- Author: OMikkel#3217

local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP","omik_drugrun")

RegisterServerEvent("omik_drugrun:payPlayer")
AddEventHandler("omik_drugrun:payPlayer", function(pay)
    local user_id = vRP.getUserId({source})
    if user_id ~= nil then
        if config.receiveBlackmoney then
            vRP.giveInventoryItem({user_id,config.blackmoneyname,pay,true})
        elseif config.receiveBankmoney then
            vRP.giveBankMoney({user_id,pay})
        else
            vRP.giveMoney({user_id,pay})
        end
    end
end)