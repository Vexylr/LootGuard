local LG = LootGuard

local Theme = {}
LG.Theme = Theme

Theme.CONTENT_WIDTH = 620
Theme.SCROLL_MIN_HEIGHT = 400

Theme.colors = {
	bg = { 0.07, 0.08, 0.09, 0.97 },
	panel = { 0.10, 0.11, 0.13, 0.95 },
	border = { 0.16, 0.18, 0.22, 1 },
	accent = { 0.79, 0.64, 0.15, 1 },
	text = { 0.92, 0.92, 0.92, 1 },
	textDim = { 0.55, 0.58, 0.62, 1 },
	ok = { 0.25, 0.85, 0.35, 1 },
	bad = { 0.95, 0.28, 0.22, 1 },
	tabInactive = { 0.10, 0.11, 0.13, 0.65 },
	tabActive = { 0.16, 0.17, 0.20, 1 },
}

function Theme:ApplyBackdrop(frame, inset)
	inset = inset or 12
	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = inset, right = inset, top = inset, bottom = inset },
	})
end

function Theme:ApplyPanelBackdrop(frame)
	local c = self.colors.panel
	frame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	frame:SetBackdropColor(c[1], c[2], c[3], c[4])
	frame:SetBackdropBorderColor(0.2, 0.22, 0.26, 0.9)
end

function Theme:ApplyHeader(fontString)
	fontString:SetFontObject(GameFontNormalLarge)
	local c = self.colors.accent
	fontString:SetTextColor(c[1], c[2], c[3])
end

function Theme:ApplyBody(fontString)
	fontString:SetFontObject(GameFontHighlight)
	local c = self.colors.text
	fontString:SetTextColor(c[1], c[2], c[3])
end

function Theme:ConfigureWrappedText(fontString, width, maxLines)
	fontString:SetWidth(width)
	fontString:SetJustifyH("LEFT")
	if fontString.SetWordWrap then
		fontString:SetWordWrap(true)
	end
	if fontString.SetMaxLines and maxLines then
		fontString:SetMaxLines(maxLines)
	end
	if fontString.SetSpacing then
		fontString:SetSpacing(2)
	end
end

function Theme:ConfigureTruncatedText(fontString)
	fontString:SetJustifyH("LEFT")
	if fontString.SetWordWrap then
		fontString:SetWordWrap(false)
	end
	if fontString.SetMaxLines then
		fontString:SetMaxLines(1)
	end
end

function Theme:FadeIn(frame, duration)
	duration = duration or 0.15
	frame:SetAlpha(0)
	frame:Show()
	UIFrameFadeIn(frame, duration, 0, 1)
end

function Theme:FadeOut(frame, duration, onDone)
	duration = duration or 0.15
	UIFrameFadeOut(frame, duration, frame:GetAlpha(), 0)
	if onDone then
		C_Timer.After(duration + 0.02, function()
			if frame then
				onDone()
				frame:SetAlpha(1)
			end
		end)
	end
end

function Theme:UpdateScroll(scroll, child, contentHeight)
	if not scroll or not child then return end
	child:SetWidth(self.CONTENT_WIDTH)
	child:SetHeight(math.max(self.SCROLL_MIN_HEIGHT, contentHeight))
	if scroll.UpdateScrollChildRect then
		scroll:UpdateScrollChildRect()
	end
end

function Theme:CreateTabButton(parent, text, width)
	local btn = CreateFrame("Button", nil, parent)
	btn:SetSize(width or 120, 28)

	local bg = btn:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	btn.bg = bg

	local accent = btn:CreateTexture(nil, "ARTWORK")
	accent:SetHeight(2)
	accent:SetPoint("BOTTOMLEFT", 6, 0)
	accent:SetPoint("BOTTOMRIGHT", -6, 0)
	btn.accent = accent

	local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	label:SetPoint("CENTER", 0, 1)
	label:SetText(text)
	btn.label = label

	local hi = btn:CreateTexture(nil, "HIGHLIGHT")
	hi:SetAllPoints()
	hi:SetColorTexture(1, 1, 1, 0.06)
	btn:SetHighlightTexture(hi)

	self:SetTabActive(btn, false)
	return btn
end

function Theme:SetTabActive(btn, active)
	if not btn or not btn.bg then return end
	local c = self.colors
	if active then
		local t = c.tabActive
		btn.bg:SetColorTexture(t[1], t[2], t[3], t[4] or 1)
		btn.accent:SetColorTexture(c.accent[1], c.accent[2], c.accent[3], 1)
		btn.label:SetTextColor(1, 0.88, 0.25)
	else
		local t = c.tabInactive
		btn.bg:SetColorTexture(t[1], t[2], t[3], t[4] or 1)
		btn.accent:SetColorTexture(c.accent[1], c.accent[2], c.accent[3], 0)
		btn.label:SetTextColor(0.62, 0.64, 0.68)
	end
	btn.isTabActive = active
end
