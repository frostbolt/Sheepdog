-- Chat announcements: your interrupts, your CC landing (with its DR state), and enemy trinkets.
local _, ns = ...
local FA = ns.FA
local U = FA.U
local DRList = LibStub("DRList-1.0")
local Announce = FA:AddModule("Announce")
FA.Announce = Announce

local band = bit.band
local TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER or 0x400
local HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE or 0x40
local DR_TAG = { [2] = " (1/2)", [3] = " (1/4)" }
local TRINKET_SHORT = { [42292] = "trinket", [7744] = "WotF", [59752] = "EMFH" }
local RETRY = 0.1   -- the aura usually shows on the unit a tick after the combat log event

local function db() return FA.db.profile.announce end

local function ShortName(name)
	if not name then return "?" end
	return (name:gsub("%-.*$", ""))
end

local function Mine(guid)
	return guid and (guid == UnitGUID("player") or guid == UnitGUID("pet"))
end

function Announce:Channel()
	local mode = db().channel
	if mode == "self" then return nil end
	if mode == "say" then return "SAY" end
	if IsInRaid() then return "RAID" end
	if IsInGroup() then return "PARTY" end
	return nil
end

function Announce:Say(msg)
	local d = db()
	if not d.enabled then return end
	if FA.test then
		FA:Print("announce: " .. msg)
		return
	end
	if d.onlyInArena and not FA:InArena() then return end
	local channel = self:Channel()
	if channel then
		SendChatMessage(msg, channel)
	else
		FA:Print(msg)
	end
end

-- Real (already diminished) duration of a debuff on the enemy frame's unit, or nil if not visible yet.
local function AuraDuration(guid, spellId)
	local f = FA.guidToFrame[guid]
	if not f or not f.unit then return nil end
	for i = 1, 40 do
		local name, _, _, _, duration, _, _, _, _, id = U.Aura(f.unit, i, "HARMFUL")
		if not name then break end
		if id == spellId then
			if duration and duration > 0 then return duration end
			return nil
		end
	end
	return nil
end

local function Seconds(d)
	local s = ("%.1f"):format(d):gsub("%.0$", "")
	return s .. "s"
end

function Announce:OnCombatLog(_, sub, _, srcGUID, _, _, _, dstGUID, dstName, dstFlags, _, spellId, spellName, _, extra1, extra2)
	local d = db()
	if not d.enabled or not Mine(srcGUID) then return end
	if d.onlyInArena and not FA.test and not FA:InArena() then return end
	if sub == "SPELL_INTERRUPT" then
		if not d.interrupts then return end
		-- extra1/extra2 are the interrupted spell's id and name
		self:Say(("Kicked %s (%s)"):format(ShortName(dstName), extra2 or "cast"))
	elseif sub == "SPELL_AURA_APPLIED" then
		if not d.cc then return end
		if band(dstFlags or 0, TYPE_PLAYER) == 0 or band(dstFlags or 0, HOSTILE) == 0 then return end
		local cat = DRList:GetCategoryBySpellID(spellId)
		if not cat then return end
		-- the DR module ran first on this event, so the level already counts this application
		local level = FA.DR:Level(dstGUID, cat)
		local tag = DR_TAG[level] or ""
		local who = ShortName(dstName)
		local what = spellName or "CC"
		local function say(duration)
			if duration then
				self:Say(("%s on %s %s%s"):format(what, who, Seconds(duration), tag))
			else
				self:Say(("%s on %s%s"):format(what, who, tag))
			end
		end
		local duration = AuraDuration(dstGUID, spellId)
		if duration then return say(duration) end
		C_Timer.After(RETRY, function() say(AuraDuration(dstGUID, spellId)) end)
	end
end

function Announce:OnTrinketUsed(f, spellId)
	if not db().trinkets then return end
	local what = TRINKET_SHORT[spellId] or "trinket"
	self:Say(("%s used %s"):format(ShortName(U.Name(f.unit)), what))
end
