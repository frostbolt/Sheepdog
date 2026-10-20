# Sheepdog Arena Frames

Enemy arena frames for World of Warcraft TBC Anniversary (interface 20506), built around what a mage needs to see.

Each enemy gets a square frame: class-colored health bar on top, power bar on the bottom, portrait in the middle. The portrait is replaced by the spell the enemy is casting (icon plus a left-to-right reveal) or by the CC they are sitting in (icon plus a big red countdown). The column on the right holds one diminishing-returns slot per category and the trinket slot. The whole frame flashes when the enemy uses a PvP trinket or Will of the Forsaken.

Design sketch: https://claude.ai/artifact/LfqSdFrz8aacZyFya3DdQY

## Install

Symlink or copy this folder into the AddOns directory of the anniversary client:

```bash
ln -s /Users/frostbolt/repos/Sheepdog "/Applications/World of Warcraft/_anniversary_/Interface/AddOns/Sheepdog"
```

Reload the UI (`/reload`) after changing files.

## Commands

| Command | What it does |
| --- | --- |
| `/sheep` | Open the settings panel |
| `/sheep test` | Toggle test mode: fake opponents cast, get CC'd and trinket on a 24 s loop |
| `/sheep test 5` | Test mode with a given number of opponents, 2 to 5 |
| `/sheep unlock` / `/sheep lock` | Show or hide the drag box |
| `/sheep reset` | Reset the position |
| `/sheep debug` | Print expansion detection, arena state and per-unit status |

## Settings

- **Layout**: lock, test mode, scale, frame size, growth direction (left to right, right to left, top to bottom, bottom to top), spacing.
- **Bars & portrait**: class color, percent or absolute health, name, bar texture (any LibSharedMedia statusbar; Minimalist ships with the addon), portrait style (3D live model, 2D face, class icon), bar heights, icon column width. Unseen enemies always fall back to the class icon; in test mode the 3D portrait shows your own character.
- **Cast & CC**: cast style (icon with a cast bar along the bottom, square icon with name and bar, or the icon revealed left to right), bar height, colors for casts, channels, uninterruptible casts and the short red "Interrupted" flash; toggles for CC, immunities and big defensives; the priority at which an aura beats an active cast. Silences (Counterspell, Silence, Silencing Shot, Spell Lock, Arcane Torrent, Garrote) show in the overlay like roots do.
- **Fonts**: font face from LibSharedMedia, outline style, and a point size for each text (bar text, name, cast name, cast time, CC name, DR counter, DR badge, trinket counter). The big CC countdown has its own font, outline, size and color. Sizes are defined at frame size 120 and scale with the frame.
- **Diminishing returns**: which DRList categories get a slot and in what order, reset countdown, whether the reset window starts on application or on removal.
- **Trinket**: tracking, flash, flash color and duration.
- **Click casting**: any number of bindings, each a modifier plus a mouse button mapped to target, focus, a spell or a macro. `%unit%` in a macro becomes the clicked frame's unit.
- **Misc**: hiding the default Blizzard arena frames (on by default; the addon buries whichever set the client has, `ArenaEnemyFrames` or `CompactArenaFrame`, out of combat).
- **Profiles**: standard AceDB profiles.

## How it works

| File | Role |
| --- | --- |
| `tools/anatomy.py` | Renders `media/anatomy.tga`, the annotated frame on the Welcome tab (needs Pillow) |
| `Core.lua` | Addon object, defaults, module registry, arena and unit lifecycle, slash commands, combat-log fan-out |
| `Data.lua` | Aura priority table (TBC spell IDs), trinket spells, DR slot icons, growth anchors, colors |
| `Units.lua` | `FA.U`: every read of a unit goes through here so test mode can substitute fake data |
| `Frames.lua` | Anchor box, secure unit buttons, bars, portrait, layout, icon slot factory |
| `CastCC.lua` | Portrait takeover for casts and CC |
| `DR.lua` | DR tracking from `COMBAT_LOG_EVENT_UNFILTERED` with DRList-1.0 |
| `Trinket.lua` | Trinket cooldown slot and the frame flash |
| `ClickCast.lua` | Bindings to secure attributes (`type2`, `spell2`, `shift-type2`, ...) |
| `TestMode.lua` | Fake opponents and a scripted loop |
| `Options.lua` | AceConfig settings panel |

Modules are plain tables registered with `FA:AddModule`. Core calls hooks such as `OnFrameCreated`, `OnLayout`, `OnUnitUpdate`, `OnUnitEvent`, `OnUnitReset` and `OnCombatLog` on each module in load order.

Frames are `SecureUnitButtonTemplate` buttons, so layout and click-cast attributes only change out of combat. Changes made in combat are queued and applied on `PLAYER_REGEN_ENABLED`.

## Smoke test outside the game

```bash
luajit tools/smoke.lua
```

Stubs the WoW API, loads the files in TOC order, enables the addon, runs test mode for a simulated 30 s, feeds combat-log events, and walks every option. It catches load-order and nil errors, not visual problems.

## Things to verify in game

- `/sheep debug` should print `expansion=tbc`. If DRList reports something else, the anniversary client uses an unexpected `WOW_PROJECT_ID` and the DR tables need a mapping.
- Trinket cooldowns in `Data.lua` are set to 2 minutes for the Medallion and Will of the Forsaken.
- `UNIT_SPELLCAST_SUCCEEDED` on arena units is the primary trinket source; the combat log is the fallback.

## Libraries

Ace3 (AceAddon, AceEvent, AceConsole, AceDB, AceDBOptions, AceGUI, AceConfig), AceGUI-3.0-SharedMediaWidgets, LibSharedMedia-3.0, CallbackHandler-1.0, LibStub, DRList-1.0. All embedded under `Libs/`.
