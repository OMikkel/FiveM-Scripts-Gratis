-------------------------------------------------------------------------
------- Created by T1GER#9080  - Converted to vRP by OMikkel#3217 -------
-------------------------------------------------------------------------

local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP","t1ger_drugs")
OMclient = Tunnel.getInterface("t1ger_drugs","t1ger_drugs")

-- START TEST
local JobCooldown 		= {}
local ConvertTimer		= {}
local DrugEffectTimer	= {}


------ DEFINES IMPORTANT ITEMS ------

for k,v in pairs(Config.ListOfDrugs) do
	if v.Enabled == true then
		vRP.defInventoryItem({v.drugcode,v.label,v.drugdesc,nil,v.drugweight})
	end
end
vRP.defInventoryItem({Config.HackerDevice,"HackerDevice USB","Can hack things",nil,0.01})


RegisterServerEvent("t1ger_drugs:syncJobsData")
AddEventHandler("t1ger_drugs:syncJobsData",function(data)
	TriggerClientEvent("t1ger_drugs:syncJobsData",-1,data)
end)

-- Server side table, to store cooldown for players:
RegisterServerEvent("t1ger_drugs:addCooldownToSource")
AddEventHandler("t1ger_drugs:addCooldownToSource",function(source)
	table.insert(JobCooldown,{cooldown = GetPlayerIdentifier(source), time = (Config.CooldownTime * 60000)})
end)

-- Server side table, to store convert timer for players:
RegisterServerEvent("t1ger_drugs:addConvertingTimer")
AddEventHandler("t1ger_drugs:addConvertingTimer",function(source,timer)
	table.insert(ConvertTimer,{convertWait = GetPlayerIdentifier(source), timeB = timer})
end)

-- Server side table, to store drug effect timer for players:
RegisterServerEvent("t1ger_drugs:addDrugEffectTimer")
AddEventHandler("t1ger_drugs:addDrugEffectTimer",function(source,timer)
	table.insert(DrugEffectTimer,{effectWait = GetPlayerIdentifier(source), timeC = timer})
end)

-- CreateThread Function for timer:
Citizen.CreateThread(function() -- do not touch this thread function!
	while true do
	Citizen.Wait(1000)
		for k,v in pairs(JobCooldown) do
			if v.time <= 0 then
				RemoveCooldown(v.cooldown)
			else
				v.time = v.time - 1000
			end
		end
		for k,v in pairs(ConvertTimer) do
			if v.timeB <= 0 then
				RemoveConvertTimer(v.convertWait)
			else
				v.timeB = v.timeB - 1000
			end
		end
		for k,v in pairs(DrugEffectTimer) do
			if v.timeC <= 0 then
				RemoveDrugEffectTimer(v.effectWait)
			else
				v.timeC = v.timeC - 1000
			end
		end
	end
end)

