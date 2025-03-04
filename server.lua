local config = require 'config'
if not config then return end

mCore = exports["mCore"]:getSharedObj()
if config.versionCheck then lib.versionCheck('overextended/ox_fuel') end

Citizen.CreateThread((function()
	local table = {
		"`identifier` VARCHAR(50) PRIMARY KEY NOT NULL DEFAULT 'MATEHUN'",
		"`diesel` INT(11) DEFAULT 0",
		"`gas` INT(11) DEFAULT 0",
		"`electric` INT(11) DEFAULT 0",
		"`money` INT(11) DEFAULT 0",
		"`station` VARCHAR(25) NOT NULL DEFAULT 'MATEHUN' UNIQUE"
	}


	mCore.createSQLTable("mate-fuelstation", table)

	mCore.LoadWebhook("fuel-station", config.Control.Webhook)
end))


local ox_inventory = exports.ox_inventory

local function setFuelState(netId, fuel)
	local vehicle = NetworkGetEntityFromNetworkId(netId)

	if vehicle == 0 or GetEntityType(vehicle) ~= 2 then
		return
	end

	local state = Entity(vehicle)?.state
	fuel = math.clamp(fuel, 0, 100)

	state:set('fuel', fuel, true)
end

---@param playerId number
---@param price number
---@return boolean?
local function defaultPaymentMethod(playerId, price)
	local success = ox_inventory:RemoveItem(playerId, 'money', price)

	if success then return true end

	local money = ox_inventory:GetItemCount(source, 'money')

	TriggerClientEvent('ox_lib:notify', source, {
		type = 'error',
		description = locale('not_enough_money', price - money)
	})
end

local payMoney = defaultPaymentMethod
exports('setPaymentMethod', function(fn)
	payMoney = fn or defaultPaymentMethod
end)

RegisterNetEvent('ox_fuel:pay', function(price, fuel, netid, station, b, fuelType)
	local src = source
	assert(type(price) == 'number', ('Price expected a number, received %s'):format(type(price)))

	if not payMoney(source, price) then return end

	fuel = math.floor(fuel)
	setFuelState(netid, fuel)


	if station then
		local income = (price * config.Control.Tax)
		print("Income", income)

		MySQL.update.await(
			("UPDATE `mate-fuelstation` SET `%s` = `%s` - ?, `money` = `money` + ? WHERE `station` = ?"):format(
			fuelType, fuelType), {
				b,
				income,
				station
			})


		TriggerClientEvent("ox_fuel:UpdateStation", -1, station)
	end

	TriggerClientEvent('ox_lib:notify', src, {
		type = 'success',
		description = locale('fuel_success', fuel, price)
	})
end)

RegisterNetEvent('ox_fuel:fuelCan', function(hasCan, price)
	if hasCan then
		local item = ox_inventory:GetCurrentWeapon(source)

		if not item or item.name ~= 'WEAPON_PETROLCAN' or not payMoney(source, price) then return end

		item.metadata.durability = 100
		item.metadata.ammo = 100

		ox_inventory:SetMetadata(source, item.slot, item.metadata)

		TriggerClientEvent('ox_lib:notify', source, {
			type = 'success',
			description = locale('petrolcan_refill', price)
		})
	else
		if not ox_inventory:CanCarryItem(source, 'WEAPON_PETROLCAN', 1) then
			return TriggerClientEvent('ox_lib:notify', source, {
				type = 'error',
				description = locale('petrolcan_cannot_carry')
			})
		end

		if not payMoney(source, price) then return end

		ox_inventory:AddItem(source, 'WEAPON_PETROLCAN', 1)

		TriggerClientEvent('ox_lib:notify', source, {
			type = 'success',
			description = locale('petrolcan_buy', price)
		})
	end
end)

RegisterNetEvent('ox_fuel:updateFuelCan', function(durability, netid, fuel)
	local source = source
	local item = ox_inventory:GetCurrentWeapon(source)

	if item and durability > 0 then
		durability = math.floor(item.metadata.durability - durability)
		item.metadata.durability = durability
		item.metadata.ammo = durability

		ox_inventory:SetMetadata(source, item.slot, item.metadata)
		setFuelState(netid, fuel)
	end

	-- player is sus?
	mCore.sendMessage(("%s(%s) Tried to use a FuelCan without a fuelCan item"):format(
		GetPlayerName(source), source
	), mCore.RequestWebhook("fuel-station"), "mhScripts, ox-fuel")
end)



-- [[ Station Control ]] --

lib.callback.register("ox_fuel:IsPlayerOwn", (function(source, target)
	if not target then
		target = source
	end

	local idf = GetPlayerIdentifierByType(target, "license"):sub(9)

	local resp = MySQL.scalar.await("SELECT identifier FROM `mate-fuelstation` WHERE identifier = ?", { idf })
	return resp
end))


lib.callback.register("ox_fuel:isStationOwned", (function(source, station)
	if not station then return end
	-- local idf = GetPlayerIdentifierByType(source, "license"):sub(9)

	local resp = MySQL.scalar.await("SELECT station FROM `mate-fuelstation` WHERE station = ?",
		{ station })
	return resp or false
end))


lib.callback.register("ox_fuel:GetStationData", (function(source, station)
	local resp = MySQL.single.await("SELECT * FROM `mate-fuelstation` WHERE station = ?", { station })
	return resp or false
end))

---@param data table
lib.callback.register("ox_fuel:BuyStation", (function(source, data)
	local success = payMoney(source, data.price)
	if not success then return false end

	local idf = GetPlayerIdentifierByType(source, "license"):sub(9)

	local resp = MySQL.insert.await(
		"INSERT INTO `mate-fuelstation` (identifier, diesel,gas,electric, money, station) VALUES (?,?,?,?,?,?)", {
			idf,
			0, 0, 0, 0,
			data.station
		})

	return true
end))


lib.callback.register("ox_fuel:station:updateFuel", (function(source, type)
	local idf = GetPlayerIdentifierByType(source, "license"):sub(9)

	if not idf then return false end

	-- TODO: Check for valid types

	math.randomseed(GetGameTimer())
	local fuel = math.random(config.Control.ReFill.min, config.Control.ReFill.max)
	local resp = MySQL.update.await(
		("UPDATE `mate-fuelstation` SET `%s` = `%s` + ? WHERE identifier = ?"):format(type, type), {
			fuel, idf
		})
	return true, fuel, type
end))


RegisterNetEvent('ox_fuel:RequestPayment', function(station)
	local src = source
	local idf = GetPlayerIdentifierByType(src, "license"):sub(9)

	if not idf then return end


	if type(station) == "table" then
		station = station[1]
	end

	local money = MySQL.scalar.await("SELECT money from `mate-fuelstation` WHERE identifier = ? AND station = ? ", {
		idf,
		station
	})

	if money <= 0 then return end

	MySQL.update.await("UPDATE `mate-fuelstation` SET money = 0 WHERE identifier = ? AND station = ?", {
		idf, station
	})

	local s = ox_inventory:AddItem(src, "money", money)

	if not s then
		mCore.sendMessage(
			("%s(%s) Borrowed money from gas-station but failed to give the money to him! Money: %s\nJogossan adoljatok neki vissza mo")
			:format(
				GetPlayerName(src),
				src,
				money
			), mCore.RequestWebhook("fuel-station"), "mhScripts, ox-fuel")
	end
end)
