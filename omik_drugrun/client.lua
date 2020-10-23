-- Script: omik_drugrun
-- Author: OMikkel#3217

-- Variabler til start delen af scriptet
local StartPed = nil
local Sposition = nil
local StartBlip = nil
local SC = {}

local J = { -- Job variabler, egentlig bare fordi jeg ikke magter at se på de lange config.xxxxx table henvisninger, så har jeg samlet det hele under table J
    JobCooldown = 0,
    Jposition = nil,
    JC = {},
    JobCat = nil,
    JobDrug = nil,
    JobVehicle = nil,
    JCLP = {},
    JCDEST = {
        number = 1
    },
    JobPed = nil,
    JobAD = nil,
    JobAN = nil,
    JobVehicleEnt = nil,
    JobPedEnt = nil,
    JPackages = {
        box = {},
        boxent = {},
        loaded = 0,
        totalPrice = 0
    },
    JobPedComb = 1
}

local STATUS = { -- Status variabler, egentlig bare fordi jeg ikke magter at rode koden igennem hver gang jeg skal bruge en ny variabel, så har jeg samlet det hele under table STATUS
    OnTheWayToVehicle = false,
    IsVehicleLockPicked = false,
    IsVehicleLoaded = false,
    IsDeliveryInProgress = false,
    IsVehicleUnloaded = false,
    IsDeliveryDone = false,
    PedIsInVehicle = false,
    CreateNewDestPed = true,
    DrivingToWaypoint = false
}

-- Udregner cooldown tilbage
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if J.JobCooldown > 0 then 
            J.JobCooldown = J.JobCooldown - 1000
        end
    end
end)

-- Spawner en StartPed til at starte et job
Citizen.CreateThread(function()
    while true do
        -- Hvis der allerede er en ped så bliver den slettet
        if DoesEntityExist(StartPed) then
            DeleteEntity(StartPed)
        end

        -- Her får vi hvilken spawnlokation startped skal spawne på
        local PSposition = Sposition
        Sposition = math.random(1,#config.locations.start)

        -- Her sørger vi for at de ikke spawner det samme sted 2 gange
        if PSposition == Sposition then
            if Sposition + 1 < #config.locations.start then
                Sposition = Sposition + 1 
            elseif Sposition - 1 > 0 and Sposition - 1 < #config.locations.start then
                Sposition = Sposition - 1
            end
        end
        SC.x,SC.y,SC.z,SC.h = config.locations.start[Sposition].coords[1], config.locations.start[Sposition].coords[2], config.locations.start[Sposition].coords[3], config.locations.start[Sposition].heading

        -- her spawner vi start ped
        if config.npcs then
            RequestModel(GetHashKey(config.locations.start[Sposition].ped))
			while not HasModelLoaded(GetHashKey(config.locations.start[Sposition].ped)) do
				Citizen.Wait(1)
			end
			StartPed = CreatePed(4, GetHashKey(config.locations.start[Sposition].ped), SC.x,SC.y,SC.z - 1.0, SC.h, false, true)
            SetBlockingOfNonTemporaryEvents(StartPed, true)
            SetEntityInvincible(StartPed, true)
            SetPedFleeAttributes(StartPed, 0, false)
            FreezeEntityPosition(StartPed, true)
			RequestAnimDict(config.locations.start[Sposition].animdict)
			while not HasAnimDictLoaded(config.locations.start[Sposition].animdict) do
				Citizen.Wait(1)
			end
            TaskPlayAnim(StartPed, config.locations.start[Sposition].animdict, config.locations.start[Sposition].animname, 8.0, -8, -1, 49, 0, 0, 0, 0)
        end

        -- her laver vi blips
        if config.blips and SC.x ~= nil then
            if StartBlip then RemoveBlip(StartBlip) end
            StartBlip = AddBlipForCoord(SC.x, SC.y, SC.z)
            SetBlipSprite (StartBlip, 51)
            SetBlipDisplay(StartBlip, 4)
            SetBlipScale  (StartBlip, 0.6)
            SetBlipColour (StartBlip, 1)
            SetBlipAsShortRange(StartBlip,true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(config.bliptext)
            EndTextCommandSetBlipName(StartBlip)
        end
        Citizen.Wait(config.npcswaptime*60000)
    end
end)



-- Laver 3D tekst og Marker
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)
		local pcoords = GetEntityCoords(GetPlayerPed(-1))

        -- Laver en marker under start ped
        if (GetDistanceBetweenCoords(pcoords, SC.x,SC.y,SC.z, true) < 100) and config.markers then
            DrawMarker(config.markertype, SC.x,SC.y,SC.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, config.markerscale[1], config.markerscale[2], config.markerscale[2], config.markercolor[1], config.markercolor[2], config.markercolor[3], 100, false, true, 2, false, false, false, false)
        end
        
        if J.JobCat == "ground" then
            -- Laver en marker under destinations ped
            if (GetDistanceBetweenCoords(pcoords, J.JCDEST.x,J.JCDEST.y,J.JCDEST.z, true) < 100) and config.markers then
                DrawMarker(config.markertype, J.JCDEST.x,J.JCDEST.y,J.JCDEST.z - 0.3, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, config.markerscale[1], config.markerscale[2], config.markerscale[2], config.markercolor[1], config.markercolor[2], config.markercolor[3], 100, false, true, 2, false, false, false, false)
            end
        elseif J.JobCat == "air" then
            -- Laver en marker over destinationen
            if (GetDistanceBetweenCoords(pcoords, J.JCDEST.x,J.JCDEST.y,J.JCDEST.z, true) < 1000) and config.markers then
                DrawMarker(6, J.JCDEST.x,J.JCDEST.y,J.JCDEST.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 25.0, 25.0, 25.0, 255, 0, 0, 100, false, true, 2, false, false, false, false)
            end
        elseif J.JobCat == "sea" then
        
        end

        -- Laver 3D tekst så man kan se hvad man skal trykke for at starte et nyt job
        if (GetDistanceBetweenCoords(pcoords, SC.x,SC.y,SC.z, true) < config.locations.start[Sposition].radius) then
            DrawText3Ds(SC.x,SC.y,SC.z, "Tryk ~g~[E]~w~ for at modtage et job")
        end
        
        -- Laver 3D tekst til papkasserne så man kan se at de kan samles op
        for i=1, #J.JPackages.boxent, 1 do
            local x,y,z = table.unpack(GetEntityCoords(J.JPackages.boxent[i]))
            if (GetDistanceBetweenCoords(pcoords, x,y,z, true) < 2.0) and not drugBoxInHand and not IsPedInAnyVehicle(GetPlayerPed(-1),false) and STATUS.IsVehicleLockPicked and DoesEntityExist(J.JobVehicleEnt) then
                DrawText3Ds(x,y,z + 0.5, "Tryk ~g~[E]~w~ for at samle kassen op")
            end
        end
	end
end)

