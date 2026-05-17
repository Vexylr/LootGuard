local LG = LootGuard

local Comm = {}
LG.Comm = Comm

function Comm:Init(addon)
	self.addon = addon
	self.prefix = LG.ADDON_PREFIX
	if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
		local result = C_ChatInfo.RegisterAddonMessagePrefix(self.prefix)
		-- 0 = Success, 1 = DuplicatePrefix (reload), 2 = InvalidPrefix
		if result == 2 then
			print("|cffc9a227LootGuard:|r Could not register comm prefix (invalid). Sync disabled.")
		end
	else
		print("|cffc9a227LootGuard:|r C_ChatInfo unavailable. Sync disabled.")
	end
	addon:RegisterComm(self.prefix, "OnComm")
end

function Comm:Pack(op, payload)
	return op .. ":" .. (payload or "")
end

function Comm:Unpack(msg)
	local op, rest = msg:match("^(.):(.*)$")
	return op, rest
end

function Comm:Send(op, payload, channel, target)
	if not LG.Storage:GetGlobal() then return end
	local msg = self:Pack(op, payload)
	if channel == "WHISPER" and target then
		self.addon:SendCommMessage(self.prefix, msg, "WHISPER", target)
	elseif channel == "GUILD" and IsInGuild() then
		self.addon:SendCommMessage(self.prefix, msg, "GUILD")
	elseif channel == "RAID" and IsInRaid() then
		self.addon:SendCommMessage(self.prefix, msg, "RAID")
	elseif channel == "PARTY" and IsInGroup() and not IsInRaid() then
		self.addon:SendCommMessage(self.prefix, msg, "PARTY")
	end
end

function Comm:OnComm(prefix, msg, distribution, sender)
	if prefix ~= self.prefix or not msg or not sender then return end
	if LG.Storage:IsLocalSender(sender) then return end

	local op, payload = self:Unpack(msg)
	if not op then return end

	if op == LG.OP_REPUTATION and LG.GuildSync then
		LG.GuildSync:OnReputation(payload, sender)
	elseif op == LG.OP_INCIDENT and LG.GuildSync then
		LG.GuildSync:OnIncident(payload, sender)
	elseif op == LG.OP_HANDSHAKE and LG.MeetSync then
		LG.MeetSync:OnHandshake(payload, sender)
	elseif op == LG.OP_DELTA and LG.MeetSync then
		LG.MeetSync:OnDelta(payload, sender)
	elseif op == LG.OP_SESSION_ROLL then
		self:OnSessionRoll(payload, sender)
	end
end

function Comm:OnSessionRoll(payload, sender)
	local g = LG.Storage:GetGlobal()
	if not g or not g.enablePartySync then return end
	-- Party roll broadcast is informational; full scoring requires local C_LootHistory
	local rollID, itemName, rollData = payload:match("^(%d+)|([^|]+)|(.*)$")
	if not rollID then return end
	-- Could extend: parse rollData and surface in session log as "[sync] ..."
end

function Comm:SendSessionRoll(record)
	local parts = {}
	for _, pr in ipairs(record.rolls or {}) do
		if pr.rollType == LG.ROLL_NEED then
			parts[#parts + 1] = string.format("%s,%s,%s,%d", pr.name, pr.realm or "", pr.class or "", pr.rollType)
		end
	end
	if #parts == 0 then return end
	local ch = IsInRaid() and "RAID" or "PARTY"
	local payload = string.format("%d|%s|%s", record.rollID or 0, record.itemName or "", table.concat(parts, ";"))
	self:Send(LG.OP_SESSION_ROLL, payload, ch)
end
