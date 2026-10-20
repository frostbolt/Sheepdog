-- PvP trinket and CC-breaking racials: cooldown slot at the bottom of the column plus a frame flash.
local _, ns = ...
local FA = ns.FA
local Trinket = FA:AddModule("Trinket")
FA.Trinket = Trinket

FA:RegisterUnitEvents("UNIT_SPELLCAST_SUCCEEDED")

local TICK = 0.2
local DEFAULT_ICON_SPELL = 42292

local function OnUpdate(s, elapsed)
	s.elapsed = (s.elapsed or 0) + elapsed
	if s.elapsed < TICK then return end
	s.elapsed = 0
	Trinket:TickFrame(s.frame)
end

function Trinket:OnFrameCreated(f)
	local s = FA.CreateSlot(f.column)
	s.frame = f
	s:SetScript("OnUpdate", OnUpdate)
	f.trinketSlot = s

	local fl = CreateFrame("Frame", nil, f)
	fl:SetAllPoints()
	fl:SetFrameLevel(f:GetFrameLevel() + 12)
	fl.tex = fl:CreateTexture(nil, "OVERLAY")
	fl.tex:SetAllPoints()
	fl.tex:SetColorTexture(1, 0.9, 0.6, 1)
	fl.tex:SetBlendMode("ADD")
	fl:SetAlpha(0)
	local ag = fl:CreateAnimationGroup()
	local a1 = ag:CreateAnimation("Alpha")
	a1:SetFromAlpha(0); a1:SetToAlpha(0.9); a1:SetDuration(0.08); a1:SetOrder(1)
	local a2 = ag:CreateAnimation("Alpha")
	a2:SetFromAlpha(0.9); a2:SetToAlpha(0); a2:SetDuration(0.6); a2:SetOrder(2)
	ag:SetScript("OnFinished", function() fl:SetAlpha(0) end)
	fl.ag, fl.a2 = ag, a2
	f.flash = fl
	self:UpdateFrame(f)
end

function Trinket:OnLayout(f, S)
	local db = FA.db.profile
	local _, h = FA.Frames:SlotMetrics(S)
	local s = f.trinketSlot
	s:ClearAllPoints()
	s:SetPoint("BOTTOMRIGHT", f.column, "BOTTOMRIGHT", 0, 0)
	s:SetSlotSize(S * db.frames.columnWidth, h)
	FA.SetFont(s.text, FA.FontSize("trinket", S))
	local c = db.trinket.flashColor
	f.flash.tex:SetColorTexture(c[1], c[2], c[3], 1)
	f.flash.a2:SetDuration(db.trinket.flashDuration or 0.7)
	self:UpdateFrame(f)
end

function Trinket:Use(f, spellId)
	local d = FA.TRINKETS[spellId]
	if not d or not FA.db.profile.trinket.enabled then return end
	local now = GetTime()
	if f.trinket and now - f.trinket.start < 0.5 then return end -- unit event and combat log both fire
	f.trinket = { start = now, duration = d.cd, spellId = spellId }
	self:UpdateFrame(f)
	if FA.db.profile.trinket.flash then
		f.flash.ag:Stop()
		f.flash.ag:Play()
	end
end

function Trinket:UpdateFrame(f)
	local s = f.trinketSlot
	local db = FA.db.profile.trinket
	if not db.enabled then
		s:Hide()
		return
	end
	s:Show()
	local t = f.trinket
	local now = GetTime()
	if t and t.start + t.duration > now then
		s.icon:SetTexture(FA.TRINKETS[t.spellId].icon)
		s.icon:SetDesaturated(true)
		s.icon:SetAlpha(0.7)
		s.border:SetColorTexture(1, 0.23, 0.23, 1)
		if s.cdStart ~= t.start then
			s.cdStart = t.start
			s.cd:SetCooldown(t.start, t.duration)
		end
		self:TickFrame(f)
	else
		f.trinket = nil
		s.icon:SetTexture(FA.TRINKETS[(t and t.spellId) or DEFAULT_ICON_SPELL].icon)
		s.icon:SetDesaturated(false)
		s.icon:SetAlpha(1)
		s.border:SetColorTexture(0.24, 0.86, 0.42, 1)
		if s.cdStart then
			s.cdStart = nil
			s.cd:Clear()
		end
		s.text:SetText("")
	end
end

function Trinket:TickFrame(f)
	local t = f.trinket
	if not t then return end
	local r = t.start + t.duration - GetTime()
	if r <= 0 then
		self:UpdateFrame(f)
	elseif r >= 60 then
		f.trinketSlot.text:SetFormattedText("%d:%02d", math.floor(r / 60), math.floor(r % 60))
	else
		f.trinketSlot.text:SetFormattedText("%d", math.ceil(r))
	end
end

function Trinket:OnUnitEvent(f, event, _, _, spellId)
	if event == "UNIT_SPELLCAST_SUCCEEDED" and FA.TRINKETS[spellId] then
		self:Use(f, spellId)
	end
end

function Trinket:OnCombatLog(_, sub, _, srcGUID, _, _, _, _, _, _, _, spellId)
	if sub == "SPELL_CAST_SUCCESS" and FA.TRINKETS[spellId] then
		local f = FA.guidToFrame[srcGUID]
		if f then self:Use(f, spellId) end
	end
end

function Trinket:OnUnitUpdate(f) self:UpdateFrame(f) end
function Trinket:OnUnitReset(f)
	f.trinket = nil
	self:UpdateFrame(f)
end
