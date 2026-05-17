local LG = LootGuard

-- WoW's minimap frame; do not shadow this name in this file.
local WOW_MINIMAP = _G.Minimap

local MinimapModule = {}
LG.Minimap = MinimapModule

function MinimapModule:EnsureDB()
	if LG.Storage.EnsureStructures then
		LG.Storage:EnsureStructures()
	end
end

function MinimapModule:Init(addon)
	self.addon = addon
	self:EnsureDB()
	self:CreateButton()
end

function MinimapModule:CreateButton()
	local btn = CreateFrame("Button", "LootGuardMinimapButton", WOW_MINIMAP)
	btn:SetSize(32, 32)
	btn:SetFrameStrata("MEDIUM")
	btn:SetMovable(true)
	btn:RegisterForDrag("LeftButton")
	btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	local icon = btn:CreateTexture(nil, "BACKGROUND")
	icon:SetSize(20, 20)
	icon:SetPoint("CENTER")
	icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10_Green")
	btn.icon = icon

	btn:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", MinimapModule.OnDragUpdate)
	end)
	btn:SetScript("OnDragStop", function(self)
		self:SetScript("OnUpdate", nil)
		local g = LG.Storage:GetGlobal()
		if g and g.minimap then
			g.minimap.angle = MinimapModule:GetAngle()
		end
	end)

	btn:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
			LG.MainFrame:EnsureBuilt()
			LG.MainFrame:ShowTab("settings")
			LG.MainFrame:Toggle(true)
		else
			LG.MainFrame:EnsureBuilt()
			LG.MainFrame:Toggle()
		end
	end)

	btn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText("LootGuard", 1, 1, 1)
		GameTooltip:AddLine("Left-click: toggle window", 0.8, 0.8, 0.8)
		GameTooltip:AddLine("Right-click: settings", 0.8, 0.8, 0.8)
		GameTooltip:Show()
	end)
	btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

	self.button = btn
	self:UpdatePosition()
end

function MinimapModule:GetAngle()
	self:EnsureDB()
	local g = LG.Storage:GetGlobal()
	if not g or not g.minimap then return 220 end
	return g.minimap.angle or 220
end

function MinimapModule:UpdatePosition()
	local angle = math.rad(self:GetAngle())
	local r = 80
	local x = math.cos(angle) * r
	local y = math.sin(angle) * r
	self.button:SetPoint("CENTER", WOW_MINIMAP, "CENTER", x, y)
end

function MinimapModule.OnDragUpdate(self)
	MinimapModule:EnsureDB()
	local mx, my = WOW_MINIMAP:GetCenter()
	local px, py = GetCursorPosition()
	local scale = WOW_MINIMAP:GetEffectiveScale()
	px, py = px / scale, py / scale
	local angle = math.deg(math.atan2(py - my, px - mx))
	local g = LG.Storage:GetGlobal()
	if g and g.minimap then
		g.minimap.angle = angle
	end
	MinimapModule:UpdatePosition()
end

function MinimapModule:Refresh()
	if not self.button then return end
	local g = LG.Storage:GetGlobal()
	local hide = g and g.minimap and g.minimap.hide
	if hide then
		self.button:Hide()
	else
		self.button:Show()
		self:UpdatePosition()
	end
end
