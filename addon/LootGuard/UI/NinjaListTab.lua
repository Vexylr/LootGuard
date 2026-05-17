local LG = LootGuard

local NinjaListTab = {}
LG.NinjaListTab = NinjaListTab

function NinjaListTab:Init(addon, frame)
	self.addon = addon
	self.frame = frame
	self.scroll = frame.Content.NinjaScroll
	self.child = self.scroll and self.scroll.GetScrollChild and self.scroll:GetScrollChild()
	self.rows = {}
	if self.child and not self.header then
		self.header = self.child:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		self.header:SetPoint("TOPLEFT", 8, -4)
		self.header:SetText("Name — Rep — Flag — Stats")
		self.header:SetTextColor(0.79, 0.64, 0.15)
	end
end

function NinjaListTab:GetEmptyRow()
	if self.emptyRow then return self.emptyRow end
	local row = CreateFrame("Frame", nil, self.child)
	row:SetSize(640, 60)
	row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.text:SetPoint("TOPLEFT", 8, -28)
	row.text:SetWidth(620)
	row.text:SetJustifyH("LEFT")
	self.emptyRow = row
	return row
end

function NinjaListTab:CreateDataRow(index)
	local row = self.rows[index]
	if row then return row end
	row = CreateFrame("Frame", nil, self.child)
	row:SetSize(640, 36)
	row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.nameText:SetPoint("LEFT", 8, 0)
	row.nameText:SetWidth(180)
	row.nameText:SetJustifyH("LEFT")
	row.repText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.repText:SetPoint("LEFT", 200, 0)
	row.repText:SetWidth(80)
	row.flagText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.flagText:SetPoint("LEFT", 290, 0)
	row.flagText:SetWidth(100)
	row.srcText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.srcText:SetPoint("LEFT", 400, 0)
	row.srcText:SetWidth(220)
	self.rows[index] = row
	return row
end

function NinjaListTab:Refresh()
	if not self.child then return end
	for _, row in ipairs(self.rows) do row:Hide() end
	if self.emptyRow then self.emptyRow:Hide() end

	local g = LG.Storage:GetGlobal()
	if not g then return end
	local minFlag = g.ninjaListMinFlag or LG.FLAG_SUSPECTED
	local list = LG.Storage:GetFlaggedPlayers(minFlag)
	local idx = 0
	for _, p in ipairs(list) do
		idx = idx + 1
		local row = self:CreateDataRow(idx)
		row:SetPoint("TOPLEFT", 0, -24 - ((idx - 1) * 38))
		row:Show()
		local displayName = p.name or "?"
		if p.realm and p.realm ~= "" then
			displayName = displayName .. "-" .. p.realm
		end
		row.nameText:SetText(displayName)
		local r, g, b = LG.Engine:GetReputationColor(p.reputation or 10)
		row.repText:SetText(string.format("%.1f / 10", p.reputation or 10))
		row.repText:SetTextColor(r, g, b)
		local flagName = LG.FLAG_NAMES[p.flag or 0] or "?"
		local fc = (p.flag or 0) >= LG.FLAG_NINJA and "|cffff4444" or "|cffffaa00"
		row.flagText:SetText(fc .. flagName .. "|r")
		row.srcText:SetText("src: " .. (p.source or "local") .. "  needs: " .. (p.totalNeeds or 0) .. "  bad: " .. (p.suspiciousNeeds or 0))
	end

	local contentHeight
	if idx == 0 then
		local row = self:GetEmptyRow()
		row:SetPoint("TOPLEFT", 0, -24)
		row:Show()
		row.text:SetText("No suspected/ninja flagged players yet.\n(Watch-tier players are hidden by default.)")
		contentHeight = 80
	else
		contentHeight = 24 + idx * 38
	end
	self.child:SetHeight(math.max(400, contentHeight))
end
