local LG = LootGuard

-- Tracks rolls when C_LootHistory is missing or empty (common on some clients).
local RollFallback = {}
LG.RollFallback = RollFallback

function RollFallback:Init(addon)
	self.addon = addon
	self.pending = {}
end

function RollFallback:ShouldUse()
	if LG.Diagnostics and LG.Diagnostics:HasLootHistory() then
		local ok, n = pcall(function() return C_LootHistory.GetNumItems() end)
		if ok and n and n > 0 then
			return false
		end
	end
	return true
end

function RollFallback:OnStartLootRoll(rollID)
	if not rollID or not LG.RollTracker or not LG.RollTracker:IsGroupContent() then return end
	if not self:ShouldUse() then return end
	local link = GetLootRollItemLink and GetLootRollItemLink(rollID)
	if not link then return end
	local itemName
	if GetLootRollItemInfo then
		itemName = GetLootRollItemInfo(rollID)
	end
	self.pending[rollID] = {
		rollID = rollID,
		itemLink = link,
		itemName = itemName,
		rolls = {},
		started = time(),
	}
end

function RollFallback:OnChatRoll(msg)
	if not msg or not LG.RollTracker or not LG.RollTracker:IsGroupContent() then return end
	if not self:ShouldUse() then return end

	local name, rollWord, item = msg:match("^(.-) rolls (Need|Greed|Disenchant) on %[(.+)%]%.?$")
	if not name then
		name, rollWord, item = msg:match("^(.-) rolls (Need|Greed|Disenchant) on (.+)%.$")
	end
	if not name or not item then return end
	name = name:gsub("^%s+", ""):gsub("%s+$", "")
	item = item:gsub("^%s+", ""):gsub("%s+$", "")

	local rollType = LG.ROLL_GREED
	if rollWord == "Need" then rollType = LG.ROLL_NEED
	elseif rollWord == "Disenchant" then rollType = LG.ROLL_DISENCHANT end

	for rollID, pending in pairs(self.pending) do
		local matchName = pending.itemName
		if matchName and (matchName == item or matchName:find(item, 1, true) or item:find(matchName, 1, true)) then
			local realm
			name, realm = LG.Storage:SplitNameRealm(name)
			pending.rolls[#pending.rolls + 1] = {
				name = name,
				realm = realm,
				class = nil,
				rollType = rollType,
				rollValue = 0,
				isWinner = false,
			}
			return
		end
	end
end

function RollFallback:FinalizeRoll(rollID)
	local pending = self.pending[rollID]
	if not pending or not LG.RollTracker then return end
	self.pending[rollID] = nil

	if LG.RollTracker.processedRolls[rollID] then return end

	local info = LG.ItemInspector:ParseItemLink(pending.itemLink)
	local record = {
		rollID = rollID,
		itemLink = pending.itemLink,
		itemID = info and info.itemID,
		itemName = info and info.itemName or "Unknown",
		quality = info and info.quality or 0,
		armorType = info and info.armorType or LG.ARMOR_NONE,
		equipLoc = info and info.equipLoc,
		itemClass = info and info.itemClass,
		itemSubClass = info and info.itemSubClass,
		itemSubClassID = info and info.itemSubClassID,
		instance = LG.RollTracker:GetInstanceName(),
		timestamp = time(),
		isDone = true,
		rolls = pending.rolls,
	}

	if #record.rolls == 0 then return end

	LG.RollTracker:RememberProcessed(rollID)
	LG.Engine:ProcessRoll(record)
	LG.Storage:AddSessionRoll(record)
	if LG.SessionTab then LG.SessionTab:Refresh() end
	if LG.NinjaListTab then LG.NinjaListTab:Refresh() end
end

function RollFallback:OnLootRollsComplete()
	if not self:ShouldUse() then return end
	for rollID in pairs(self.pending) do
		self:FinalizeRoll(rollID)
	end
	if LG.RollTracker and LG.Diagnostics and LG.Diagnostics:HasLootHistory() then
		C_Timer.After(0.5, function()
			if LG.RollTracker then LG.RollTracker:FullScan() end
		end)
	end
end

function RollFallback:OnCancelLootRoll(rollID)
	if rollID then self.pending[rollID] = nil end
end
