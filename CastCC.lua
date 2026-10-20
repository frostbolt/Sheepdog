-- Portrait takeover: an active cast or a CC aura replaces the portrait.
-- Cast styles: "bar" (icon with a cast bar along the bottom), "iconbar" (square icon on the left, name and
-- bar on the right), "reveal" (icon uncovered left to right). CC: icon plus a big countdown.
local _, ns = ...
local FA = ns.FA
local U = FA.U
local CastCC = FA:AddModule("CastCC")
FA.CastCC = CastCC

FA:RegisterUnitEvents("UNIT_AURA", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED",
	"UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_CHANNEL_START",
	"UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_CHANNEL_STOP")

local LSM = LibStub("LibSharedMedia-3.0", true)
local THROTTLE = 0.04

local function OnUpdate(c, elapsed)
	c.elapsed = (c.elapsed or 0) + elapsed
	if c.elapsed < THROTTLE then return end
	c.elapsed = 0
	CastCC:Tick(c.frame)
end

local function BarTexture()
	local name = FA.db.profile.frames.barTexture
	if LSM and name then return LSM:Fetch("statusbar", name) or FA.WHITE end
	return FA.WHITE
end

function CastCC:OnFrameCreated(f)
	local c = CreateFrame("Frame", nil, f.portrait)
	c:SetAllPoints()
	c:SetFrameLevel(f.portrait:GetFrameLevel() + 2)
	c.frame = f

	c.icon = c:CreateTexture(nil, "ARTWORK")
	c.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	-- reveal style
	c.shade = c:CreateTexture(nil, "OVERLAY", nil, 1)
	c.shade:SetColorTexture(0.02, 0.03, 0.06, 0.78)
	c.shade:SetPoint("TOPRIGHT")
	c.shade:SetPoint("BOTTOMRIGHT")
	c.shade:SetWidth(1)
	c.edge = c:CreateTexture(nil, "OVERLAY", nil, 2)
	c.edge:SetColorTexture(0.91, 0.84, 0.63, 1)
	c.edge:SetPoint("TOPRIGHT", c.shade, "TOPLEFT", 1, 0)
	c.edge:SetPoint("BOTTOMRIGHT", c.shade, "BOTTOMLEFT", 1, 0)
	c.edge:SetWidth(2)

	-- bar styles
	local bar = CreateFrame("StatusBar", nil, c)
	bar:SetFrameLevel(c:GetFrameLevel() + 1)
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	bar.bg = bar:CreateTexture(nil, "BACKGROUND")
	bar.bg:SetAllPoints()
	bar.bg:SetColorTexture(0.05, 0.06, 0.08, 0.85)
	bar.line = bar:CreateTexture(nil, "OVERLAY", nil, 7)
	bar.line:SetColorTexture(0, 0, 0, 1)
	bar.line:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 1)
	bar.line:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 1)
	bar.line:SetHeight(1)
	c.bar = bar

	local t = CreateFrame("Frame", nil, c)
	t:SetAllPoints()
	t:SetFrameLevel(c:GetFrameLevel() + 2)
	c.spell = t:CreateFontString(nil, "OVERLAY")
	c.spell:SetJustifyH("LEFT")
	c.left = t:CreateFontString(nil, "OVERLAY")
	c.left:SetJustifyH("RIGHT")
	c.big = t:CreateFontString(nil, "OVERLAY")
	c.big:SetPoint("CENTER")
	c.big:SetTextColor(1, 0.18, 0.18)
	c.ccname = t:CreateFontString(nil, "OVERLAY")
	c.ccname:SetPoint("BOTTOM", 0, 3)

	c:SetScript("OnUpdate", OnUpdate)
	c:Hide()
	f.center = c
end

