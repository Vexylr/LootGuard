local LG = LootGuard

local Theme = {}
LG.Theme = Theme

Theme.colors = {
	bg = { 0.07, 0.08, 0.09, 0.97 },
	border = { 0.16, 0.18, 0.22, 1 },
	accent = { 0.79, 0.64, 0.15, 1 },
	text = { 0.92, 0.92, 0.92, 1 },
	textDim = { 0.55, 0.58, 0.62, 1 },
	ok = { 0.25, 0.85, 0.35, 1 },
	bad = { 0.95, 0.28, 0.22, 1 },
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

function Theme:FadeIn(frame, duration)
	UIFrameFadeIn(frame, duration or 0.2, 0, 1)
end

function Theme:FadeOut(frame, duration, onDone)
	UIFrameFadeOut(frame, duration or 0.2, 1, 0)
	if onDone then
		frame.fadeHook = onDone
	end
end

function Theme:CreateTabButton(parent, text, width)
	local btn = CreateFrame("Button", nil, parent)
	btn:SetSize(width or 120, 28)
	local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	label:SetPoint("CENTER")
	label:SetText(text)
	btn.label = label
	btn:SetNormalTexture("Interface\\Buttons\\UI-Silver-Button-Up")
	btn:SetHighlightTexture("Interface\\Buttons\\UI-Silver-Button-Highlight")
	btn:SetPushedTexture("Interface\\Buttons\\UI-Silver-Button-Down")
	return btn
end
