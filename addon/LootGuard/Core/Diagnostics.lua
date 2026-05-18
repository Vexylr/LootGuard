local LG = LootGuard

local Diagnostics = {}
LG.Diagnostics = Diagnostics

function Diagnostics:HasLootHistory()
	return C_LootHistory and C_LootHistory.GetNumItems and C_LootHistory.GetItem
end

function Diagnostics:PrintStatus()
	local f = LG.MainFrame and LG.MainFrame.frame
	local g = LG.Storage and LG.Storage.GetGlobal and LG.Storage:GetGlobal()
	local hist = self:HasLootHistory()
	local n = 0
	if hist then
		local ok, count = pcall(function() return C_LootHistory.GetNumItems() end)
		if ok and count then n = count end
	end
	local v, b, d, i = GetBuildInfo()
	print("|cffc9a227LootGuard debug|r")
	print("  UI frame:", f and "OK" or "MISSING (XML OnLoad failed?)")
	print("  Minimap btn:", LG.Minimap and LG.Minimap.button and "OK" or "missing")
	print("  DB:", g and "OK" or "missing")
	print("  C_LootHistory:", hist and ("yes (" .. tostring(n) .. " items)") or "NO — rolls need fallback events")
	print("  In group:", tostring(IsInGroup()), " In raid:", tostring(IsInRaid()))
	print("  Client:", tostring(v), "build", tostring(b), "interface", tostring(i))
	print("  TOC Interface: 40402 — enable 'Load out of date' if yours differs")
	print("  Commands: /lg  /lg session  /lg debug")
end

function Diagnostics:PrintLoaded()
	local hist = self:HasLootHistory()
	local mode = hist and "loot history API" or "legacy roll events only"
	print("|cffc9a227LootGuard|r loaded (" .. mode .. "). Type |cffffffff/lg|r or |cffffffff/lg debug|r.")
end
