local LG = LootGuard

local ClassRules = {}
LG.ClassRules = ClassRules

-- fileName -> class token (upper)
local CLASS_FILE = {
	WARRIOR = "WARRIOR",
	PALADIN = "PALADIN",
	HUNTER = "HUNTER",
	ROGUE = "ROGUE",
	PRIEST = "PRIEST",
	DEATHKNIGHT = "DEATHKNIGHT",
	SHAMAN = "SHAMAN",
	MAGE = "MAGE",
	WARLOCK = "WARLOCK",
	DRUID = "DRUID",
}

-- ItemWeaponSubclass IDs (locale-independent; see documentation/api-reference/LuaEnum.lua)
local W = {
	Axe1H = 0, Axe2H = 1, Bows = 2, Guns = 3, Mace1H = 4, Mace2H = 5,
	Polearm = 6, Sword1H = 7, Sword2H = 8, Staff = 10, Unarmed = 13,
	Dagger = 15, Thrown = 16, Crossbow = 18, Wand = 19,
}

-- Expected armor for legitimate NEED on armor pieces
ClassRules.ARMOR_BY_CLASS = {
	WARRIOR = { plate = true },
	PALADIN = { plate = true },
	DEATHKNIGHT = { plate = true },
	HUNTER = { mail = true, leather = true },
	SHAMAN = { mail = true, leather = true },
	ROGUE = { leather = true },
	DRUID = { leather = true },
	MAGE = { cloth = true },
	PRIEST = { cloth = true },
	WARLOCK = { cloth = true },
}

-- Weapon subclass IDs per class (true = allowed, false = explicitly wrong)
ClassRules.WEAPON_IDS_BY_CLASS = {
	WARRIOR = {
		[W.Axe1H] = true, [W.Axe2H] = true, [W.Mace1H] = true, [W.Mace2H] = true,
		[W.Sword1H] = true, [W.Sword2H] = true, [W.Polearm] = true, [W.Staff] = true,
		[W.Dagger] = true, [W.Unarmed] = true,
		[W.Bows] = false, [W.Guns] = false, [W.Crossbow] = false, [W.Thrown] = false, [W.Wand] = false,
	},
	PALADIN = {
		[W.Axe1H] = true, [W.Axe2H] = true, [W.Mace1H] = true, [W.Mace2H] = true,
		[W.Sword1H] = true, [W.Sword2H] = true, [W.Polearm] = true,
	},
	HUNTER = {
		[W.Bows] = true, [W.Guns] = true, [W.Crossbow] = true, [W.Polearm] = true, [W.Staff] = true,
		[W.Axe1H] = true, [W.Axe2H] = true, [W.Sword1H] = true, [W.Sword2H] = true,
		[W.Dagger] = true, [W.Unarmed] = true,
	},
	ROGUE = {
		[W.Dagger] = true, [W.Sword1H] = true, [W.Mace1H] = true, [W.Axe1H] = true, [W.Unarmed] = true,
		[W.Bows] = true, [W.Guns] = true, [W.Crossbow] = true, [W.Thrown] = true,
	},
	PRIEST = {
		[W.Mace1H] = true, [W.Dagger] = true, [W.Staff] = true, [W.Wand] = true,
	},
	DEATHKNIGHT = {
		[W.Axe1H] = true, [W.Axe2H] = true, [W.Mace1H] = true, [W.Mace2H] = true,
		[W.Sword1H] = true, [W.Sword2H] = true, [W.Polearm] = true,
	},
	SHAMAN = {
		[W.Axe1H] = true, [W.Axe2H] = true, [W.Mace1H] = true, [W.Mace2H] = true,
		[W.Dagger] = true, [W.Unarmed] = true, [W.Staff] = true, [W.Sword1H] = true, [W.Sword2H] = true,
	},
	MAGE = {
		[W.Staff] = true, [W.Wand] = true, [W.Dagger] = true, [W.Sword1H] = true,
	},
	WARLOCK = {
		[W.Staff] = true, [W.Wand] = true, [W.Dagger] = true, [W.Sword1H] = true,
	},
	DRUID = {
		[W.Dagger] = true, [W.Mace1H] = true, [W.Staff] = true, [W.Mace2H] = true,
		[W.Polearm] = true, [W.Unarmed] = true,
	},
}

