--[[
	Carry Full Crates - core module (shared)

	Provides crate detection, container inventory, and container weight calculations.
]]

CarryFullCrates = CarryFullCrates or {}

local CFC = CarryFullCrates

CFC.MODDATA_KEY = "CFC"
CFC.VERSION = 1

-- Vanilla + common crate container types (matched case-insensitively).
CFC.containerTypes = {
	crates = true,
	crate = true,
	woodcrate = true,
	wooden_crate = true,
	metalcrate = true,
	metal_crate = true,
	militarycrate = true,
	military_crate = true,
	smallcrate = true,
	small_crate = true,
	fancy_metal_crate = true,
}

-- Sprite name substrings (lowercase) that also mark an object as a crate.
CFC.spritePatterns = {
	"crate",
}

function CFC.AddContainerType(typeName)
	if type(typeName) == "string" then
		CFC.containerTypes[string.lower(typeName)] = true
	end
end

function CFC.AddSpritePattern(pattern)
	if type(pattern) == "string" then
		local lower = string.lower(pattern)
		for _, existing in ipairs(CFC.spritePatterns) do
			if existing == lower then
				return
			end
		end
		table.insert(CFC.spritePatterns, lower)
	end
end

-- True when the world object has at least one container with items in it.
function CFC.hasItems(object)
	local ok, result = pcall(function()
		return not object:isObjectNoContainerOrEmpty()
	end)
	return ok and result or false
end

function CFC.isSupportedCrate(object)
	if not object or not instanceof(object, "IsoObject") then
		return false
	end
	local okCount, containerCount = pcall(function()
		return object:getContainerCount()
	end)
	if not okCount or not containerCount or containerCount < 1 then
		return false
	end
	-- match by container type
	for i = 0, containerCount - 1 do
		local cont = object:getContainerByIndex(i)
		if cont then
			local ctype = cont:getType()
			if ctype and CFC.containerTypes[string.lower(ctype)] then
				return true
			end
		end
	end
	-- match by sprite name
	local sprite = object:getSprite()
	local spriteName = sprite and sprite:getName()
	if spriteName then
		local lower = string.lower(spriteName)
		for _, pattern in ipairs(CFC.spritePatterns) do
			if string.find(lower, pattern, 1, true) then
				return true
			end
		end
	end
	return false
end

-- Deep copy limited to values that can round-trip through saved modData.
local function copyModData(t)
	if type(t) ~= "table" then
		return nil
	end
	local out = {}
	for k, v in pairs(t) do
		local vt = type(v)
		if vt == "number" or vt == "string" or vt == "boolean" then
			out[k] = v
		elseif vt == "table" then
			out[k] = copyModData(v)
		end
	end
	return out
end

local function captureItem(item)
	local data = {}
	data.fullType = item:getFullType()
	data.count = item:getCount()
	data.condition = item:getCondition()
	local okMax, maxCond = pcall(function()
		return item:getConditionMax()
	end)
	if okMax then
		data.conditionMax = maxCond
	end
	local okCustom, isCustom = pcall(function()
		return item:hasCustomName()
	end)
	if okCustom and isCustom then
		local okName, customName = pcall(function()
			return item:getName()
		end)
		if okName then
			data.name = customName
		end
	end
	if instanceof(item, "DrainableComboItem") then
		local okDelta, delta = pcall(function()
			return item:getDelta()
		end)
		if okDelta then
			data.delta = delta
		end
	end
	if instanceof(item, "Food") then
		local okAge, age = pcall(function()
			return item:getAge()
		end)
		if okAge then
			data.age = age
		end
	end
	local okWet, wetness = pcall(function()
		return item:getWetness()
	end)
	if okWet and wetness and wetness ~= 0 then
		data.wetness = wetness
	end
	if item:hasModData() then
		local md = copyModData(item:getModData())
		if md and next(md) ~= nil then
			data.modData = md
		end
	end
	return data
end

-- Snapshot every container of the world object into a plain table.
function CFC.captureObject(object)
	local data = { containers = {} }
	for i = 0, object:getContainerCount() - 1 do
		local cont = object:getContainerByIndex(i)
		if cont then
			local cdata = { type = cont:getType(), items = {} }
			local items = cont:getItems()
			for j = 0, items:size() - 1 do
				local item = items:get(j)
				if item then
					local ok, idata = pcall(captureItem, item)
					if ok and idata and idata.fullType then
						table.insert(cdata.items, idata)
					end
				end
			end
			table.insert(data.containers, cdata)
		end
	end
	return data
end

-- Live encumbrance of the contents; resolves weights from whatever item
-- scripts the player's game actually has loaded (other mods included).
function CFC.sumContentsWeight(object)
	local total = 0
	for i = 0, object:getContainerCount() - 1 do
		local cont = object:getContainerByIndex(i)
		if cont then
			local items = cont:getItems()
			for j = 0, items:size() - 1 do
				local item = items:get(j)
				if item then
					local ok, w = pcall(function()
						return item:getActualWeight()
					end)
					if ok and w then
						total = total + w
					end
				end
			end
		end
	end
	return total
end

local function addRestoredItem(cont, item)
	cont:AddItem(item)
	if isClient() then
		sendAddItemToContainer(cont, item)
	end
end

local function restoreItemInto(cont, data)
	if not data.fullType then
		return
	end
	local item = instanceItem(data.fullType)
	if not item then
		return
	end
	if data.conditionMax and data.conditionMax > 0 then
		pcall(function()
			item:setConditionMax(data.conditionMax)
		end)
	end
	if data.condition then
		pcall(function()
			item:setCondition(data.condition)
		end)
	end
	if data.count and data.count > 1 then
		pcall(function()
			item:setCount(data.count)
		end)
	end
	if data.delta and instanceof(item, "DrainableComboItem") then
		pcall(function()
			item:setDelta(data.delta)
		end)
	end
	if data.age and instanceof(item, "Food") then
		pcall(function()
			item:setAge(data.age)
		end)
	end
	if data.wetness then
		pcall(function()
			item:setWetness(data.wetness)
		end)
	end
	if data.name then
		pcall(function()
			item:setName(data.name)
			item:setCustomName(true)
		end)
	end
	if data.modData then
		local md = item:getModData()
		for k, v in pairs(data.modData) do
			md[k] = v
		end
	end
	addRestoredItem(cont, item)
	-- fallback if setCount is unavailable: spawn remaining units individually
	local want = data.count or 1
	local okHave, have = pcall(function()
		return item:getCount()
	end)
	have = (okHave and have) or 1
	while have < want do
		local extra = instanceItem(data.fullType)
		if not extra then
			break
		end
		addRestoredItem(cont, extra)
		have = have + 1
	end
end

local function findContainer(object, typeName)
	for i = 0, object:getContainerCount() - 1 do
		local cont = object:getContainerByIndex(i)
		if cont and cont:getType() == typeName then
			return cont
		end
	end
	if object:getContainerCount() > 0 then
		return object:getContainerByIndex(0)
	end
	return nil
end

-- Recreate all captured items in the placed world object.
function CFC.restoreObject(object, data)
	if not object or not data or not data.containers then
		return
	end
	for _, cdata in ipairs(data.containers) do
		local cont = findContainer(object, cdata.type)
		if cont then
			for _, idata in ipairs(cdata.items or {}) do
				pcall(restoreItemInto, cont, idata)
			end
		end
	end
end
