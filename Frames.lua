-- Frame construction and layout: anchor box, secure unit buttons, health and power bars, portrait.
local _, ns = ...
local FA = ns.FA
local U = FA.U
local Frames = FA:AddModule("Frames")
FA.Frames = Frames

FA:RegisterUnitEvents("UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER",
	"UNIT_DISPLAYPOWER", "UNIT_NAME_UPDATE", "UNIT_PORTRAIT_UPDATE", "UNIT_MODEL_CHANGED")

local LSM = LibStub("LibSharedMedia-3.0", true)
local BASE_SIZE = 120

-- Ships the Minimalist bar texture (same file ShadowedUnitFrames uses) so it exists without SUF.
if LSM then
	LSM:Register("statusbar", "Minimalist", "Interface\\AddOns\\Sheepdog\\media\\Minimalist")
end

local function BarTexture()
	local name = FA.db and FA.db.profile.frames.barTexture
	if LSM and name then
		return LSM:Fetch("statusbar", name) or FA.WHITE
	end
	return FA.WHITE
end

local function FontPath(face)
	local db = FA.db and FA.db.profile.font
	face = face or (db and db.face)
	if LSM and face then
		return LSM:Fetch("font", face) or FA.FONT
	end
	return FA.FONT
end

-- size is in points; flags default to the profile's outline setting; face to the profile's font
local function SetFont(fs, size, flags, face)
	local db = FA.db and FA.db.profile.font
	flags = flags or (db and db.outline) or "OUTLINE"
	if flags == "NONE" then flags = "" end
	fs:SetFont(FontPath(face), math.max(6, math.floor(size + 0.5)), flags)
end
FA.SetFont = SetFont

-- Point size for a named text at frame size S (sizes are defined at frame size 120).
function FA.FontSize(key, S)
	local sizes = FA.db.profile.font.sizes
	return (sizes[key] or 10) * S / BASE_SIZE
end

-- Four thin textures around a frame; cheaper and older-client-safe compared to backdrops.
local function AddBorder(frame, size, r, g, b, a)
	local t = {}
	for i = 1, 4 do
		t[i] = frame:CreateTexture(nil, "OVERLAY", nil, 7)
		t[i]:SetColorTexture(r, g, b, a or 1)
	end
	t[1]:SetPoint("TOPLEFT", -size, size); t[1]:SetPoint("TOPRIGHT", size, size); t[1]:SetHeight(size)
	t[2]:SetPoint("BOTTOMLEFT", -size, -size); t[2]:SetPoint("BOTTOMRIGHT", size, -size); t[2]:SetHeight(size)
	t[3]:SetPoint("TOPLEFT", -size, size); t[3]:SetPoint("BOTTOMLEFT", -size, -size); t[3]:SetWidth(size)
	t[4]:SetPoint("TOPRIGHT", size, size); t[4]:SetPoint("BOTTOMRIGHT", size, -size); t[4]:SetWidth(size)
	frame.borderTextures = t
	return t
end
FA.AddBorder = AddBorder

local function CreateBar(parent)
	local bar = CreateFrame("StatusBar", nil, parent)
	bar:SetStatusBarTexture(FA.WHITE)
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(1)
	bar.bg = bar:CreateTexture(nil, "BACKGROUND")
	bar.bg:SetAllPoints()
	bar.bg:SetColorTexture(0.12, 0.14, 0.17, 1)
	bar.text = bar:CreateFontString(nil, "OVERLAY")
	bar.text:SetPoint("LEFT", 4, 0)
	bar.text:SetJustifyH("LEFT")
	SetFont(bar.text, 12)
	AddBorder(bar, 1, 0, 0, 0)
	return bar
end

