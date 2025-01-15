local config    = require 'config'
local utils     = require 'client.utils'
local control   = {}

local isPressed = false
local owning    = false


local stationPos = nil
local truck      = nil
local trailer    = nil

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
                    label = "Refill",
                    args = point

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
          -- Refill
          local function cleanup()
               if truck and DoesEntityExist(truck) then
                    DeleteEntity(truck)
               end
               if trailer and DoesEntityExist(trailer) then
                    DeleteEntity(trailer)
               end
               ClearGpsPlayerWaypoint()
          end

          local data = args.data.Refill
          local found, pos = utils.FindPoint(data.Spawnpoints)

          if not found then
               lib.notify({
                    description = locale("no_space")
               })
               return
          end
          --
          lib.requestModel(data.Model)
          truck = CreateVehicle(data.Model, pos.x, pos.y, pos.z, pos.w, true, true)
          SetModelAsNoLongerNeeded(data.Model)

          if config.Control.WarpPlayerIntoTruck then
               TaskWarpPedIntoVehicle(cache.ped, truck, -1)
          end

          local destination = data.Destinations[math.random(1, #data.Destinations)]
          if not destination then cleanup() end

          SetNewWaypoint(destination.x, destination.y)

          while DoesEntityExist(truck) do
               local dist = #(GetEntityCoords(cache.ped).xy - destination.xy)
               if dist <= 15.0 then
                    lib.requestModel(data.Trailer)
                    trailer = CreateVehicle(data.Trailer, destination.x, destination.y, destination.z, destination
                         .w,
                         true, true)
                    break
               end
               Wait(500)
          end

          --

          while true do
               local trailing, tr = GetVehicleTrailerVehicle(truck)

               local p = GetOffsetFromEntityInWorldCoords(trailer, 0, 0, 2)
               DrawMarker(0, p.x, p.y, p.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 255, 255, 255, false, false,
                    2, false, nil, nil, false)
               if tr == trailer then
                    break
               end

               Wait(500)
          end


          SetNewWaypoint(data.DropOff.x, data.DropOff.y)

          Citizen.CreateThread((function()
               while true do
                    local dist = #(GetEntityCoords(cache.ped).xy - data.DropOff.xy)

                    if dist <= 20.0 then
                         DrawMarker(1, data.DropOff.x, data.DropOff.y, data.DropOff.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 5.0,
                              5.0, 5.0, 255, 255, 255, 155, false, false, 2, false, nil, nil, false)
                    end

                    if dist <= 4.5 then
                         local active, a = lib.isTextUIOpen()

                         if not active then
                              lib.showTextUI("Press [E] to deliver fuel")
                         end
                         if IsControlJustReleased(2, 38) and not isPressed then
                              isPressed = true
                              Citizen.CreateThread((function()
                                   Wait(400)
                                   isPressed = false
                              end))

                              cleanup()

                              lib.callback.await("ox_fuel:station:updateFuel", 5000)
                              break
                         end
                    end

                    Wait(1)
               end
          end))

          --
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


     if truck and DoesEntityExist(truck) then
          DeleteEntity(truck)
     end
     if trailer and DoesEntityExist(trailer) then
          DeleteEntity(trailer)
     end

     lib.hideTextUI()
end))


return control