-- Position icon, bar and texts for the chosen style. Called from OnLayout, so out of combat only.
function CastCC:ApplyStyle(f, S)
	local db = FA.db.profile
	local c = f.center
	local style = db.cast.style or "bar"
	local ph = S * (1 - db.frames.hpHeight - db.frames.powerHeight)
	local barH = math.max(4, math.floor(S * (db.cast.barHeight or 0.14) + 0.5))
	c.style = style

	c.icon:ClearAllPoints()
	c.bar:ClearAllPoints()
	c.spell:ClearAllPoints()
	c.left:ClearAllPoints()
	c.spell:SetWidth(0)

	if style == "reveal" then
		c.icon:SetAllPoints()
		if f.iconCoords then c.icon:SetTexCoord(unpack(f.iconCoords)) end
		c.bar:Hide()
		c.spell:SetPoint("BOTTOM", 0, 3)
		c.spell:SetJustifyH("CENTER")
		c.left:SetPoint("TOPRIGHT", -3, -2)
	elseif style == "iconbar" then
		c.icon:SetPoint("TOPLEFT")
		c.icon:SetPoint("BOTTOMLEFT")
		c.icon:SetWidth(ph)
		c.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		c.bar:SetPoint("BOTTOMLEFT", c.icon, "BOTTOMRIGHT", 0, 0)
		c.bar:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", 0, 0)
		c.bar:SetHeight(barH)
		c.bar:Show()
		c.spell:SetPoint("BOTTOMLEFT", c.bar, "TOPLEFT", 3, 3)
		c.spell:SetPoint("RIGHT", c, "RIGHT", -2, 0)
		c.spell:SetJustifyH("LEFT")
		c.left:SetPoint("RIGHT", c.bar, "RIGHT", -3, 0)
	else -- bar
		c.icon:SetAllPoints()
		if f.iconCoords then c.icon:SetTexCoord(unpack(f.iconCoords)) end
		c.bar:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", 0, 0)
		c.bar:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", 0, 0)
		c.bar:SetHeight(barH)
		c.bar:Show()
		c.spell:SetPoint("LEFT", c.bar, "LEFT", 3, 0)
		c.spell:SetPoint("RIGHT", c.left, "LEFT", -4, 0)
		c.spell:SetJustifyH("LEFT")
		c.left:SetPoint("RIGHT", c.bar, "RIGHT", -3, 0)
	end
	c.bar:SetStatusBarTexture(BarTexture())
	c.shade:Hide()
	c.edge:Hide()
end

function CastCC:OnLayout(f, S)
	local font = FA.db.profile.font
	FA.SetFont(f.center.spell, FA.FontSize("castName", S))
	FA.SetFont(f.center.left, FA.FontSize("castTime", S))
	FA.SetFont(f.center.big, FA.FontSize("big", S), font.bigOutline or "THICKOUTLINE", font.bigFace)
	local col = font.bigColor or { 1, 0.18, 0.18 }
	f.center.big:SetTextColor(col[1], col[2], col[3])
	FA.SetFont(f.center.ccname, FA.FontSize("ccName", S))
	self:ApplyStyle(f, S)
	if f.mode then self:Decide(f) end
end

local function Allowed(entry, db)
	if entry.kind == "cc" then return true end
	if entry.kind == "immune" then return db.showImmunities end
	if entry.kind == "defensive" then return db.showDefensives end
	return false
end

function CastCC:ReadCast(f)
	if not FA.db.profile.cast.enabled then f.cast = nil return end
	local name, icon, startMs, endMs, channel, notInterruptible = U.CastInfo(f.unit)
	if name and startMs and endMs then
		f.cast = { name = name, icon = icon, startMs = startMs, endMs = endMs, channel = channel, shielded = notInterruptible }
	else
		f.cast = nil
	end
end

local function ScanFilter(f, filter, db, best)
	for i = 1, 40 do
		local name, icon, _, _, duration, expiration, _, _, _, spellId = U.Aura(f.unit, i, filter)
		if not name then break end
		local e = (spellId and FA.AURA_PRIO[spellId]) or FA.AURA_PRIO_BY_NAME[name]
		local expired = expiration and expiration > 0 and expiration <= GetTime()
		if e and not expired and Allowed(e, db) then
			if not best or e.prio > best.prio or (e.prio == best.prio and (expiration or 0) > (best.expiration or 0)) then
				best = best or {}
				best.name, best.icon, best.duration, best.expiration, best.prio, best.kind =
					name, icon, duration or 0, expiration or 0, e.prio, e.kind
			end
		end
	end
	return best
end

function CastCC:ReadAuras(f)
	local db = FA.db.profile.cc
	if not db.enabled then f.cc = nil return end
	local best = ScanFilter(f, "HARMFUL", db, nil)
	best = ScanFilter(f, "HELPFUL", db, best)
	f.cc = best