-- Icon slot used by the DR and trinket columns: colored border, inset icon, swipe, our own text.
function FA.CreateSlot(parent)
	local s = CreateFrame("Frame", nil, parent)
	s.border = s:CreateTexture(nil, "BACKGROUND")
	s.border:SetAllPoints()
	s.border:SetColorTexture(0.24, 0.86, 0.42, 1)
	s.icon = s:CreateTexture(nil, "ARTWORK")
	s.icon:SetPoint("TOPLEFT", 2, -2)
	s.icon:SetPoint("BOTTOMRIGHT", -2, 2)
	s.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	s.cd = CreateFrame("Cooldown", nil, s, "CooldownFrameTemplate")
	s.cd:SetAllPoints(s.icon)
	s.cd:SetDrawEdge(false)
	s.cd:SetDrawBling(false)
	s.cd:SetSwipeColor(0, 0, 0, 0.65)
	s.cd:SetHideCountdownNumbers(true)
	s.cd.noCooldownCount = true -- OmniCC stays out; we draw the number ourselves
	local overlay = CreateFrame("Frame", nil, s)
	overlay:SetAllPoints()
	overlay:SetFrameLevel(s.cd:GetFrameLevel() + 2)
	s.text = overlay:CreateFontString(nil, "OVERLAY")
	s.text:SetPoint("CENTER", -1, 1) -- leaves the bottom-right corner to the badge
	SetFont(s.text, 10)
	s.badge = overlay:CreateFontString(nil, "OVERLAY")
	s.badge:SetPoint("BOTTOMRIGHT", -1, 1)
	SetFont(s.badge, 8)
	-- keep the icon's proportions inside a slot that is not exactly square
	function s:SetSlotSize(w, h)
		self:SetSize(w, h)
		self.icon:SetTexCoord(FA.CropCoords(h / w))
	end
	return s
end

function Frames:Create()
	if self.anchor then return end
	local anchor = CreateFrame("Frame", "SheepdogAnchor", UIParent)
	anchor:SetSize(120, 120)
	anchor:SetMovable(true)
	anchor:SetClampedToScreen(true)
	anchor:SetFrameStrata("MEDIUM")
	self.anchor = anchor

	local ov = CreateFrame("Frame", nil, anchor)
	ov:SetAllPoints() -- re-anchored to the frames in Layout
	ov:SetFrameStrata("HIGH")
	ov:EnableMouse(true)
	ov:RegisterForDrag("LeftButton")
	ov:SetScript("OnDragStart", function() anchor:StartMoving() end)
	ov:SetScript("OnDragStop", function()
		anchor:StopMovingOrSizing()
		Frames:SavePosition()
	end)
	ov.bg = ov:CreateTexture(nil, "BACKGROUND")
	ov.bg:SetAllPoints()
	ov.bg:SetColorTexture(0.41, 0.8, 0.94, 0.18)
	AddBorder(ov, 2, 0.41, 0.8, 0.94, 0.9)
	ov.text = ov:CreateFontString(nil, "OVERLAY")
	ov.text:SetPoint("CENTER")
	SetFont(ov.text, 12)
	ov.text:SetText("Sheepdog\ndrag to move\n/sheep lock")
	ov:Hide()
	self.overlay = ov

	for i = 1, FA.MAX_ARENA do self:CreateUnitFrame(i) end
	self:LoadPosition()
	self:Layout()
end

local function OnEvent(frame, event, ...)
	FA:OnUnitEvent(frame, event, ...)
end

function Frames:CreateUnitFrame(i)
	local unit = "arena" .. i
	local f = CreateFrame("Button", "SheepdogFrame" .. i, self.anchor, "SecureUnitButtonTemplate")
	f.unit = unit
	f.id = i
	f:SetAttribute("unit", unit)
	f:RegisterForClicks("AnyUp")
	f:SetScript("OnShow", function(s) FA:UpdateUnit(s.unit) end)
	f:SetScript("OnEvent", OnEvent)
	for _, ev in ipairs(FA.UNIT_EVENTS) do
		pcall(f.RegisterUnitEvent, f, ev, unit)
	end

	f.hp = CreateBar(f)
	f.power = CreateBar(f)

	local p = CreateFrame("Frame", nil, f)
	p.bg = p:CreateTexture(nil, "BACKGROUND")
	p.bg:SetAllPoints()
	p.bg:SetColorTexture(0.04, 0.05, 0.07, 1)
	p.tex = p:CreateTexture(nil, "ARTWORK")
	p.tex:SetAllPoints()
	-- live 3D model, used when the portrait style is "3d" and the unit is in view
	p.model = CreateFrame("PlayerModel", nil, p)
	p.model:SetAllPoints()
	p.model:Hide()
	local nameHolder = CreateFrame("Frame", nil, p)
	nameHolder:SetAllPoints()
	nameHolder:SetFrameLevel(p:GetFrameLevel() + 1)
	p.name = nameHolder:CreateFontString(nil, "OVERLAY")
	p.name:SetPoint("BOTTOM", 0, 3)
	SetFont(p.name, 10)
	AddBorder(p, 1, 0, 0, 0)
	f.portrait = p

	f.column = CreateFrame("Frame", nil, f)

	FA.frames[unit] = f
	FA.frameList[i] = f
	FA:Call("OnFrameCreated", f)
	RegisterUnitWatch(f)
	return f
