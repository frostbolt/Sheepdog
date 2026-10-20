-- Sheepdog: enemy arena frames for TBC Anniversary.
-- Core: addon object, saved variables, module registry, arena/unit lifecycle, slash commands.

local ADDON_NAME, ns = ...
local FA = LibStub("AceAddon-3.0"):NewAddon("Sheepdog", "AceEvent-3.0", "AceConsole-3.0")
ns.FA = FA
_G.Sheepdog = FA

FA.VERSION = "0.1.0"
FA.MAX_ARENA = 5
FA.units = {}
for i = 1, FA.MAX_ARENA do FA.units[i] = "arena" .. i end

FA.frames = {}        -- unit -> frame
FA.frameList = {}     -- index -> frame
FA.guidToFrame = {}   -- guid -> frame (filled when a unit is seen)
FA.modules = {}
FA.moduleOrder = {}
FA.UNIT_EVENTS = {}   -- events every unit frame registers; modules append in their files
FA.test = false

-- Modules are plain tables with optional hooks. Each hook receives the module as self.
--   OnEnable()                      once, after frames exist
--   OnFrameCreated(frame)           once per unit frame
--   OnLayout(frame, S)              whenever size/growth/spacing change (out of combat)
--   Refresh()                       whenever settings change
--   OnUnitUpdate(frame, unit)       unit seen / shown / full refresh
--   OnUnitEvent(frame, event, ...)  a unit event for that frame's unit
--   OnUnitReset(frame, unit)        unit gone or arena left
--   OnArenaEnter() / OnArenaLeave()
function FA:AddModule(name, mod)
	mod = mod or {}
	mod.name = name
	self.modules[name] = mod
	table.insert(self.moduleOrder, mod)
	return mod
end

function FA:Call(method, ...)
	for _, mod in ipairs(self.moduleOrder) do
		local fn = mod[method]
		if fn then fn(mod, ...) end
	end
end

function FA:RegisterUnitEvents(...)
	for i = 1, select("#", ...) do
		table.insert(self.UNIT_EVENTS, (select(i, ...)))
	end
end

FA.defaults = {
	profile = {
		locked = true,
		scale = 1,
		size = 80,
		growth = "right",      -- right, left, down, up
		spacing = 10,
		previewCount = 1,      -- frames the drag box covers
		position = { point = "CENTER", x = 320, y = 40 },
		frames = {
			hpHeight = 0.2,
			powerHeight = 0.2,
			columnWidth = 0.25,
			columnGap = 0.035,
			classColorHealth = true,
			showPercent = true,
			showName = true,
			portrait = "3d",       -- 3d (live model), 2d (static face), class (class icon)
			barTexture = "Minimalist",
		},
		testCount = 5,
		font = {
			face = "Oswald",           -- bundled (SIL OFL)
			outline = "NONE",          -- NONE, OUTLINE, THICKOUTLINE
			-- the big CC countdown has its own face, outline and color
			bigFace = "FORCED SQUARE",  -- from Details or a SharedMedia pack; falls back to Oswald
			bigOutline = "OUTLINE",
			bigColor = { 1, 0.18, 0.18 },
			-- point sizes at frame size 120; they scale with the frame size
			sizes = { bar = 13, name = 9, castName = 9, castTime = 11, big = 40, ccName = 9, dr = 10, badge = 6, trinket = 9 },
		},
		cc = {
			enabled = true,
			showImmunities = true,
			showDefensives = false,
			hardPriority = 7,   -- auras at or above this priority beat an active cast
		},
		cast = {
			enabled = true,
			style = "bar",             -- bar, iconbar, reveal
			barHeight = 0.2,           -- fraction of the frame size
			castColor = { 0.95, 0.78, 0.3 },
			channelColor = { 0.35, 0.65, 0.95 },
			uninterruptibleColor = { 0.6, 0.6, 0.6 },
			interruptColor = { 0.9, 0.2, 0.2 },
			interruptFlash = true,
			interruptDuration = 0.8,
		},
		dr = {
			enabled = true,
			slots = { "incapacitate", "root", "stun", "fear" },
			showReset = true,
			timerStartAuraEnd = false,
		},
		trinket = {
			enabled = true,
			flash = true,
			flashColor = { 1, 0.9, 0.6 },
			flashDuration = 0.7,
		},
		clickcast = {
			bindings = {
				{ mod = "", button = 1, action = "target" },
				{ mod = "", button = 2, action = "spell", spell = "Polymorph" },
				{ mod = "", button = 3, action = "spell", spell = "Counterspell" },
				{ mod = "shift", button = 2, action = "spell", spell = "Frost Nova" },
			},
		},
		hideBlizzard = true,
	},
}

