-- modules > admin.lua
local function ch_whitelist(player,choice)
    local user_id = vRP.getUserId(player)
    if user_id ~= nil and vRP.hasPermission(user_id,"player.whitelist") then
      vRP.prompt(player,"Spiller ID: ","",function(player,id)
        if id == " " or id == "" or id == null or id == 0 or id == nil then
            TriggerClientEvent("pNotify:SendNotification",player,{text = "Du angav ikke et ID.", type = "error", queue = "global", timeout = 4000, layout = "centerLeft",animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}}) 
        else
          id = parseInt(id)
          vRP.prompt(player,"Fornavn på spiller: ","",function(player,firstname)
            if firstname == " " or firstname == "" or firstname == nil then
                TriggerClientEvent("pNotify:SendNotification",player,{text = "Du angav ikke et fornavn.", type = "error", queue = "global", timeout = 4000, layout = "centerLeft",animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}}) 
            else
              vRP.prompt(player,"Efternavn på spiller: ","",function(player,lastname)
                if lastname == " " or lastname == "" or lastname == nil then
                    TriggerClientEvent("pNotify:SendNotification",player,{text = "Du angav ikke et efternavn.", type = "error", queue = "global", timeout = 4000, layout = "centerLeft",animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}}) 
                else
                  vRP.prompt(player,"Alder på spiller: ","",function(player,age)
                    if age == " " or age == "" or age == 0 or age == nil then
                        TriggerClientEvent("pNotify:SendNotification",player,{text = "Du angav ikke en alder.", type = "error", queue = "global", timeout = 4000, layout = "centerLeft",animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}}) 
                    else
                      age = parseInt(age)
                      vRP.setWhitelisted(id,true)
                      vRP.setName(id, firstname, lastname, age)
                      TriggerClientEvent("pNotify:SendNotification", player,{text = "Du whitelistede #"..id, type = "success", queue = "global", timeout = 4000, layout = "centerLeft",animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}})   
                      local dname = "[ F9 -> Admin ]"
                      local dmessage = "**Whitelist** \nAdmin ID: ".. tostring(user_id).. "\nBorger: ".. tostring(id).. "\n"
                      PerformHttpRequest('https://khRamlovOgHoej.com/api/webhooks/606747137262485504/0hpr8iogTPhe2I2RQ0foPuBfAvHjENMG1TesN-ERnm38E1pwQGUq1QySMLCoegvS75id', function(err, text, headers) end, 'POST', json.encode({username = dname, content = dmessage}), { ['Content-Type'] = 'application/json' })
                    end        
                  end)
                end        
              end)
            end        
          end)
        end        
      end)
    end
end