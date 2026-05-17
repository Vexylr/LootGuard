local LG = LootGuard

local Merge = {}
LG.Merge = Merge

function Merge:FlagSeverity(a, b)
	return math.max(a or 0, b or 0)
end

function Merge:MergePlayer(localPlayer, remotePlayer)
	if not remotePlayer then return localPlayer end
	if not localPlayer then return remotePlayer end

	local newer = (remotePlayer.lastSeen or 0) > (localPlayer.lastSeen or 0)
	if newer then
		localPlayer.reputation = remotePlayer.reputation
		localPlayer.totalNeeds = math.max(localPlayer.totalNeeds or 0, remotePlayer.totalNeeds or 0)
		localPlayer.suspiciousNeeds = math.max(localPlayer.suspiciousNeeds or 0, remotePlayer.suspiciousNeeds or 0)
	end

	localPlayer.flag = self:FlagSeverity(localPlayer.flag, remotePlayer.flag)
	localPlayer.class = localPlayer.class or remotePlayer.class
	localPlayer.lastSeen = math.max(localPlayer.lastSeen or 0, remotePlayer.lastSeen or 0)
	if remotePlayer.source == "sync" then
		localPlayer.source = "sync"
	end

	-- merge incidents (dedupe)
	local seen = {}
	for _, inc in ipairs(localPlayer.incidents or {}) do
		seen[(inc.rollID or "") .. ":" .. (inc.timestamp or 0)] = true
	end
	for _, inc in ipairs(remotePlayer.incidents or {}) do
		local k = (inc.rollID or "") .. ":" .. (inc.timestamp or 0)
		if not seen[k] then
			LG.Incidents:AddToPlayer(localPlayer, inc)
			seen[k] = true
		end
	end

	return localPlayer
end

function Merge:MergeRecord(key, remote)
	if not key or not remote or not LG.Storage.db then return end
	local players = LG.Storage.db.realm.players
	local localP = players[key]
	if localP then
		local remoteFlag = remote.flag
		self:MergePlayer(localP, remote)
		LG.Engine:RecalculateReputation(localP)
		-- Remote snapshot has no incidents; keep the worse (lower) public rep score
		if remote.reputation then
			localP.reputation = math.min(localP.reputation, remote.reputation)
		end
		LG.Engine:UpdateFlag(localP, "")
		localP.flag = self:FlagSeverity(localP.flag, remoteFlag)
	else
		local syncedRep = remote.reputation or 10
		local remoteFlag = remote.flag
		players[key] = remote
		LG.Engine:RecalculateReputation(remote)
		remote.reputation = math.min(remote.reputation, syncedRep)
		LG.Engine:UpdateFlag(remote, "")
		remote.flag = self:FlagSeverity(remote.flag, remoteFlag)
	end
end