-- Hvad skal der ske når E bliver trykket på tæt på en StartPed
Citizen.CreateThread(function()
	while true do
        Citizen.Wait(10)
        local pcoords = GetEntityCoords(GetPlayerPed(-1))

		if (GetDistanceBetweenCoords(pcoords, SC.x,SC.y,SC.z, true) < config.locations.start[Sposition].radius) then
            if IsControlJustReleased(0, 38) then
                if J.JobCooldown == nil or J.JobCooldown == 0 then
                    STATUS.IsDeliveryDone = false
                    -- sletter gamle props så de ikke spawner i hinanden
                    if DoesEntityExist(J.JobVehicleEnt) then
                        DeleteEntity(J.JobVehicleEnt)
                    end
                    if DoesEntityExist(J.JobPedEnt) then
                        DeleteEntity(J.JobPedEnt)
                    end
                    for i=1, #J.JPackages.boxent, 1 do
                        if DoesEntityExist(J.JPackages.boxent[i]) then
                            DeleteEntity(J.JPackages.boxent[i])
                        end
                    end
                    
                    -- Resetter hele lortet så det ikke bugger
                    STATUS.OnTheWayToVehicle,STATUS.IsVehicleLockPicked,STATUS.IsVehicleLoaded,STATUS.IsDeliveryInProgress,STATUS.IsVehicleUnloaded,STATUS.IsDeliveryDone,STATUS.DrivingToWaypoint,STATUS.CreateNewDestPed = false, false, false, false, false, false, false, true
                    J.JCDEST.x, J.JCDEST.y, J.JCDEST.z = nil, nil, nil
                    J.JobPedEnt, J.JobVehicleEnt = nil, nil
                    J.JPackages.loaded, J.JPackages.totalPrice = 0,0

                    -- udfylder en masse ligegyldige variabler
                    if config.locations.start[Sposition].jobs == "random" then
                        J.JobCat = math.random(2,3)
                        if J.JobCat == 2 then J.JobCat = "air" 
                        elseif J.JobCat == 3  then J.JobCat = "ground"
                        --elseif J.JobCat == 4 then J.JobCat = "sea"
                        end
                    else 
                        J.JobCat = tostring(config.locations.start[Sposition].jobs)
                    end
                    J.JCDEST.number = math.random(1, #config.destinations)
                    J.JobPedComb = math.random(1, #config.pedcombinations)
                    J.JCDEST.x, J.JCDEST.y, J.JCDEST.z = config.destinations[J.JCDEST.number].x, config.destinations[J.JCDEST.number].y, config.destinations[J.JCDEST.number].z
                    J.JobPed, J.JobAD, J.JobAN = config.pedcombinations[J.JobPedComb].ped,config.pedcombinations[J.JobPedComb].animdict, config.pedcombinations[J.JobPedComb].animname
                    if J.JobCat == "air" then 
                        J.JCDEST.x, J.JCDEST.y, J.JCDEST.z = config.destinations[J.JCDEST.number].x, config.destinations[J.JCDEST.number].y, config.destinations[J.JCDEST.number].z + 250
                        J.Jposition = math.random(1, #config.locations.air)
                        J.JC.x,J.JC.y,J.JC.z,J.JC.h = config.locations.air[J.Jposition].coords[1], config.locations.air[J.Jposition].coords[2], config.locations.air[J.Jposition].coords[3], config.locations.air[J.Jposition].heading
                        J.JCLP.x,J.JCLP.y,J.JCLP.z,J.JCLP.h = config.locations.air[J.Jposition].lockpickcoords[1], config.locations.air[J.Jposition].lockpickcoords[2], config.locations.air[J.Jposition].lockpickcoords[3], config.locations.air[J.Jposition].lockpickheading
                        J.JobVehicle = config.locations.air[J.Jposition].vehicle
                        J.JPackages.box[1],J.JPackages.box[2],J.JPackages.box[3],J.JPackages.box[4],J.JPackages.box[5] = config.locations.air[J.Jposition].boxes[1], config.locations.air[J.Jposition].boxes[2], config.locations.air[J.Jposition].boxes[3], config.locations.air[J.Jposition].boxes[4], config.locations.air[J.Jposition].boxes[5]
                        if config.locations.air[J.Jposition].drugs == "random" then
                            J.JobDrug = math.random(1,3)
                            if J.JobDrug == 1 then J.JobDrug = "coke" 
                            elseif J.JobDrug == 2 then J.JobDrug = "meth"
                            elseif J.JobDrug == 3  then J.JobDrug = "weed"
                            end
                        else 
                            J.JobDrug = tostring(config.locations.air[J.Jposition].drugs)
                        end
                    elseif J.JobCat == "sea" then 
                        J.Jposition = math.random(1, #config.locations.sea)
                        J.JC.x,J.JC.y,J.JC.z,J.JC.h = config.locations.sea[J.Jposition].coords[1], config.locations.sea[J.Jposition].coords[2], config.locations.sea[J.Jposition].coords[3], config.locations.sea[J.Jposition].heading
                        J.JCLP.x,J.JCLP.y,J.JCLP.z,J.JCLP.h = config.locations.sea[J.Jposition].lockpickcoords[1], config.locations.sea[J.Jposition].lockpickcoords[2], config.locations.sea[J.Jposition].lockpickcoords[3], config.locations.sea[J.Jposition].lockpickheading
                        J.JobVehicle = config.locations.sea[J.Jposition].vehicle
                        J.JPackages.box[1],J.JPackages.box[2],J.JPackages.box[3],J.JPackages.box[4],J.JPackages.box[5] = config.locations.sea[J.Jposition].boxes[1], config.locations.sea[J.Jposition].boxes[2], config.locations.sea[J.Jposition].boxes[3], config.locations.sea[J.Jposition].boxes[4], config.locations.sea[J.Jposition].boxes[5]
                        if config.locations.sea[J.Jposition].drugs == "random" then
                            J.JobDrug = math.random(1,3)
                            if J.JobDrug == 1 then J.JobDrug = "coke" 
                            elseif J.JobDrug == 2 then J.JobDrug = "meth"
                            elseif J.JobDrug == 3  then J.JobDrug = "weed"
                            end
                        else 
                            J.JobDrug = tostring(config.locations.sea[J.Jposition].drugs)
                        end
                    elseif J.JobCat == "ground" then 
                        J.Jposition = math.random(1, #config.locations.ground)
                        J.JC.x,J.JC.y,J.JC.z,J.JC.h = config.locations.ground[J.Jposition].coords[1], config.locations.ground[J.Jposition].coords[2], config.locations.ground[J.Jposition].coords[3], config.locations.ground[J.Jposition].heading
                        J.JCLP.x,J.JCLP.y,J.JCLP.z,J.JCLP.h = config.locations.ground[J.Jposition].lockpickcoords[1], config.locations.ground[J.Jposition].lockpickcoords[2], config.locations.ground[J.Jposition].lockpickcoords[3], config.locations.ground[J.Jposition].lockpickheading
                        J.JobVehicle = config.locations.ground[J.Jposition].vehicle
                        J.JPackages.box[1],J.JPackages.box[2],J.JPackages.box[3],J.JPackages.box[4],J.JPackages.box[5] = config.locations.ground[J.Jposition].boxes[1], config.locations.ground[J.Jposition].boxes[2], config.locations.ground[J.Jposition].boxes[3], config.locations.ground[J.Jposition].boxes[4], config.locations.ground[J.Jposition].boxes[5]
                        if config.locations.ground[J.Jposition].drugs == "random" then
                            J.JobDrug = math.random(1,3)
                            if J.JobDrug == 1 then J.JobDrug = "coke" 
                            elseif J.JobDrug == 2 then J.JobDrug = "meth"
                            elseif J.JobDrug == 3  then J.JobDrug = "weed"
                            end
                        else 
                            J.JobDrug = tostring(config.locations.ground[J.Jposition].drugs)
                        end
                    end
                    if J.JobDrug == "coke" then
                        J.JPackages.max = config.drugs.coke.boxes
                    elseif J.JobDrug == "meth" then
                        J.JPackages.max = config.drugs.meth.boxes
                    elseif J.JobDrug == "weed" then
                        J.JPackages.max = config.drugs.weed.boxes
                    end
                                        
                    -- Sætter waypoint, spawner køretøj, spawner papkasser og sætter cooldown samt sender notifikation
                    SetNewWaypoint(J.JC.x+0.0001,J.JC.y+0.0001)
                    SpawnVehicle(J.JC.x,J.JC.y,J.JC.z,J.JC.h,J.JobVehicle)
                    SpawnBoxes(J.JPackages.max)
                    J.JobCooldown = (config.jobcooldown*60000)
                    TriggerEvent("pNotify:SendNotification",{text = "<h3>Du startede et nyt job, følg din GPS 🛰️</h3>",type = "info",timeout = (4000),layout = "centerRight",queue = "global",animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}})  
                    STATUS.OnTheWayToVehicle = true
                else
                    -- Sender en notifikation hvis man stadig har cooldown
                    TriggerEvent("pNotify:SendNotification",{text = "<h3>Du har stadig "..math.floor((J.JobCooldown / 1000)).." sekunder tilbage før du kan starte et nyt job ⏳</h3>",type = "info",timeout = (4000),layout = "centerRight",queue = "global",animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}})  
                    Citizen.Wait(500)
                end
            end
        end
	end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local pcoords = GetEntityCoords(GetPlayerPed(-1))
        local VehiclePosition = GetEntityCoords(J.JobVehicleEnt) 
        
        if J.JobCat == "ground" then
            -- Sætter vejledende tekst på skærmen
            if STATUS.OnTheWayToVehicle == true and not STATUS.IsDeliveryDone then
                DrawScreenHelpText("Kør hen til målet på din GPS")
            end
            if STATUS.DrivingToWaypoint == true  and not STATUS.IsDeliveryDone then
                DrawScreenHelpText("Kør hen til målet på din GPS")
            end
            if (GetDistanceBetweenCoords(pcoords, VehiclePosition.x, VehiclePosition.y, VehiclePosition.z, true) <= 10) and not STATUS.IsVehicleLoaded and not STATUS.IsDeliveryInProgress  and not STATUS.IsDeliveryDone then
                STATUS.OnTheWayToVehicle = false
                DrawScreenHelpText("Lås køretøjet op og last derefter køretøjet")
            end
            if (GetDistanceBetweenCoords(pcoords, J.JCDEST.x,J.JCDEST.y,J.JCDEST.z, true) <= 10)  and not STATUS.IsDeliveryDone then
                DrawScreenHelpText("Aflever dine pakker til køberen")
            end
            if (GetDistanceBetweenCoords(pcoords, J.JCDEST.x,J.JCDEST.y,J.JCDEST.z, true) <= 10)  and not STATUS.IsDeliveryDone then
                STATUS.DrivingToWaypoint = false
            end


            -- Aktiverer lockpick delen af køretøjet
            if (GetDistanceBetweenCoords(pcoords, VehiclePosition.x, VehiclePosition.y, VehiclePosition.z, true) <= 3) and STATUS.IsVehicleLockPicked == false then
                DrawText3Ds(VehiclePosition.x, VehiclePosition.y, VehiclePosition.z, "Tryk ~g~[E]~w~ for at låse køretøjet op")
                if IsControlJustPressed(0, 38) then 
                    LockpickVehicle()
                    Citizen.Wait(500)
                end
            end

            -- Tegner 3D tekst som viser hvor meget køretøjet er fyldt
            if (GetDistanceBetweenCoords(pcoords, VehiclePosition.x, VehiclePosition.y, VehiclePosition.z, true) <= 5) and STATUS.IsVehicleLockPicked == true and not IsPedInAnyVehicle(GetPlayerPed(-1),false) and not STATUS.IsDeliveryDone then
                DrawText3Ds(VehiclePosition.x, VehiclePosition.y, VehiclePosition.z, J.JPackages.loaded.."/"..J.JPackages.max.." "..J.JobDrug.." pakker er lastet")
                print(STATUS.IsVehicleLockPicked)
                print(IsPedInAnyVehicle(GetPlayerPed(-1),false))
                print(STATUS.IsDeliveryDone)
                print(GetDistanceBetweenCoords(pcoords, VehiclePosition.x, VehiclePosition.y, VehiclePosition.z, true))
            end

            -- Hvis bilen er lastet med alle pakkerne, så sætter den waypoint til destinationen
            if J.JPackages.loaded == J.JPackages.max then
                STATUS.IsVehicleLoaded = true
                STATUS.IsDeliveryInProgress = true
                SetNewWaypoint(J.JCDEST.x+0.0001,J.JCDEST.y+0.0001)
                STATUS.DrivingToWaypoint = true

                if STATUS.CreateNewDestPed == true then
                    -- Hvis der allerede er en ped så bliver den slettet
                    if DoesEntityExist(J.JobPedEnt) then
                        DeleteEntity(J.JobPedEnt)
                    end
                    -- her spawner vi destination ped
                    if config.npcs then
                        RequestModel(tonumber(J.JobPed))
                        local i = 0
                        while not HasModelLoaded(tonumber(J.JobPed)) and i < 3000 do
                            Citizen.Wait(1)
                            i = i + 1
                        end
                        J.JobPedEnt = CreatePed(4, tonumber(J.JobPed), J.JCDEST.x,J.JCDEST.y,J.JCDEST.z - 0.3, 180.0, false, true)
                        SetBlockingOfNonTemporaryEvents(J.JobPedEnt, true)
                        SetEntityInvincible(J.JobPedEnt, true)
                        SetPedFleeAttributes(J.JobPedEnt, 0, false)
                        FreezeEntityPosition(J.JobPedEnt, true)
                        RequestAnimDict(J.JobAD)
                        while not HasAnimDictLoaded(J.JobAD) do
                            Citizen.Wait(1)
                        end
                        TaskPlayAnim(J.JobPedEnt, J.JobAD, J.JobAN, 8.0, -8, -1, 49, 0, 0, 0, 0)
                        STATUS.CreateNewDestPed = false
                    end
                end

            end

            -- Gør så man kan samle kasser op når man er tæt på
            for i=1, #J.JPackages.boxent, 1 do
                local x,y,z = table.unpack(GetEntityCoords(J.JPackages.boxent[i]))
                if (GetDistanceBetweenCoords(pcoords, x,y,z, true) < 2.0) then
                    if not drugBoxInHand and IsControlJustPressed(0, 38) and not IsPedInAnyVehicle(GetPlayerPed(-1),false) then
                        if IsEntityAttachedToEntity(J.JPackages.boxent[i], J.JobVehicleEnt) then
                            RequestAnimDict("anim@heists@box_carry@")
                            while not HasAnimDictLoaded("anim@heists@box_carry@") do
                                Citizen.Wait(10)
                            end
                            TaskPlayAnim(GetPlayerPed(-1),"anim@heists@box_carry@","idle",1.0, -1.0, -1, 49, 0, 0, 0, 0)
                            Citizen.Wait(300)
                            local boneNumber = 28422
                            SetCurrentPedWeapon(GetPlayerPed(-1), 0xA2719263) 
                            local bone = GetPedBoneIndex(GetPlayerPed(-1), boneNumber)
                            attachedprop = J.JPackages.boxent[i]
                            AttachEntityToEntity(J.JPackages.boxent[i], GetPlayerPed(-1), bone, 0.0, 0.0, 0.0, 135.0, 0.0, 0.0, 1, 1, 0, 0, 2, 1)
                            SetEntityVisible(attachedprop, true)
                            drugBoxInHand = true
                            J.JPackages.loaded = J.JPackages.loaded - 1
                        else
                            RequestAnimDict("anim@heists@box_carry@")
                            while not HasAnimDictLoaded("anim@heists@box_carry@") do
                                Citizen.Wait(10)
                            end
                            TaskPlayAnim(GetPlayerPed(-1),"anim@heists@box_carry@","idle",1.0, -1.0, -1, 49, 0, 0, 0, 0)
                            Citizen.Wait(300)
                            local boneNumber = 28422
                            SetCurrentPedWeapon(GetPlayerPed(-1), 0xA2719263) 
                            local bone = GetPedBoneIndex(GetPlayerPed(-1), boneNumber)
                            attachedprop = J.JPackages.boxent[i]
                            AttachEntityToEntity(J.JPackages.boxent[i], GetPlayerPed(-1), bone, 0.0, 0.0, 0.0, 135.0, 0.0, 0.0, 1, 1, 0, 0, 2, 1)
                            SetEntityVisible(attachedprop, true)
                            drugBoxInHand = true
                        end
                    end
                end
            end

            -- Gør så man kan laste køretøjet når man er tæt på
            if (GetDistanceBetweenCoords(pcoords, VehiclePosition.x,VehiclePosition.y,VehiclePosition.z, true) < 2.0) and drugBoxInHand then
                DrawText3Ds(VehiclePosition.x,VehiclePosition.y,VehiclePosition.z + 1.0, "Tryk ~g~[E]~w~ for at laste køretøjet")
                if drugBoxInHand and IsControlJustPressed(0, 38) and not IsPedInAnyVehicle(GetPlayerPed(-1),false) then
                    AttachEntityToEntity(attachedprop, J.JobVehicleEnt, GetEntityBoneIndexByName(J.JobVehicleEnt, "chassis"), 0.0, 0.0, 0.0, 135.0, 0.0, 0.0, 1, 1, 0, 0, 2, 1)
                    SetEntityVisible(attachedprop, false)
                    ClearPedTasks(GetPlayerPed(-1))
                    drugBoxInHand = false
                    attachedprop = nil
                    J.JPackages.loaded = J.JPackages.loaded + 1
                end
            end

            -- Denne del sørger for at man får penge for det man sælger og at man køre et nyt sted hen hver gang
            if (GetDistanceBetweenCoords(pcoords, J.JCDEST.x,J.JCDEST.y,J.JCDEST.z, true) < 1.5) and drugBoxInHand then
                DrawText3Ds(J.JCDEST.x,J.JCDEST.y,J.JCDEST.z + 0.7, "Tryk ~g~[E]~w~ for at aflevere en pakke")
                if drugBoxInHand and IsControlJustPressed(0, 38) and not IsPedInAnyVehicle(GetPlayerPed(-1),false) then
                    local boneNumber = 28422
                    SetCurrentPedWeapon(J.JobPedEnt, 0xA2719263) 
                    local bone = GetPedBoneIndex(J.JobPedEnt, boneNumber)
                    AttachEntityToEntity(attachedprop, J.JobPedEnt, bone, 0.0, 0.0, 0.0, 135.0, 0.0, 0.0, 1, 1, 0, 0, 2, 1)
                    SetEntityVisible(attachedprop, true)
                    SetEntityAsNoLongerNeeded(attachedprop)
                    PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 0)
                    ClearPedTasks(GetPlayerPed(-1))
                    attachedprop = nil
                    drugBoxInHand = false

                    if J.JobDrug == "coke" then
                        price = math.random(config.drugs.coke.sellprice[1], config.drugs.coke.sellprice[2])
                    elseif J.JobDrug == "meth" then
                        price = math.random(config.drugs.meth.sellprice[1], config.drugs.meth.sellprice[2])
                    elseif J.JobDrug == "weed" then
                        price = math.random(config.drugs.weed.sellprice[1], config.drugs.weed.sellprice[2])
                    end
                    J.JPackages.totalPrice = J.JPackages.totalPrice + price
                    if J.JPackages.loaded >= 1 then
                        TriggerEvent("pNotify:SendNotification",{text = "<h3>Du afleverede en kasse og modtog "..math.floor(price).." - Du har "..J.JPackages.loaded.." pakker tilbage</h3>",type = "info",timeout = (4000),layout = "centerRight",queue = "global",animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}})  
                        TriggerServerEvent("omik_drugrun:payPlayer", price)
                        
                        local Pnumber = J.JCDEST.number
                        local Pped = J.JobPedComb
                        J.JCDEST.number = math.random(1,#config.destinations)
                        J.JobPedComb = math.random(1,#config.pedcombinations)

                        -- Her sørger vi for at de ikke spawner det samme sted 2 gange
                        if Pnumber == J.JCDEST.number then
                            if J.JCDEST.number + 1 < #config.destinations then
                                J.JCDEST.number = J.JCDEST.number + 1 
                            elseif J.JCDEST.number - 1 > 0 and J.JCDEST.number - 1 < #config.destinations then
                                J.JCDEST.number = J.JCDEST.number - 1
                            end
                        end
                        if Pped == J.JobPedComb then
                            if J.JobPedComb + 1 < #config.pedcombinations then
                                J.JobPedComb = J.JobPedComb + 1 
                            elseif J.JobPedComb - 1 > 0 and J.JobPedComb - 1 < #config.pedcombinations then
                                J.JobPedComb = J.JobPedComb - 1
                            end
                        end
                        J.JCDEST.x, J.JCDEST.y,J.JCDEST.z = config.destinations[J.JCDEST.number].x,config.destinations[J.JCDEST.number].y,config.destinations[J.JCDEST.number].z
                        J.JobPed, J.JobAD, J.JobAN = config.pedcombinations[J.JobPedComb].ped,config.pedcombinations[J.JobPedComb].animdict, config.pedcombinations[J.JobPedComb].animname
                        SetNewWaypoint(J.JCDEST.x+0.0001,J.JCDEST.y+0.0001)
                        STATUS.DrivingToWaypoint = true
                        ForgetPed(J.JobPedEnt)
                        print("YES")
            
                        -- her spawner vi destination ped
                        if config.npcs then
                            RequestModel(tonumber(J.JobPed))
                            local i = 0
                            while not HasModelLoaded(tonumber(J.JobPed)) and i < 3000 do
                                Citizen.Wait(1)
                                i = i + 1
                            end
                            J.JobPedEnt = CreatePed(4, tonumber(J.JobPed), J.JCDEST.x,J.JCDEST.y,J.JCDEST.z - 0.5, 180.0, false, true)
                            SetBlockingOfNonTemporaryEvents(J.JobPedEnt, true)
                            SetEntityInvincible(J.JobPedEnt, true)
                            SetPedFleeAttributes(J.JobPedEnt, 0, false)
                            FreezeEntityPosition(J.JobPedEnt, true)
                            RequestAnimDict(J.JobAD)
                            while not HasAnimDictLoaded(J.JobAD) do
                                Citizen.Wait(1)
                            end
                            TaskPlayAnim(J.JobPedEnt, J.JobAD, J.JobAN, 8.0, -8, -1, 49, 0, 0, 0, 0)
                        end
                    elseif J.JPackages.loaded <= 0 then
                        TriggerServerEvent("omik_drugrun:payPlayer", price)
                        TriggerEvent("pNotify:SendNotification",{text = "<h3>Du færdiggjorde jobbet og modtog i alt "..math.floor(J.JPackages.totalPrice).."</h3>",type = "info",timeout = (4000),layout = "centerRight",queue = "global",animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}})  
                        STATUS.IsDeliveryDone = true
                        ForgetPed(J.JobPedEnt)

                        -- Resetter hele lortet så det ikke bugger
                        STATUS.OnTheWayToVehicle,STATUS.IsVehicleLockPicked,STATUS.IsVehicleLoaded,STATUS.IsDeliveryInProgress,STATUS.IsVehicleUnloaded,STATUS.IsDeliveryDone,STATUS.DrivingToWaypoint,STATUS.CreateNewDestPed = false, false, false, false, false, false, false, true
                        J.JCDEST.x, J.JCDEST.y, J.JCDEST.z = nil, nil, nil
                        J.JobPedEnt, J.JobVehicleEnt = nil, nil
                        J.JPackages.loaded, J.JPackages.totalPrice = 0,0
                    end
                end
            end
        elseif J.JobCat == "air" then
            -- Sætter vejledende tekst på skærmen
            if STATUS.OnTheWayToVehicle == true and not STATUS.IsDeliveryDone then
                DrawScreenHelpText("Kør hen til målet på din GPS")
            end
            if STATUS.DrivingToWaypoint == true  and not STATUS.IsDeliveryDone then
                DrawScreenHelpText("Flyv hen til målet på din GPS")
            end
            if (GetDistanceBetweenCoords(pcoords, VehiclePosition.x, VehiclePosition.y, VehiclePosition.z, true) <= 10) and not STATUS.IsVehicleLoaded and not STATUS.IsDeliveryInProgress  and not STATUS.IsDeliveryDone then
                STATUS.OnTheWayToVehicle = false
                DrawScreenHelpText("Lås køretøjet op og last derefter køretøjet")
            end
            if (GetDistanceBetweenCoords(pcoords, J.JCDEST.x,J.JCDEST.y,J.JCDEST.z, true) <= 50)  and not STATUS.IsDeliveryDone then
                DrawScreenHelpText("Smid en pakke indenfor området")
                STATUS.DrivingToWaypoint = false
            end

            -- Aktiverer lockpick delen af køretøjet
            if (GetDistanceBetweenCoords(pcoords, VehiclePosition.x, VehiclePosition.y, VehiclePosition.z, true) <= 3) and STATUS.IsVehicleLockPicked == false then
                DrawText3Ds(VehiclePosition.x, VehiclePosition.y, VehiclePosition.z, "Tryk ~g~[E]~w~ for at låse køretøjet op")
                if IsControlJustPressed(0, 38) then 
                    LockpickVehicle()
                    Citizen.Wait(500)
                end
            end

            -- Tegner 3D tekst som viser hvor meget køretøjet er fyldt
            if (GetDistanceBetweenCoords(pcoords, VehiclePosition.x, VehiclePosition.y, VehiclePosition.z, true) <= 5) and STATUS.IsVehicleLockPicked == true and not IsPedInAnyVehicle(GetPlayerPed(-1),false) and not STATUS.IsDeliveryDone then
                DrawText3Ds(VehiclePosition.x, VehiclePosition.y, VehiclePosition.z, J.JPackages.loaded.."/"..J.JPackages.max.." "..J.JobDrug.." pakker er lastet")
            end

            -- Hvis bilen er lastet med alle pakkerne, så sætter den waypoint til destinationen
            if J.JPackages.loaded == J.JPackages.max then
                STATUS.IsVehicleLoaded = true
                STATUS.IsDeliveryInProgress = true
                SetNewWaypoint(J.JCDEST.x+0.0001,J.JCDEST.y+0.0001)
                STATUS.DrivingToWaypoint = true
            end

            -- Gør så man kan samle kasser op når man er tæt på
            for i=1, #J.JPackages.boxent, 1 do
                local x,y,z = table.unpack(GetEntityCoords(J.JPackages.boxent[i]))
                if (GetDistanceBetweenCoords(pcoords, x,y,z, true) < 2.0) then
                    if not drugBoxInHand and IsControlJustPressed(0, 38) and not IsPedInAnyVehicle(GetPlayerPed(-1),false) then
                        if IsEntityAttachedToEntity(J.JPackages.boxent[i], J.JobVehicleEnt) then
                            RequestAnimDict("anim@heists@box_carry@")
                            while not HasAnimDictLoaded("anim@heists@box_carry@") do
                                Citizen.Wait(10)
                            end
                            TaskPlayAnim(GetPlayerPed(-1),"anim@heists@box_carry@","idle",1.0, -1.0, -1, 49, 0, 0, 0, 0)
                            Citizen.Wait(300)
                            local boneNumber = 28422
                            SetCurrentPedWeapon(GetPlayerPed(-1), 0xA2719263) 
                            local bone = GetPedBoneIndex(GetPlayerPed(-1), boneNumber)
                            attachedprop = J.JPackages.boxent[i]
                            AttachEntityToEntity(J.JPackages.boxent[i], GetPlayerPed(-1), bone, 0.0, 0.0, 0.0, 135.0, 0.0, 0.0, 1, 1, 0, 0, 2, 1)
                            SetEntityVisible(attachedprop, true)
                            drugBoxInHand = true
                            J.JPackages.loaded = J.JPackages.loaded - 1
                        else
                            RequestAnimDict("anim@heists@box_carry@")
                            while not HasAnimDictLoaded("anim@heists@box_carry@") do
                                Citizen.Wait(10)
                            end
                            TaskPlayAnim(GetPlayerPed(-1),"anim@heists@box_carry@","idle",1.0, -1.0, -1, 49, 0, 0, 0, 0)
                            Citizen.Wait(300)
                            local boneNumber = 28422
                            SetCurrentPedWeapon(GetPlayerPed(-1), 0xA2719263) 
                            local bone = GetPedBoneIndex(GetPlayerPed(-1), boneNumber)
                            attachedprop = J.JPackages.boxent[i]
                            AttachEntityToEntity(J.JPackages.boxent[i], GetPlayerPed(-1), bone, 0.0, 0.0, 0.0, 135.0, 0.0, 0.0, 1, 1, 0, 0, 2, 1)
                            SetEntityVisible(attachedprop, true)
                            drugBoxInHand = true
                        end
                    end
                end
            end

            -- Gør så man kan laste køretøjet når man er tæt på
            if (GetDistanceBetweenCoords(pcoords, VehiclePosition.x,VehiclePosition.y,VehiclePosition.z, true) < 2.0) and drugBoxInHand then
                DrawText3Ds(VehiclePosition.x,VehiclePosition.y,VehiclePosition.z + 0.5, "Tryk ~g~[E]~w~ for at laste køretøjet")
                if drugBoxInHand and IsControlJustPressed(0, 38) and not IsPedInAnyVehicle(GetPlayerPed(-1),false) then
                    AttachEntityToEntity(attachedprop, J.JobVehicleEnt, GetEntityBoneIndexByName(J.JobVehicleEnt, "chassis"), 0.0, 0.0, 0.0, 135.0, 0.0, 0.0, 1, 1, 0, 0, 2, 1)
                    SetEntityVisible(attachedprop, false)
                    ClearPedTasks(GetPlayerPed(-1))
                    drugBoxInHand = false
                    attachedprop = nil
                    J.JPackages.loaded = J.JPackages.loaded + 1
                end
            end

            -- Denne del sørger for at man får penge for det man sælger og at man køre et nyt sted hen hver gang
            if (GetDistanceBetweenCoords(pcoords, J.JCDEST.x,J.JCDEST.y,J.JCDEST.z, true) < 50) and J.JPackages.loaded > 0 then
                DrawText3Ds(J.JCDEST.x,J.JCDEST.y,J.JCDEST.z + 0.7, "Tryk ~g~[E]~w~ for at smide en pakke")
                if IsControlJustPressed(0, 38) then
                    OpenBombBayDoors(J.JobVehicleEnt)
                    local box = GetHashKey("prop_cs_cardbox_01")
                    local x,y,z = table.unpack(GetEntityCoords(GetPlayerPed(-1)))

                    RequestModel(box)
                    while not HasModelLoaded(box) do
                        Citizen.Wait(1)
                    end
                    
                    airDrop = CreateObject(box, VehiclePosition.x, VehiclePosition.y, VehiclePosition.z, true, true, false)
                    SetEntityVisible(airDrop, true)
                    SetEntityLodDist(airDrop, 1000)
                    FreezeEntityPosition(airDrop, false)
                    if not HasNamedPtfxAssetLoaded("scr_ar_planes") then
                        RequestNamedPtfxAsset("scr_ar_planes")
                        local i = 0
                        while not HasNamedPtfxAssetLoaded("scr_ar_planes") and i < 3000 do
                            Wait(1)
                            i = i + 1
                        end
                    end
                    
                    UseParticleFxAssetNextCall("scr_ar_planes")
                    particle = StartParticleFxLoopedOnEntity("scr_ar_trail_smoke",airDrop,0.0,0.0,0.5,0.0,0.0,0.0,0.5,true,true,true)
                    SetParticleFxLoopedColour(particle, 255.0, 0.0, 0.0)
                    PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 0)
                    ClearPedTasks(GetPlayerPed(-1))
                    
                    J.JPackages.loaded = J.JPackages.loaded - 1
                    if J.JobDrug == "coke" then
                        price = math.random(config.drugs.coke.sellprice[1], config.drugs.coke.sellprice[2])
                    elseif J.JobDrug == "meth" then
                        price = math.random(config.drugs.meth.sellprice[1], config.drugs.meth.sellprice[2])
                    elseif J.JobDrug == "weed" then
                        price = math.random(config.drugs.weed.sellprice[1], config.drugs.weed.sellprice[2])
                    end
                    J.JPackages.totalPrice = J.JPackages.totalPrice + price
                    StopParticles(particle)
                    if J.JPackages.loaded >= 1 then
                        TriggerEvent("pNotify:SendNotification",{text = "<h3>Du afleverede en kasse og modtog "..math.floor(price).." - Du har "..J.JPackages.loaded.." pakker tilbage</h3>",type = "info",timeout = (4000),layout = "centerRight",queue = "global",animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}})  
                        TriggerServerEvent("omik_drugrun:payPlayer", price)
                        
                        local Pnumber = J.JCDEST.number
                        local Pped = J.JobPedComb
                        J.JCDEST.number = math.random(1,#config.destinations)
                        J.JobPedComb = math.random(1,#config.pedcombinations)

                        -- Her sørger vi for at de ikke spawner det samme sted 2 gange
                        if Pnumber == J.JCDEST.number then
                            if J.JCDEST.number + 1 < #config.destinations then
                                J.JCDEST.number = J.JCDEST.number + 1 
                            elseif J.JCDEST.number - 1 > 0 and J.JCDEST.number - 1 < #config.destinations then
                                J.JCDEST.number = J.JCDEST.number - 1
                            end
                        end
                        if Pped == J.JobPedComb then
                            if J.JobPedComb + 1 < #config.pedcombinations then
                                J.JobPedComb = J.JobPedComb + 1 
                            elseif J.JobPedComb - 1 > 0 and J.JobPedComb - 1 < #config.pedcombinations then
                                J.JobPedComb = J.JobPedComb - 1
                            end
                        end
                        J.JCDEST.x, J.JCDEST.y,J.JCDEST.z = config.destinations[J.JCDEST.number].x,config.destinations[J.JCDEST.number].y,config.destinations[J.JCDEST.number].z + 250
                        J.JobPed, J.JobAD, J.JobAN = config.pedcombinations[J.JobPedComb].ped,config.pedcombinations[J.JobPedComb].animdict, config.pedcombinations[J.JobPedComb].animname
                        SetNewWaypoint(J.JCDEST.x+0.0001,J.JCDEST.y+0.0001)
                        STATUS.DrivingToWaypoint = true
                    elseif J.JPackages.loaded <= 0 then
                        TriggerServerEvent("omik_drugrun:payPlayer", price)
                        TriggerEvent("pNotify:SendNotification",{text = "<h3>Du færdiggjorde jobbet og modtog i alt "..math.floor(J.JPackages.totalPrice).."</h3>",type = "info",timeout = (4000),layout = "centerRight",queue = "global",animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}})  
                        SetNewWaypoint(J.JC.x+0.0001,J.JC.y+0.0001)
                        STATUS.IsDeliveryDone = true

                        -- Resetter hele lortet så det ikke bugger
                        STATUS.OnTheWayToVehicle,STATUS.IsVehicleLockPicked,STATUS.IsVehicleLoaded,STATUS.IsDeliveryInProgress,STATUS.IsVehicleUnloaded,STATUS.IsDeliveryDone,STATUS.DrivingToWaypoint,STATUS.CreateNewDestPed = false, false, false, false, false, false, false, true
                        J.JCDEST.x, J.JCDEST.y, J.JCDEST.z = nil, nil, nil
                        J.JobPedEnt, J.JobVehicleEnt = nil, nil
                        J.JPackages.loaded, J.JPackages.totalPrice = 0,0
                    end
                end
            end
        elseif J.JobCat == "sea" then
        
        end
    end
end)

-- For pedsne til at opføre sig som normalt
function ForgetPed(ped)
    SetEntityInvincible(ped,false)
    SetBlockingOfNonTemporaryEvents(ped, false)
    FreezeEntityPosition(ped, false)
    ped = SetPedAsNoLongerNeeded()
end

-- Stopper particles som bliver lavet ved airdrop
function StopParticles(particle)
    Wait(10000)
    StopParticleFxLooped(particle,0)
    CloseBombBayDoors(J.JobVehicleEnt)
end

-- Sørger for at man kan lockpicke køretøjet
function LockpickVehicle()
    local PlayerPed = GetPlayerPed(-1)
	local animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
	local animName = "machinic_loop_mechandplayer"
	
	RequestAnimDict(animDict)
	while not HasAnimDictLoaded(animDict) do
		Citizen.Wait(50)
	end
	
	SetCurrentPedWeapon(PlayerPed, GetHashKey("WEAPON_UNARMED"),true)
	Citizen.Wait(500)
	FreezeEntityPosition(PlayerPed, true)
	TaskPlayAnimAdvanced(PlayerPed, animDict, animName, J.JCLP.x, J.JCLP.y, J.JCLP.z, 0.0, 0.0, J.JCLP.h, 3.0, 1.0, -1, 31, 0, 0, 0 )

	exports['progressBars']:startUI(7500, "Låser køretøjet op")
	Citizen.Wait(7500)
	
	ClearPedTasks(PlayerPed)
	FreezeEntityPosition(PlayerPed, false)
	STATUS.IsVehicleLockPicked = true
	SetVehicleDoorsLockedForAllPlayers(J.JobVehicleEnt, false)
end

-- Sørger for at spawne papkasserne
function SpawnBoxes(max)
    for i=1, max, 1 do
        local box = GetHashKey("prop_cs_cardbox_01")
        local x,y,z = J.JPackages.box[i][1],J.JPackages.box[i][2],J.JPackages.box[i][3]

        RequestModel(box)
        while not HasModelLoaded(box) do
          Citizen.Wait(1)
        end
      
        J.JPackages.boxent[i] = CreateObject(box, x, y, z - 0.95, true, true, false)
        PlaceObjectOnGroundProperly(J.JPackages.boxent[i])
    end
end

-- Sørger for at spawne køretøjet
function SpawnVehicle(x,y,z,h,model)
    local mhash = GetHashKey(model)

    local i = 0
    while not HasModelLoaded(mhash) and i < 10000 do
        RequestModel(mhash)
        Citizen.Wait(10)
        i = i + 1
    end

    if HasModelLoaded(mhash) then
        J.JobVehicleEnt = CreateVehicle(mhash, x,y,z+0.5,h, true, false) -- added player heading
        SetVehicleOnGroundProperly(J.JobVehicleEnt)
        SetEntityInvincible(J.JobVehicleEnt,false)
        SetEntityAsMissionEntity(J.JobVehicleEnt, true, true) -- set as mission entity
        SetVehicleDoorsLockedForAllPlayers(J.JobVehicleEnt, true)
    end
end

-- Sørger for at 3D tekst bliver lavet
function DrawText3Ds(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370
    DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 0, 0, 0, 100)
end

-- Sørger for at den vejledende tekst bliver lavet
function DrawScreenHelpText(text)
    SetTextScale(0.5, 0.5)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextEntry("STRING")
    SetTextCentre(1)
    SetTextOutline()
    AddTextComponentString(text)
    DrawText(0.5,0.955)
end
