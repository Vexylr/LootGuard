local LG = LootGuard

local Storage = {}
LG.Storage = Storage

local defaults = {
	global = {
		minimap = { hide = false, angle = 220 },
		windowPos = nil,
		enableGuildSync = true,
		enableMeetSync = true,
		enablePartySync = true,
		showTooltip = true,
		scale = 10,
		watchRep = 7,
		suspectedRep = 5,
		ninjaRep = 3,
		watchViolations = 1,
		suspectedViolations24h = 2,
		ninjaViolationsInstance = 3,
		ninjaListMinFlag = 2,
	},
	char = {
		sessionRolls = {},
	},
	realm = {
		players = {},
	},
}

function Storage:Init(db)
	self.db = db
	self:EnsureStructures()
end

function Storage:EnsureStructures()
	if not self.db then return end
	if not self.db.realm then
		self.db.realm = { players = {} }
	end
	if not self.db.realm.players then
		self.db.realm.players = {}
	end
	if not self.db.char then
		self.db.char = { sessionRolls = {} }
	end
	local g = self.db.global
	if not g then
		self.db.global = CopyTable(defaults.global)
		g = self.db.global
	end
	if not g.minimap then
		g.minimap = { hide = false, angle = 220 }
	end
	if g.minimap.hide == nil then
		g.minimap.hide = false
	end
	if g.minimap.angle == nil then
		g.minimap.angle = 220
	end
	for k, v in pairs(defaults.global) do
		if k ~= "minimap" and g[k] == nil then
			g[k] = v
		end
	end
	if not g.playerKeysMigrated then
		self:MigratePlayerKeys()
		g.playerKeysMigrated = true
	end
end

-- Fix older sync rows keyed as "Name-" when realm was omitted
function Storage:MigratePlayerKeys()
	local players = self.db.realm.players
	local rekey = {}
	for key, p in pairs(players) do
		if key:sub(-1) == "-" and p.name then
			rekey[#rekey + 1] = { oldKey = key, player = p }
		end
	end
	for _, entry in ipairs(rekey) do
		local key, p = entry.oldKey, entry.player
		local realm = (p.realm and p.realm ~= "") and p.realm or GetRealmName()
		local newKey = self:GetPlayerKey(p.name, realm)
		if not newKey or newKey == key then
			players[key] = nil
		elseif players[newKey] then
			if LG.Merge and LG.Engine then
				local snapRep = p.reputation
				local snapFlag = p.flag
				LG.Merge:MergePlayer(players[newKey], p)
				LG.Engine:RecalculateReputation(players[newKey])
				if snapRep then
					players[newKey].reputation = math.min(players[newKey].reputation, snapRep)
				end
				LG.Engine:UpdateFlag(players[newKey], nil)
				if snapFlag then
					players[newKey].flag = LG.Merge:FlagSeverity(players[newKey].flag, snapFlag)
				end
			end
			players[key] = nil
		else
			p.realm = realm
			players[newKey] = p
			players[key] = nil
		end
	end
end

function Storage:GetDefaults()
	return defaults
end

function Storage:GetGlobal()
	if not self.db then return nil end
	self:EnsureStructures()
	return self.db.global
end

function Storage:SplitNameRealm(fullName, defaultRealm)
	if not fullName or fullName == "" then return nil, nil end
	local sep = fullName:find("-", 1, true)
	if sep then
		return fullName:sub(1, sep - 1), fullName:sub(sep + 1)
	end
	return fullName, defaultRealm or GetRealmName()
end

function Storage:GetPlayerKey(name, realm)
	if not name or name == "" then return nil end
	if not realm and name:find("-", 1, true) then
		name, realm = self:SplitNameRealm(name)
	end
	realm = realm or GetRealmName()
	return name .. "-" .. realm
end

function Storage:ParseKey(key)
	if not key then return nil, nil end
	return self:SplitNameRealm(key, GetRealmName())
end

function Storage:IsLocalSender(sender)
	if not sender then return false end
	local name, realm = self:SplitNameRealm(sender)
	local playerName, playerRealm = UnitName("player"), GetRealmName()
	if name == playerName and (not realm or realm == playerRealm or realm == "") then
		return true
	end
	return sender == playerName or sender == (playerName .. "-" .. playerRealm)
end

function Storage:GetPlayer(key)
	if not key or not self.db then return nil end
	self:EnsureStructures()
	local players = self.db.realm.players
	if not players[key] then
		local pname, prealm = self:ParseKey(key)
		players[key] = {
			name = pname or key,
			realm = prealm or GetRealmName(),
			reputation = 10,
			totalNeeds = 0,
			suspiciousNeeds = 0,
			flag = LG.FLAG_NONE,
			incidents = {},
			lastSeen = 0,
			class = nil,
			source = "local",
		}
	end
	return players[key]
end

function Storage:GetSessionRolls()
	if not self.db then return {} end
	self:EnsureStructures()
	if not self.db.char.sessionRolls then
		self.db.char.sessionRolls = {}
	end
	return self.db.char.sessionRolls
end

function Storage:AddSessionRoll(record)
	local rolls = self:GetSessionRolls()
	rolls[#rolls + 1] = record
	while #rolls > 200 do
		table.remove(rolls, 1)
	end
end

function Storage:GetFlaggedPlayers(minFlag)
	if not self.db then return {} end
	self:EnsureStructures()
	minFlag = minFlag or LG.FLAG_SUSPECTED
	local list = {}
	for key, p in pairs(self.db.realm.players) do
		if (p.flag or 0) >= minFlag then
			list[#list + 1] = p
			p.key = key
		end
	end
	table.sort(list, function(a, b)
		return (a.flag or 0) > (b.flag or 0) or (a.reputation or 10) < (b.reputation or 10)
	end)
	return list
end

function Storage:SerializePlayer(p)
	return string.format(
		"%s|%s|%.2f|%d|%d|%d|%s",
		p.name or "",
		p.realm or "",
		p.reputation or 10,
		p.flag or 0,
		p.totalNeeds or 0,
		p.suspiciousNeeds or 0,
		p.class or ""
	)
end

function Storage:DeserializePlayer(str)
	local name, realm, rep, flag, total, susp, class = str:match("^([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|(.*)$")
	if not name or name == "" then return nil end
	realm = (realm ~= "" and realm) or GetRealmName()
	local key = self:GetPlayerKey(name, realm)
	return key, {
		name = name,
		realm = realm,
		reputation = tonumber(rep) or 10,
		flag = tonumber(flag) or 0,
		totalNeeds = tonumber(total) or 0,
		suspiciousNeeds = tonumber(susp) or 0,
		class = (class ~= "" and class) or nil,
		incidents = {},
		lastSeen = time(),
		source = "sync",
	}
end
