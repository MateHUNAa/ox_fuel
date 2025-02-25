local fuelTypes = require 'data.fuelType'
local utils = {}

local Peds = {}

AddEventHandler("onResourceStop", (function(res)
	if GetCurrentResourceName() ~= res then return end

	for i = 1, #Peds do
		local ped = Peds[i]
		if DoesEntityExist(ped) then
		DeleteEntity(ped)
		end
	end
end))
---@param coords vector3
---@return integer
function utils.createBlip(coords)
	local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
	SetBlipSprite(blip, 361)
	SetBlipDisplay(blip, 4)
	SetBlipScale(blip, 0.8)
	SetBlipColour(blip, 6)
	SetBlipAsShortRange(blip, true)
	BeginTextCommandSetBlipName('ox_fuel_station')
	EndTextCommandSetBlipName(blip)

	return blip
end

function utils.getVehicleInFront()
	local coords = GetEntityCoords(cache.ped)
	local destination = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 2.2, -0.25)
	local handle = StartShapeTestCapsule(coords.x, coords.y, coords.z, destination.x, destination.y, destination.z, 2.2,
		2, cache.ped, 4)

	while true do
		Wait(0)
		local retval, _, _, _, entityHit = GetShapeTestResult(handle)

		if retval ~= 1 then
			return entityHit ~= 0 and entityHit
		end
	end
end

function utils.FindPoint(tbl)
	for i, pos in pairs(tbl) do
		local closestVehicle, coords = lib.getClosestVehicle(vec3(pos.x, pos.y, pos.z), 1.8, false)
		if not closestVehicle then return true, pos end
	end

	return false, nil
end

function utils.isCorrectFuelType(model, fuelType)
	if fuelTypes[fuelType] then
		for _, v in ipairs(fuelTypes[fuelType]) do
			if v == model then
				return true
			end
		end
	end

	-- if fuelTypes.DEFAULT == fuelType then
	-- 	return true
	-- end

	return false
end

function utils.getVehicleFuelType(model)
	for fuelType, models in pairs(fuelTypes) do
		if fuelType ~= "DEFAULT" then
			for _, v in ipairs(models) do
				if v == model then
					return fuelType
				end
			end
		end
	end
	return fuelTypes.DEFAULT
end

exports("GetVehicleFuelType", utils.getVehicleFuelType)

local bones = {
	'petrolcap',
	'petroltank',
	'petroltank_l',
	'hub_lr',
	'engine',
}

---@param vehicle integer
function utils.getVehiclePetrolCapBoneIndex(vehicle)
	for i = 1, #bones do
		local boneIndex = GetEntityBoneIndexByName(vehicle, bones[i])

		if boneIndex ~= -1 then
			return boneIndex
		end
	end
end

---@return number
local function defaultMoneyCheck()
	return exports.ox_inventory:GetItemCount('money')
end

utils.getMoney = defaultMoneyCheck

exports('setMoneyCheck', function(fn)
	utils.getMoney = fn or defaultMoneyCheck
end)


---@class makePedData
---@field coords vector4
---@field freeze? boolean
---@field collision? boolean
---@field scenario? string
---@field anim? table|nil
---@param data makePedData
utils.makePed = (function(model, data, options)
	if not IsModelValid(model) then
		return print("^4Invalid Model^7: '^6" .. model .. "^7'")
	end

	local count = 1
	if options then
		for _, option in pairs(options) do
			if option.onSelect then
				count += 1

				local event = ("option_%p_%s"):format(option.onSelect, count)
				---@type function
				local onSelect = option.onSelect

				AddEventHandler(event, (function()
					onSelect(option.args)
				end))
				option.event = event
				option.onSelect = nil
			end

			if option.icon then
				option.icon = ("fa-solid fa-%s"):format(option.icon)
			end
		end
	end


	local ped, id
	local p = lib.points.new({
		coords = data.coords.xyz,
		distance = 80.0,
		onEnter = (function()
			lib.requestModel(model, 5000)

			Peds[#Peds + 1] = CreatePed(0, model, data.coords.x, data.coords.y, data.coords.z,
				data.coords.w,
				false,
				true)
			ped = Peds[#Peds]

			SetEntityInvincible(ped, true)
			SetBlockingOfNonTemporaryEvents(ped, true)
			FreezeEntityPosition(ped, data.freeze or true)

			if data.collision then
				SetEntityNoCollisionEntity(ped, PlayerPedId(), false)
			end

			if data.scenario then
				TaskStartScenarioInPlace(ped, data.scenario, 0, true)
			end
			if data.anim then
				local dict = data.anim[1]
				if not HasAnimDictLoaded(dict) then
					print("^2Loading Anim Dictionary^7: '^6" .. dict .. "^7'")
					while not HasAnimDictLoaded(dict) do
						RequestAnimDict(dict)
						Wait(5)
					end
				end
				TaskPlayAnim(ped, data.anim[1], data.anim[2], 1.0, 1.0, -1, 1, 0.2, false, false, false)
			end

			if options then
				id = ("%s_ped_%s"):format("__MATEHUN__", ped)

				exports["ox_target"]:addLocalEntity(ped, options)
			end
		end),

		onExit = (function()
			if id then
				exports["ox_target"]:removeLocalEntity(ped)
				id = nil
			end
			DeleteEntity(ped)
			SetModelAsNoLongerNeeded(model)
			ped = nil
		end)
	})


	function p:onExit()
		if DoesEntityExist(Peds[#Peds]) then
			DeleteEntity(Peds[#Peds])
		end
	end
end)

return utils
