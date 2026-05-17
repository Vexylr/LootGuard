local LG = LootGuard

local ItemInspector = {}
LG.ItemInspector = ItemInspector

local ARMOR_SUB = {
	[1] = LG.ARMOR_CLOTH,
	[2] = LG.ARMOR_LEATHER,
	[3] = LG.ARMOR_MAIL,
	[4] = LG.ARMOR_PLATE,
}

function ItemInspector:ParseItemLink(itemLink)
	if not itemLink then return nil end
	local itemID = tonumber(itemLink:match("item:(%d+)"))
	if not itemID then return nil end

	-- Return order per Blizzard API (classID/subclassID are 12/13, not 6/7)
	local name, link, quality, iLevel, reqLevel, itemType, itemSubType, _, equipLoc, _, _, classID, subClassID =
		GetItemInfo(itemLink)

	if not name then
		return {
			itemID = itemID,
			itemLink = itemLink,
			itemName = "Loading...",
			quality = 0,
			armorType = LG.ARMOR_NONE,
			equipLoc = nil,
			itemClass = nil,
			itemSubClass = nil,
			pending = true,
		}
	end

	local armorType = LG.ARMOR_NONE
	local subClassName = itemSubType
	if classID == LG.ITEM_CLASS_ARMOR then
		armorType = ARMOR_SUB[subClassID] or LG.ARMOR_NONE
		subClassName = select(2, GetItemSubClassInfo(classID, subClassID)) or itemSubType
	elseif classID == LG.ITEM_CLASS_WEAPON then
		subClassName = select(2, GetItemSubClassInfo(classID, subClassID)) or itemSubType
	end

	return {
		itemID = itemID,
		itemLink = link or itemLink,
		itemName = name,
		quality = quality or 0,
		armorType = armorType,
		equipLoc = equipLoc,
		itemClass = classID,
		itemSubClass = subClassName,
		itemSubClassID = subClassID,
		reqLevel = reqLevel,
		pending = false,
	}
end

function ItemInspector:IsEquippable(info)
	if not info then return false end
	return info.equipLoc and info.equipLoc ~= ""
end

function ItemInspector:IsArmor(info)
	return info and info.itemClass == LG.ITEM_CLASS_ARMOR
end

function ItemInspector:IsWeapon(info)
	return info and info.itemClass == LG.ITEM_CLASS_WEAPON
end
