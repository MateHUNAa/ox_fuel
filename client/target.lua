local config = require 'config'
local state  = require 'client.state'
local utils  = require 'client.utils'
local fuel   = require 'client.fuel'

if config.petrolCan.enabled then
	exports.ox_target:addModel(config.pumpModels, {
		{
			distance = 2,
			onSelect = function(data)
				local sb = Entity(data.entity).state
				local station = sb["station"] or false

				local dp = lib.inputDialog("Fueling", {
					{
						type = "select",
						label = "Select the fuel type",
						options = {
							{
								label = "Gasoline",
								value = "gas"
							},
							{
								label = "Diesel",
								value = "diesel"
							},
							{
								label = "Electric",
								value = "electric"
							}
						},
						required = true,
						default = "gas",
					}
				})

				if not dp or not dp[1] then return end

				if utils.getMoney() >= config.priceTick then
					fuel.startFueling(state.lastVehicle, 1, station, sb, dp[1])
				else
					lib.notify({ type = 'error', description = locale('refuel_cannot_afford') })
				end
			end,
			icon = "fas fa-gas-pump",
			label = locale('start_fueling'),
			canInteract = function(entity)
				local sb = Entity(entity).state

				if sb then
					if sb["gas"] <= 0 and sb["diesel"] <= 0 and sb["electric"] <= 0 then
						return false
					end

					if state.lastVehicle then
						local vehicleName = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(state
							.lastVehicle)))
						local vehState = Entity(state.lastVehicle).state
						if vehState["fuel-type"] then
							local ret = utils.isCorrectFuelType(vehicleName, vehState["fuel-type"])

							if not ret then
								if config.Control.DEBUGPRINT_FOR_ADMINS then
									local a = lib.callback.await("mate-admin:cb:isAdmin")
									if a then
										print("[ADMIN]: WRONG FUEL TYPE")
									end
								end
								return false
							end
						end
					end
				else
					return false
				end



				if state.isFueling or cache.vehicle or lib.progressActive() then
					return false
				end

				return state.lastVehicle and #(GetEntityCoords(state.lastVehicle) - GetEntityCoords(cache.ped)) <= 3
			end
		},
		{
			distance = 2,
			canInteract = (function(entity)
				local sb = Entity(entity).state

				-- FIXME: TODO: types,& InputDialog
				local fuel = sb["fuel"] or 0
				if fuel <= 0 then
					return false
				end
				return true
			end),
			onSelect = function(data)
				local petrolCan = config.petrolCan.enabled and GetSelectedPedWeapon(cache.ped) == `WEAPON_PETROLCAN`
				local moneyAmount = utils.getMoney()

				if moneyAmount < config.petrolCan.price then
					return lib.notify({ type = 'error', description = locale('petrolcan_cannot_afford') })
				end

				return fuel.getPetrolCan(data.coords, petrolCan)
			end,
			icon = "fas fa-faucet",
			label = locale('petrolcan_buy_or_refill'),
		},
	})
else
	-- FIXME: TODO: Copy above here.5
	exports.ox_target:addModel(config.pumpModels, {
		{
			distance = 2,
			onSelect = function(data)
				local sb = Entity(data.entity).state
				local station = sb["station"] or false

				local dp = lib.inputDialog("Fueling", {
					{
						type = "select",
						label = "Select the fuel type",
						options = {
							{
								label = "Gasoline",
								value = "Gasoline"
							},
							{
								label = "Diesel",
								value = "Diesel"
							},
							{
								label = "Electric",
								value = "Electric"
							}
						},
						required = true,
						default = "Gasoline",
					}
				})

				if not dp or not dp[1] then return end

				if utils.getMoney() >= config.priceTick then
					fuel.startFueling(state.lastVehicle, 1, station, sb, dp[1])
				else
					lib.notify({ type = 'error', description = locale('refuel_cannot_afford') })
				end
			end,
			icon = "fas fa-gas-pump",
			label = locale('start_fueling'),
			canInteract = function(entity)
				local sb = Entity(entity).state

				if sb then
					if sb["fuel"] <= 0 then
						return false
					end

					if state.lastVehicle then
						local vehicleName = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
						local vehState = Entity(state.lastVehicle).state
						if vehState["fuel-type"] then
							local ret = utils.isCorrectFuelType(vehicleName, vehState["fuel-type"])


							if not ret then
								if config.Control.DEBUGPRINT_FOR_ADMINS then
									local a = lib.callback.await("mate-admin:cb:isAdmin")
									if a then
										print("[ADMIN]: WRONG FUEL TYPE")
									end
								end
								return false
							end
						end
					end
				else
					return false
				end



				if state.isFueling or cache.vehicle or lib.progressActive() then
					return false
				end

				return state.lastVehicle and #(GetEntityCoords(state.lastVehicle) - GetEntityCoords(cache.ped)) <= 3
			end
		},
	})
end

if config.petrolCan.enabled then
	exports.ox_target:addGlobalVehicle({
		{
			distance = 2,
			onSelect = function(data)
				if not state.petrolCan then
					return lib.notify({ type = 'error', description = locale('petrolcan_not_equipped') })
				end

				if state.petrolCan.metadata.ammo <= config.durabilityTick then
					return lib.notify({
						type = 'error',
						description = locale('petrolcan_not_enough_fuel')
					})
				end

				fuel.startFueling(data.entity)
			end,
			icon = "fas fa-gas-pump",
			label = locale('start_fueling'),
			canInteract = function(entity)
				if state.isFueling or cache.vehicle or lib.progressActive() or not DoesVehicleUseFuel(entity) then
					return false
				end
				return state.petrolCan and config.petrolCan.enabled
			end
		},
		{
			distance = 2,
			onSelect = (function(data)

			end),
			icon = "fa-solid fa-oil-can",
			label = "Wrong fuel-type",
			canInteract = (function(entity)
				local state = Entity(entity).state
				if state then
					return not utils.isCorrectFuelType(
						string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(entity))), state["fuel-type"])
				end
			end)
		}
	})
end