-- Blizzard arena frames -------------------------------------------------------------------
-- Which frames exist depends on the client: Wrath-style ArenaEnemyFrames (plus prep frames) or the
-- newer CompactArenaFrame. Reparenting to a hidden frame keeps them hidden even if Blizzard code
-- calls Show() later. Secure frames can only be touched out of combat.
local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

local function Bury(frame)
	if not frame or frame.sheepdogBuried then return end
	frame:UnregisterAllEvents()
	frame:Hide()
	frame:SetParent(hiddenParent)
	frame.sheepdogBuried = true
end

function FA:HideBlizzardFrames()
	if not self.db.profile.hideBlizzard then return end
	if InCombatLockdown() then
		self.pendingHideBlizzard = true
		return
	end
	self.pendingHideBlizzard = nil
	Bury(_G.ArenaEnemyFrames)
	Bury(_G.ArenaPrepFrames)
	Bury(_G.CompactArenaFrame)
	for i = 1, self.MAX_ARENA do
		Bury(_G["ArenaEnemyFrame" .. i])
		Bury(_G["ArenaEnemyFrame" .. i .. "PetFrame"])
		Bury(_G["ArenaPrepFrame" .. i])
		Bury(_G["CompactArenaFrameMember" .. i])
	end
end

function FA:ADDON_LOADED(_, name)
	if name == "Blizzard_ArenaUI" then self:HideBlizzardFrames() end
end

function FA:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("SheepdogDB", self.defaults, true)
	self.db.RegisterCallback(self, "OnProfileChanged", "Refresh")
	self.db.RegisterCallback(self, "OnProfileCopied", "Refresh")
	self.db.RegisterCallback(self, "OnProfileReset", "Refresh")
	self:RegisterChatCommand("sheep", "ChatCommand")
	self:RegisterChatCommand("sheepdog", "ChatCommand")
	if self.SetupOptions then self:SetupOptions() end
end

function FA:OnEnable()
	self.Frames:Create()
	self:Call("OnEnable")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZoneChanged")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "ZoneChanged")
	self:RegisterEvent("ARENA_OPPONENT_UPDATE")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("ADDON_LOADED")
	self:Refresh()
	self:ZoneChanged()
	-- the Blizzard arena UI is load-on-demand on some clients; pull it in so it can be hidden now
	if self.db.profile.hideBlizzard then
		local load = (C_AddOns and C_AddOns.LoadAddOn) or LoadAddOn
		if load then pcall(load, "Blizzard_ArenaUI") end
		self:HideBlizzardFrames()
	end
end

-- One combat log subscription, fanned out to modules (AceEvent allows one handler per event).
function FA:COMBAT_LOG_EVENT_UNFILTERED()
	self:Call("OnCombatLog", CombatLogGetCurrentEventInfo())
end

function FA:InArena()
	local _, instanceType = IsInInstance()
	return instanceType == "arena"
end

function FA:ZoneChanged()
	if self.test then return end
	if self:InArena() then
		if not self.inArena then
			self.inArena = true
			self:Call("OnArenaEnter")
		end
		self:HideBlizzardFrames()
		for _, unit in ipairs(self.units) do self:UpdateUnit(unit) end
	elseif self.inArena ~= false then
		self.inArena = false
		self:ResetAll()
		self:Call("OnArenaLeave")
	end
end

function FA:ARENA_OPPONENT_UPDATE(_, unit, reason)
	local frame = self.frames[unit]
	if not frame then return end
	if reason == "seen" or reason == "unseen" then
		self:UpdateUnit(unit)
	elseif reason == "destroyed" or reason == "cleared" then
		self:ResetUnit(unit)
	end
end

