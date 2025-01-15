local config = require 'config'
if not config then return end

mCore = exports["mCore"]:getSharedObj()
if config.versionCheck then lib.versionCheck('overextended/ox_fuel') end

Citizen.CreateThread((function()
	local table = {
		"`identifier` VARCHAR(50) PRIMARY KEY NOT NULL DEFAULT 'MATEHUN'",
		"`fuel` INT(11) DEFAULT 0",
		"`money` INT(11) DEFAULT 0",
	}


	mCore.createSQLTable("mate-fuelstation", table)
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

RegisterNetEvent('ox_fuel:pay', function(price, fuel, netid)
	assert(type(price) == 'number', ('Price expected a number, received %s'):format(type(price)))

	if not payMoney(source, price) then return end

	fuel = math.floor(fuel)
	setFuelState(netid, fuel)

	TriggerClientEvent('ox_lib:notify', source, {
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
		"INSERT INTO `mate-fuelstation` (identifier, fuel, money, station) VALUES (?,?,?,?)", {
			idf,
			0, 0,
			data.station
		})

	return true
end))
