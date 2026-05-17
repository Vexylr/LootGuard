local LG = LootGuard

local SettingsTab = {}
LG.SettingsTab = SettingsTab

function SettingsTab:Init(addon, frame)
	self.addon = addon
	self.panel = frame.Content.Settings
	self:Build()
end

function SettingsTab:CreateCheckbox(parent, label, key, y)
	local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	cb:SetPoint("TOPLEFT", 16, y)
	cb.label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	cb.label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
	cb.label:SetText(label)
	cb:SetScript("OnClick", function(self)
		if not LG.Storage.db then return end
		LG.Storage:EnsureStructures()
		LG.Storage.db.global[self.key] = self:GetChecked() and true or false
	end)
	cb.key = key
	return cb
end

function SettingsTab:Build()
	if self.built then
		self:LoadValues()
		return
	end
	self.built = true
	local p = self.panel
	local title = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 12, -8)
	title:SetText("Settings")
	LG.Theme:ApplyHeader(title)

	local y = -40
	local checks = {
		{ "enableGuildSync", "Enable guild reputation sync" },
		{ "enableMeetSync", "Enable meet / whisper sync" },
		{ "enablePartySync", "Enable party roll broadcast" },
		{ "showTooltip", "Show reputation on unit tooltips" },
	}
	self.checks = {}
	for _, c in ipairs(checks) do
		local cb = self:CreateCheckbox(p, c[2], c[1], y)
		self.checks[c[1]] = cb
		y = y - 28
	end

	local cbMini = self:CreateCheckbox(p, "Hide minimap button", "minimapHide", y)
	cbMini:SetScript("OnClick", function(self)
		LG.Storage:EnsureStructures()
		LG.Storage.db.global.minimap.hide = self:GetChecked() and true or false
		LG.Minimap:Refresh()
	end)
	self.checkMini = cbMini

	local openBtn = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
	openBtn:SetSize(160, 24)
	openBtn:SetPoint("TOPLEFT", 16, y - 40)
	openBtn:SetText("Advanced thresholds")
	openBtn:SetScript("OnClick", function()
		LibStub("AceConfigDialog-3.0"):Open("LootGuard")
	end)

	local clearBtn = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
	clearBtn:SetSize(160, 24)
	clearBtn:SetPoint("TOPLEFT", openBtn, "BOTTOMLEFT", 0, -8)
	clearBtn:SetText("Clear session log")
	clearBtn:SetScript("OnClick", function()
		if not LG.Storage.db then return end
		wipe(LG.Storage:GetSessionRolls())
		if LG.SessionTab then LG.SessionTab:Refresh() end
		print("|cffc9a227LootGuard:|r Session log cleared.")
	end)

	self:LoadValues()
end

function SettingsTab:LoadValues()
	if not LG.Storage.db then return end
	LG.Storage:EnsureStructures()
	local g = LG.Storage.db.global
	for key, cb in pairs(self.checks) do
		cb:SetChecked(g[key] ~= false)
	end
	if self.checkMini then
		self.checkMini:SetChecked(g.minimap and g.minimap.hide)
	end
end

function SettingsTab:RegisterAceConfig()
	if self.configRegistered then return end
	self.configRegistered = true
	local defaults = LG.Storage:GetDefaults().global
	local function global()
		return LG.Storage.db and LG.Storage.db.global
	end
	local options = {
		type = "group",
		name = "LootGuard",
		args = {
			scale = {
				type = "range", name = "Reputation scale", min = 1, max = 20, step = 1,
				get = function() local g = global(); return g and g.scale or defaults.scale end,
				set = function(_, v)
					local g = global(); if not g then return end
					g.scale = v
					LG.Engine:RefreshAllFlags()
				end,
			},
			watchRep = {
				type = "range", name = "Watch below rep", min = 1, max = 10, step = 0.5,
				get = function() local g = global(); return g and g.watchRep or defaults.watchRep end,
				set = function(_, v)
					local g = global(); if not g then return end
					g.watchRep = v
					LG.Engine:RefreshAllFlags()
				end,
			},
			suspectedRep = {
				type = "range", name = "Suspected below rep", min = 1, max = 10, step = 0.5,
				get = function() local g = global(); return g and g.suspectedRep or defaults.suspectedRep end,
				set = function(_, v)
					local g = global(); if not g then return end
					g.suspectedRep = v
					LG.Engine:RefreshAllFlags()
				end,
			},
			ninjaRep = {
				type = "range", name = "Ninja below rep", min = 1, max = 10, step = 0.5,
				get = function() local g = global(); return g and g.ninjaRep or defaults.ninjaRep end,
				set = function(_, v)
					local g = global(); if not g then return end
					g.ninjaRep = v
					LG.Engine:RefreshAllFlags()
				end,
			},
			ninjaListMinFlag = {
				type = "select",
				name = "Ninja list shows",
				values = {
					[1] = "Watch and above",
					[2] = "Suspected and above",
					[3] = "Ninja only",
				},
				get = function()
					local g = global()
					return (g and g.ninjaListMinFlag) or defaults.ninjaListMinFlag or LG.FLAG_SUSPECTED
				end,
				set = function(_, v)
					local g = global(); if not g then return end
					g.ninjaListMinFlag = v
					if LG.NinjaListTab then LG.NinjaListTab:Refresh() end
				end,
			},
			watchViolations = {
				type = "range", name = "Watch: violations (24h)", min = 1, max = 10, step = 1,
				get = function() local g = global(); return g and g.watchViolations or defaults.watchViolations end,
				set = function(_, v)
					local g = global(); if not g then return end
					g.watchViolations = v
					LG.Engine:RefreshAllFlags()
				end,
			},
			suspectedViolations24h = {
				type = "range", name = "Suspected: violations (24h)", min = 1, max = 10, step = 1,
				get = function() local g = global(); return g and g.suspectedViolations24h or defaults.suspectedViolations24h end,
				set = function(_, v)
					local g = global(); if not g then return end
					g.suspectedViolations24h = v
					LG.Engine:RefreshAllFlags()
				end,
			},
			ninjaViolationsInstance = {
				type = "range", name = "Ninja: wrong armor (one run)", min = 1, max = 10, step = 1,
				get = function() local g = global(); return g and g.ninjaViolationsInstance or defaults.ninjaViolationsInstance end,
				set = function(_, v)
					local g = global(); if not g then return end
					g.ninjaViolationsInstance = v
					LG.Engine:RefreshAllFlags()
				end,
			},
		},
	}
	LibStub("AceConfig-3.0"):RegisterOptionsTable("LootGuard", options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("LootGuard", "LootGuard")
end
