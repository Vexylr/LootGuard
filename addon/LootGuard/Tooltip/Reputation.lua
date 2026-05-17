local LG = LootGuard

local Reputation = {}
LG.Reputation = Reputation

function Reputation:Init(addon)
	self.addon = addon
	GameTooltip:HookScript("OnTooltipSetUnit", function(tip)
		self:OnUnit(tip)
	end)
end

function Reputation:ResolveUnit(tip)
	if tip.GetUnit then
		local name, unit = tip:GetUnit()
		if unit and UnitExists(unit) then return unit, name end
	end
	if UnitExists("mouseover") and UnitIsPlayer("mouseover") then
		return "mouseover", UnitName("mouseover")
	end
	return nil, nil
end

function Reputation:OnUnit(tip)
	local g = LG.Storage:GetGlobal()
	if not g or not g.showTooltip then return end
	local unit, _ = self:ResolveUnit(tip)
	if not unit or not UnitIsPlayer(unit) then return end
	local name, realm = UnitName(unit)
	if not name then return end
	realm = realm or GetRealmName()
	local key = LG.Storage:GetPlayerKey(name, realm)
	local players = LG.Storage.db.realm.players
	local p = players[key]
	if not p then
		for _, pl in pairs(players) do
			if pl.name == name and (pl.realm == realm or pl.realm == nil or pl.realm == "") then
				p = pl
				break
			end
		end
	end
	if not p then return end

	if (p.flag or 0) >= LG.FLAG_NINJA then
		tip:AddLine("|cffff4444WARNING: Flagged ninja looter|r", 1, 0.25, 0.2)
	end

	local rep = p.reputation or 10
	local r, g, b = LG.Engine:GetReputationColor(rep)
	tip:AddLine(" ")
	tip:AddDoubleLine("Loot Reputation", string.format("%.1f / 10", rep), r, g, b, 1, 1, 1)
	local flagName = LG.FLAG_NAMES[p.flag or 0]
	if (p.flag or 0) > LG.FLAG_NONE then
		local fr, fg, fb = 1, 0.8, 0.2
		if p.flag >= LG.FLAG_NINJA then fr, fg, fb = 1, 0.2, 0.2 end
		tip:AddLine("Status: " .. flagName, fr, fg, fb)
	end
	if p.incidents and p.incidents[1] then
		local inc = p.incidents[1]
		tip:AddLine(string.format("(%s — %s)", inc.type or "?", inc.itemName or "?"), 0.7, 0.7, 0.7)
	end
end
