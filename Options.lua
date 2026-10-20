-- Settings panel (AceConfig). /sheep opens it; it also lives under Interface > AddOns > Sheepdog.
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

local options

local function Notify()
	AceConfigRegistry:NotifyChange("Sheepdog")
end

local function BuildBindings()
	local CC = FA.ClickCast
	local bindings = FA.db.profile.clickcast.bindings
	local args = {
		help = {
			type = "description", order = 0, fontSize = "medium",
			name = "Each binding is one mouse button plus an optional modifier. Spells are cast on the clicked enemy. " ..
				"In a macro, %unit% is replaced with arena1, arena2 and so on. Changes apply when you are out of combat.",
		},
		add = {
			type = "execute", order = 1000, name = "Add binding",
			func = function()
				table.insert(bindings, { mod = "", button = 2, action = "none" })
				BuildBindings()
				Notify()
			end,
		},
	}
	for i, b in ipairs(bindings) do
		args["b" .. i] = {
			type = "group", inline = true, order = i,
			name = function() return CC:Describe(b) end,
			args = {
				mod = {
					type = "select", order = 1, name = "Modifier", values = CC.MODS,
					get = function() return b.mod or "" end,
					set = function(_, v) b.mod = v; CC:Apply(); Notify() end,
				},
				button = {
					type = "select", order = 2, name = "Button", values = CC.BUTTONS,
					get = function() return b.button or 1 end,
					set = function(_, v) b.button = v; CC:Apply(); Notify() end,
				},
				action = {
					type = "select", order = 3, name = "Action", values = CC.ACTIONS,
					get = function() return b.action or "none" end,
					set = function(_, v) b.action = v; CC:Apply(); Notify() end,
				},
				spell = {
					type = "input", order = 4, name = "Spell name",
					hidden = function() return b.action ~= "spell" end,
					get = function() return b.spell or "" end,
					set = function(_, v) b.spell = v:trim(); CC:Apply(); Notify() end,
				},
				macro = {
					type = "input", order = 5, name = "Macro text", multiline = 3, width = "full",
					hidden = function() return b.action ~= "macro" end,
					get = function() return b.macro or "" end,
					set = function(_, v) b.macro = v; CC:Apply(); Notify() end,
				},
				remove = {
					type = "execute", order = 9, name = "Remove", width = "half",
					func = function()
						table.remove(bindings, i)
						CC:Apply()
						BuildBindings()
						Notify()
					end,
				},
			},
		}
	end
	options.args.clickcast.args = args
end

local function DRSlotValues()
	local v = {}
	for cat, name in pairs(DRList:GetCategories()) do v[cat] = name end
	return v
end

local C = {
	h = "|cff69ccf0", g = "|cff3ddc6a", y = "|cfff5c542", o = "|cffff8a3d", r = "|cffff3b3b", m = "|cff8d95a3", e = "|r",
}

local WELCOME = {
	intro = "Sheepdog shows one square frame per enemy, built around what a mage needs to see: who is casting, who is sitting in CC and for how long, which CC is still safe to use, and whose trinket is down. Click a frame to target it; right-click casts Polymorph, middle-click Counterspell, Shift + right-click Frost Nova (all changeable under Click casting).",
	anatomy = C.h .. "Frame anatomy" .. C.e .. "\n\n" ..
		C.h .. "1  Health bar (top)" .. C.e .. "\nClass colored, lifted toward white so the dark percent stays readable.\n\n" ..
		C.h .. "2  Portrait (middle)" .. C.e .. "\nThe live 3D model by default. It is replaced by whatever matters more, in this order: a breakable CC (Polymorph, Sap, fear, stun) with a big red countdown; then an active cast with its icon and a cast bar; then a root or silence; then the portrait again. A rooted enemy who starts casting shows the cast.\n\n" ..
		C.h .. "3  Power bar (bottom)" .. C.e .. "\nMana blue, rage red, energy yellow. For a healer this is the number you watch.\n\n" ..
		C.h .. "4  Diminishing returns (right column)" .. C.e .. "\nOne slot per category, top to bottom: incapacitate (Polymorph), stun, root (Frost Nova), fear by default. The border is the answer to \"can I CC this now?\":\n" ..
		"   " .. C.g .. "green" .. C.e .. "   no DR, a fresh CC lasts full duration\n" ..
		"   " .. C.y .. "yellow" .. C.e .. "  applied once, the next one lasts half\n" ..
		"   " .. C.o .. "orange" .. C.e .. "  applied twice, the next one lasts a quarter\n" ..
		"   " .. C.r .. "red" .. C.e .. "     immune until the category resets\n" ..
		"The number is seconds until that category resets (20 s in TBC). The small badge shows the same as a fraction.\n\n" ..
		C.h .. "5  Trinket (bottom of the column)" .. C.e .. "\nBright with a green border while the PvP trinket is available. When the enemy uses it or Will of the Forsaken, the whole frame flashes, the icon dims, and the countdown shows when it is back.",
	tips = C.h .. "Getting started" .. C.e .. "\n\n" ..
		"Use the buttons below to see the frames with fake opponents and to drag them into place. " ..
		"Everything else is in the tabs: Layout for size and growth direction, Fonts for every text, Click casting for your mouse bindings.\n\n" ..
		C.m .. "Commands: /sheep, /sheep test [2-5], /sheep lock, /sheep unlock, /sheep reset, /sheep debug" .. C.e,
}

