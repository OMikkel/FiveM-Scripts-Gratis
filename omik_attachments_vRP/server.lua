-- Lavet af: OMikkel#3217
-- Script: omik_attachments

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() == resourceName) then
        TriggerClientEvent("omik_attachments:CloseMenu", -1)
    end
  end)