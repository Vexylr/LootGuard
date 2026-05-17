local LG = LootGuard

local Engine = {}
LG.Engine = Engine

function Engine:Init(addon)
	self.addon = addon
end

function Engine:ResolveRollClass(playerRoll)
	local pk = LG.Storage:GetPlayerKey(playerRoll.name, playerRoll.realm)
	local myKey = LG.Storage:GetPlayerKey(UnitName("player"), GetRealmName())
	if pk and pk == myKey then
		return LG.ClassRules:GetPlayerClassToken("player")
	end
	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			local unit = "raid" .. i
			if UnitExists(unit) then
				local n, r = UnitName(unit)
				if LG.Storage:GetPlayerKey(n, r) == pk then
					return LG.ClassRules:GetPlayerClassToken(unit)
				end
			end
		end
	elseif IsInGroup() then
		for i = 1, 4 do
			local unit = "party" .. i
			if UnitExists(unit) then
				local n, r = UnitName(unit)
				if LG.Storage:GetPlayerKey(n, r) == pk then
					return LG.ClassRules:GetPlayerClassToken(unit)
				end
			end
		end
	end
	return LG.ClassRules:NormalizeClass(playerRoll.class)
end

function Engine:RefreshAllFlags()
	if not LG.Storage.db or not LG.Storage.db.realm then return end
	for _, player in pairs(LG.Storage.db.realm.players) do
		self:RecalculateReputation(player)
		self:UpdateFlag(player, nil)
	end
	if LG.NinjaListTab then LG.NinjaListTab:Refresh() end
end

function Engine:EvaluateNeed(playerKey, playerRoll, rollRecord)
	local classToken = self:ResolveRollClass(playerRoll)
	local violations = {}
	local info = rollRecord

	if LG.ItemInspector:IsArmor(info) and LG.ItemInspector:IsEquippable(info) then
		if not LG.ClassRules:CanNeedArmor(classToken, info.armorType) then
			violations[#violations + 1] = LG.VIOL_WRONG_ARMOR
		end
	elseif LG.ItemInspector:IsWeapon(info) then
		if not LG.ClassRules:CanNeedWeapon(classToken, info.itemSubClass, info.itemSubClassID) then
			violations[#violations + 1] = LG.VIOL_WRONG_WEAPON
		end
	end

	-- need spam: 4+ needs in session instance with majority suspicious
	local sessionNeeds = self:CountSessionNeeds(playerKey, rollRecord.instance)
	if sessionNeeds >= 4 and #violations > 0 then
		violations[#violations + 1] = LG.VIOL_NEED_SPAM
	end

	return violations
end

function Engine:CountSessionNeeds(playerKey, instance)
	local count = 0
	for _, r in ipairs(LG.Storage:GetSessionRolls()) do
		if r.instance == instance then
			for _, pr in ipairs(r.rolls or {}) do
				local pk = LG.Storage:GetPlayerKey(pr.name, pr.realm)
				if pk == playerKey and pr.rollType == LG.ROLL_NEED then
					count = count + 1
				end
			end
		end
	end
	return count
end

function Engine:ProcessRoll(rollRecord)
	local anyViolation = false

	for _, pr in ipairs(rollRecord.rolls or {}) do
		if pr.rollType == LG.ROLL_NEED then
			local key = LG.Storage:GetPlayerKey(pr.name, pr.realm)
			if key then
				local player = LG.Storage:GetPlayer(key)
				player.class = player.class or self:ResolveRollClass(pr)
				player.lastSeen = time()
				player.totalNeeds = (player.totalNeeds or 0) + 1

				local violations = self:EvaluateNeed(key, pr, rollRecord)
				pr.violations = violations
				pr.verdict = (#violations == 0) and "ok" or "bad"

				if #violations > 0 then
					anyViolation = true
					player.suspiciousNeeds = (player.suspiciousNeeds or 0) + 1
					for _, vType in ipairs(violations) do
						local inc = LG.Incidents:Create(vType, key, rollRecord, pr)
						LG.Incidents:AddToPlayer(player, inc)
						pr.incidentType = vType
					end
				end

				self:RecalculateReputation(player)
				self:UpdateFlag(player, rollRecord.instance)

				if LG.GuildSync then
					LG.GuildSync:QueuePlayer(key)
				end
			end
		end
	end

	return anyViolation
end

function Engine:RecalculateReputation(player)
	if not player then return end
	local g = LG.Storage:GetGlobal()
	if not g then return end
	local scale = g.scale or 10
	local weights = LG.VIOLATION_WEIGHTS
	local weighted = 0
	for _, inc in ipairs(player.incidents or {}) do
		weighted = weighted + (weights[inc.type] or 1)
	end
	local denom = math.max(1, player.totalNeeds or 1)
	local rep = 10 - (weighted / denom) * (scale / 2)
	player.reputation = math.max(1, math.min(10, rep))
end

function Engine:UpdateFlag(player, instanceName)
	if not player then return end
	local g = LG.Storage:GetGlobal()
	if not g then return end
	local rep = player.reputation or 10
	local recent = LG.Incidents:CountRecent(player, 86400)
	local instViol
	if instanceName and instanceName ~= "" then
		instViol = LG.Incidents:CountInInstance(player, instanceName)
	else
		instViol = LG.Incidents:CountWorstInstance(player)
	end

	local flag = LG.FLAG_NONE
	if rep < (g.ninjaRep or 3) or instViol >= (g.ninjaViolationsInstance or 3) then
		flag = LG.FLAG_NINJA
	elseif rep < (g.suspectedRep or 5) or recent >= (g.suspectedViolations24h or 2) then
		flag = LG.FLAG_SUSPECTED
	elseif rep < (g.watchRep or 7) or recent >= (g.watchViolations or 1) then
		flag = LG.FLAG_WATCH
	end
	player.flag = flag
end

function Engine:GetReputationColor(rep)
	if rep >= 8 then return 0.2, 0.9, 0.3 end
	if rep >= 5 then return 0.95, 0.85, 0.2 end
	return 0.95, 0.25, 0.2
end
