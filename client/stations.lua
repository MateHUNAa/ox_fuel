local config = require 'config'
local state = require 'client.state'
local utils = require 'client.utils'
local stations = lib.load 'data.stations'
local control = require 'client.stationControl'
local mCore = exports["mCore"]:getSharedObj()

if config.showBlips == 2 then
	for station, data in pairs(stations) do utils.createBlip(data.pumps[1]) end
end


-- if config.ox_target and config.showBlips ~= 1 then return end

---@param point CPoint
local function onEnterStation(point)
	if config.showBlips == 1 and not point.blip then
		point.blip = utils.createBlip(point.pumps[1])
	end

	local resp = lib.callback.await("ox_fuel:isStationOwned", false, point.station)
	point.owned = resp or false


	if resp then
		local stationData = lib.callback.await("ox_fuel:GetStationData", false, point.station)
		if stationData then
			point.rawData = stationData
			point.owner = stationData.identifier
		end
	else
		point.rawData.fuel = 100
	end

	for i, entity in pairs(GetGamePool("CObject")) do
		local entityModel = GetEntityModel(entity)
		for _, model in pairs(config.pumpModels) do
			if entityModel == model then
				local sb = Entity(entity).state
				sb:set("station", point.station or "MATEHUN", true)
				sb:set("fuel", point.rawData.fuel or 0, true)
				break
			end
		end
	end
end

RegisterNetEvent('ox_fuel:UpdateStation', function(station)
	local stationData = lib.callback.await("ox_fuel:GetStationData", false, station)

	if state.currentStation then
		state.currentStation.rawData.fuel = stationData.fuel
		state.currentStation.fuel = stationData.fuel
	end
end)

---@param point CPoint
local function nearbyStation(point)
	if point.currentDistance > 30 then return end

	state.currentStation = point

	local pumps = point.pumps
	local pumpDistance

	for i = 1, #pumps do
		local pump = pumps[i]
		pumpDistance = #(cache.coords - pump)



		if pumpDistance <= 3 then
			state.nearestPump = pump

			-- Ugly
			if state.nearestPump then
				Citizen.CreateThread((function()
					while true do
						if not state.nearestPump then break end
						mCore.Draw3DText(state.nearestPump.x, state.nearestPump.y, state.nearestPump.z + 2,
							("Fuel: %s"):format(point.rawData.fuel), nil, nil, nil, false, "BebasNeueOtf")
						Wait(1)
					end
				end))
			end

			repeat
				pumpDistance = #(GetEntityCoords(cache.ped) - pump)
				Wait(100)
			until pumpDistance > 3

			state.nearestPump = nil

			return
		end
	end

	-- Initiate Station Control
	control.Loop(point)
end

---@param point CPoint
local function onExitStation(point)
	if point.blip then
		point.blip = RemoveBlip(point.blip)
	end
end

for station, data in pairs(stations) do
	lib.points.new({
		coords   = station,
		distance = 60,
		onEnter  = onEnterStation,
		onExit   = onExitStation,
		nearby   = nearbyStation,
		pumps    = data.pumps,
		station  = data.stationID,
		owned    = false,
		owner    = "MATEHUN",
		rawData  = {},
		data     = data
	})
end
