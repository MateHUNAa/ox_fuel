local config = require 'config'
local state = require 'client.state'
local utils = require 'client.utils'
local fuel = {}

---@param vehState StateBag
---@param vehicle integer
---@param amount number
---@param replicate? boolean
function fuel.setFuel(vehState, vehicle, amount, replicate)
	if DoesEntityExist(vehicle) then
		amount = math.clamp(amount, 0, 100)

		SetVehicleFuelLevel(vehicle, amount)
		vehState:set('fuel', amount, replicate)
	end
end

function fuel.getPetrolCan(coords, refuel)
	TaskTurnPedToFaceCoord(cache.ped, coords.x, coords.y, coords.z, config.petrolCan.duration)
	Wait(500)

	if lib.progressCircle({
		    duration = config.petrolCan.duration,
		    useWhileDead = false,
		    canCancel = true,
		    disable = {
			    move = true,
			    car = true,
			    combat = true,
		    },
		    anim = {
			    dict = 'timetable@gardener@filling_can',
			    clip = 'gar_ig_5_filling_can',
			    flags = 49,
		    }
	    }) then
		if refuel and exports.ox_inventory:GetItemCount('WEAPON_PETROLCAN') then
			return TriggerServerEvent('ox_fuel:fuelCan', true, config.petrolCan.refillPrice)
		end

		TriggerServerEvent('ox_fuel:fuelCan', false, config.petrolCan.price)
	end

	ClearPedTasks(cache.ped)
end

function fuel.startFueling(vehicle, isPump, station, stationState, fuelType)
	local vehState  = Entity(vehicle).state
	local minusFuel = 0
	fuelType        = fuelType:match("^%s*(.-)%s*$")
	if not (string.match(fuelType, "gas") or string.match(fuelType, "diesel") or string.match(fuelType, "electric")) then
		return print("FATAL: fuelType is nil or not found ! err-code: fuel:53")
	end
	local stationFuel = stationState[tostring(fuelType)] or 0

	if stationFuel <= 0 then
		return lib.notify({
			type = "error",
			description = locale("station_empty")
		})
	end

	local fuelAmount = vehState.fuel or GetVehicleFuelLevel(vehicle)
	local duration   = math.ceil((100 - fuelAmount) / config.refillValue) * config.refillTick
	local price, moneyAmount
	local durability = 0

	if 100 - fuelAmount < config.refillValue then
		return lib.notify({ type = 'error', description = locale('tank_full') })
	end

	if isPump then
		price = 0
		moneyAmount = utils.getMoney()

		if config.priceTick > moneyAmount then
			return lib.notify({
				type = 'error',
				description = locale('not_enough_money', config.priceTick)
			})
		end
	elseif not state.petrolCan then
		return lib.notify({ type = 'error', description = locale('petrolcan_not_equipped') })
	elseif state.petrolCan.metadata.ammo <= config.durabilityTick then
		return lib.notify({
			type = 'error',
			description = locale('petrolcan_not_enough_fuel')
		})
	end

	state.isFueling = true

	TaskTurnPedToFaceEntity(cache.ped, vehicle, duration)
	Wait(500)

	CreateThread(function()
		lib.progressCircle({
			duration = duration,
			useWhileDead = false,
			canCancel = true,
			disable = {
				move = true,
				car = true,
				combat = true,
			},
			anim = {
				dict = isPump and 'timetable@gardener@filling_can' or 'weapon@w_sp_jerrycan',
				clip = isPump and 'gar_ig_5_filling_can' or 'fire',
			},
		})

		state.isFueling = false
	end)

	while state.isFueling do
		if isPump then
			stationFuel -= config.Control.fuelTick
			minusFuel   += config.Control.fuelTick
			price       += config.priceTick

			if stationFuel <= 0 then
				if lib.progressActive() then
					lib.cancelProgress()
				end
			end

			if price + config.priceTick >= moneyAmount then
				if lib.progressActive() then
					lib.cancelProgress()
				end
			end
		elseif state.petrolCan then
			durability += config.durabilityTick

			if durability >= state.petrolCan.metadata.ammo then
				if lib.progressActive() then
					lib.cancelProgress()
				end
				durability = state.petrolCan.metadata.ammo
				break
			end
		else
			break
		end

		fuelAmount += config.refillValue

		if fuelAmount >= 100 then
			state.isFueling = false
			fuelAmount = 100.0
		end

		Wait(config.refillTick)
	end

	ClearPedTasks(cache.ped)

	local oldType = vehState["fuel-type"]
	if isPump then
		if oldType ~= fuelType then
			vehState:set("fuel-type", fuelType or fuelType.DEFAULT, true)
		end

		TriggerServerEvent('ox_fuel:pay', price, fuelAmount, NetworkGetNetworkIdFromEntity(vehicle), station, minusFuel,
			fuelType or fuelType.DEFAULT)
	else -- Petrol Can
		if oldType ~= fuelType then
			vehState:set("fuel-type", state.petrolCan.metadata.fuelType or fuelType.DEFAULT, true)
		end
		TriggerServerEvent('ox_fuel:updateFuelCan', durability, NetworkGetNetworkIdFromEntity(vehicle), fuelAmount)
	end
end

return fuel
