local addonName = ...
local LG = LootGuard

local Addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceEvent-3.0", "AceConsole-3.0", "AceTimer-3.0", "AceComm-3.0")
LG.addon = Addon

function Addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("LootGuardDB", LG.Storage:GetDefaults(), true)
	LG.Storage:Init(self.db)

	LG.Engine:Init(self)
	LG.RollTracker:Init(self)
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
end

function Addon:OnEnable()
	self:RegisterEvent("LOOT_HISTORY_ROLL_CHANGED", "OnLootHistory")
	self:RegisterEvent("LOOT_HISTORY_ROLL_COMPLETE", "OnLootHistory")
	self:RegisterEvent("LOOT_HISTORY_FULL_UPDATE", "OnLootHistory")
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
end

function Addon:OnLootHistory(event, ...)
	if LG.RollTracker then
		LG.RollTracker:OnLootHistoryEvent(event, ...)
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
	if msg == "config" or msg == "settings" then
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
		print("|cffc9a227LootGuard|r v1.0.0 — /lg, /lg session, /lg ninja, /lg sync, /lg config")
	else
		LG.MainFrame:EnsureBuilt()
		LG.MainFrame:Toggle()
	end
end
