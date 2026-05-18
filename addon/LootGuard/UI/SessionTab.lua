local LG = LootGuard

local SessionTab = {}
LG.SessionTab = SessionTab

local ROW_GAP = 6
local ICON_SIZE = 36
local BADGE_WIDTH = 72

function SessionTab:Init(addon, frame)
	self.addon = addon
	self.frame = frame
	self.scroll = frame.Content.SessionScroll
	self.child = self.scroll and self.scroll.GetScrollChild and self.scroll:GetScrollChild()
	self.rows = {}
	if self.child then
		self.child:SetWidth(LG.Theme.CONTENT_WIDTH)
	end
end

function SessionTab:Clear()
	for _, row in ipairs(self.rows) do
		row:Hide()
	end
end

function SessionTab:CreateRow(index)
	local row = self.rows[index]
	if row then return row end

	local w = LG.Theme.CONTENT_WIDTH
	row = CreateFrame("Frame", nil, self.child)
	row:SetWidth(w)

	local icon = row:CreateTexture(nil, "ARTWORK")
	icon:SetSize(ICON_SIZE, ICON_SIZE)
	icon:SetPoint("TOPLEFT", 6, -4)
	row.icon = icon

	local badge = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	badge:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -8)
	badge:SetWidth(BADGE_WIDTH)
	badge:SetJustifyH("RIGHT")
	row.badge = badge

	local title = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2)
	title:SetPoint("RIGHT", badge, "LEFT", -6, 0)
	title:SetHeight(14)
	LG.Theme:ConfigureTruncatedText(title)
	row.title = title

	local detail = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	detail:SetPoint("TOPLEFT", icon, "BOTTOMRIGHT", 8, -2)
	detail:SetPoint("RIGHT", row, "RIGHT", -10, 0)
	LG.Theme:ConfigureWrappedText(detail, w - ICON_SIZE - 24, 4)
	row.detail = detail

	self.rows[index] = row
	return row
end

function SessionTab:LayoutRow(row, yOffset)
	row:ClearAllPoints()
	row:SetPoint("TOPLEFT", 0, -yOffset)
end

function SessionTab:MeasureRow(row)
	local detailH = row.detail:GetStringHeight() or 14
	local h = math.max(52, ICON_SIZE + 12 + detailH)
	row:SetHeight(h)
	return h + ROW_GAP
end

function SessionTab:FormatRollLine(pr)
	local rt = LG.ROLL_TYPE_NAMES[pr.rollType] or "?"
	local line = string.format("%s: %s", pr.name, rt)
	if pr.rollType == LG.ROLL_NEED and pr.verdict == "bad" then
		line = line .. " (!)"
	end
	return line
end

function SessionTab:Refresh()
	if not self.child then
		if self.scroll then
			self.scroll:SetScript("OnShow", function() LG.SessionTab:Refresh() end)
		end
		return
	end
	self:Clear()
	if not LG.Storage.db then return end

	local rolls = LG.Storage:GetSessionRolls()
	local y = 4
	local idx = 0

	for i = #rolls, 1, -1 do
		local r = rolls[i]
		idx = idx + 1
		local row = self:CreateRow(idx)
		self:LayoutRow(row, y)
		row:Show()

		if r.itemLink then
			GetItemInfo(r.itemLink)
		end
		local tex = r.itemLink and select(10, GetItemInfo(r.itemLink))
		row.icon:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
		row.title:SetText(r.itemName or "?")

		local parts = {}
		for _, pr in ipairs(r.rolls or {}) do
			parts[#parts + 1] = self:FormatRollLine(pr)
		end
		row.detail:SetText(table.concat(parts, "\n"))

		local bad = false
		for _, pr in ipairs(r.rolls or {}) do
			if pr.verdict == "bad" then
				bad = true
				break
			end
		end
		if bad then
			row.badge:SetText("|cffff4444Flagged|r")
		else
			row.badge:SetText("|cff44ff44OK|r")
		end

		y = y + self:MeasureRow(row)
	end

	if idx == 0 then
		local row = self:CreateRow(1)
		self:LayoutRow(row, y)
		row:Show()
		row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		row.title:SetText("No rolls logged this session yet.")
		row.detail:SetText("Join a party or raid and roll on group loot to populate this tab.")
		row.badge:SetText("")
		y = y + self:MeasureRow(row)
	end

	LG.Theme:UpdateScroll(self.scroll, self.child, y + 8)
end
