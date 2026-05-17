local LG = LootGuard

local Incidents = {}
LG.Incidents = Incidents

function Incidents:Create(violationType, playerKey, rollRecord, playerRoll)
	return {
		type = violationType,
		playerKey = playerKey,
		playerName = playerRoll.name,
		class = playerRoll.class,
		itemName = rollRecord.itemName,
		itemLink = rollRecord.itemLink,
		instance = rollRecord.instance,
		timestamp = rollRecord.timestamp or time(),
		rollID = rollRecord.rollID,
		armorType = rollRecord.armorType,
	}
end

function Incidents:AddToPlayer(player, incident, maxCount)
	if not player or not incident then return end
	maxCount = maxCount or 50
	player.incidents = player.incidents or {}
	for _, inc in ipairs(player.incidents) do
		if inc.type == incident.type
			and inc.itemName == incident.itemName
			and (inc.timestamp or 0) == (incident.timestamp or 0)
			and (inc.rollID or 0) == (incident.rollID or 0)
		then
			return
		end
	end
	table.insert(player.incidents, 1, incident)
	while #player.incidents > maxCount do
		table.remove(player.incidents)
	end
end

function Incidents:CountRecent(player, withinSeconds)
	withinSeconds = withinSeconds or 86400
	local now = time()
	local count = 0
	for _, inc in ipairs(player.incidents or {}) do
		if (now - (inc.timestamp or 0)) <= withinSeconds then
			count = count + 1
		end
	end
	return count
end

local function isGearViolation(incType)
	return incType == LG.VIOL_WRONG_ARMOR or incType == LG.VIOL_WRONG_WEAPON
end

function Incidents:CountInInstance(player, instanceName)
	local count = 0
	for _, inc in ipairs(player.incidents or {}) do
		if inc.instance == instanceName and isGearViolation(inc.type) then
			count = count + 1
		end
	end
	return count
end

-- Highest gear-violation count in any one instance (used when no instance context)
function Incidents:CountWorstInstance(player)
	local perInstance = {}
	for _, inc in ipairs(player.incidents or {}) do
		if isGearViolation(inc.type) and inc.instance then
			perInstance[inc.instance] = (perInstance[inc.instance] or 0) + 1
		end
	end
	local worst = 0
	for _, count in pairs(perInstance) do
		if count > worst then worst = count end
	end
	return worst
end
