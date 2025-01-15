local config = require 'config'
local control = {}

local isPressed = false


Citizen.CreateThread((function ()
     
end))

function control.Loop(point)
     -- Marker to control station
     DrawMarker(1, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
          config.Control.Marker.size, config.Control.Marker.size, config.Control.Marker.size, 255, 0, 0, 100, false,
          false, 2, false, nil, nil, false)

     local isOpen, text = lib.isTextUIOpen()
     if point.currentDistance <= config.Control.Marker.size - .5 then
          if not isOpen then
               lib.showTextUI("Press [E] to interact")
          end

          if IsControlJustReleased(2, 38) and not isPressed then
               isPressed = true
               --

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

end

lib.registerMenu({
     id = "fuel-menu",
     title = "Fuel Menu",
     options = {
          {
               label = "Control",
          },
          {
               label = "Money"
          }
     }
}, onSelect)

return control
