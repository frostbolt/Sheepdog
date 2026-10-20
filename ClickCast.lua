-- Click casting: bindings from the profile become secure attributes on each unit button.
-- Attributes can only change out of combat; changes made mid-fight apply when it ends.
local _, ns = ...
local FA = ns.FA
local ClickCast = FA:AddModule("ClickCast")
FA.ClickCast = ClickCast

ClickCast.ACTIONS = { target = "Target", focus = "Focus", spell = "Cast spell", macro = "Run macro", none = "Nothing" }
ClickCast.MODS = { [""] = "None", shift = "Shift", ctrl = "Ctrl", alt = "Alt" }
ClickCast.BUTTONS = { [1] = "Left", [2] = "Right", [3] = "Middle", [4] = "Button 4", [5] = "Button 5" }

function ClickCast:Describe(b)
	local mod = (b.mod and b.mod ~= "") and (self.MODS[b.mod] .. " + ") or ""
	local what = self.ACTIONS[b.action] or "?"
	if b.action == "spell" then what = b.spell and b.spell ~= "" and b.spell or "(no spell)" end
	if b.action == "macro" then what = "macro" end
	return mod .. (self.BUTTONS[b.button] or "?") .. " click: " .. what
end

function ClickCast:Apply()
	if InCombatLockdown() then
		self.pending = true
		return
	end
	self.pending = nil
	local bindings = FA.db.profile.clickcast.bindings
	for _, f in ipairs(FA.frameList) do
		if f.appliedAttrs then
			for _, k in ipairs(f.appliedAttrs) do f:SetAttribute(k, nil) end
		end
		f.appliedAttrs = {}
		for _, b in ipairs(bindings) do
			local prefix = (b.mod and b.mod ~= "") and (b.mod .. "-") or ""
			local n = tostring(b.button or 1)
			local function set(key, value)
				local attr = prefix .. key .. n
				f:SetAttribute(attr, value)
				table.insert(f.appliedAttrs, attr)
			end
			if b.action == "target" then
				set("type", "target")
			elseif b.action == "focus" then
				set("type", "focus")
			elseif b.action == "spell" and b.spell and b.spell ~= "" then
				set("type", "spell")
				set("spell", b.spell)
			elseif b.action == "macro" and b.macro and b.macro ~= "" then
				set("type", "macro")
				set("macrotext", (b.macro:gsub("%%unit%%", f.unit)))
			end
		end
	end
end

function ClickCast:ApplyPending()
	if self.pending then self:Apply() end
end

function ClickCast:OnEnable() self:Apply() end
function ClickCast:Refresh() self:Apply() end
