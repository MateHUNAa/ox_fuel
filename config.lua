if not lib.checkDependency('ox_lib', '3.22.0', true) then return end
if not lib.checkDependency('ox_inventory', '2.30.0', true) then return end

return {
	-- Get notified when a new version releases
	versionCheck = false,

	-- Enable support for ox_target
	ox_target = true,

	/*
	* Show or hide gas stations blips
	* 0 - Hide all
	* 1 - Show nearest (5000ms interval check)
	* 2 - Show all
	*/
	showBlips = 2,

	-- Total duration (ex. 10% missing fuel): 10 / 0.25 * 250 = 10 seconds

	-- Fuel refill value (every 250msec add 0.25%)
	refillValue = 0.50,

	-- Fuel tick time (every 250 msec)
	refillTick = 250,

	-- Fuel cost (Added once every tick)
	priceTick = 5,

	-- Can durability loss per refillTick
	durabilityTick = 1.3,

	-- Enables fuel can
	petrolCan = {
		enabled     = true,
		duration    = 5000,
		price       = 1000,
		refillPrice = 800,
	},

	---Modifies the fuel consumption rate of all vehicles - see [`SET_FUEL_CONSUMPTION_RATE_MULTIPLIER`](https://docs.fivem.net/natives/?_0x845F3E5C).
	globalFuelConsumptionRate = 10.0,

	-- Gas pump models
	pumpModels = {
		`prop_gas_pump_old2`,
		`prop_gas_pump_1a`,
		`prop_vintage_pump`,
		`prop_gas_pump_old3`,
		`prop_gas_pump_1c`,
		`prop_gas_pump_1b`,
		`prop_gas_pump_1d`,
	},


	-- [[ StationControl ]] --

	Control = {
		-- Useful console prints for admins, Like if a player think something is a bug what is a feature then its printed to console for admins!
		DEBUGPRINT_FOR_ADMINS = true, -- RECOMMENDED

		-- Boss menu marker size
		Marker = {
			size    = vec3(3.0, 3.0, 1.0),

			-- Marker Colors (VV)
			Owned   = vec4(0, 50, 255, 80),
			Buyable = vec4(0, 100, 0, 100)
		},

		-- Teleport player into the refill truck
		WarpPlayerIntoTruck = true,

		-- When refilling the station
		ReFill = {
			min = 5,  -- Minimum value to give from the trailer
			max = 25, -- Maximum value to give from the trailer
		},

		-- Fuel removed from station (Added once every tick)
		fuelTick = .5,

		-- (Price * Tax) == Income
		Tax = .75,

		Webhook =
		"https://discord.com/api/webhooks/1329239536299016313/nZNOCe2ebohWmePrupSX2hPFWLIptydgnVon7J8AC13sUlu6f6Ql6lmGuSQxLgseHnTy"
	}

}