end

-- Icon column geometry shared by the DR and trinket modules: n slots stacked in the column.
function Frames:SlotMetrics(S)
	local db = FA.db.profile
	local n = #db.dr.slots + 1
	local gap = math.max(1, math.floor(S * 0.012 + 0.5))
	local h = (S - (n - 1) * gap) / n
	return n, h, gap
end

function Frames:Layout()
	if not self.anchor or InCombatLockdown() then return end
	local db = FA.db.profile
	local S = db.size
	local colW, colGap = S * db.frames.columnWidth, S * db.frames.columnGap
	local W = S + colGap + colW
	local hpH, pwH = S * db.frames.hpHeight, S * db.frames.powerHeight
	local g = FA.GROWTH[db.growth] or FA.GROWTH.right
	local spacing = db.spacing
	local n = math.max(1, db.previewCount or 3)

	self.anchor:SetScale(db.scale)
	if g.x ~= 0 then
		self.anchor:SetSize(n * W + (n - 1) * spacing, S)
	else
		self.anchor:SetSize(W, n * S + (n - 1) * spacing)
	end

	for i, f in ipairs(FA.frameList) do
		f:SetSize(W, S)
		f:ClearAllPoints()
		if i == 1 then
			f:SetPoint(g.point, self.anchor, g.point, 0, 0)
		else
			f:SetPoint(g.point, FA.frameList[i - 1], g.relative, g.x * spacing, g.y * spacing)
		end

		f.hp:ClearAllPoints()
		f.hp:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
		f.hp:SetSize(S, hpH)
		f.hp:SetStatusBarTexture(BarTexture())
		f.power:SetStatusBarTexture(BarTexture())
		SetFont(f.hp.text, FA.FontSize("bar", S))

		f.power:ClearAllPoints()
		f.power:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
		f.power:SetSize(S, pwH)
		SetFont(f.power.text, FA.FontSize("bar", S))

		f.portrait:ClearAllPoints()
		f.portrait:SetPoint("TOPLEFT", f.hp, "BOTTOMLEFT", 0, 0)
		f.portrait:SetPoint("BOTTOMRIGHT", f.power, "TOPRIGHT", 0, 0)
		SetFont(f.portrait.name, FA.FontSize("name", S))
		-- the portrait area is wider than tall; square textures get center-cropped to fit
		f.portraitAspect = (S - hpH - pwH) / S
		f.iconCoords = { FA.CropCoords(f.portraitAspect) }

		f.column:ClearAllPoints()
		f.column:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
		f.column:SetSize(colW, S)

		FA:Call("OnLayout", f, S)
	end

	-- the drag box spans the first n frames, whatever direction they grow in
	local first, last = FA.frameList[1], FA.frameList[math.min(n, #FA.frameList)]
	local ov = self.overlay
	ov:ClearAllPoints()
	if db.growth == "left" then
		ov:SetPoint("TOPRIGHT", first, "TOPRIGHT", 4, 4)
		ov:SetPoint("BOTTOMLEFT", last, "BOTTOMLEFT", -4, -4)
	elseif db.growth == "up" then
		ov:SetPoint("BOTTOMLEFT", first, "BOTTOMLEFT", -4, -4)
		ov:SetPoint("TOPRIGHT", last, "TOPRIGHT", 4, 4)
	else -- right, down
		ov:SetPoint("TOPLEFT", first, "TOPLEFT", -4, 4)
		ov:SetPoint("BOTTOMRIGHT", last, "BOTTOMRIGHT", 4, -4)
	end
end

function Frames:SetLocked(locked)
	if not self.overlay then return end
	if locked then self.overlay:Hide() else self.overlay:Show() end
end

function Frames:SavePosition()
	local point, _, _, x, y = self.anchor:GetPoint(1)
	local pos = FA.db.profile.position
	pos.point, pos.x, pos.y = point or "CENTER", x or 0, y or 0
end

function Frames:LoadPosition()
	local pos = FA.db.profile.position
	self.anchor:ClearAllPoints()
	self.anchor:SetPoint(pos.point or "CENTER", UIParent, pos.point or "CENTER", pos.x or 0, pos.y or 0)
end

-- Unit data -> bars and portrait -------------------------------------------------------------

local function ClassColor(class)
	local c = class and (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
	if c then return c.r, c.g, c.b end
	return 0.6, 0.6, 0.6
end

function Frames:UpdateHealth(f)
	local hp, max = U.Health(f.unit)
	max = (max and max > 0) and max or 1
	hp = hp or 0
	f.hp:SetValue(hp / max)
	if FA.db.profile.frames.showPercent then
		f.hp.text:SetFormattedText("%d%%", math.floor(hp / max * 100 + 0.5))
	else
		f.hp.text:SetText(AbbreviateLargeNumbers and AbbreviateLargeNumbers(hp) or hp)
	end
end

function Frames:UpdatePower(f)
	local power, max, token = U.Power(f.unit)
	max = (max and max > 0) and max or 1
	power = power or 0
	f.power:SetValue(power / max)
	f.power.text:SetFormattedText("%d%%", math.floor(power / max * 100 + 0.5))
	local c = FA.POWER_COLORS[token] or FA.POWER_COLORS.MANA
	-- lifted toward white like the health bar so the dark percent text reads on it
	f.power:SetStatusBarColor(c[1] * 0.55 + 0.45, c[2] * 0.55 + 0.45, c[3] * 0.55 + 0.45)
	f.power.bg:SetColorTexture(c[1] * 0.25, c[2] * 0.25, c[3] * 0.25, 1)
end

function Frames:UpdateClass(f)
	local class = U.Class(f.unit)
	local r, g, b = ClassColor(class)
	f.class = class
	if FA.db.profile.frames.classColorHealth then
		-- lift toward white so the dark percent text stays readable, as in the sketch
		f.hp:SetStatusBarColor(r * 0.58 + 0.42, g * 0.58 + 0.42, b * 0.58 + 0.42)
		f.hp.bg:SetColorTexture(r * 0.22, g * 0.22, b * 0.22, 1)
	else
		f.hp:SetStatusBarColor(0.24, 0.86, 0.42)
		f.hp.bg:SetColorTexture(0.12, 0.14, 0.17, 1)
	end
	f.hp.text:SetTextColor(0.1, 0.12, 0.16)
	f.power.text:SetTextColor(0.1, 0.12, 0.16)
end

function Frames:UpdatePortrait(f)
	local unit = f.unit
	local db = FA.db.profile.frames
	if db.showName then
		f.portrait.name:SetText(U.Name(unit) or "")
	else
		f.portrait.name:SetText("")
	end
	local style = db.portrait or "3d"
	local aspect = f.portraitAspect or 0.64
	local visible = U.IsVisible(unit)
	local p = f.portrait
	if style == "3d" and (visible or FA.test) then
		-- in test mode the fake units have no model, so show your own character
		p.model:Show()
		p.tex:Hide()
		p.model:SetUnit(FA.test and "player" or unit)
		p.model:SetPortraitZoom(1)
		p.model:SetPosition(0, 0, 0)
		return
	end
	p.model:Hide()
	p.tex:Show()
	if style ~= "class" and visible then
		SetPortraitTexture(p.tex, unit)
		p.tex:SetTexCoord(FA.CropCoords(aspect, 0, 1, 0, 1))
	else
		local coords = f.class and CLASS_ICON_TCOORDS[f.class]
		if coords then
			p.tex:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
			p.tex:SetTexCoord(FA.CropCoords(aspect, coords[1], coords[2], coords[3], coords[4]))
		else
			p.tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
			p.tex:SetTexCoord(FA.CropCoords(aspect))
		end
	end
end

function Frames:OnUnitUpdate(f)
	self:UpdateClass(f)
	self:UpdateHealth(f)
	self:UpdatePower(f)
	self:UpdatePortrait(f)
end

function Frames:OnUnitEvent(f, event)
	if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
		self:UpdateHealth(f)
	elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
		self:UpdatePower(f)
	elseif event == "UNIT_NAME_UPDATE" or event == "UNIT_PORTRAIT_UPDATE" or event == "UNIT_MODEL_CHANGED" then
		self:UpdatePortrait(f)
	end
end

function Frames:OnUnitReset(f)
	f.class = nil
	f.hp:SetValue(1)
	f.hp.text:SetText("")
	f.power:SetValue(1)
	f.power.text:SetText("")
	f.portrait.name:SetText("")
	f.portrait.tex:SetTexture(nil)
	f.portrait.tex:Show()
	f.portrait.model:ClearModel()
	f.portrait.model:Hide()
end
