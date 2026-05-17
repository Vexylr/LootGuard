local LG = LootGuard

local SessionTab = {}
LG.SessionTab = SessionTab

function SessionTab:Init(addon, frame)
	self.addon = addon
	self.frame = frame
	self.scroll = frame.Content.SessionScroll
	self.child = self.scroll and self.scroll.GetScrollChild and self.scroll:GetScrollChild()
	self.rows = {}
end

function SessionTab:Clear()
	for _, row in ipairs(self.rows) do row:Hide() end
end

function SessionTab:CreateRow(index)
	local row = self.rows[index]
	if row then return row end
	row = CreateFrame("Frame", nil, self.child)
	row:SetSize(640, 48)
	row:SetPoint("TOPLEFT", 0, -((index - 1) * 50))
	local icon = row:CreateTexture(nil, "ARTWORK")
	icon:SetSize(36, 36)
	icon:SetPoint("LEFT", 4, 0)
	row.icon = icon
	local title = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2)
	title:SetWidth(400)
	title:SetJustifyH("LEFT")
	row.title = title
	local detail = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	detail:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 8, 2)
	detail:SetWidth(520)
	detail:SetJustifyH("LEFT")
	row.detail = detail
	local badge = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	badge:SetPoint("RIGHT", row, "RIGHT", -8, 0)
	row.badge = badge
	self.rows[index] = row
	return row
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
	local idx = 0
	for i = #rolls, 1, -1 do
		local r = rolls[i]
		idx = idx + 1
		local row = self:CreateRow(idx)
		row:Show()
		if r.itemLink then
			GetItemInfo(r.itemLink)
		end
		local tex = r.itemLink and select(10, GetItemInfo(r.itemLink))
		if tex then
			row.icon:SetTexture(tex)
		else
			row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		end
		row.title:SetText(r.itemName or "?")
		local parts = {}
		for _, pr in ipairs(r.rolls or {}) do
			parts[#parts + 1] = self:FormatRollLine(pr)
		end
		row.detail:SetText(table.concat(parts, "  |  "))
		local bad = false
		for _, pr in ipairs(r.rolls or {}) do
			if pr.verdict == "bad" then bad = true break end
		end
		if bad then
			row.badge:SetText("|cffff4444Flagged|r")
		else
			row.badge:SetText("|cff44ff44OK|r")
		end
		row:SetHeight(48)
	end
	if idx == 0 then
		local row = self:CreateRow(1)
		row:Show()
		row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		row.title:SetText("No rolls logged this session yet.")
		row.detail:SetText("Join a party or raid and roll on group loot to populate this tab.")
		row.badge:SetText("")
		idx = 1
	end
	local h = math.max(400, idx * 50)
	self.child:SetHeight(h)
end