-- Full refresh of one unit: called on show, on "seen", on settings change.
function FA:UpdateUnit(unit)
	local frame = self.frames[unit]
	if not frame or not self.U.Exists(unit) then return end
	local guid = self.U.GUID(unit)
	if guid then
		if frame.guid and frame.guid ~= guid then self.guidToFrame[frame.guid] = nil end
		frame.guid = guid
		self.guidToFrame[guid] = frame
	end
	self:Call("OnUnitUpdate", frame, unit)
end

function FA:ResetUnit(unit)
	local frame = self.frames[unit]
	if not frame then return end
	if frame.guid then
		self.guidToFrame[frame.guid] = nil
		frame.guid = nil
	end
	self:Call("OnUnitReset", frame, unit)
end

function FA:ResetAll()
	for _, unit in ipairs(self.units) do self:ResetUnit(unit) end
end

-- Dispatcher for per-frame unit events (registered on each frame in Frames.lua).
function FA:OnUnitEvent(frame, event, ...)
	self:Call("OnUnitEvent", frame, event, ...)
end

-- Apply settings. Layout touches secure frames, so it waits for combat to end.
function FA:Refresh()
	if InCombatLockdown() then
		self.pendingRefresh = true
		return
	end
	self.pendingRefresh = nil
	self.Frames:Layout()
	self.Frames:SetLocked(self.db.profile.locked)
	self:Call("Refresh")
	for _, unit in ipairs(self.units) do
		if self.frames[unit]:IsShown() then self:UpdateUnit(unit) end
	end
end

function FA:PLAYER_REGEN_ENABLED()
	if self.pendingRefresh then self:Refresh() end
	if self.pendingHideBlizzard then self:HideBlizzardFrames() end
	if self.ClickCast then self.ClickCast:ApplyPending() end
	if self.TestMode then self.TestMode:ApplyPending() end
end

function FA:ChatCommand(input)
	local cmd = (input or ""):trim():lower()
	if cmd == "" or cmd == "config" or cmd == "options" then
		LibStub("AceConfigDialog-3.0"):Open("Sheepdog")
	elseif cmd == "lock" then
		self.db.profile.locked = true
		self.Frames:SetLocked(true)
		self:Print("Frames locked.")
	elseif cmd == "unlock" then
		self.db.profile.locked = false
		self.Frames:SetLocked(false)
		self:Print("Frames unlocked. Drag the box, then /sheep lock.")
	elseif cmd == "test" or cmd:match("^test%s+%d$") then
		local n = tonumber(cmd:match("%d$"))
		if n then
			self.db.profile.testCount = math.max(2, math.min(self.MAX_ARENA, n))
			if self.test then self.TestMode:Disable() end
			self.TestMode:Enable()
		else
			self.TestMode:Toggle()
		end
	elseif cmd == "reset" then
		self.db.profile.position = CopyTable(self.defaults.profile.position)
		self.Frames:LoadPosition()
		self:Print("Position reset.")
	elseif cmd == "debug" then
		local DRList = LibStub("DRList-1.0")
		self:Print(("v%s  expansion=%s  project=%s  inArena=%s  test=%s  combat=%s"):format(
			self.VERSION, tostring(DRList.gameExpansion), tostring(WOW_PROJECT_ID),
			tostring(self:InArena()), tostring(self.test), tostring(InCombatLockdown())))
		self:Print(("blizzard frames: ArenaEnemyFrames=%s CompactArenaFrame=%s hidden=%s"):format(
			tostring(_G.ArenaEnemyFrames ~= nil), tostring(_G.CompactArenaFrame ~= nil),
			tostring((_G.ArenaEnemyFrames and _G.ArenaEnemyFrames.sheepdogBuried) or (_G.CompactArenaFrame and _G.CompactArenaFrame.sheepdogBuried) or false)))
		for _, unit in ipairs(self.units) do
			local f = self.frames[unit]
			self:Print(("%s shown=%s exists=%s class=%s guid=%s"):format(unit, tostring(f:IsShown()),
				tostring(self.U.Exists(unit)), tostring(self.U.Class(unit)), tostring(f.guid)))
		end
	else
		self:Print("Commands: /sheep (options), /sheep lock, /sheep unlock, /sheep test [2-5], /sheep reset, /sheep debug")
	end
end
