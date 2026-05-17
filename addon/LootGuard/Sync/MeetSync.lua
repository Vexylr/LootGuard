local LG = LootGuard

local MeetSync = {}
LG.MeetSync = MeetSync

function MeetSync:Init(addon)
	self.addon = addon
	self.handshaking = {}
	self.cooldowns = {}
end

function MeetSync:PruneCooldowns(now)
	local n = 0
	for key, t in pairs(self.cooldowns) do
		if (now - t) > 600 then
			self.cooldowns[key] = nil
		else
			n = n + 1
		end
	end
	if n > 300 then
		self.cooldowns = {}
	end
end

function MeetSync:GetDBHash()
	if not LG.Storage.db or not LG.Storage.db.realm then return "0:0" end
	local n = 0
	for _ in pairs(LG.Storage.db.realm.players) do n = n + 1 end
	return string.format("%d:%d", n, LG.ADDON_VERSION)
end

function MeetSync:OnPlayerSeen(unit)
	local g = LG.Storage:GetGlobal()
	if not g or not g.enableMeetSync then return end
	if not unit or not UnitIsPlayer(unit) then return end
	if UnitIsUnit(unit, "player") then return end
	if UnitIsEnemy("player", unit) then return end
	local name, realm = UnitName(unit)
	if not name then return end
	realm = realm or GetRealmName()
	local key = LG.Storage:GetPlayerKey(name, realm)
	local now = GetTime()
	local cd = self.cooldowns[key]
	if cd and (now - cd) < 120 then return end
	self.cooldowns[key] = now
	self:PruneCooldowns(now)
	local whisperTarget = GetUnitName(unit, true) or name
	self:SendHandshake(whisperTarget)
end

function MeetSync:SendHandshake(target)
	local payload = string.format("%d|%s", LG.ADDON_VERSION, self:GetDBHash())
	LG.Comm:Send(LG.OP_HANDSHAKE, payload, "WHISPER", target)
end

function MeetSync:PruneHandshakes(now)
	now = now or GetTime()
	for name, t in pairs(self.handshaking) do
		if (now - t) > 300 then
			self.handshaking[name] = nil
		end
	end
end

function MeetSync:OnHandshake(payload, sender)
	local g = LG.Storage:GetGlobal()
	if not g or not g.enableMeetSync then return end
	local ver, hash = payload:match("^(%d+)|(.+)$")
	if tonumber(ver) ~= LG.ADDON_VERSION then return end
	local now = GetTime()
	self:PruneHandshakes(now)
	if self.handshaking[sender] and (now - self.handshaking[sender]) < 90 then return end
	self.handshaking[sender] = now
	local reply = string.format("%d|%s", LG.ADDON_VERSION, self:GetDBHash())
	LG.Comm:Send(LG.OP_HANDSHAKE, reply, "WHISPER", sender)
	self:SendDelta(sender)
end

function MeetSync:SendDelta(target)
	if not LG.Storage.db or not LG.Storage.db.realm then return end
	local chunks = {}
	for key, p in pairs(LG.Storage.db.realm.players) do
		if (p.flag or 0) >= LG.FLAG_WATCH then
			chunks[#chunks + 1] = LG.Storage:SerializePlayer(p)
		end
	end
	if #chunks == 0 then return end
	local payload = table.concat(chunks, "\n")
	LG.Comm:Send(LG.OP_DELTA, payload, "WHISPER", target)
end

function MeetSync:OnDelta(payload, sender)
	local g = LG.Storage:GetGlobal()
	if not g or not g.enableMeetSync then return end
	for line in payload:gmatch("[^\n]+") do
		local key, remote = LG.Storage:DeserializePlayer(line)
		if key then
			LG.Merge:MergeRecord(key, remote)
		end
	end
	if LG.NinjaListTab then LG.NinjaListTab:Refresh() end
end
