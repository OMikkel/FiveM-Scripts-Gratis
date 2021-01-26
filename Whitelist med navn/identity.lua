-- DEVONETWORK FILER
-- modules > identity.lua
function vRP.setName(user_id,firstname, lastname, age)
    vRP.getUserIdentity(user_id, function(identity)
      if identity == nil then
        vRP.generateRegistrationNumber(function(registration)
          if registration ~= nil then
            vRP.generatePhoneNumber(function(phone)
              if phone ~= nil then
                MySQL.execute("vRP/init_user_identity", {
                  user_id = user_id,
                  registration = registration,
                  phone = phone,
                  firstname = firstname,
                  name = lastname,
                  age = age
                })
              end
            end)
          end
        end)
      else
        MySQL.execute("vRP/update_user_identity", {
          user_id = user_id,
          firstname = firstname,
          name = lastname,
          age = age,
          phone = identity.phone
        })
      end
    end)
end









-- SKY UNIVERSE FILER
-- modules > identity.lua
function vRP.setName(user_id,firstname, lastname, age)
    vRP.getUserIdentity(user_id, function(identity)
      if identity == nil then
        vRP.generateRegistrationNumber(function(registration)
          if registration ~= nil then
            vRP.generatePhoneNumber(function(phone)
              if phone ~= nil then
                MySQL.execute("vRP/init_user_identity", {
                  user_id = user_id,
                  registration = registration,
                  phone = phone,
                  firstname = firstname,
                  name = lastname,
                  age = age
                })
              end
            end)
          end
        end)
      else
        MySQL.execute("vRP/update_user_identity", {
          user_id = user_id,
          firstname = firstname,
          name = lastname,
          age = age,
          phone = identity.phone,
          registration = identity.registration
        })
      end
    end)
end