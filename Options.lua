-- Settings panel (AceConfig). /sheep opens it; it also lives under Interface > AddOns > Sheepdog.
-- Six tabs: Setup, Look, Tracking, Click casting, Announce, Profiles. Rare knobs sit under "Advanced".
local _, ns = ...
local FA = ns.FA
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local DRList = LibStub("DRList-1.0")

local function resolve(path)
	local t = FA.db.profile
	local keys = { strsplit(".", path) }
	for i = 1, #keys - 1 do t = t[keys[i]] end
	return t, keys[#keys]
end
local function get(info)
	local t, k = resolve(info.arg)
	return t[k]
end
local function set(info, v)
	local t, k = resolve(info.arg)
	t[k] = v
	FA:Refresh()
end
local function getColor(info)
	local t, k = resolve(info.arg)
	return t[k][1], t[k][2], t[k][3]
end
local function setColor(info, r, g, b)
	local t, k = resolve(info.arg)
	t[k] = { r, g, b }
	FA:Refresh()
end
local function toggle(order, name, arg, desc, width)
	return { type = "toggle", order = order, name = name, desc = desc, arg = arg, get = get, set = set, width = width }
end
local function range(order, name, arg, min, max, step, extra)
	local o = { type = "range", order = order, name = name, arg = arg, min = min, max = max, step = step, get = get, set = set }
	if extra then for k, v in pairs(extra) do o[k] = v end end
	return o
end
local function color(order, name, arg, width)
	return { type = "color", order = order, name = name, arg = arg, get = getColor, set = setColor, width = width }
end
local function fonts() return LibStub("LibSharedMedia-3.0"):HashTable("font") end
local function bars() return LibStub("LibSharedMedia-3.0"):HashTable("statusbar") end

local options
local function Notify() AceConfigRegistry:NotifyChange("Sheepdog") end

-- Setup -----------------------------------------------------------------------------------

local C = { h = "|cff69ccf0", m = "|cff8d95a3", e = "|r" }
local INTRO = "One frame per enemy: health on top, power below, the portrait in the middle. The portrait gives way to " ..
	"whatever matters more: a breakable CC with a big countdown, then a cast with its bar, then a root or silence. " ..
	"The column on the right holds one diminishing-returns slot per category (green full, yellow half, orange quarter, " ..
	"red immune, number = seconds to reset) and the trinket, which flashes the whole frame when used.\n\n" ..
	"Click a frame to target it. Right-click Polymorph, middle-click Counterspell, Shift + right-click Frost Nova; " ..
	"change these under Click casting.\n\n" ..
	C.m .. "/sheep  ·  /sheep test [2-5]  ·  /sheep unlock  ·  /sheep lock  ·  /sheep reset  ·  /sheep debug" .. C.e

local function RestartTest()
	if FA.test then FA.TestMode:Disable(); FA.TestMode:Enable() end
end

local setup = {
	type = "group", name = "Setup", order = 1,
	args = {
		title = { type = "description", order = 0, fontSize = "large", name = C.h .. "Sheepdog Arena Frames" .. C.e .. "  " .. C.m .. "v" .. FA.VERSION .. C.e },
		map = { type = "description", order = 1, name = "", image = "Interface\\AddOns\\Sheepdog\\media\\anatomy", imageWidth = 512, imageHeight = 256 },
		intro = { type = "description", order = 2, fontSize = "medium", name = INTRO .. "\n" },
		test = {
			type = "execute", order = 10, width = 0.9,
			name = function() return FA.test and "Stop test mode" or "Start test mode" end,
			func = function() FA.TestMode:Toggle() end,
		},
		testCount = {
			type = "select", order = 11, name = "", width = 0.8,
			values = { [2] = "2 opponents", [3] = "3 opponents", [4] = "4 opponents", [5] = "5 opponents" },
			get = function() return FA.db.profile.testCount end,
			set = function(_, v) FA.db.profile.testCount = v; RestartTest(); FA:Refresh() end,
		},
		lock = {
			type = "execute", order = 12, width = 0.9,
			name = function() return FA.db.profile.locked and "Unlock and drag" or "Lock frames" end,
			func = function()
				FA.db.profile.locked = not FA.db.profile.locked
				FA.Frames:SetLocked(FA.db.profile.locked)
			end,
		},
		resetPos = {
			type = "execute", order = 13, name = "Reset position", width = 0.8,
			func = function()
				FA.db.profile.position = CopyTable(FA.defaults.profile.position)
				FA.Frames:LoadPosition()
			end,
		},
		size = range(20, "Size", "scale", 0.5, 2, 0.05, { isPercent = true, width = 1.5 }),
		growth = {
			type = "select", order = 21, name = "Grow", width = 1,
			values = { right = "Left to right", left = "Right to left", down = "Top to bottom", up = "Bottom to top" },
			arg = "growth", get = get, set = set,
		},
		spacing = range(22, "Spacing", "spacing", 0, 60, 1, { width = 1 }),
		advanced = {
			type = "group", inline = true, order = 90, name = "Advanced",
			args = {
				hideBlizzard = {
					type = "toggle", order = 1, name = "Hide Blizzard arena frames", width = 1.5,
					desc = "Turning this back on needs a reload.",
					get = function() return FA.db.profile.hideBlizzard end,
					set = function(_, v) FA.db.profile.hideBlizzard = v; if v then FA:HideBlizzardFrames() end end,
				},
				showInBattlegrounds = {
					type = "toggle", order = 2, name = "Show in battlegrounds", width = 1.5,
					desc = "Battlegrounds expose flag carriers as arena units. Off keeps the frames arena-only.",
					get = function() return FA.db.profile.showInBattlegrounds end,
					set = function(_, v) FA.db.profile.showInBattlegrounds = v; FA:UpdateUnitWatch() end,
				},
				previewCount = {
					type = "select", order = 3, name = "Drag box covers", width = 1,
					values = { [0] = "As many as test opponents", [1] = "1 frame", [2] = "2 frames", [3] = "3 frames", [4] = "4 frames", [5] = "5 frames" },
					arg = "previewCount", get = get, set = set,
				},
			},
		},
	},
}

-- Look ------------------------------------------------------------------------------------

local look = {
	type = "group", name = "Look", order = 2,
	args = {
		barsH = { type = "header", order = 1, name = "Bars" },
		barTexture = { type = "select", order = 2, name = "Texture", dialogControl = "LSM30_Statusbar", values = bars, arg = "frames.barTexture", get = get, set = set },
		barHeight = range(3, "Bar height", "frames.barHeight", 0.1, 0.3, 0.01, { isPercent = true, desc = "Health, power and the cast bar." }),
		healthText = {
			type = "select", order = 4, name = "Health text",
			values = { percent = "Percent", absolute = "Absolute", none = "None" },
			arg = "frames.healthText", get = get, set = set,
		},
		classColorHealth = toggle(5, "Class color on health", "frames.classColorHealth"),

		portraitH = { type = "header", order = 10, name = "Portrait" },
		portrait = {
			type = "select", order = 11, name = "Style",
			desc = "Unseen enemies (stealth) always fall back to the class icon.",
			values = { ["3d"] = "3D live model", ["2d"] = "2D face", class = "Class icon" },
			arg = "frames.portrait", get = get, set = set,
		},
		showName = toggle(12, "Show name", "frames.showName"),
		columnWidth = range(13, "Icon column width", "frames.columnWidth", 0.15, 0.3, 0.01, { isPercent = true }),

		textH = { type = "header", order = 20, name = "Text" },
		face = { type = "select", order = 21, name = "Font", dialogControl = "LSM30_Font", values = fonts, arg = "font.face", get = get, set = set },
		outline = {
			type = "select", order = 22, name = "Outline", width = 0.8,
			values = { NONE = "None", OUTLINE = "Outline", THICKOUTLINE = "Thick" },
			arg = "font.outline", get = get, set = set,
		},
		scale = range(23, "Text size", "font.scale", 0.7, 1.5, 0.05, { isPercent = true, desc = "One multiplier for every label and counter except the CC countdown." }),
		bigH = { type = "header", order = 30, name = "CC countdown" },
		bigFace = { type = "select", order = 31, name = "Font", dialogControl = "LSM30_Font", values = fonts, arg = "font.bigFace", get = get, set = set },
		big = range(32, "Size", "font.sizes.big", 10, 60, 1, { width = 1 }),
		bigColor = color(33, "Color", "font.bigColor", 0.6),

		advanced = {
			type = "group", inline = true, order = 90, name = "Advanced",
			args = {
				bigOutline = {
					type = "select", order = 1, name = "CC countdown outline", width = 1,
					values = { NONE = "None", OUTLINE = "Outline", THICKOUTLINE = "Thick" },
					arg = "font.bigOutline", get = get, set = set,
				},
				bar = range(10, "Health / power text", "font.sizes.bar", 6, 30, 1, { width = 1 }),
				name = range(11, "Name", "font.sizes.name", 6, 24, 1, { width = 1 }),
				castName = range(12, "Cast name", "font.sizes.castName", 6, 24, 1, { width = 1 }),
				castTime = range(13, "Cast time", "font.sizes.castTime", 6, 30, 1, { width = 1 }),
				ccName = range(14, "CC name", "font.sizes.ccName", 6, 24, 1, { width = 1 }),
				dr = range(15, "DR counter", "font.sizes.dr", 6, 24, 1, { width = 1 }),
				badge = range(16, "DR badge", "font.sizes.badge", 5, 20, 1, { width = 1 }),
				trinket = range(17, "Trinket counter", "font.sizes.trinket", 6, 24, 1, { width = 1 }),
			},
		},
	},
}

-- Tracking --------------------------------------------------------------------------------

local function SlotValues()
	local v = {}
	for cat, name in pairs(DRList:GetCategories()) do v[cat] = name end
	return v
end

local tracking = {
	type = "group", name = "Tracking", order = 3,
	args = {
		castH = { type = "header", order = 1, name = "Casts" },
		castEnabled = toggle(2, "Show casts", "cast.enabled", "Replace the portrait with the spell being cast.", 0.8),
		castStyle = {
			type = "select", order = 3, name = "", width = 1.4,
			values = { bar = "Icon with cast bar", iconbar = "Square icon, name and bar", reveal = "Icon revealed left to right" },
			arg = "cast.style", get = get, set = set,
		},
		castColor = color(4, "Cast", "cast.castColor", 0.5),
		channelColor = color(5, "Channel", "cast.channelColor", 0.5),
		uninterruptibleColor = color(6, "Shielded", "cast.uninterruptibleColor", 0.5),
		interruptColor = color(7, "Interrupted", "cast.interruptColor", 0.6),
		interruptFlash = toggle(8, "Flash on interrupt", "cast.interruptFlash", "A short red 'Interrupted' bar when a cast is kicked.", 1),

		ccH = { type = "header", order = 10, name = "Crowd control takes over the portrait for" },
		breakable = toggle(11, "Breakable CC", "cc.show.breakable", "Polymorph, Sap, Blind, fears, Cyclone. Beats an active cast.", 0.9),
		stuns = toggle(12, "Stuns", "cc.show.stuns", "Beats an active cast.", 0.7),
		roots = toggle(13, "Roots and silences", "cc.show.roots", "Shown only while the enemy is not casting.", 1),
		immunities = toggle(14, "Immunities", "cc.show.immunities", "Ice Block, Divine Shield, stealth, drinking. Beats an active cast.", 0.8),
		defensives = toggle(15, "Big defensives", "cc.show.defensives", "Shield Wall, Barkskin, Pain Suppression, offensive cooldowns.", 0.9),

		drH = { type = "header", order = 20, name = "Diminishing returns" },
		slots = {
			type = "multiselect", order = 21, name = "Slots", values = SlotValues,
			get = function(_, key) return tContains(FA.db.profile.dr.slots, key) end,
			set = function(_, key, v)
				local slots = FA.db.profile.dr.slots
				if v then
					if not tContains(slots, key) then table.insert(slots, key) end
				else
					for i = #slots, 1, -1 do if slots[i] == key then table.remove(slots, i) end end
				end
				FA:Refresh()
			end,
		},
		order = {
			type = "input", order = 22, name = "Order, top to bottom", width = 2,
			desc = "Category names separated by commas, as listed above (incapacitate, root, stun, fear ...).",
			get = function() return table.concat(FA.db.profile.dr.slots, ", ") end,
			set = function(_, v)
				local valid = DRList:GetCategories()
				local slots = {}
				for cat in v:gmatch("[^,%s]+") do
					cat = cat:lower()
					if valid[cat] and not tContains(slots, cat) then table.insert(slots, cat) end
				end
				FA.db.profile.dr.slots = slots
				FA:Refresh()
			end,
		},
		showReset = toggle(23, "Show seconds to reset", "dr.showReset", nil, 1.2),

		trinketH = { type = "header", order = 30, name = "Trinket" },
		flash = toggle(31, "Flash frame on use", "trinket.flash", nil, 1),
		flashColor = color(32, "", "trinket.flashColor", 0.4),
		flashDuration = range(33, "Flash duration", "trinket.flashDuration", 0.2, 2, 0.1, { width = 1 }),

		advanced = {
			type = "group", inline = true, order = 90, name = "Advanced",
			args = {
				timerStartAuraEnd = toggle(1, "DR window starts when the CC ends", "dr.timerStartAuraEnd", "Off: the window starts when the CC lands (TBC default).", 1.6),
				drEnabled = toggle(2, "Track diminishing returns", "dr.enabled", nil, 1.2),
				trinketEnabled = toggle(3, "Track trinkets", "trinket.enabled", nil, 1),
			},
		},
	},
}

-- Click casting ---------------------------------------------------------------------------

local clickcast = { type = "group", name = "Click casting", order = 4, args = {} }

local function BuildBindings()
	local CC = FA.ClickCast
	local bindings = FA.db.profile.clickcast.bindings
	local args = {
		help = {
			type = "description", order = 0, fontSize = "medium",
			name = "Modifier, mouse button, action. Spells are cast on the clicked enemy; in a macro %unit% becomes arena1, arena2 and so on. Changes apply out of combat.",
		},
		add = {
			type = "execute", order = 1000, name = "Add binding", width = 0.8,
			func = function()
				table.insert(bindings, { mod = "", button = 2, action = "none" })
				BuildBindings(); Notify()
			end,
		},
		defaults = {
			type = "execute", order = 1001, name = "Restore defaults", width = 0.9,
			func = function()
				FA.db.profile.clickcast.bindings = CopyTable(FA.defaults.profile.clickcast.bindings)
				CC:Apply(); BuildBindings(); Notify()
			end,
		},
	}
	for i, b in ipairs(bindings) do
		local function apply() CC:Apply(); Notify() end
		args["b" .. i] = {
			type = "group", inline = true, order = i, name = "",
			args = {
				mod = {
					type = "select", order = 1, name = "", width = 0.55, values = CC.MODS,
					get = function() return b.mod or "" end, set = function(_, v) b.mod = v; apply() end,
				},
				button = {
					type = "select", order = 2, name = "", width = 0.6, values = CC.BUTTONS,
					get = function() return b.button or 1 end, set = function(_, v) b.button = v; apply() end,
				},
				action = {
					type = "select", order = 3, name = "", width = 0.7, values = CC.ACTIONS,
					get = function() return b.action or "none" end, set = function(_, v) b.action = v; apply() end,
				},
				spell = {
					type = "input", order = 4, name = "", width = 0.9,
					hidden = function() return b.action ~= "spell" end,
					get = function() return b.spell or "" end, set = function(_, v) b.spell = v:trim(); apply() end,
				},
				remove = {
					type = "execute", order = 9, name = "Remove", width = 0.5,
					func = function() table.remove(bindings, i); CC:Apply(); BuildBindings(); Notify() end,
				},
				macro = {
					type = "input", order = 5, name = "Macro", multiline = 3, width = "full",
					hidden = function() return b.action ~= "macro" end,
					get = function() return b.macro or "" end, set = function(_, v) b.macro = v; apply() end,
				},
			},
		}
	end
	clickcast.args = args
end

-- Announce --------------------------------------------------------------------------------

local announce = {
	type = "group", name = "Announce", order = 5,
	args = {
		enabled = toggle(1, "Announce in chat", "announce.enabled", nil, 1),
		channel = {
			type = "select", order = 2, name = "", width = 1,
			values = { group = "Group (party or raid)", say = "Say", self = "Only me" },
			arg = "announce.channel", get = get, set = set,
		},
		onlyInArena = toggle(3, "Only in arena", "announce.onlyInArena", "Off: also in battlegrounds and the open world.", 0.8),
		h = { type = "header", order = 10, name = "What" },
		interrupts = toggle(11, "My interrupts", "announce.interrupts", "Interrupted Lightwell: Greater Heal", 0.9),
		cc = toggle(12, "My CC landing", "announce.cc", "Polymorph on Shivv (half). Your pet's Freeze counts.", 0.9),
		trinkets = toggle(13, "Enemy trinkets", "announce.trinkets", "Shivv used PvP Trinket", 0.9),
		help = { type = "description", order = 20, fontSize = "medium", name = "In test mode the lines print to your own chat frame so you can check the wording." },
	},
}

options = {
	type = "group", name = "Sheepdog", childGroups = "tab",
	args = { setup = setup, look = look, tracking = tracking, clickcast = clickcast, announce = announce },
}

function FA:SetupOptions()
	BuildBindings()
	options.args.profiles = AceDBOptions:GetOptionsTable(self.db)
	options.args.profiles.order = 100
	AceConfig:RegisterOptionsTable("Sheepdog", options)
	AceConfigDialog:AddToBlizOptions("Sheepdog", "Sheepdog")
	AceConfigDialog:SetDefaultSize("Sheepdog", 720, 600)
	self.db.RegisterCallback(self, "OnProfileChanged", function() BuildBindings(); Notify() end)
end
