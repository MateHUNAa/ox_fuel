local config = require 'config'
local control = {}

local isPressed = false
local owning = false

Citizen.CreateThread((function()
     local resp = lib.callback.await("ox_fuel:IsPlayerOwn", false)
     owning = resp or false
end))

function control.Loop(point)
     -- Marker to control station

     if owning and not string.match(LocalPlayer.state.identifier, point.owner) then
          return
     end



     local isOpen, text = lib.isTextUIOpen()

     -- Buyable
     if not owning and not point.owned then
          DrawMarker(1, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
               config.Control.Marker.size, config.Control.Marker.size, config.Control.Marker.size, 0, 100, 0, 100, false,
               false, 2, false, nil, nil, false)

          if point.currentDistance <= config.Control.Marker.size - .5 then
               if not IsOpen then
                    lib.showTextUI("Press [E] to buy")
               end


               if IsControlJustReleased(2, 38) and not isPressed then
                    isPressed = true

                    --
                    local success = lib.callback.await("ox_fuel:BuyStation", false, {
                         station = point.station,
                         price = point.data.price
                    })

                    print(success)
                    if success then
                         owning      = true
                         point.owned = true
                         point.owner = LocalPlayer.state.identifier
                    end
                    --

                    Citizen.CreateThread((function()
                         Wait(300)
                         isPressed = false
                    end))
               end
          else
               lib.hideTextUI()
          end

          return
     end


     -- Owning

     DrawMarker(1, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
          config.Control.Marker.size, config.Control.Marker.size, config.Control.Marker.size, 0, 50, 255, 80, false,
          false, 2, false, nil, nil, false)

     if point.currentDistance <= config.Control.Marker.size - .5 then
          if not isOpen then
               lib.showTextUI("Press [E] to interact")
          end

          if IsControlJustReleased(2, 38) and not isPressed then
               isPressed = true
               --

               local Options = {}

               Options[#Options + 1] = {
                    label = "Control"
               }

               Options[#Options + 1] = {
                    label = "Stats",
                    args = point
               }

               lib.setMenuOptions("fuel-menu", Options)
               lib.showMenu("fuel-menu")

               --
               Citizen.CreateThread((function()
                    Wait(300)
                    isPressed = false
               end))
          end
     else
          if isOpen then
               lib.hideTextUI()
          end
     end
end

local function onSelect(selected, scroll, args)
     if selected == 1 then

     elseif selected == 2 then
          print(args.rawData.money, args.rawData.fuel)
     end
end

lib.registerMenu({
     id = "fuel-menu",
     title = "Fuel Menu",
     options = {
          {
               label = "Prob not working"
          }
     }
}, onSelect)


AddEventHandler("onResourceStop", (function(res)
     if GetCurrentResourceName() ~= res then return end

     lib.hideTextUI()
end))


return control
