-- Loads before libraries; registers /lg even if Ace3 fails later.
local addonName = ...
LootGuard = LootGuard or {}
local LG = LootGuard
LG.ADDON_NAME = addonName or "LootGuard"

if not C_Timer then
	C_Timer = {}
	function C_Timer.After(delay, callback)
		local frame = CreateFrame("Frame")
		local elapsed = 0
		frame:SetScript("OnUpdate", function(self, delta)
			elapsed = elapsed + delta
			if elapsed >= delay then
				self:SetScript("OnUpdate", nil)
				callback()
			end
		end)
	end
end

function LG.SlashHandler(msg)
	if LG.loadError then
		print("|cffff4444LootGuard load error:|r " .. tostring(LG.loadError))
		print("|cffffcc00Tip:|r Character screen → AddOns → enable LootGuard + |cffffffffLoad out of date AddOns|r")
		return
	end
	if LG.addon and LG.addon.OnChat then
		LG.addon:OnChat(msg or "")
		return
	end
	local v, b, d, i = GetBuildInfo()
	print("|cffffcc00LootGuard|r is not running. Addon disabled or failed during load?")
	print("  Client interface:", tostring(i), "  TOC expects: 40402")
	print("  /console scriptErrors 1  then  /reload  — check for red Lua errors.")
end

_G.SLASH_LOOTGUARD1 = "/lootguard"
_G.SLASH_LOOTGUARD2 = "/lg"
_G.SlashCmdList = _G.SlashCmdList or {}
_G.SlashCmdList["LOOTGUARD"] = function(msg)
	LG.SlashHandler(msg)
end
