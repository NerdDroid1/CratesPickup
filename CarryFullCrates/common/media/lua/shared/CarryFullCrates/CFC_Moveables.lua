--[[
	Carry Full Crates - moveables integration (shared)

	Wraps ISMoveableSpriteProps so supported crates can be picked up while
	they still contain items. Originals are always preserved and still
	handle every non-crate object.
]]

require "CarryFullCrates/CFC_Main"

local CFC = CarryFullCrates

if not ISMoveableSpriteProps then
	return
end

local canPickUpInternalOrig = ISMoveableSpriteProps.canPickUpMoveableInternal

-- Vanilla pickup gate with only the "container must be empty" clause
-- bypassed for supported crates (B42 ISMoveableSpriteProps.lua:1202).
function ISMoveableSpriteProps:canPickUpMoveableInternal(_character, _square, _object, _isMulti)
	if _object and not self.isMultiSprite and CFC.isSupportedCrate(_object) then
		local canPickUp = false
		if self.isMoveable and instanceof(_square, "IsoGridSquare") then
			-- CFC: vanilla checks `_object:isObjectNoContainerOrEmpty()` here; skipped on purpose.
			canPickUp = true
			if (not _isMulti or self.isForceSingleItem) and canPickUp then
				canPickUp = _character:getInventory():hasRoomFor(_character, self.weight)
			end
			if canPickUp and self.isTable then
				canPickUp = not _square:has("IsTableTop") and _object == self:getTopTable(_square)
			end
			self.yOffsetCursor = _object and _object:getRenderYOffset() or 0

			if canPickUp and self.isWaterCollector then
				if _object and _object:hasFluid() then
					canPickUp = false
				end
			end

			if canPickUp and self.type == "Window" then
				if _object and instanceof(_object, "IsoWindow") then
					canPickUp = _object:isDestroyed() or (not _object:IsOpen())
					if _object:isBarricaded() then
						canPickUp = false
					end
				else
					canPickUp = false
				end
			end

			if canPickUp and self.type == "WindowObject" then
				if _character:getSquare() and _character:getSquare():has(IsoFlagType.exterior) then
					canPickUp = false
				end
			end

			if canPickUp and self.isoType == "IsoMannequin" then
				canPickUp = true
			end

			if canPickUp and instanceof(_object, "IsoBarbecue") then
				canPickUp = not _object:isLit() and not _object:hasPropaneTank()
			end

			if canPickUp and instanceof(_object, "IsoFireplace") then
				canPickUp = not (_object:isLit() or _object:isSmouldering())
			end

			if canPickUp and _character and instanceof(_character, "IsoGameCharacter") then
				local hasSKill, _ = self:hasRequiredSkill(_character, "pickup")
				local hasTool = not self.pickUpTool and true or self:hasTool(_character, "pickup")
				canPickUp = hasSKill and hasTool
			end
		end
		return canPickUp
	end
	if canPickUpInternalOrig then
		return canPickUpInternalOrig(self, _character, _square, _object, _isMulti)
	end
	return false
end

local pickUpInternalOrig = ISMoveableSpriteProps.pickUpMoveableInternal

function ISMoveableSpriteProps:pickUpMoveableInternal(_character, _square, _object, _sprInstance, _spriteName, _createItem, _rotating)
	local isCrate = (not self.isMultiSprite) and _object ~= nil and _createItem
		and CFC.isSupportedCrate(_object) and CFC.hasItems(_object)

	local snapshot = nil
	if isCrate then
		snapshot = CFC.captureObject(_object)
		snapshot.contentsWeight = CFC.sumContentsWeight(_object)
	end

	local item = pickUpInternalOrig(self, _character, _square, _object, _sprInstance, _spriteName, _createItem, _rotating)

	if isCrate and item and instanceof(item, "InventoryItem") then
		item:getModData()[CFC.MODDATA_KEY] = snapshot
		-- held encumbrance = crate base weight + everything inside it
		local baseWeight = item:getActualWeight()
		item:setActualWeight(baseWeight + (snapshot.contentsWeight or 0))
		-- carried in both hands, like generators (ISTakeGenerator pattern)
		if _character and instanceof(_character, "IsoGameCharacter")
			and _character:getInventory():contains(item) then
			_character:setPrimaryHandItem(item)
			_character:setSecondaryHandItem(item)
		end
	end

	return item
end

local placeInternalOrig = ISMoveableSpriteProps.placeMoveableInternal

function ISMoveableSpriteProps:placeMoveableInternal(_character, _square, _item, _spriteName)
	local obj = placeInternalOrig(self, _character, _square, _item, _spriteName)

	if obj and _item and instanceof(_item, "InventoryItem") and _item:hasModData() then
		local snapshot = _item:getModData()[CFC.MODDATA_KEY]
		if snapshot and snapshot.containers then
			CFC.restoreObject(obj, snapshot)
		end
	end

	return obj
end

local infoFlagsOrig = ISMoveableSpriteProps.getInfoPanelFlagsPerTile

function ISMoveableSpriteProps:getInfoPanelFlagsPerTile(_square, _object, _player, _mode)
	infoFlagsOrig(self, _square, _object, _player, _mode)
	if _mode == "pickup" and _object and not self.isMultiSprite and CFC.isSupportedCrate(_object) then
		-- pickup is allowed now, so don't show the red "Items in container" line
		InfoPanelFlags.hasItems = false
	end
end
