local addonName = ...
local LG = LootGuard

local Addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceEvent-3.0", "AceConsole-3.0", "AceTimer-3.0", "AceComm-3.0")
LG.addon = Addon

local function SlashHandler(msg)
	Addon:OnChat(msg)
end

function Addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("LootGuardDB", LG.Storage:GetDefaults(), true)
	LG.Storage:Init(self.db)

	LG.Engine:Init(self)
	LG.RollTracker:Init(self)
	if LG.RollFallback then LG.RollFallback:Init(self) end
	LG.Comm:Init(self)
	LG.GuildSync:Init(self)
	LG.MeetSync:Init(self)
	LG.MainFrame:Init(self)
	LG.Minimap:Init(self)
	LG.Reputation:Init(self)
	LG.SettingsTab:RegisterAceConfig()

	if LG.MainFrame.frame then
		LG.MainFrame:EnsureBuilt()
	end

	self:RegisterChatCommand("lootguard", "OnChat")
	self:RegisterChatCommand("lg", "OnChat")

	-- Fallback slash registration if AceConsole fails on some clients
	_G.SLASH_LOOTGUARD1 = "/lootguard"
	_G.SLASH_LOOTGUARD2 = "/lg"
	_G.SlashCmdList = _G.SlashCmdList or {}
	_G.SlashCmdList["LOOTGUARD"] = SlashHandler
end

function Addon:OnEnable()
	self:RegisterEvent("LOOT_HISTORY_ROLL_CHANGED", "OnLootHistory")
	self:RegisterEvent("LOOT_HISTORY_ROLL_COMPLETE", "OnLootHistory")
	self:RegisterEvent("LOOT_HISTORY_FULL_UPDATE", "OnLootHistory")
	self:RegisterEvent("START_LOOT_ROLL", "OnStartLootRoll")
	self:RegisterEvent("LOOT_ROLLS_COMPLETE", "OnLootRollsComplete")
	self:RegisterEvent("CANCEL_LOOT_ROLL", "OnCancelLootRoll")
	self:RegisterEvent("CHAT_MSG_SYSTEM", "OnChatMsgSystem")
	self:RegisterEvent("PLAYER_GUILD_UPDATE", "OnGuildUpdate")
	self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnRosterUpdate")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", "OnMouseover")
	self:RegisterEvent("GET_ITEM_INFO_RECEIVED", "OnItemInfoReceived")

	LG.Minimap:Refresh()
	if LG.GuildSync then
		LG.GuildSync:OnLogin()
	end
	if LG.RollTracker then
		self:ScheduleTimer(function()
			if IsInGroup() or IsInRaid() then
				LG.RollTracker:FullScan()
			end
		end, 2)
	end
	if LG.MainFrame.frame then
		LG.MainFrame:EnsureBuilt()
	end
	if LG.Diagnostics then
		LG.Diagnostics:PrintLoaded()
	end
end

function Addon:OnLootHistory(event, ...)
	if LG.RollTracker then
		LG.RollTracker:OnLootHistoryEvent(event, ...)
	end
end

function Addon:OnStartLootRoll(event, rollID)
	if LG.RollFallback then
		LG.RollFallback:OnStartLootRoll(rollID)
	end
end

function Addon:OnLootRollsComplete()
	if LG.RollFallback then
		LG.RollFallback:OnLootRollsComplete()
	end
	if LG.RollTracker then
		C_Timer.After(0.35, function()
			if LG.RollTracker then LG.RollTracker:FullScan() end
		end)
	end
end

function Addon:OnCancelLootRoll(event, rollID)
	if LG.RollFallback then
		LG.RollFallback:OnCancelLootRoll(rollID)
	end
end

function Addon:OnChatMsgSystem(event, msg)
	if LG.RollFallback then
		LG.RollFallback:OnChatRoll(msg)
	end
end

function Addon:OnItemInfoReceived(event, itemID)
	if itemID and LG.RollTracker then
		LG.RollTracker:OnItemInfo(itemID)
	end
end

function Addon:OnGuildUpdate()
	local g = LG.Storage:GetGlobal()
	if LG.GuildSync and g and g.enableGuildSync then
		LG.GuildSync:BroadcastAll()
	end
end

function Addon:OnRosterUpdate()
	if not IsInGroup() then return end
	local g = LG.Storage:GetGlobal()
	if not g or not LG.MeetSync or not g.enableMeetSync then return end
	if IsInRaid() then
		local n = GetNumGroupMembers()
		for i = 1, n do
			local unit = "raid" .. i
			if UnitExists(unit) then LG.MeetSync:OnPlayerSeen(unit) end
		end
	else
		for i = 1, 4 do
			local unit = "party" .. i
			if UnitExists(unit) then LG.MeetSync:OnPlayerSeen(unit) end
		end
	end
end

function Addon:OnMouseover()
	local g = LG.Storage:GetGlobal()
	if not g or not g.enableMeetSync then return end
	if LG.MeetSync then LG.MeetSync:OnPlayerSeen("mouseover") end
end

function Addon:OnChat(msg)
	msg = (msg or ""):lower()
	if msg == "debug" or msg == "status" then
		if LG.Diagnostics then LG.Diagnostics:PrintStatus() end
	elseif msg == "config" or msg == "settings" then
		LG.SettingsTab:RegisterAceConfig()
		LibStub("AceConfigDialog-3.0"):Open("LootGuard")
	elseif msg == "session" then
		LG.MainFrame:EnsureBuilt()
		LG.MainFrame:ShowTab("session")
		LG.MainFrame:Toggle(true)
	elseif msg == "ninja" or msg == "list" then
		LG.MainFrame:EnsureBuilt()
		LG.MainFrame:ShowTab("ninja")
		LG.MainFrame:Toggle(true)
	elseif msg == "sync" then
		if not IsInGuild() then
			print("|cffc9a227LootGuard:|r You must be in a guild to sync.")
		elseif LG.GuildSync then
			LG.GuildSync:BroadcastAll()
			print("|cffc9a227LootGuard:|r Guild sync requested.")
		end
	elseif msg == "help" or msg == "?" then
		print("|cffc9a227LootGuard|r v1.0.0 — /lg, /lg session, /lg ninja, /lg sync, /lg config, /lg debug")
	else
		if not LG.MainFrame.frame then
			print("|cffc9a227LootGuard:|r UI frame missing. Try /reload. /lg debug for details.")
			if LG.Diagnostics then LG.Diagnostics:PrintStatus() end
			return
		end
		LG.MainFrame:EnsureBuilt()
		LG.MainFrame:Toggle()
	end
end
