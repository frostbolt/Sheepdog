-- Static data for TBC: aura priorities for the portrait takeover, trinket spells, DR slot icons.
local _, ns = ...
local FA = ns.FA

-- Compatibility wrappers (TBC 2.5.x still has the classic globals; newer clients moved them).
local GetSpellInfoRaw = GetSpellInfo or function(id)
	local t = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id)
	if t then return t.name, nil, t.iconID end
end
function FA.GetSpellInfo(id) return GetSpellInfoRaw(id) end
function FA.SpellIcon(id)
	local _, _, icon = GetSpellInfoRaw(id)
	return icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Portrait takeover table. Higher priority wins. kind drives the on/off switches in options:
--   cc        breakable CC, stuns, roots, silences, disarms (always on)
--   immune    immunities, stealth, drinking (on by default)
--   defensive big defensives (off by default)
-- Priorities follow the GladiusEx BCC table so the ordering is familiar.
-- At or above cc.hardPriority (7) an aura beats an active cast; below it a cast shows first.
local P = {}
local function add(kind, prio, ...)
	for i = 1, select("#", ...) do P[(select(i, ...))] = { prio = prio, kind = kind } end
end

-- Immunities and stealth (10)
add("immune", 10, 45438, 642, 1022, 27827, 34692, 5215, 32612, 1784, 11327, 5384, 23920, 31224, 46924)
add("immune", 10, 44166, 27089, 46755, 430, 431, 432, 1133, 1135, 1137, 10250, 22734, 27094, 43183, 43706) -- drinks
-- Breakable CC (9)
add("cc", 9.1, 118, 12824, 12825, 12826, 28271, 28272, 6770, 2070, 11297)                 -- Polymorph ranks, Sap
add("cc", 9, 2637, 18657, 18658, 3355, 14308, 14309, 19386, 24132, 24133, 27068, 20066)   -- Hibernate, Freezing Trap, Wyvern Sting, Repentance
add("cc", 9, 1776, 1777, 8629, 11285, 11286, 38764, 1513, 14326, 14327, 31661, 33041, 33042, 33043) -- Gouge, Scare Beast, Dragon's Breath
add("cc", 9, 8122, 8124, 10888, 10890, 2094, 5782, 6213, 6215, 5484, 17928, 6358, 5246)   -- Psychic Scream, Blind, Fear, Howl, Seduction, Intimidating Shout
add("cc", 9, 22570, 33786, 605, 19503, 37506)                                             -- Maim, Cyclone, Mind Control, Scatter Shot
-- Stuns (8)
add("cc", 8, 5211, 6798, 8983, 24394, 853, 5588, 5589, 10308, 1833, 408, 8643, 30283, 30413, 30414)
add("cc", 8, 20549, 12809, 100, 25275, 19410, 19577, 7922, 44041, 44047)                  -- War Stomp, Concussion Blow, Charge, Intercept, Impact, Intimidation, Charge stun, Chastise
-- Immunes II (7)
add("immune", 7, 33206, 5277, 26669, 19263)                                               -- Pain Suppression, Evasion, Deterrence
-- Defensives I (6.5)
add("defensive", 6.5, 3411, 45182, 871, 6940, 22812, 498, 12975)
-- Immunes III (6)
add("immune", 6, 18499, 8178, 6346)                                                       -- Berserker Rage, Grounding Totem Effect, Fear Ward
-- Roots, disarms (5)
add("cc", 5, 6789, 17925, 17926, 27223, 339, 1062, 5195, 5196, 9852, 9853, 26989)
add("cc", 5, 122, 865, 6131, 10230, 27088, 33395, 676, 16979, 19185, 19306, 20702, 26177, 13810)
-- Silences (5.5): a silenced healer or caster is the window you are looking for
add("cc", 5.5, 15487, 18469, 34490, 1330, 18498, 19244, 19647, 25046, 28730, 15618, 24259, 32747, 31117)
--   Silence, Counterspell - Silenced, Silencing Shot, Garrote - Silence, Shield Bash - Silenced,
--   Spell Lock (two ranks), Arcane Torrent (two), Silence (Gag Order style), Spell Lock, Unstable Affliction silence
-- Offensives worth a glance (3)
add("defensive", 3, 19574, 12042, 12472, 29977, 31884, 13750, 2825, 32182, 1719, 12292, 3045, 10060, 14177)

FA.AURA_PRIO = P
FA.AURA_PRIO_BY_NAME = {}
for id, entry in pairs(P) do
	local name = GetSpellInfoRaw(id)
	if name and (not FA.AURA_PRIO_BY_NAME[name] or FA.AURA_PRIO_BY_NAME[name].prio < entry.prio) then
		FA.AURA_PRIO_BY_NAME[name] = entry
	end
end

-- Trinkets and racials that break CC. Cooldowns are the TBC values; verify in game.
FA.TRINKETS = {
	[42292] = { cd = 120, name = "PvP Trinket" },            -- Medallion of the Alliance/Horde
	[7744]  = { cd = 120, name = "Will of the Forsaken" },
	[59752] = { cd = 120, name = "Every Man for Himself" },  -- Wrath only, harmless here
}
for id, t in pairs(FA.TRINKETS) do t.icon = FA.SpellIcon(id) end

-- Default icon per DR category when nothing has been applied yet.
FA.DR_CATEGORY_SPELL = {
	incapacitate = 118, stun = 853, root = 122, fear = 5782, disorient = 2094,
	kidney_shot = 408, random_stun = 12809, random_root = 19185, disarm = 676,
	scatter = 19503, mind_control = 605, death_coil = 6789, unstable_affliction = 30108,
	chastise = 44041, counterattack = 19306, silence = 15487, taunt = 355, knockback = 51490,
}

FA.GROWTH = {
	right = { point = "TOPLEFT", relative = "TOPRIGHT", x = 1, y = 0 },
	left  = { point = "TOPRIGHT", relative = "TOPLEFT", x = -1, y = 0 },
	down  = { point = "TOPLEFT", relative = "BOTTOMLEFT", x = 0, y = -1 },
	up    = { point = "BOTTOMLEFT", relative = "TOPLEFT", x = 0, y = 1 },
}

FA.POWER_COLORS = {
	MANA = { 0.29, 0.48, 1 },
	RAGE = { 1, 0.23, 0.23 },
	ENERGY = { 0.96, 0.85, 0.29 },
	FOCUS = { 1, 0.5, 0.25 },
}

FA.DR_COLORS = {
	[0] = { 0.24, 0.86, 0.42 },
	[1] = { 0.96, 0.77, 0.26 },
	[2] = { 1, 0.54, 0.24 },
	[3] = { 1, 0.23, 0.23 },
}
FA.DR_BADGE = { [0] = "", [1] = "\194\189", [2] = "\194\188", [3] = "X" } -- ½ ¼ X

-- Crop a square texture so it keeps its proportions inside a region of height/width = aspect.
-- l, r, t, b are the base texcoords (defaults trim the usual icon border).
function FA.CropCoords(aspect, l, r, t, b)
	l, r, t, b = l or 0.08, r or 0.92, t or 0.08, b or 0.92
	local w, h = r - l, b - t
	if aspect < 1 then
		local nh = w * aspect
		local mid = (t + b) / 2
		return l, r, mid - nh / 2, mid + nh / 2
	elseif aspect > 1 then
		local nw = h / aspect
		local mid = (l + r) / 2
		return mid - nw / 2, mid + nw / 2, t, b
	end
	return l, r, t, b
end

FA.FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
FA.WHITE = "Interface\\Buttons\\WHITE8X8"