-- Fallback for English clients / cached roll records without subclass IDs
ClassRules.WEAPONS_BY_CLASS = {
	WARRIOR = { ["One-Handed Axes"] = true, ["Two-Handed Axes"] = true, ["One-Handed Maces"] = true, ["Two-Handed Maces"] = true,
		["One-Handed Swords"] = true, ["Two-Handed Swords"] = true, ["Polearms"] = true, ["Staves"] = true, ["Daggers"] = true, ["Fist Weapons"] = true, ["Bows"] = false, ["Guns"] = false, ["Crossbows"] = false, ["Thrown"] = false, ["Wands"] = false },
	PALADIN = { ["One-Handed Axes"] = true, ["Two-Handed Axes"] = true, ["One-Handed Maces"] = true, ["Two-Handed Maces"] = true,
		["One-Handed Swords"] = true, ["Two-Handed Swords"] = true, ["Polearms"] = true },
	HUNTER = { ["Bows"] = true, ["Guns"] = true, ["Crossbows"] = true, ["Polearms"] = true, ["Staves"] = true,
		["One-Handed Axes"] = true, ["Two-Handed Axes"] = true, ["One-Handed Swords"] = true, ["Two-Handed Swords"] = true, ["Daggers"] = true, ["Fist Weapons"] = true },
	ROGUE = { ["Daggers"] = true, ["One-Handed Swords"] = true, ["One-Handed Maces"] = true, ["One-Handed Axes"] = true, ["Fist Weapons"] = true, ["Bows"] = true, ["Guns"] = true, ["Crossbows"] = true, ["Thrown"] = true },
	PRIEST = { ["One-Handed Maces"] = true, ["Daggers"] = true, ["Staves"] = true, ["Wands"] = true },
	DEATHKNIGHT = { ["One-Handed Axes"] = true, ["Two-Handed Axes"] = true, ["One-Handed Maces"] = true, ["Two-Handed Maces"] = true,
		["One-Handed Swords"] = true, ["Two-Handed Swords"] = true, ["Polearms"] = true },
	SHAMAN = { ["One-Handed Axes"] = true, ["Two-Handed Axes"] = true, ["One-Handed Maces"] = true, ["Two-Handed Maces"] = true,
		["Daggers"] = true, ["Fist Weapons"] = true, ["Staves"] = true, ["One-Handed Swords"] = true, ["Two-Handed Swords"] = true },
	MAGE = { ["Staves"] = true, ["Wands"] = true, ["Daggers"] = true, ["One-Handed Swords"] = true },
	WARLOCK = { ["Staves"] = true, ["Wands"] = true, ["Daggers"] = true, ["One-Handed Swords"] = true },
	DRUID = { ["Daggers"] = true, ["One-Handed Maces"] = true, ["Staves"] = true, ["Two-Handed Maces"] = true, ["Polearms"] = true, ["Fist Weapons"] = true },
}

function ClassRules:NormalizeClass(classToken)
	if not classToken then return nil end
	local upper = classToken:upper():gsub("%s+", "")
	return CLASS_FILE[upper] or upper
end

function ClassRules:CanNeedArmor(classToken, armorType)
	classToken = self:NormalizeClass(classToken)
	if not classToken or not armorType or armorType == LG.ARMOR_NONE then return true end
	local allowed = self.ARMOR_BY_CLASS[classToken]
	if not allowed then return true end
	return allowed[armorType] == true
end

function ClassRules:CanNeedWeapon(classToken, subClassName, subClassID)
	classToken = self:NormalizeClass(classToken)
	if not classToken then return true end

	if subClassID ~= nil then
		local byId = self.WEAPON_IDS_BY_CLASS[classToken]
		if byId then
			local v = byId[subClassID]
			if v ~= nil then return v end
		end
	end

	if subClassName and subClassName ~= "" then
		local byName = self.WEAPONS_BY_CLASS[classToken]
		if byName then
			local v = byName[subClassName]
			if v ~= nil then return v end
		end
	end

	return true
end

function ClassRules:GetPlayerClassToken(unit)
	if not unit then return nil end
	local _, classFile = UnitClass(unit)
	return self:NormalizeClass(classFile)
end
