local LG = LootGuard

local RollTracker = {}
LG.RollTracker = RollTracker

function RollTracker:Init(addon)
	self.addon = addon
	self.processedRolls = {}
	self.pendingItems = {}
	self.processedOrder = {}
end

function RollTracker:OnItemInfo(itemID)
	if not itemID or not self.pendingItems then return end
	for rollID, pendingID in pairs(self.pendingItems) do
		if pendingID == itemID and not self.processedRolls[rollID] then
			local idx = self:FindItemIndex(rollID)
			if idx then
				self:RefreshItem(idx)
			end
		end
	end
end

function RollTracker:RememberProcessed(rollID)
	self.processedRolls[rollID] = true
	self.pendingItems[rollID] = nil
	self.processedOrder[#self.processedOrder + 1] = rollID
	while #self.processedOrder > 500 do
		local old = table.remove(self.processedOrder, 1)
		self.processedRolls[old] = nil
		self.pendingItems[old] = nil
	end
end

function RollTracker:IsGroupContent()
	return IsInGroup() or IsInRaid()
end

function RollTracker:GetInstanceName()
	local name = GetInstanceInfo()
	if name and name ~= "" then return name end
	return GetZoneText() or "Unknown"
end

function RollTracker:OnLootHistoryEvent(event, ...)
	if not self:IsGroupContent() then return end
	if event == "LOOT_HISTORY_ROLL_CHANGED" then
		local itemIdx, playerIdx = ...
		self:RefreshItem(itemIdx)
	elseif event == "LOOT_HISTORY_ROLL_COMPLETE" or event == "LOOT_HISTORY_FULL_UPDATE" then
		self:FullScan()
	end
end

function RollTracker:FullScan()
	if not C_LootHistory or not C_LootHistory.GetNumItems then return end
	local n = C_LootHistory.GetNumItems()
	for i = 1, n do
		self:RefreshItem(i)
	end
end

function RollTracker:FindItemIndex(rollID)
	if not C_LootHistory or not C_LootHistory.GetNumItems then return nil end
	local n = C_LootHistory.GetNumItems()
	for i = 1, n do
		local rid = C_LootHistory.GetItem(i)
		if rid == rollID then return i end
	end
end

function RollTracker:RefreshItem(itemIdx, forceProcess)
	if not C_LootHistory then return end
	local rollID, itemLink, numPlayers, isDone = C_LootHistory.GetItem(itemIdx)
	if not rollID or not itemLink then return end
	if self.processedRolls[rollID] and not isDone then return end

	local info = LG.ItemInspector:ParseItemLink(itemLink)
	if info and info.pending and not forceProcess then
		self.pendingItems[rollID] = info.itemID or true
		if info.itemID and GetItemInfo then
			GetItemInfo(info.itemID)
		end
		C_Timer.After(1, function()
			if self.processedRolls[rollID] then return end
			local idx = self:FindItemIndex(rollID) or itemIdx
			self:RefreshItem(idx)
		end)
		C_Timer.After(3, function()
			if self.processedRolls[rollID] then return end
			local idx = self:FindItemIndex(rollID) or itemIdx
			local _, link, _, _, done = C_LootHistory.GetItem(idx)
			if done and link then
				self:RefreshItem(idx, true)
			else
				self:RefreshItem(idx)
			end
		end)
		return
	end

	if info and info.pending and forceProcess then
		info.pending = false
		if not info.itemName or info.itemName == "Loading..." then
			info.itemName = "Unknown Item"
		end
	end

	local record = {
		rollID = rollID,
		itemLink = itemLink,
		itemID = info and info.itemID,
		itemName = info and info.itemName or "Unknown",
		quality = info and info.quality or 0,
		armorType = info and info.armorType or LG.ARMOR_NONE,
		equipLoc = info and info.equipLoc,
		itemClass = info and info.itemClass,
		itemSubClass = info and info.itemSubClass,
		itemSubClassID = info and info.itemSubClassID,
		instance = self:GetInstanceName(),
		timestamp = time(),
		isDone = isDone,
		rolls = {},
	}

	for i = 1, numPlayers or 0 do
		local name, class, rollType, roll, isWinner = C_LootHistory.GetPlayerInfo(itemIdx, i)
		if name then
			local realm
			name, realm = LG.Storage:SplitNameRealm(name)
			record.rolls[#record.rolls + 1] = {
				name = name,
				realm = realm,
				class = class,
				rollType = rollType,
				rollValue = roll,
				isWinner = isWinner,
			}
		end
	end

	if isDone and not self.processedRolls[rollID] then
		self:RememberProcessed(rollID)
		LG.Engine:ProcessRoll(record)
		LG.Storage:AddSessionRoll(record)
		local g = LG.Storage:GetGlobal()
		if LG.Comm and g and g.enablePartySync then
			LG.Comm:SendSessionRoll(record)
		end
		if LG.SessionTab then
			LG.SessionTab:Refresh()
		end
		if LG.NinjaListTab then
			LG.NinjaListTab:Refresh()
		end
	end
end

