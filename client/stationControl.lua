local config    = require 'config'
local utils     = require 'client.utils'
local stations  = require 'data.stations'
local control   = {}

local isPressed = false
local owning    = nil


local truck          = nil
local trailer        = nil

local closestStation = nil

Citizen.CreateThread((function()
     local resp = lib.callback.await("ox_fuel:IsPlayerOwn", false)
     owning = resp or false
end))


for station, data in pairs(stations) do
     utils.makePed("a_m_m_soucent_03", {
          scenario = "WORLD_HUMAN_CLIPBOARD",
          collision = false,
          coords = station.xyzw,
          freeze = true,
          anim = nil
     }, {
          {
               label = "Buy station",
               name = "station_buy",
               icon = "shop",
               distance = 3.0,
               canInteract = (function()
                    if not closestStation then
                         return false
                    end

                    if owning and string.match(LocalPlayer.state.identifier, closestStation.owner) then
                         return false
                    end

                    if not owning and not closestStation.owned then
                         return true
                    end
               end),
               onSelect = (function()
                    if not closestStation then
                         print("FATAL: No `closestStation` found")
                         return
                    end
                    local success = lib.callback.await("ox_fuel:BuyStation", false, {
                         station = closestStation.station,
                         price = closestStation.data.price
                    })

                    if success then
                         owning = true
                         closestStation:keyUpdate("owned", true)
                         closestStation:keyUpdate("owner", LocalPlayer.state.identifier)
                         Wait(200)
                         closestStation:onEnter()
                    end
               end)
          },
          {
               label = "actions",
               name = "actions",
               icon = "industry",
               canInteract = (function()
                    if not owning then return false end
                    if not closestStation then return false end
                    if closestStation.owned and string.match(closestStation.owner, LocalPlayer.state.identifier) then
                         return true
                    else
                         return false
                    end
               end),
               onSelect = (function()
                    if not closestStation then return print("No closeestStation") end
                    local data = {
                         Fuels       = {
                              {
                                   fuel = closestStation.rawData.diesel,
                                   type = "diesel"
                              },
                              {
                                   fuel = closestStation.rawData.gas,
                                   type = "gas"
                              },
                              {
                                   fuel = closestStation.rawData.electric,
                                   type = "electric"
                              }
                         },
                         income      = closestStation.rawData.money,
                         stationName = closestStation.station,
                         tax         = 20
                    }

                    SendNUIMessage({
                         action = "open",
                         data = data
                    })
                    SetNuiFocus(true, true)
               end)
          }
     })
end

function control.onExit(point)
     closestStation = nil
end

function control.onEnter(point)
     closestStation = point
end

--
-- NUI CALLBACK
--

RegisterNUICallback("exit", function(d, cb)
     cb("ok")
     SetNuiFocus(false, false)
end)

RegisterNUICallback("start-refill", function(cbdata, cb)
     print("NUI->Refill", json.encode(cbdata))
     cb("ok")
     SetNuiFocus(false, false)
     SendNUIMessage({
          action = "visibility",
          data = false
     })
     -- Action Below

     local function cleanup()
          if truck and DoesEntityExist(truck) then
               DeleteEntity(truck)
          end
          if trailer and DoesEntityExist(trailer) then
               DeleteEntity(trailer)
          end
          ClearGpsPlayerWaypoint()
          lib.hideTextU()
     end

     if not closestStation then return print("No closestStation") end

     -- TODO: Check the closestStation owned by the current user.
     closestStation:onEnter()

     args = closestStation

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
          local sleep = 1
          local trailing, tr = GetVehicleTrailerVehicle(truck)

          local p = GetOffsetFromEntityInWorldCoords(trailer, 0, 0, 2)
          DrawMarker(0, p.x, p.y, p.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 255, 255, 255, false, false,
               2, false, nil, nil, false)
          if tr == trailer then
               break
          end

          Wait(sleep)
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

                         lib.hideTextU()
                         cleanup()

                         local s, fuel = lib.callback.await("ox_fuel:station:updateFuel", false, cbdata)
                         if s then
                              Wait(200)
                              args:onEnter()
                         else
                              print("Failed to update `rawData.fuel`")
                         end
                         break
                    end
               end

               Wait(1)
          end
     end))
end)

RegisterNUICallback("cashout", function(data, cb)
     cb("ok")

     SendNUIMessage({ action = "visibility", data = false })
     SetNuiFocus(false, false)

     if not closestStation then return end
     if not owning then return end
     if not closestStation.owned then return end

     if not string.match(LocalPlayer.state.identifier, closestStation.owner) then return end

     TriggerServerEvent('ox_fuel:RequestPayment', { closestStation.station })
     --
end)

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
