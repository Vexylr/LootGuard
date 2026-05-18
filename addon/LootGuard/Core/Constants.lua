LootGuard = LootGuard or {}
local LG = LootGuard
LG.ADDON_PREFIX = "LGv1"
LG.ADDON_VERSION = 1

-- Roll types (match Blizzard constants)
LG.ROLL_PASS = 0
LG.ROLL_NEED = 1
LG.ROLL_GREED = 2
LG.ROLL_DISENCHANT = 3

LG.ROLL_TYPE_NAMES = {
	[0] = "Pass",
	[1] = "Need",
	[2] = "Greed",
	[3] = "Disenchant",
}

-- Flag severity (higher = worse)
LG.FLAG_NONE = 0
LG.FLAG_WATCH = 1
LG.FLAG_SUSPECTED = 2
LG.FLAG_NINJA = 3

LG.FLAG_NAMES = {
	[0] = "Clear",
	[1] = "Watch",
	[2] = "Suspected",
	[3] = "Ninja",
}

-- Violation types
LG.VIOL_WRONG_ARMOR = "wrong_armor"
LG.VIOL_WRONG_WEAPON = "wrong_weapon"
LG.VIOL_NEED_SPAM = "need_spam"

LG.VIOLATION_WEIGHTS = {
	wrong_armor = 2.0,
	wrong_weapon = 1.5,
	need_spam = 1.0,
}

-- Comm opcodes
LG.OP_REPUTATION = "R"
LG.OP_INCIDENT = "I"
LG.OP_HANDSHAKE = "H"
LG.OP_DELTA = "D"
LG.OP_SESSION_ROLL = "S"

LG.ARMOR_CLOTH = "cloth"
LG.ARMOR_LEATHER = "leather"
LG.ARMOR_MAIL = "mail"
LG.ARMOR_PLATE = "plate"
LG.ARMOR_NONE = "none"

-- Item class IDs (GetItemInfo)
LG.ITEM_CLASS_ARMOR = 4
LG.ITEM_CLASS_WEAPON = 2