RegisterCommand("drugjob", function(source,args,rawCommand)
	local user_id = vRP.getUserId({source})
	if not HasCooldown(GetPlayerIdentifier(source)) then
		if vRP.hasInventoryItem({user_id, Config.HackerDevice}) then
			TriggerClientEvent("t1ger_drugs:UsableItem",source)
		else
			TriggerClientEvent("pNotify:SendNotification",source,{text = "You need a "..Config.HackerDevice.." to use the USB",type = "error",timeout = (2000),layout = "centerLeft",queue = "global",animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"},killer = true})  
		end
	 else
		local notifytext = string.format("USB is usable in: %s minutes",GetCooldownTime(GetPlayerIdentifier(source)))
		TriggerClientEvent("pNotify:SendNotification",source,{text = notifytext,type = "info",timeout = (2000),layout = "centerLeft",queue = "global",animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"},killer = true})  
  	end
end, false)


-- Server Event for Buying Drug Job:
RegisterServerEvent("t1ger_drugs:GetSelectedJob")
AddEventHandler("t1ger_drugs:GetSelectedJob", function(drugType,BuyPrice,minReward,maxReward)
	local user_id = vRP.getUserId({source})

	if vRP.tryPayment({user_id,BuyPrice}) then 
		TriggerEvent("t1ger_drugs:addCooldownToSource",source)
		TriggerClientEvent("t1ger_drugs:BrowseAvailableJobs",source, 0, drugType, minReward, maxReward)
		if drugType == "Coke" or drugType == "coke" then
			label = "Coke"
		elseif drugType == "Meth" or drugType == "meth" then
			label = "Meth"
		elseif drugType == "Weed" or drugType == "weed" then
			label = "Weed"
		end
		TriggerClientEvent("pNotify:SendNotification",source,{text = "You paid $"..BuyPrice.." for a "..label.." job",type = "success",timeout = (2000),layout = "centerLeft",queue = "global",animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"},killer = true})  
	else
		TriggerClientEvent("pNotify:SendNotification",source,{text = "Not enough money",type = "error",timeout = (2000),layout = "centerLeft",queue = "global",animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"},killer = true})  
	end
end)

-- Server Event for Job Reward:
RegisterServerEvent("t1ger_drugs:JobReward")
AddEventHandler("t1ger_drugs:JobReward",function(minReward,maxReward,typeDrug)
	local minDrugReward = minReward
	local maxDrugReward = maxReward
	local idname
	local user_id = vRP.getUserId({source})
	drugAmount = math.random(minDrugReward,maxDrugReward)
	if typeDrug == "Coke" or typeDrug == "coke" then
		idname = Config.CokeDrug
	elseif typeDrug == "Meth" or typeDrug == "meth" then
		idname = Config.MethDrug
	elseif typeDrug == "Weed" or typeDrug == "weed" then
		idname = Config.WeedDrug
	end
	print("ID: "..idname)
	print("DRUG: "..typeDrug)
	print("AMOUNT: "..drugAmount)
	vRP.giveInventoryItem({user_id,idname,drugAmount,true})
end)

-- Usable item to convert drugs:
Citizen.CreateThread(function()
	for k,v in pairs(Config.DrugConversion) do 
		if vRP.hasInventoryItem({user_id, v.UsableItem}) then
			local user_id = vRP.getUserId({source})
			local itemLabel = v.UsableItem
			local drugOutput
			local requiredItems

			local scale = vRP.getInventoryItemAmount({user_id,v.hqscale})

			if v.HighQualityScale and scale >= 1 then
				if scale >= 1 then
					drugOutput = v.RewardAmount.b
					requiredItems = v.RequiredItemAmount.d
				else
					drugOutput = v.RewardAmount.a
					requiredItems = v.RequiredItemAmount.c
				end
			else
				drugOutput = v.RewardAmount
				requiredItems = v.RequiredItemAmount
			end

			local reqItems = vRP.getInventoryItemAmount({user_id,v.RequiredItem})
			if reqItems < requiredItems then
				local reqItemLabel = v.RequiredItem
				TriggerClientEvent("pNotify:SendNotification",source,{text = "You do not have enough "..reqItemLabel,type = "error",timeout = (2000),layout = "centerLeft",queue = "global",animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"},killer = true})  
				return
			end

			


			if vRP.getInventoryWeight({user_id}) < vRP.getInventoryMaxWeight({user_id}) then
				if not Converting(GetPlayerIdentifier(source)) then
					TriggerEvent("t1ger_drugs:addConvertingTimer",source,v.ConversionTime)
					vRP.tryGetInventoryItem({user_id,v.UsableItem,1,true})
					vRP.tryGetInventoryItem({user_id,v.RequiredItem,requiredItems,true})
					TriggerClientEvent("t1ger_drugs:ConvertProcess",source,k,v)
					Citizen.Wait(v.ConversionTime)
					vRP.giveInventoryItem({user_id,v.RewardItem,drugOutput,true})
				else
					local formattedstring = string.format("You are already converting",GetConvertTime(GetPlayerIdentifier(source)))
					TriggerClientEvent("pNotify:SendNotification",source,{text = formattedstring,type = "error",timeout = (2000),layout = "centerLeft",queue = "global",animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"},killer = true})  

				end	
			else
				TriggerClientEvent("pNotify:SendNotification",source,{text = "You do not have enough empty space for more "..itemLabel,type = "error",timeout = (2000),layout = "centerLeft",queue = "global",animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"},killer = true})  
			end	
		end
	end
end)

RegisterServerEvent('t1ger_drugs:DrugJobInProgress')
AddEventHandler('t1ger_drugs:DrugJobInProgress', function(targetCoords, streetName)
	TriggerClientEvent('t1ger_drugs:outlawNotify', -1,string.format("^0Shots fired and ongoing grand theft auto at ^5%s^0",streetName))
	TriggerClientEvent('t1ger_drugs:OutlawBlipEvent', -1, targetCoords)
end)

RegisterServerEvent('t1ger_drugs:DrugSaleInProgress')
AddEventHandler('t1ger_drugs:DrugSaleInProgress', function(targetCoords, streetName)
	TriggerClientEvent('t1ger_drugs:outlawNotify', -1,string.format("^0Possible drug sale at ^5%s^0",streetName))
	TriggerClientEvent('t1ger_drugs:OutlawBlipEvent', -1, targetCoords)
end)

RegisterServerEvent("t1ger_drugs:sellDrugs")
AddEventHandler("t1ger_drugs:sellDrugs", function()
	local user_id = vRP.getUserId({source})
	local drugamount = 0
	local price = 0
	local drugType = nil
	
	if vRP.getInventoryItemAmount({user_id, Config.WeedDrug}) > 0 then
		drugType = Config.WeedDrug
		if vRP.getInventoryItemAmount({user_id, Config.WeedDrug}) == 1 then
			drugamount = 1
		elseif vRP.getInventoryItemAmount({user_id, Config.WeedDrug}) == 2 then
			drugamount = math.random(1,2)
		elseif vRP.getInventoryItemAmount({user_id, Config.WeedDrug}) == 3 then	
			drugamount = math.random(1,3)
		elseif vRP.getInventoryItemAmount({user_id, Config.WeedDrug}) >= 4 then	
			drugamount = math.random(1,4)
		end
		
	elseif vRP.getInventoryItemAmount({user_id, Config.MethDrug}) > 0 then
		drugType = Config.MethDrug
		if vRP.getInventoryItemAmount({user_id, Config.MethDrug}) == 1 then
			drugamount = 1
		elseif vRP.getInventoryItemAmount({user_id, Config.MethDrug}) == 2 then
			drugamount = math.random(1,2)
		elseif vRP.getInventoryItemAmount({user_id, Config.MethDrug}) >= 3 then	
			drugamount = math.random(1,3)
		end
		
	elseif vRP.getInventoryItemAmount({user_id, Config.CokeDrug}) > 0 then
		drugType = Config.CokeDrug
		if vRP.getInventoryItemAmount({user_id, Config.CokeDrug}) == 1 then
			drugamount = 1
		elseif vRP.getInventoryItemAmount({user_id, Config.CokeDrug}) == 2 then
			drugamount = math.random(1,2)
		elseif vRP.getInventoryItemAmount({user_id, Config.CokeDrug}) >= 3 then	
			drugamount = math.random(1,3)
		end
	
	else
		TriggerClientEvent("pNotify:SendNotification",source,{text = "You have no more drugs on you",type = "error",timeout = (2000),layout = "centerLeft",queue = "global",animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"},killer = true})  

		return
	end
	
	if drugType==Config.WeedDrug then
		price = math.random(Config.WeedSale.min,Config.WeedSale.max) * 10 * drugamount
	elseif drugType==Config.MethDrug then
		price = math.random(Config.MethSale.min,Config.MethSale.max) * 10 * drugamount
	elseif drugType==Config.CokeDrug then
		price = math.random(Config.CokeSale.min,Config.CokeSale.max) * 10 * drugamount
	end
	local drugLabel
	if drugType ~= nil then
		-- Get label if else statement
			if drugType == "coke1g" then
				drugLabel = "Coke"
			elseif drugType == "meth1g" then
				drugLabel = "Meth"
			elseif drugType == "weed4g" then
				drugLabel = "Weed"
			end

		vRP.tryGetInventoryItem({user_id,drugType,drugamount,true})
		if Config.ReceiveDirtyCash then
			vRP.giveInventoryItem({user_id,"dirty_money",price,true})
		else
			vRP.giveMoney({user_id,price})
		end
		TriggerClientEvent("pNotify:SendNotification",source,{text = "You sold "..drugamount.."x "..drugLabel.." for $"..price ,type = "success",timeout = (2000),layout = "centerLeft",queue = "global",animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"},killer = true})  

	end		
end)

-- Do not touch these 6 functions!
function RemoveCooldown(source)
	for k,v in pairs(JobCooldown) do
		if v.cooldown == source then
			table.remove(JobCooldown,k)
		end
	end
end
function GetCooldownTime(source)
	for k,v in pairs(JobCooldown) do
		if v.cooldown == source then
			return math.ceil(v.time/60000)
		end
	end
end
function HasCooldown(source)
	for k,v in pairs(JobCooldown) do
		if v.cooldown == source then
			return true
		end
	end
	return false
end
function RemoveDrugEffectTimer(source)
	for k,v in pairs(DrugEffectTimer) do
		if v.effectWait == source then
			table.remove(DrugEffectTimer,k)
		end
	end
end
function GetDrugEffectTime(source)
	for k,v in pairs(DrugEffectTimer) do
		if v.effectWait == source then
			return math.ceil(v.timeC/1000)
		end
	end
end
function DrugEffect(source)
	for k,v in pairs(DrugEffectTimer) do
		if v.effectWait == source then
			return true
		end
	end
	return false
end
function RemoveConvertTimer(source)
	for k,v in pairs(ConvertTimer) do
		if v.convertWait == source then
			table.remove(ConvertTimer,k)
		end
	end
end
function GetConvertTime(source)
	for k,v in pairs(ConvertTimer) do
		if v.convertWait == source then
			return math.ceil(v.timeB/1000)
		end
	end
end
function Converting(source)
	for k,v in pairs(ConvertTimer) do
		if v.convertWait == source then
			return true
		end
	end
	return false
end
