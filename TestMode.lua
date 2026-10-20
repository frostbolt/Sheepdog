-- Test mode: three fake opponents fed through the same unit layer and event paths as real ones.
local _, ns = ...
local FA = ns.FA
local DRList = LibStub("DRList-1.0")
local TM = FA:AddModule("TestMode")
FA.TestMode = TM

TM.data = {}

local OPPONENTS = {
	{ class = "MAGE",    name = "Frostbite", power = "MANA" },
	{ class = "ROGUE",   name = "Shivv",     power = "ENERGY" },
	{ class = "PRIEST",  name = "Lightwell", power = "MANA" },
	{ class = "WARRIOR", name = "Bonk",      power = "RAGE" },
	{ class = "DRUID",   name = "Mooncalf",  power = "MANA" },
}

-- CC used by the script: spellId, PvP base duration, DR category.
local CC = {
	poly   = { 118, 10, "incapacitate" },
	nova   = { 122, 8, "root" },
	kidney = { 408, 6, "kidney_shot" },
	cheap  = { 1833, 4, "stun" },
	fear   = { 8122, 8, "fear" },
}

-- Twenty-four second loop. Times are offsets into the loop.
local LOOP = 24
local SCRIPT = {
	{ t = 0.5,  unit = "arena3", cc = "poly" },
	{ t = 1.0,  unit = "arena1", cast = { "Frostbolt", 3.0, 116 } },
	{ t = 1.5,  unit = "arena2", cc = "nova" },
	{ t = 3.5,  unit = "arena3", trinket = 42292 },
	{ t = 4.2,  unit = "arena3", cc = "poly" },
	{ t = 5.0,  unit = "arena1", cc = "kidney" },
	{ t = 6.5,  unit = "arena3", cast = { "Greater Heal", 3.0, 2060 } },
	{ t = 2.6,  unit = "arena1", interrupt = true },
	{ t = 8.0,  unit = "arena2", cc = "nova" },
	{ t = 21.0, unit = "arena3", cast = { "Mind Flay", 3.0, 15407, true } },
	{ t = 9.5,  unit = "arena3", cc = "poly" },
	{ t = 11.5, unit = "arena3", cc = "poly" },
	{ t = 13.0, unit = "arena2", trinket = 7744 },
	{ t = 14.0, unit = "arena1", cast = { "Polymorph", 1.5, 118 } },
	{ t = 16.0, unit = "arena2", cc = "cheap" },
	{ t = 18.0, unit = "arena1", cc = "fear" },
	{ t = 20.0, unit = "arena2", cast = { "Shadowstep", 0.0, 36554 } },
	-- extra opponents in 4v4 / 5v5 test
	{ t = 2.0,  unit = "arena4", cast = { "Slam", 1.5, 1464 } },
	{ t = 6.0,  unit = "arena4", cc = "poly" },
	{ t = 7.0,  unit = "arena5", cast = { "Cyclone", 1.5, 33786 } },
	{ t = 10.0, unit = "arena5", cc = "fear" },
	{ t = 15.0, unit = "arena4", trinket = 42292 },
	{ t = 19.0, unit = "arena5", cc = "cheap" },
}

local function Fire(unit, event, ...)
	local f = FA.frames[unit]
	if f then FA:OnUnitEvent(f, event, unit, ...) end
end

function TM:Toggle()
	if FA.test then self:Disable() else self:Enable() end
end

function TM:Enable()
	if InCombatLockdown() then
		self.pendingEnable = true
		FA:Print("Test mode starts when combat ends.")
		return
	end
	FA.test = true
	wipe(self.data)
	local count = math.max(2, math.min(FA.MAX_ARENA, FA.db.profile.testCount or 3))
	for i = 1, count do
		local o = OPPONENTS[i]
		self.data["arena" .. i] = {
			guid = "Test-Sheepdog-" .. i, class = o.class, name = o.name, seed = i * 1.7,
			hp = 100, hpMax = 100, power = 100, powerMax = 100, powerType = o.power,
			auras = { HARMFUL = {}, HELPFUL = {} },
		}
	end
	FA.DR:Wipe()
	for i, f in ipairs(FA.frameList) do
		UnregisterUnitWatch(f)
		if i <= count then f:Show() else f:Hide() end
	end
	for i = 1, count do FA:UpdateUnit("arena" .. i) end
	self.start = GetTime()
	self.cycle = nil
	self.fired = {}
	if self.ticker then self.ticker:Cancel() end
	self.ticker = C_Timer.NewTicker(0.1, function() TM:Tick() end)
	FA:Print(("Test mode on with %d opponents. /sheep test again to stop, /sheep test 5 for a full team, /sheep unlock to move."):format(count))
