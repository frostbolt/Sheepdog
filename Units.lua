-- Unit data layer. Every module reads units through FA.U so test mode can feed fake data.
local _, ns = ...
local FA = ns.FA
local U = {}
FA.U = U

local UnitAuraRaw = UnitAura or function(unit, i, filter)
	local a = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex and C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
	if not a then return end
	return a.name, a.icon, a.applications, a.dispelName, a.duration, a.expirationTime,
		a.sourceUnit, a.isStealable, a.nameplateShowPersonal, a.spellId
end

local function test(unit)
	return FA.test and FA.TestMode and FA.TestMode.data[unit] or nil
end

function U.Exists(unit)
	local t = test(unit)
	if FA.test then return t ~= nil end
	return UnitExists(unit)
end

function U.GUID(unit)
	local t = test(unit)
	if t then return t.guid end
	return UnitGUID(unit)
end

function U.Class(unit)
	local t = test(unit)
	if t then return t.class end
	local _, class = UnitClass(unit)
	return class
end

function U.Name(unit)
	local t = test(unit)
	if t then return t.name end
	return UnitName(unit)
end

function U.IsVisible(unit)
	local t = test(unit)
	if t then return false end
	return UnitIsVisible(unit)
end

function U.Health(unit)
	local t = test(unit)
	if t then return t.hp, t.hpMax end
	return UnitHealth(unit), UnitHealthMax(unit)
end

function U.Power(unit)
	local t = test(unit)
	if t then return t.power, t.powerMax, t.powerType end
	local _, token = UnitPowerType(unit)
	return UnitPower(unit), UnitPowerMax(unit), token or "MANA"
end

-- Returns name, icon, startMs, endMs, isChannel, notInterruptible (or nil when idle).
function U.CastInfo(unit)
	local t = test(unit)
	if t then
		local c = t.cast
		if c then return c.name, c.icon, c.startMs, c.endMs, c.channel, false end
		return nil
	end
	local name, _, texture, startMs, endMs, _, _, notInterruptible = UnitCastingInfo(unit)
	if name then return name, texture, startMs, endMs, false, notInterruptible end
	name, _, texture, startMs, endMs, _, notInterruptible = UnitChannelInfo(unit)
	if name then return name, texture, startMs, endMs, true, notInterruptible end
	return nil
end

-- Same tuple as UnitAura: name, icon, count, dispelType, duration, expiration, source, stealable, _, spellId
function U.Aura(unit, i, filter)
	local t = test(unit)
	if t then
		local list = t.auras and t.auras[filter]
		local a = list and list[i]
		if not a then return nil end
		return a.name, a.icon, 1, nil, a.duration, a.expiration, nil, false, false, a.spellId
	end
	return UnitAuraRaw(unit, i, filter)
end
