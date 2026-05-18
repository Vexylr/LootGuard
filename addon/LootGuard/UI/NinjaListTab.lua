local LG = LootGuard

local NinjaListTab = {}
LG.NinjaListTab = NinjaListTab

local HEADER_Y = -6
local ROW_START_Y = -28
local ROW_HEIGHT = 34
local ROW_GAP = 4

local COL = {
	NAME = 10,
	REP = 188,
	FLAG = 278,
	STATS = 368,
}

function NinjaListTab:Init(addon, frame)
	self.addon = addon
	self.frame = frame
	self.scroll = frame.Content.NinjaScroll
	self.child = self.scroll and self.scroll.GetScrollChild and self.scroll:GetScrollChild()
	self.rows = {}
	if self.child then
		self.child:SetWidth(LG.Theme.CONTENT_WIDTH)
		self:EnsureHeader()
	end
end

function NinjaListTab:EnsureHeader()
	if not self.child or self.header then return end
	local h = self.child

	local nameH = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	nameH:SetPoint("TOPLEFT", COL.NAME, HEADER_Y)
	nameH:SetText("Name")
	nameH:SetTextColor(0.79, 0.64, 0.15)

	local repH = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	repH:SetPoint("TOPLEFT", COL.REP, HEADER_Y)
	repH:SetText("Rep")
	repH:SetTextColor(0.79, 0.64, 0.15)

	local flagH = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	flagH:SetPoint("TOPLEFT", COL.FLAG, HEADER_Y)
	flagH:SetText("Flag")
	flagH:SetTextColor(0.79, 0.64, 0.15)

	local statsH = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	statsH:SetPoint("TOPLEFT", COL.STATS, HEADER_Y)
	statsH:SetText("Stats")
	statsH:SetTextColor(0.79, 0.64, 0.15)

	self.header = true
end

function NinjaListTab:GetEmptyRow()
	if self.emptyRow then return self.emptyRow end
	local row = CreateFrame("Frame", nil, self.child)
	row:SetSize(LG.Theme.CONTENT_WIDTH, 56)
	row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.text:SetPoint("TOPLEFT", COL.NAME, -20)
	row.text:SetWidth(LG.Theme.CONTENT_WIDTH - 20)
	row.text:SetJustifyH("LEFT")
	if row.text.SetWordWrap then
		row.text:SetWordWrap(true)
	end
	self.emptyRow = row
	return row
end

function NinjaListTab:CreateDataRow(index)
	local row = self.rows[index]
	if row then return row end

	row = CreateFrame("Frame", nil, self.child)
	row:SetSize(LG.Theme.CONTENT_WIDTH, ROW_HEIGHT)

	if index % 2 == 0 then
		local bg = row:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(0.12, 0.13, 0.15, 0.45)
	end

	row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.nameText:SetPoint("LEFT", COL.NAME, 0)
	row.nameText:SetWidth(COL.REP - COL.NAME - 8)
	row.nameText:SetJustifyH("LEFT")
	LG.Theme:ConfigureTruncatedText(row.nameText)

	row.repText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.repText:SetPoint("LEFT", COL.REP, 0)
	row.repText:SetWidth(82)

	row.flagText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.flagText:SetPoint("LEFT", COL.FLAG, 0)
	row.flagText:SetWidth(84)

	row.srcText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.srcText:SetPoint("LEFT", COL.STATS, 0)
	row.srcText:SetWidth(LG.Theme.CONTENT_WIDTH - COL.STATS - 8)
	row.srcText:SetJustifyH("LEFT")
	LG.Theme:ConfigureTruncatedText(row.srcText)

	self.rows[index] = row
	return row
end

function NinjaListTab:Refresh()
	if not self.child then return end
	self:EnsureHeader()

	for _, row in ipairs(self.rows) do
		row:Hide()
	end
	if self.emptyRow then
		self.emptyRow:Hide()
	end

	local settings = LG.Storage:GetGlobal()
	if not settings then return end

	local minFlag = settings.ninjaListMinFlag or LG.FLAG_SUSPECTED
	local list = LG.Storage:GetFlaggedPlayers(minFlag)
	local y = -ROW_START_Y
	local idx = 0

	for _, p in ipairs(list) do
		idx = idx + 1
		local row = self:CreateDataRow(idx)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 0, y)
		row:Show()

		local displayName = p.name or "?"
		if p.realm and p.realm ~= "" then
			displayName = displayName .. "-" .. p.realm
		end
		row.nameText:SetText(displayName)

		local repR, repG, repB = LG.Engine:GetReputationColor(p.reputation or 10)
		row.repText:SetText(string.format("%.1f", p.reputation or 10))
		row.repText:SetTextColor(repR, repG, repB)

		local flagName = LG.FLAG_NAMES[p.flag or 0] or "?"
		local fc = (p.flag or 0) >= LG.FLAG_NINJA and "|cffff4444" or "|cffffaa00"
		row.flagText:SetText(fc .. flagName .. "|r")
		row.srcText:SetText(string.format(
			"needs %d  bad %d  (%s)",
			p.totalNeeds or 0,
			p.suspiciousNeeds or 0,
			p.source or "local"
		))

		y = y - (ROW_HEIGHT + ROW_GAP)
	end

	local contentHeight
	if idx == 0 then
		local row = self:GetEmptyRow()
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 0, y)
		row:Show()
		row.text:SetText(
			"No suspected or ninja flagged players yet.\n"
				.. "Change list filter under Settings → Advanced thresholds."
		)
		contentHeight = 90
	else
		contentHeight = math.abs(y) + ROW_HEIGHT + 12
	end

	LG.Theme:UpdateScroll(self.scroll, self.child, contentHeight)
end
