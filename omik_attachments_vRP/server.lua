-- Lavet af: OMikkel#3217
-- Script: omik_attachments

local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

vRPs = {}
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP","omik_attachments")
OMclient = Tunnel.getInterface("omik_attachments","omik_attachments")
Tunnel.bindInterface("omik_attachments",vRPs)
MySQL = module("vrp_mysql", "MySQL")

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() == resourceName) then
        TriggerClientEvent("omik_attachments:CloseMenu", -1)
    end
end)

function vRPs.hasPlayerPermission(selectedWeapon)
	local _source = source
    local user_id = vRP.getUserId({_source})
    if vRP.hasPermission({user_id, Config.openPerm}) then
        OMclient.OpenMenu(_source, {selectedWeapon})
    else
        TriggerClientEvent("pNotify:SendNotification", _source,{text ="⛔️ Du har ikke lov til at åbne denne menu ⛔️", type = "error", queue = "global",timeout = 4000, layout = "bottomCenter",animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"},killer = true})
    end
end