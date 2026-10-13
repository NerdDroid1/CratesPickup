--[[
	Carry Full Crates - inventory transfer guard (client)

	A loaded crate is carried in both hands and cannot be stashed inside
	any bag: worn backpacks, bags held in hand, bags nested in other bags,
	or bags lying on the ground. Floor, vehicle and world containers stay
	allowed, so the crate can always be dropped or stored in the open.
]]

require "CarryFullCrates/CFC_Main"

local CFC = CarryFullCrates

if not ISInventoryTransferAction then
	return
end

local isValidOrig = ISInventoryTransferAction.isValid

function ISInventoryTransferAction:isValid()
	local item = self.item
	if item and self.destContainer and item:hasModData() then
		if item:getModData()[CFC.MODDATA_KEY] then
			local ok, containingItem = pcall(function()
				return self.destContainer:getContainingItem()
			end)
			if ok and containingItem ~= nil then
				return false
			end
		end
	end
	if isValidOrig then
		return isValidOrig(self)
	end
	return true
end
