-- Lavet af: OMikkel#3217
-- Script: omik_attachments

vRPc = {}
vRP = Proxy.getInterface("vRP")
Tunnel.bindInterface("omik_attachments",vRPc)
Proxy.addInterface("omik_attachments",vRPc)
OMserver = Tunnel.getInterface("omik_attachments","omik_attachments")

RegisterNetEvent("omik_attachments:CloseMenu")
AddEventHandler("omik_attachments:CloseMenu", function()
    CloseMenu()
end)

RegisterNUICallback("CloseMenu", function(data,cb)
    CloseMenu()
    cb("ok")
end)

RegisterNUICallback("AttachExtra", function(data,cb)
    AddComponent(data.attachment)
    cb("ok")
end)

-- Hotkey del
Citizen.CreateThread(function()
	while Config.hotkey[1] and Config.locations do
        Citizen.Wait(1)
        local Pcoords = GetEntityCoords(GetPlayerPed(-1))
        local isHoldingWeapon, selectedWeapon = GetCurrentPedWeapon(GetPlayerPed(-1))
        selectedWeapon = tostring(selectedWeapon)
        for k,v in pairs(Config.locations) do
            if GetDistanceBetweenCoords(Pcoords, v[1], v[2], v[3], true) < Config.visible then
                DrawMarker(v[4], v[1], v[2], v[3] - 1, 0, 0, 0, 0, 0, 0, Config.reach, Config.reach, Config.reach, v[5], v[6], v[7] ,255, 0, 0, 0, 0)
            end
            if GetDistanceBetweenCoords(Pcoords, v[1], v[2], v[3], true) < Config.reach then
                if Config.weapons[selectedWeapon] ~= nil then
                    Draw3DText(v[1], v[2], v[3], Config.hovertext..Config.weapons[selectedWeapon][1])
                else
                    Draw3DText(v[1], v[2], v[3], Config.hovertext.."Ugyldigt våben...")
                end
                if IsControlJustReleased(0, Config.hotkey[2]) then
                    if Config.weapons[selectedWeapon] ~= nil then
                        OMserver.hasPlayerPermission({selectedWeapon})
                        --OpenMenu(tostring(selectedWeapon))
                    end
                end
            end
        end

	end
end)

function Draw3DText(x, y, z, text)
	local onScreen, _x, _y = World3dToScreen2d(x, y, z)
	local px, py, pz = table.unpack(GetGameplayCamCoords())

	SetTextScale(0.35, 0.35)
	SetTextFont(4)
	SetTextProportional(1)
	SetTextColour(255, 255, 255, 215)
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(_x, _y)
	local factor = (string.len(text)) / 370
	DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 20,20,20,150)
end

function AddComponent(attachment)
    local Ped = GetPlayerPed(-1)
    local isHoldingWeapon, selectedWeapon = GetCurrentPedWeapon(Ped)
    print(isHoldingWeapon, selectedWeapon, attachment)
    if attachment ~= nil then
        GiveWeaponComponentToPed(Ped, selectedWeapon, GetHashKey(attachment))
    end
end

function CloseMenu()
    SetNuiFocus(false, false)
    SendNUIMessage({status = "CloseMenu"})
end
function vRPc.OpenMenu(selectedWeapon)
    SetNuiFocus(true, true)
    SendNUIMessage({status = "OpenMenu", action = "AddAttachments", table = Config.attachments[selectedWeapon], info = Config.weapons[selectedWeapon]})
end