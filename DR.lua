-- Diminishing returns per enemy, one slot per category, tracked from the combat log with DRList-1.0.
local _, ns = ...
local FA = ns.FA
local DRList = LibStub("DRList-1.0")
local DR = FA:AddModule("DR")
FA.DR = DR

DR.byGUID = {}   -- guid -> { [category] = { applied = n, expires = t, spellId = id, icon = path } }

local band = bit.band
local TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER or 0x400
local HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE or 0x40
local TICK = 0.1
local catIcon = {}

local function CategoryIcon(cat)
	if not catIcon[cat] then
		catIcon[cat] = FA.SpellIcon(FA.DR_CATEGORY_SPELL[cat] or 0)
	end
	return catIcon[cat]
end

function DR:OnEnable()
	C_Timer.NewTicker(30, function() DR:Purge() end)
end

function DR:OnCombatLog(_, sub, _, _, _, _, _, dstGUID, _, dstFlags, _, spellId, _, _, auraType)
	if auraType ~= "DEBUFF" then return end
	if sub ~= "SPELL_AURA_APPLIED" and sub ~= "SPELL_AURA_REFRESH" and sub ~= "SPELL_AURA_REMOVED" then return end
	if band(dstFlags or 0, TYPE_PLAYER) == 0 or band(dstFlags or 0, HOSTILE) == 0 then return end
	local cat = DRList:GetCategoryBySpellID(spellId)
	if not cat then return end
	if sub == "SPELL_AURA_REMOVED" then
		if FA.db.profile.dr.timerStartAuraEnd then self:StartTimer(dstGUID, cat) end
		return
	end
	self:Apply(dstGUID, cat, spellId)
end

-- A CC of this category landed on this GUID: raise the level and (re)start the reset window.
function DR:Apply(guid, cat, spellId)
	local now = GetTime()
	local list = self.byGUID[guid]
	if not list then list = {}; self.byGUID[guid] = list end
	local e = list[cat]
	if not e then e = { applied = 0 }; list[cat] = e end
	if e.expires and e.expires <= now then e.applied = 0 end
	e.applied = math.min(e.applied + 1, 3)
	e.spellId = spellId
	e.icon = FA.SpellIcon(spellId)
	e.expires = now + DRList:GetResetTime(cat)
	self:Changed(guid)
end

function DR:StartTimer(guid, cat)
	local e = self.byGUID[guid] and self.byGUID[guid][cat]
	if not e then return end
	e.expires = GetTime() + DRList:GetResetTime(cat)
	self:Changed(guid)
end

-- Current DR level (0 none, 1 half next, 2 quarter next, 3 immune) for a GUID and category.
function DR:Level(guid, cat)
	local e = guid and self.byGUID[guid] and self.byGUID[guid][cat]
	if e and e.expires > GetTime() then return e.applied, e end
	return 0, e
end

function DR:Changed(guid)
	local f = FA.guidToFrame[guid]
	if f then self:UpdateFrame(f) end
end

function DR:Purge()
	local now = GetTime()
	for guid, list in pairs(self.byGUID) do
		for cat, e in pairs(list) do
			if e.expires <= now then list[cat] = nil end
		end
		if not next(list) then self.byGUID[guid] = nil end
	end
end

function DR:Wipe()
	wipe(self.byGUID)
	for _, f in ipairs(FA.frameList) do self:UpdateFrame(f) end
end

function DR:OnArenaEnter() self:Wipe() end
function DR:OnArenaLeave() self:Wipe() end

-- Slots -------------------------------------------------------------------------------------

local function OnUpdate(ticker, elapsed)
	ticker.elapsed = (ticker.elapsed or 0) + elapsed
	if ticker.elapsed < TICK then return end
	ticker.elapsed = 0
	DR:TickFrame(ticker.frame)
end

function DR:OnFrameCreated(f)
	f.drSlots = {}
	local ticker = CreateFrame("Frame", nil, f.column)
	ticker.frame = f
	ticker:SetScript("OnUpdate", OnUpdate)
	f.drTicker = ticker
end

function DR:EnsureSlots(f, n)
	for i = #f.drSlots + 1, n do
		f.drSlots[i] = FA.CreateSlot(f.column)
	end
end

function DR:OnLayout(f, S)
	local db = FA.db.profile
	local _, h, gap = FA.Frames:SlotMetrics(S)
	local w = S * db.frames.columnWidth
	local slots = db.dr.slots
	self:EnsureSlots(f, #slots)
	for i, s in ipairs(f.drSlots) do
		s:ClearAllPoints()
		if i <= #slots and db.dr.enabled then
			s.cat = slots[i]
			s:SetPoint("TOPRIGHT", f.column, "TOPRIGHT", 0, -(i - 1) * (h + gap))
			s:SetSlotSize(w, h)
			FA.SetFont(s.text, FA.FontSize("dr", S))
			FA.SetFont(s.badge, FA.FontSize("badge", S))
			s:Show()
		else
			s.cat = nil
			s:Hide()
		end
	end
	self:UpdateFrame(f)
end

function DR:UpdateFrame(f)
	if not f.drSlots then return end
	local now = GetTime()
	local list = f.guid and self.byGUID[f.guid]
	for _, s in ipairs(f.drSlots) do
		if s.cat then
			local e = list and list[s.cat]
			local level = (e and e.expires > now) and e.applied or 0
			local c = FA.DR_COLORS[level]
			s.border:SetColorTexture(c[1], c[2], c[3], 1)
			s.badge:SetText(FA.DR_BADGE[level])
			s.icon:SetTexture((level > 0 and e.icon) or CategoryIcon(s.cat))
			s.icon:SetDesaturated(level == 0)
			s.icon:SetAlpha(level == 0 and 0.55 or 1)
			if level > 0 then
				if s.cdExpires ~= e.expires then
					s.cdExpires = e.expires
					local reset = DRList:GetResetTime(s.cat)
					s.cd:SetCooldown(e.expires - reset, reset)
				end
			elseif s.cdExpires then
				s.cdExpires = nil
				s.cd:Clear()
				s.text:SetText("")
			end
			s.level, s.entry = level, e
		end
	end
end

function DR:TickFrame(f)
	local now = GetTime()
	local expired
	local show = FA.db.profile.dr.showReset
	for _, s in ipairs(f.drSlots) do
		if s.level and s.level > 0 and s.entry then
			local r = s.entry.expires - now
			if r <= 0 then
				expired = true
			elseif show then
				s.text:SetFormattedText("%d", math.ceil(r))
			end
		end
	end
	if expired then self:UpdateFrame(f) end
end

function DR:OnUnitUpdate(f) self:UpdateFrame(f) end
function DR:OnUnitReset(f) self:UpdateFrame(f) end
