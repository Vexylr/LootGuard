local LG = LootGuard

local MainFrame = {}
LG.MainFrame = MainFrame

function LootGuardMainFrame_OnLoad(frame)
	if not LootGuard or not LootGuard.Theme or not LootGuard.MainFrame then return end
	LG.MainFrame.frame = frame
	LG.Theme:ApplyBackdrop(frame, 10)
	if frame.Title then
		LG.Theme:ApplyHeader(frame.Title)
	end
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		LG.MainFrame:SavePosition()
	end)
	if frame.Close then
		frame.Close:SetScript("OnClick", function() LG.MainFrame:Toggle(false) end)
	end
end

function LootGuardMainFrame_OnHide(frame)
	if LootGuard and LootGuard.MainFrame then
		LG.MainFrame:SavePosition()
	end
end

function MainFrame:SavePosition()
	local f = self.frame
	local g = LG.Storage:GetGlobal()
	if not f or not g then return end
	local point, _, relPoint, x, y = f:GetPoint()
	if not point then return end
	g.windowPos = { point, relPoint, x, y }
end

function MainFrame:RestorePosition()
	local g = LG.Storage:GetGlobal()
	local pos = g and g.windowPos
	local f = self.frame
	if not f or not pos then return end
	f:ClearAllPoints()
	f:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
end

function MainFrame:EnsureBuilt()
	if self.built or not self.frame then return end
	self.built = true
	self:BuildTabs()
	self:RestorePosition()
end

function MainFrame:BuildTabs()
	local f = self.frame
	local bar = f.TabBar
	local content = f.Content

	if content and not content.lgPanelStyled then
		LG.Theme:ApplyPanelBackdrop(content)
		content.lgPanelStyled = true
	end
	if content and content.Settings and not content.Settings.lgPanelStyled then
		LG.Theme:ApplyPanelBackdrop(content.Settings)
		content.Settings.lgPanelStyled = true
	end

	self.tabs = {}
	local defs = {
		{ id = "session", label = "Session", scroll = content.SessionScroll, panel = nil },
		{ id = "ninja", label = "Ninja List", scroll = content.NinjaScroll, panel = nil },
		{ id = "settings", label = "Settings", scroll = nil, panel = content.Settings },
	}
	local x = 0
	for _, d in ipairs(defs) do
		local btn = LG.Theme:CreateTabButton(bar, d.label, 130)
		btn:SetPoint("LEFT", bar, "LEFT", x, 0)
		x = x + 132
		btn.tabId = d.id
		btn.scroll = d.scroll
		btn.panel = d.panel
		btn:SetScript("OnClick", function(self) LG.MainFrame:ShowTab(self.tabId) end)
		self.tabs[d.id] = btn
	end
	LG.SessionTab:Init(LG.addon, f)
	LG.NinjaListTab:Init(LG.addon, f)
	LG.SettingsTab:Init(LG.addon, f)
	self:ShowTab("session")
end

function MainFrame:ShowTab(tabId)
	local f = self.frame
	for id, btn in pairs(self.tabs) do
		local active = (id == tabId)
		if btn.scroll then btn.scroll:SetShown(active) end
		if btn.panel then btn.panel:SetShown(active) end
		LG.Theme:SetTabActive(btn, active)
	end
	self.currentTab = tabId
	if tabId == "session" then
		LG.SessionTab:Refresh()
	elseif tabId == "ninja" then
		LG.NinjaListTab:Refresh()
	elseif tabId == "settings" then
		LG.SettingsTab:LoadValues()
	end
end

function MainFrame:Toggle(show)
	self:EnsureBuilt()
	local f = self.frame
	if not f then return end
	if show == nil then show = not f:IsShown() end

	if self._fadePending then
		self._fadePending = nil
	end

	if show then
		f:SetAlpha(1)
		f:Show()
		LG.Theme:FadeIn(f, 0.12)
		self:ShowTab(self.currentTab or "session")
	else
		LG.Theme:FadeOut(f, 0.12, function()
			if LG.MainFrame.frame then
				LG.MainFrame.frame:Hide()
			end
		end)
	end
end

function MainFrame:Init(addon)
	self.addon = addon
end