options = {
	type = "group", name = "Sheepdog", childGroups = "tab",
	args = {
		welcome = {
			type = "group", name = "Welcome", order = 0,
			args = {
				title = { type = "description", order = 1, fontSize = "large", name = C.h .. "Sheepdog Arena Frames" .. C.e .. "  " .. C.m .. "v" .. FA.VERSION .. C.e .. "\n" },
				intro = { type = "description", order = 2, fontSize = "medium", name = WELCOME.intro .. "\n" },
				map = {
					type = "description", order = 2.5, name = "",
					image = "Interface\\AddOns\\Sheepdog\\media\\anatomy", imageWidth = 512, imageHeight = 256,
				},
				anatomy = { type = "description", order = 3, fontSize = "medium", name = WELCOME.anatomy .. "\n" },
				tips = { type = "description", order = 4, fontSize = "medium", name = WELCOME.tips .. "\n" },
				test = {
					type = "execute", order = 10, name = function() return FA.test and "Stop test mode" or "Start test mode" end,
					func = function() FA.TestMode:Toggle() end,
				},
				lock = {
					type = "execute", order = 11, name = function() return FA.db.profile.locked and "Unlock frames" or "Lock frames" end,
					func = function()
						FA.db.profile.locked = not FA.db.profile.locked
						FA.Frames:SetLocked(FA.db.profile.locked)
					end,
				},
			},
		},
		layout = {
			type = "group", name = "Layout", order = 1,
			args = {
				locked = {
					type = "toggle", order = 1, name = "Lock frames",
					desc = "Unlocked frames show a drag box. Drag it anywhere, then lock again.",
					get = function() return FA.db.profile.locked end,
					set = function(_, v) FA.db.profile.locked = v; FA.Frames:SetLocked(v) end,
				},
				test = {
					type = "toggle", order = 2, name = "Test mode",
					desc = "Show fake opponents that cast, get CC'd and trinket on a loop.",
					get = function() return FA.test end,
					set = function() FA.TestMode:Toggle() end,
				},
				testCount = {
					type = "range", order = 2.5, name = "Test opponents", desc = "2v2 up to 5v5. Restarts test mode if it is running.",
					min = 2, max = 5, step = 1,
					get = function() return FA.db.profile.testCount end,
					set = function(_, v)
						FA.db.profile.testCount = v
						if FA.test then FA.TestMode:Disable(); FA.TestMode:Enable() end
					end,
				},
				resetPos = {
					type = "execute", order = 3, name = "Reset position",
					func = function()
						FA.db.profile.position = CopyTable(FA.defaults.profile.position)
						FA.Frames:LoadPosition()
					end,
				},
				h1 = { type = "header", order = 10, name = "Size" },
				scale = { type = "range", order = 11, name = "Scale", min = 0.5, max = 2, step = 0.05, isPercent = true, arg = "scale", get = get, set = set },
				size = { type = "range", order = 12, name = "Frame size", desc = "Edge length of one frame before scaling.", min = 80, max = 240, step = 2, arg = "size", get = get, set = set },
				h2 = { type = "header", order = 20, name = "Growth" },
				growth = {
					type = "select", order = 21, name = "Grow",
					values = { right = "Left to right", left = "Right to left", down = "Top to bottom", up = "Bottom to top" },
					arg = "growth", get = get, set = set,
				},
				spacing = { type = "range", order = 22, name = "Spacing", min = 0, max = 60, step = 1, arg = "spacing", get = get, set = set },
				previewCount = { type = "range", order = 23, name = "Drag box covers", desc = "How many frames the unlock box spans.", min = 1, max = 5, step = 1, arg = "previewCount", get = get, set = set },
			},
		},
		bars = {
			type = "group", name = "Bars & portrait", order = 2,
			args = {
				classColorHealth = { type = "toggle", order = 1, name = "Class-colored health", arg = "frames.classColorHealth", get = get, set = set },
				showPercent = { type = "toggle", order = 2, name = "Health as percent", arg = "frames.showPercent", get = get, set = set },
				showName = { type = "toggle", order = 3, name = "Show name", arg = "frames.showName", get = get, set = set },
				barTexture = {
					type = "select", order = 3.5, name = "Bar texture", dialogControl = "LSM30_Statusbar",
					values = function() return LibStub("LibSharedMedia-3.0"):HashTable("statusbar") end,
					arg = "frames.barTexture", get = get, set = set,
				},
				portrait = {
					type = "select", order = 4, name = "Portrait",
					desc = "3D is the live animated model. Unseen enemies (stealth) always fall back to the class icon.",
					values = { ["3d"] = "3D live model", ["2d"] = "2D face", class = "Class icon" },
					arg = "frames.portrait", get = get, set = set,
				},
				hpHeight = { type = "range", order = 10, name = "Health bar height", min = 0.1, max = 0.3, step = 0.01, isPercent = true, arg = "frames.hpHeight", get = get, set = set },
				powerHeight = { type = "range", order = 11, name = "Power bar height", min = 0.1, max = 0.3, step = 0.01, isPercent = true, arg = "frames.powerHeight", get = get, set = set },
				columnWidth = { type = "range", order = 12, name = "Icon column width", min = 0.15, max = 0.3, step = 0.01, isPercent = true, arg = "frames.columnWidth", get = get, set = set },
			},
		},
		cc = {
			type = "group", name = "Cast & CC", order = 3,
			args = {
				cast = { type = "toggle", order = 1, name = "Show casts", desc = "Replace the portrait with the spell being cast.", arg = "cast.enabled", get = get, set = set },
				castStyle = {
					type = "select", order = 1.1, name = "Cast style",
					values = { bar = "Icon with cast bar", iconbar = "Square icon, name and bar", reveal = "Icon revealed left to right" },
					arg = "cast.style", get = get, set = set,
				},
				barHeight = { type = "range", order = 1.2, name = "Cast bar height", min = 0.08, max = 0.3, step = 0.01, isPercent = true, arg = "cast.barHeight", get = get, set = set },
				castColor = { type = "color", order = 1.3, name = "Cast color", arg = "cast.castColor", get = getColor, set = setColor },
				channelColor = { type = "color", order = 1.4, name = "Channel color", arg = "cast.channelColor", get = getColor, set = setColor },
				uninterruptibleColor = { type = "color", order = 1.5, name = "Uninterruptible color", arg = "cast.uninterruptibleColor", get = getColor, set = setColor },
				interruptFlash = { type = "toggle", order = 1.6, name = "Flash on interrupt", desc = "Show a red 'Interrupted' bar for a moment when a cast is kicked.", arg = "cast.interruptFlash", get = get, set = set },
				interruptColor = { type = "color", order = 1.7, name = "Interrupt color", arg = "cast.interruptColor", get = getColor, set = setColor },
				sep = { type = "header", order = 1.9, name = "Crowd control" },
				cc = { type = "toggle", order = 2, name = "Show CC", desc = "Replace the portrait with the active CC and a countdown.", arg = "cc.enabled", get = get, set = set },
				showImmunities = { type = "toggle", order = 3, name = "Show immunities", desc = "Ice Block, Divine Shield, stealth, drinking and the like.", arg = "cc.showImmunities", get = get, set = set },
				showDefensives = { type = "toggle", order = 4, name = "Show big defensives", desc = "Shield Wall, Barkskin, Pain Suppression, offensive cooldowns.", arg = "cc.showDefensives", get = get, set = set },
				hardPriority = {
					type = "range", order = 11, name = "CC beats cast at priority", min = 5, max = 10, step = 0.5,
					desc = "Auras with at least this priority show over an active cast. 9 = breakable CC, 8 = stuns, 7 = immunities, 5 = roots and silences.",
					arg = "cc.hardPriority", get = get, set = set,
				},
			},
		},
		dr = {
			type = "group", name = "Diminishing returns", order = 4,
			args = {
				enabled = { type = "toggle", order = 1, name = "Track DR", arg = "dr.enabled", get = get, set = set },
				showReset = { type = "toggle", order = 2, name = "Show seconds to reset", arg = "dr.showReset", get = get, set = set },
				timerStartAuraEnd = { type = "toggle", order = 3, name = "Reset window starts when the CC ends", desc = "Off: the window starts when the CC lands (Diminish default for TBC).", arg = "dr.timerStartAuraEnd", get = get, set = set },
				slots = {
					type = "multiselect", order = 10, name = "Categories shown, top to bottom", values = DRSlotValues,
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
				legend = {
					type = "description", order = 20, fontSize = "medium",
					name = "Border: green = full duration next, yellow = half, orange = quarter, red = immune. The number is seconds until the category resets (20 s in TBC).",
				},
			},
		},
		trinket = {
			type = "group", name = "Trinket", order = 5,
			args = {
				enabled = { type = "toggle", order = 1, name = "Track trinket", desc = "PvP trinket and Will of the Forsaken.", arg = "trinket.enabled", get = get, set = set },
				flash = { type = "toggle", order = 2, name = "Flash frame on use", arg = "trinket.flash", get = get, set = set },
				flashColor = { type = "color", order = 3, name = "Flash color", arg = "trinket.flashColor", get = getColor, set = setColor },
				flashDuration = { type = "range", order = 4, name = "Flash duration", min = 0.2, max = 2, step = 0.1, arg = "trinket.flashDuration", get = get, set = set },
			},
		},
		clickcast = {
			type = "group", name = "Click casting", order = 6,
			args = {},
		},
		fonts = {
			type = "group", name = "Fonts", order = 6.5,
			args = {
				face = {
					type = "select", order = 1, name = "Font", dialogControl = "LSM30_Font",
					values = function() return LibStub("LibSharedMedia-3.0"):HashTable("font") end,
					arg = "font.face", get = get, set = set,
				},
				outline = {
					type = "select", order = 2, name = "Outline",
					values = { NONE = "None", OUTLINE = "Outline", THICKOUTLINE = "Thick outline" },
					arg = "font.outline", get = get, set = set,
				},
				help = { type = "description", order = 3, fontSize = "medium", name = "Sizes are in points at frame size 120 and scale with the frame size and the overall scale." },
				bar = { type = "range", order = 10, name = "Health / power text", min = 6, max = 30, step = 1, arg = "font.sizes.bar", get = get, set = set },
				name = { type = "range", order = 11, name = "Name", min = 6, max = 24, step = 1, arg = "font.sizes.name", get = get, set = set },
				castName = { type = "range", order = 12, name = "Cast spell name", min = 6, max = 24, step = 1, arg = "font.sizes.castName", get = get, set = set },
				castTime = { type = "range", order = 13, name = "Cast time left", min = 6, max = 30, step = 1, arg = "font.sizes.castTime", get = get, set = set },
				ccHeader = { type = "header", order = 30, name = "CC countdown" },
				bigFace = {
					type = "select", order = 31, name = "Countdown font", dialogControl = "LSM30_Font",
					values = function() return LibStub("LibSharedMedia-3.0"):HashTable("font") end,
					arg = "font.bigFace", get = get, set = set,
				},
				bigOutline = {
					type = "select", order = 32, name = "Countdown outline",
					values = { NONE = "None", OUTLINE = "Outline", THICKOUTLINE = "Thick outline" },
					arg = "font.bigOutline", get = get, set = set,
				},
				big = { type = "range", order = 33, name = "Countdown size", min = 10, max = 60, step = 1, arg = "font.sizes.big", get = get, set = set },
				bigColor = { type = "color", order = 34, name = "Countdown color", arg = "font.bigColor", get = getColor, set = setColor },
				ccName = { type = "range", order = 15, name = "CC name", min = 6, max = 24, step = 1, arg = "font.sizes.ccName", get = get, set = set },
				dr = { type = "range", order = 16, name = "DR reset counter", min = 6, max = 24, step = 1, arg = "font.sizes.dr", get = get, set = set },
				badge = { type = "range", order = 17, name = "DR badge (½ ¼ X)", min = 5, max = 20, step = 1, arg = "font.sizes.badge", get = get, set = set },
				trinket = { type = "range", order = 18, name = "Trinket countdown", min = 6, max = 24, step = 1, arg = "font.sizes.trinket", get = get, set = set },
			},
		},
		misc = {
			type = "group", name = "Misc", order = 7,
			args = {
				hideBlizzard = {
					type = "toggle", order = 2, name = "Hide Blizzard arena frames", width = "full",
					desc = "Hides the default enemy arena frames. Turning this back on needs a reload.",
					get = function() return FA.db.profile.hideBlizzard end,
					set = function(_, v)
						FA.db.profile.hideBlizzard = v
						if v then FA:HideBlizzardFrames() end
					end,
				},
			},
		},
	},
}

function FA:SetupOptions()
	BuildBindings()
	options.args.profiles = AceDBOptions:GetOptionsTable(self.db)
	options.args.profiles.order = 100
	AceConfig:RegisterOptionsTable("Sheepdog", options)
	AceConfigDialog:AddToBlizOptions("Sheepdog", "Sheepdog")
	AceConfigDialog:SetDefaultSize("Sheepdog", 720, 560)
	self.db.RegisterCallback(self, "OnProfileChanged", function() BuildBindings(); Notify() end)
end
