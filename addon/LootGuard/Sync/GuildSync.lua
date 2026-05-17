local LG = LootGuard

local GuildSync = {}
LG.GuildSync = GuildSync

function GuildSync:Init(addon)
	self.addon = addon
	self.queue = {}
	self.lastBroadcast = 0
	addon:ScheduleRepeatingTimer(function() self:OnTick() end, 300)
end

function GuildSync:QueuePlayer(key)
	self.queue[key] = true
end

function GuildSync:OnTick()
	local g = LG.Storage:GetGlobal()
	if not g or not g.enableGuildSync then return end
	if not IsInGuild() then return end
	local now = GetTime()
	if now - self.lastBroadcast < 30 and not next(self.queue) then return end

	for key in pairs(self.queue) do
		self:BroadcastPlayer(key)
		self.queue[key] = nil
	end
	self.lastBroadcast = now
end

function GuildSync:BroadcastPlayer(key)
	if not LG.Storage.db or not LG.Storage.db.realm then return end
	local p = LG.Storage.db.realm.players[key]
	if not p then return end
	local payload = string.format("%s;%d", LG.Storage:SerializePlayer(p), time())
	LG.Comm:Send(LG.OP_REPUTATION, payload, "GUILD")

	if p.incidents and p.incidents[1] then
		local inc = p.incidents[1]
		local incPayload = string.format("%s|%s|%s|%s|%d", key, inc.type or "", inc.itemName or "", inc.instance or "", inc.timestamp or 0)
		LG.Comm:Send(LG.OP_INCIDENT, incPayload, "GUILD")
	end
end

function GuildSync:BroadcastAll()
	if not LG.Storage.db or not LG.Storage.db.realm then return end
	if not IsInGuild() then return end
	for key in pairs(LG.Storage.db.realm.players) do
		self:QueuePlayer(key)
	end
	self:OnTick()
end

function GuildSync:OnReputation(payload, sender)
	local g = LG.Storage:GetGlobal()
	if not g or not g.enableGuildSync then return end
	local data, ts = payload:match("^(.-);(%d+)$")
	if not data then data = payload end
	local key, remote = LG.Storage:DeserializePlayer(data)
	if not key then return end
	remote.lastSeen = tonumber(ts) or time()
	LG.Merge:MergeRecord(key, remote)
	if LG.NinjaListTab then LG.NinjaListTab:Refresh() end
end

function GuildSync:OnIncident(payload, sender)
	local g = LG.Storage:GetGlobal()
	if not g or not g.enableGuildSync then return end
	local key, iType, item, inst, ts = payload:match("^([^|]+)|([^|]*)|([^|]*)|([^|]*)|(%d+)$")
	if not key then return end
	local p = LG.Storage:GetPlayer(key)
	local prevFlag = p.flag or LG.FLAG_NONE
	LG.Incidents:AddToPlayer(p, {
		type = iType,
		itemName = item,
		instance = inst,
		timestamp = tonumber(ts) or time(),
	})
	LG.Engine:RecalculateReputation(p)
	LG.Engine:UpdateFlag(p, inst)
	if LG.Merge then
		p.flag = LG.Merge:FlagSeverity(p.flag, prevFlag)
	end
	if LG.NinjaListTab then LG.NinjaListTab:Refresh() end
end

function GuildSync:OnLogin()
	local g = LG.Storage:GetGlobal()
	if not self.addon or not g or not g.enableGuildSync then return end
	if not IsInGuild() then return end
	-- Debounce: OnEnable runs every /reload; avoid stacking broadcasts
	if self.loginScheduled then return end
	self.loginScheduled = true
	self.addon:ScheduleTimer(function()
		self.loginScheduled = nil
		local g = LG.Storage:GetGlobal()
		if g and g.enableGuildSync and IsInGuild() then
			self:BroadcastAll()
		end
	end, 5)
end
