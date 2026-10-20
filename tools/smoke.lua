-- Smoke test outside the game: stub just enough of the WoW API to load the addon in TOC order,
-- enable it, run test mode for a simulated 30 s, drive the options table, and apply click casting.
-- Usage: luajit tools/smoke.lua   (from the addon folder; luajit ships with the bit library)

local ROOT = arg[0]:match("^(.*)/tools/") or "."
local now = 1000
_G.GetTime = function() return now end

-- Frames ---------------------------------------------------------------------------------
local Frame = {}
Frame.__index = function(t, k)
	local m = Frame[k]
	if m then return m end
	-- Methods are PascalCase; anything else is a data field the addon stored, so nil like a real frame.
	if type(k) == "string" and k:match("^%u") then return function() end end
	return nil
end
local function NewFrame(kind, name, parent)
	local f = setmetatable({ kind = kind, name = name, parent = parent, scripts = {}, attrs = {}, shown = true, children = {} }, Frame)
	if parent and parent.children then table.insert(parent.children, f) end
	return f
end
function Frame:GetFrameLevel() return 1 end
function Frame:GetWidth() return 100 end
function Frame:GetHeight() return 100 end
function Frame:GetPoint() return "CENTER", nil, "CENTER", 0, 0 end
function Frame:Show() self.shown = true end
function Frame:Hide() self.shown = false end
function Frame:IsShown() return self.shown end
function Frame:SetShown(v) self.shown = v end
function Frame:SetScript(ev, fn) self.scripts[ev] = fn end
function Frame:GetScript(ev) return self.scripts[ev] end
function Frame:SetAttribute(k, v) self.attrs[k] = v end
function Frame:GetAttribute(k) return self.attrs[k] end
function Frame:CreateTexture() return NewFrame("Texture", nil, self) end
function Frame:CreateFontString() return NewFrame("FontString", nil, self) end
function Frame:CreateAnimationGroup() return NewFrame("AnimationGroup", nil, self) end
function Frame:CreateAnimation() return NewFrame("Animation", nil, self) end
function Frame:RegisterUnitEvent(ev) self.events = self.events or {}; self.events[ev] = true end
function Frame:SetText(t) self.text = t end
function Frame:SetFormattedText(fmt, ...) self.text = string.format(fmt, ...) end
function Frame:GetText() return self.text end
_G.CreateFrame = NewFrame
_G.UIParent = NewFrame("Frame", "UIParent")

local function pump(frame, elapsed)
	local s = frame.scripts.OnUpdate
	if s then s(frame, elapsed) end
	for _, c in ipairs(frame.children) do pump(c, elapsed) end
end