end

local function CastColor(cast, db)
	if cast.interrupted then return db.interruptColor end
	if cast.shielded then return db.uninterruptibleColor end
	if cast.channel then return db.channelColor end
	return db.castColor
end

function CastCC:Decide(f)
	local c = f.center
	if not c then return end
	local db = FA.db.profile.cast
	local cc = f.cc
	local cast = f.cast
	if not cast and f.castFlash and f.castFlash.until_ > GetTime() then cast = f.castFlash end
	local hard = FA.db.profile.cc.hardPriority or 7
	local mode
	if cc and cc.prio >= hard then
		mode = "cc"
	elseif cast then
		mode = "cast"
	elseif cc then
		mode = "cc"
	end
	f.mode = mode
	f.castShown = cast
	if not mode then
		c:Hide()
		return
	end
	c:Show()
	if mode == "cast" then
		c.icon:SetTexture(cast.icon)
		c.spell:Show(); c.left:Show()
		c.big:Hide(); c.ccname:Hide()
		c.spell:SetText(cast.interrupted and "Interrupted" or cast.name)
		if c.style == "reveal" then
			c.shade:SetShown(not cast.interrupted)
			c.edge:SetShown(not cast.interrupted)
			c.bar:Hide()
			c.spell:SetTextColor(1, 1, 1)
			if cast.interrupted then c.spell:SetTextColor(1, 0.3, 0.3) end
		else
			c.bar:Show()
			local col = CastColor(cast, db)
			c.bar:SetStatusBarColor(col[1], col[2], col[3])
			c.spell:SetTextColor(1, 1, 1)
		end
	else
		c.icon:SetTexture(cc.icon)
		c.shade:Hide(); c.edge:Hide(); c.spell:Hide(); c.left:Hide(); c.bar:Hide()
		c.big:Show(); c.ccname:Show()
		c.ccname:SetText(cc.name)
	end
	self:Tick(f)
end

function CastCC:Tick(f)
	local c = f.center
	local now = GetTime()
	if f.mode == "cast" then
		local cast = f.castShown
		if not cast then self:Decide(f) return end
		if cast.interrupted then
			if now >= cast.until_ then
				f.castFlash = nil
				self:Decide(f)
				return
			end
			if c.style ~= "reveal" then c.bar:SetValue(1) end
			c.left:SetText("")
			return
		end
		local total = (cast.endMs - cast.startMs) / 1000
		local elapsed = now - cast.startMs / 1000
		if total <= 0 or elapsed > total + 0.3 then
			f.cast = nil
			self:Decide(f)
			return
		end
		local p = math.min(1, math.max(0, elapsed / total))
		if cast.channel then p = 1 - p end
		if c.style == "reveal" then
			c.shade:SetWidth(math.max(0.01, c:GetWidth() * (1 - p)))
		else
			c.bar:SetValue(p)
		end
		c.left:SetFormattedText("%.1f", math.max(0, total - elapsed))
	elseif f.mode == "cc" then
		local cc = f.cc
		if cc.expiration and cc.expiration > 0 then
			local r = cc.expiration - now
			if r <= 0 then
				f.cc = nil
				self:Decide(f)
				return
			end
			if r < 10 then
				c.big:SetFormattedText("%.1f", r)
			else
				c.big:SetFormattedText("%d", math.ceil(r))
			end
		else
			c.big:SetText("")
		end
	end
end

function CastCC:OnUnitEvent(f, event)
	if event == "UNIT_AURA" then
		self:ReadAuras(f)
	else
		if event == "UNIT_SPELLCAST_INTERRUPTED" and f.cast and FA.db.profile.cast.interruptFlash then
			f.castFlash = {
				name = f.cast.name, icon = f.cast.icon, interrupted = true,
				until_ = GetTime() + (FA.db.profile.cast.interruptDuration or 0.8),
			}
		end
		self:ReadCast(f)
	end
	self:Decide(f)
end

function CastCC:OnUnitUpdate(f)
	self:ReadCast(f)
	self:ReadAuras(f)
	self:Decide(f)
end

function CastCC:OnUnitReset(f)
	f.cast, f.cc, f.castFlash = nil, nil, nil
	self:Decide(f)
end