end

function TM:Disable()
	if InCombatLockdown() then
		self.pendingDisable = true
		FA:Print("Test mode stops when combat ends.")
		return
	end
	if self.ticker then self.ticker:Cancel(); self.ticker = nil end
	FA.test = false
	wipe(self.data)
	FA.DR:Wipe()
	for _, f in ipairs(FA.frameList) do
		FA:ResetUnit(f.unit)
		RegisterUnitWatch(f)
		if not UnitExists(f.unit) then f:Hide() end
	end
	FA:Print("Test mode off.")
end

function TM:ApplyPending()
	if self.pendingEnable then self.pendingEnable = nil; self:Enable() end
	if self.pendingDisable then self.pendingDisable = nil; self:Disable() end
end

function TM:Run(step)
	local unit = step.unit
	local d = self.data[unit]
	if not d then return end
	local now = GetTime()
	if step.cast then
		local name, dur, id, channel = step.cast[1], step.cast[2], step.cast[3], step.cast[4]
		for _, a in ipairs(d.auras.HARMFUL) do
			if a.spellId ~= 122 then return end -- in hard CC: a real unit could not cast
		end
		if dur > 0 then
			d.cast = { name = name, icon = FA.SpellIcon(id), startMs = now * 1000, endMs = (now + dur) * 1000, channel = channel }
			Fire(unit, channel and "UNIT_SPELLCAST_CHANNEL_START" or "UNIT_SPELLCAST_START")
		else
			Fire(unit, "UNIT_SPELLCAST_SUCCEEDED", nil, id)
		end
	elseif step.interrupt then
		if d.cast then
			d.cast = nil
			Fire(unit, "UNIT_SPELLCAST_INTERRUPTED")
		end
	elseif step.cc then
		local id, base, cat = unpack(CC[step.cc])
		local level = FA.DR:Level(d.guid, cat)
		local mult = level == 0 and 1 or (DRList:GetNextDR(level, cat) or 0)
		FA.DR:Apply(d.guid, cat, id)
		local name = FA.GetSpellInfo(id) or step.cc
		if mult > 0 then
			local dur = base * mult
			table.insert(d.auras.HARMFUL, { name = name, icon = FA.SpellIcon(id), duration = dur, expiration = now + dur, spellId = id })
			if cat ~= "root" and d.cast then
				d.cast = nil
				Fire(unit, "UNIT_SPELLCAST_INTERRUPTED")
			end
			Fire(unit, "UNIT_AURA")
		else
			FA:Print(unit .. " is immune to " .. name .. " (" .. cat .. ")")
		end
	elseif step.trinket then
		wipe(d.auras.HARMFUL)
		Fire(unit, "UNIT_AURA")
		Fire(unit, "UNIT_SPELLCAST_SUCCEEDED", nil, step.trinket)
	end
end

function TM:Tick()
	if not FA.test then return end
	local now = GetTime()
	local t = (now - self.start) % LOOP
	local cycle = math.floor((now - self.start) / LOOP)
	if cycle ~= self.cycle then
		self.cycle = cycle
		wipe(self.fired)
	end
	for idx, step in ipairs(SCRIPT) do
		if not self.fired[idx] and t >= step.t then
			self.fired[idx] = true
			self:Run(step)
		end
	end
	for unit, d in pairs(self.data) do
		d.hp = math.floor(55 + 45 * (0.5 + 0.5 * math.sin(now / 4 + d.seed)))
		d.power = math.floor(40 + 60 * (0.5 + 0.5 * math.cos(now / 7 + d.seed)))
		Fire(unit, "UNIT_HEALTH")
		Fire(unit, "UNIT_POWER_UPDATE")
		local list = d.auras.HARMFUL
		local changed
		for i = #list, 1, -1 do
			if list[i].expiration <= now then
				table.remove(list, i)
				changed = true
			end
		end
		if changed then Fire(unit, "UNIT_AURA") end
		if d.cast and d.cast.endMs <= now * 1000 then
			d.cast = nil
			Fire(unit, "UNIT_SPELLCAST_STOP")
		end
	end
end