-- Globals --------------------------------------------------------------------------------
_G.WOW_PROJECT_MAINLINE, _G.WOW_PROJECT_CLASSIC, _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 1, 2, 5
_G.WOW_PROJECT_ID = 5
_G.GetLocale = function() return "enUS" end
_G.STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
_G.RAID_CLASS_COLORS = { MAGE = { r = .41, g = .8, b = .94 }, ROGUE = { r = 1, g = .96, b = .41 }, PRIEST = { r = 1, g = 1, b = 1 } }
_G.CLASS_ICON_TCOORDS = { MAGE = { 0, 0, 0, 0 }, ROGUE = { 0, 0, 0, 0 }, PRIEST = { 0, 0, 0, 0 } }
_G.COMBATLOG_OBJECT_TYPE_PLAYER, _G.COMBATLOG_OBJECT_REACTION_HOSTILE = 0x400, 0x40
_G.InCombatLockdown = function() return false end
_G.IsInInstance = function() return false, "none" end
_G.UnitExists = function() return false end
_G.UnitGUID = function() return nil end
_G.UnitClass = function() return nil end
_G.UnitName = function() return nil end
_G.UnitIsVisible = function() return false end
_G.UnitHealth = function() return 0 end
_G.UnitHealthMax = function() return 0 end
_G.UnitPower = function() return 0 end
_G.UnitPowerMax = function() return 0 end
_G.UnitPowerType = function() return 0, "MANA" end
_G.UnitCastingInfo = function() return nil end
_G.UnitChannelInfo = function() return nil end
_G.UnitAura = function() return nil end
_G.SetPortraitTexture = function() end
_G.RegisterUnitWatch = function() end
_G.UnregisterUnitWatch = function() end
_G.GetSpellInfo = function(id) return "Spell" .. tostring(id), nil, "icon" .. tostring(id) end
_G.AbbreviateLargeNumbers = function(n) return tostring(n) end
_G.CopyTable = function(t) local c = {} for k, v in pairs(t) do c[k] = type(v) == "table" and CopyTable(v) or v end return c end
_G.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
_G.tContains = function(t, v) for _, x in ipairs(t) do if x == v then return true end end return false end
_G.strsplit = function(sep, s) local out = {} for piece in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do out[#out + 1] = piece end return unpack(out) end
string.trim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
_G.strmatch, _G.strfind, _G.strlower, _G.strupper, _G.format, _G.gsub, _G.strlen = string.match, string.find, string.lower, string.upper, string.format, string.gsub, string.len
_G.tinsert, _G.tremove, _G.floor, _G.ceil, _G.max, _G.min = table.insert, table.remove, math.floor, math.ceil, math.max, math.min
local tickers = {}
_G.C_Timer = { NewTicker = function(interval, fn) local t = { interval = interval, fn = fn, due = now + interval } tickers[t] = true t.Cancel = function() tickers[t] = nil end return t end }
local cleu
_G.CombatLogGetCurrentEventInfo = function() return unpack(cleu) end
_G.LoadAddOn = function() return false end
_G.ArenaEnemyFrames = NewFrame("Frame", "ArenaEnemyFrames")

-- Libraries: real LibStub and DRList, stubbed Ace3 --------------------------------------
local function run(path, ...)
	local chunk, err = loadfile(ROOT .. "/" .. path)
	assert(chunk, err)
	return chunk(...)
end
run("Libs/LibStub/LibStub.lua")
run("Libs/DRList-1.0/DRList-1.0.lua")
run("Libs/DRList-1.0/Spells.lua")

local addonObj
local AceAddon = LibStub:NewLibrary("AceAddon-3.0", 1)
function AceAddon:NewAddon(name)
	addonObj = {
		name = name, events = {},
		RegisterEvent = function(self, ev, handler) self.events[ev] = handler or ev end,
		UnregisterEvent = function(self, ev) self.events[ev] = nil end,
		RegisterChatCommand = function() end,
		Print = function(_, ...) print("[FA]", ...) end,
	}
	return addonObj
end
local AceDB = LibStub:NewLibrary("AceDB-3.0", 1)
function AceDB:New(_, defaults) return { profile = CopyTable(defaults.profile), RegisterCallback = function() end } end
local AceConfig = LibStub:NewLibrary("AceConfig-3.0", 1)
local registered
function AceConfig:RegisterOptionsTable(_, t) registered = t end
local ACD = LibStub:NewLibrary("AceConfigDialog-3.0", 1)
function ACD:AddToBlizOptions() end
function ACD:SetDefaultSize() end
function ACD:Open() end
local ACR = LibStub:NewLibrary("AceConfigRegistry-3.0", 1)
function ACR:NotifyChange() end
local ADO = LibStub:NewLibrary("AceDBOptions-3.0", 1)
function ADO:GetOptionsTable() return { type = "group", args = {} } end
local LSM = LibStub:NewLibrary("LibSharedMedia-3.0", 1)
function LSM:Fetch(kind, name) return kind .. "\\" .. tostring(name) end
function LSM:Register() return true end
function LSM:HashTable() return { ["Friz Quadrata TT"] = "Fonts\\FRIZQT__.TTF", Arial = "Fonts\\ARIALN.TTF" } end

-- Load the addon in TOC order ------------------------------------------------------------
local ns = {}
for line in io.lines(ROOT .. "/Sheepdog_TBC.toc") do
	local file = line:match("^([%w_]+%.lua)%s*$")
	if file then run(file, "Sheepdog", ns) end
end
local FA = ns.FA
assert(FA == addonObj, "addon object mismatch")

local function fire(ev, ...)
	local h = FA.events[ev]
	if type(h) == "string" then FA[h](FA, ev, ...) else h(ev, ...) end
end

local function advance(seconds)
	local steps = math.floor(seconds / 0.1 + 0.5)
	for _ = 1, steps do
		now = now + 0.1
		for t in pairs(tickers) do
			if now >= t.due then t.due = now + t.interval; t.fn() end
		end
		for _, f in ipairs(FA.frameList) do pump(f, 0.1) end
	end
end

-- Exercise --------------------------------------------------------------------------------
FA:OnInitialize()
FA:OnEnable()
assert(#FA.frameList == 5, "five frames")
assert(_G.ArenaEnemyFrames.sheepdogBuried and not _G.ArenaEnemyFrames:IsShown(), "Blizzard arena frames hidden")
assert(FA.frames.arena1.attrs.type2 == "spell" and FA.frames.arena1.attrs.spell2 == "Polymorph", "default right-click binding")
assert(FA.frames.arena1.attrs["shift-spell2"] == "Frost Nova", "shift binding")
assert(FA.frames.arena1.attrs.type3 == "spell" and FA.frames.arena1.attrs.spell3 == "Counterspell", "middle binding")
assert(LibStub("DRList-1.0").gameExpansion == "tbc", "DRList expansion")

FA.db.profile.testCount = 3
FA.TestMode:Enable()
assert(FA.test and FA.frames.arena3:IsShown() and not FA.frames.arena4:IsShown(), "test frames shown")
assert(FA.frames.arena1.portrait.model:IsShown() and not FA.frames.arena1.portrait.tex:IsShown(), "3D portrait in test mode")
local l, r, t, b = FA.CropCoords(0.64)
assert(math.abs((b - t) - 0.84 * 0.64) < 1e-9 and l == 0.08 and r == 0.92, "crop keeps proportions")
FA:ChatCommand("test 5")
assert(FA.frames.arena5:IsShown(), "5v5 test mode")
FA:ChatCommand("test 3")
advance(1)
assert(FA.frames.arena3.mode == "cc", "arena3 polymorphed at t=0.5, got " .. tostring(FA.frames.arena3.mode))
assert(FA.frames.arena1.mode == "cast", "arena1 casting at t=1.0")
local lvl = FA.DR:Level(FA.TestMode.data.arena3.guid, "incapacitate")
assert(lvl == 1, "DR level after first poly = 1, got " .. tostring(lvl))
advance(1.5)
assert(FA.frames.arena1.mode == "cast" and FA.frames.arena1.castShown and not FA.frames.arena1.castShown.interrupted, "mage casting at t=2.5")
advance(0.5)
assert(FA.frames.arena1.castShown and FA.frames.arena1.castShown.interrupted, "interrupt flash at t=3.0")
advance(1)
assert(FA.frames.arena3.trinket, "arena3 trinketed at t=3.5")
assert(FA.frames.arena1.mode ~= "cast", "interrupt flash gone by t=4.0, mode=" .. tostring(FA.frames.arena1.mode))
local shown = FA.frames.arena3.trinketSlot.text:GetText()
assert(type(shown) == "string" and shown:match("^1:%d%d$"), "trinket countdown m:ss, got " .. tostring(shown))
advance(9)
lvl = FA.DR:Level(FA.TestMode.data.arena3.guid, "incapacitate")
assert(lvl == 4 or lvl == 3, "DR level after four polys capped at 3, got " .. tostring(lvl))
advance(20)
FA:ChatCommand("debug")
FA.TestMode:Disable()
assert(not FA.test and not FA.frames.arena1:IsShown(), "frames hidden after test mode")

-- combat log path with a real-looking event
FA.guidToFrame["Player-1-ABC"] = FA.frames.arena1
cleu = { now, "SPELL_AURA_APPLIED", false, "Player-1-ME", "Me", 0x511, 0, "Player-1-ABC", "Them", 0x548, 0, 118, "Polymorph", 64, "DEBUFF" }
fire("COMBAT_LOG_EVENT_UNFILTERED")
assert(FA.DR:Level("Player-1-ABC", "incapacitate") == 1, "CLEU DR apply")
cleu = { now, "SPELL_CAST_SUCCESS", false, "Player-1-ABC", "Them", 0x548, 0, "", nil, 0, 0, 42292, "PvP Trinket", 1 }
fire("COMBAT_LOG_EVENT_UNFILTERED")
assert(FA.frames.arena1.trinket, "CLEU trinket")

-- options table: every get runs, every set round-trips its own value
local function walk(t, path)
	for k, o in pairs(t.args or {}) do
		local info = { arg = o.arg, [1] = k }
		if o.type == "group" then
			walk(o, path .. "." .. k)
		elseif o.get and o.type ~= "multiselect" then
			local v1, v2, v3 = o.get(info)
			if o.set and o.type ~= "execute" then o.set(info, v1, v2, v3) end
		elseif o.type == "multiselect" then
			for key in pairs(type(o.values) == "function" and o.values() or o.values) do
				local v = o.get(info, key)
				o.set(info, key, v)
			end
		end
	end
end
walk(registered, "root")
FA.db.profile.growth = "down"
FA:Refresh()
table.insert(FA.db.profile.clickcast.bindings, { mod = "ctrl", button = 2, action = "macro", macro = "/cast [@%unit%] Fire Blast" })
FA.ClickCast:Apply()
assert(FA.frames.arena2.attrs["ctrl-macrotext2"] == "/cast [@arena2] Fire Blast", "macro unit substitution")

print("smoke test passed")
