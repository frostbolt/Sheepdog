# Sheepdog Arena Frames

Enemy arena frames for World of Warcraft TBC Anniversary, built around what a mage needs to see: who is casting, who is sitting in CC and for how long, which CC is still safe to use, and whose trinket is down. Other classes work too; the defaults are just tuned for a mage.

## What you see

Each enemy gets a square frame:

- **Health bar** on top, class colored, with the percent.
- **Portrait** in the middle, a live 3D model. It is replaced by whatever matters more: a breakable CC (Polymorph, Sap, fear, stun) shows its icon with a big red countdown; an active cast shows the spell icon with a cast bar; a root or silence shows below those.
- **Power bar** on the bottom: mana, rage or energy.
- **Diminishing returns** in the column on the right, one slot per category. Green border: a fresh CC lasts full duration. Yellow: half. Orange: quarter. Red: immune. The number is seconds until the category resets.
- **Trinket** at the bottom of the column. When the enemy uses the PvP trinket or Will of the Forsaken the whole frame flashes and the slot counts down the cooldown.

Click casting is built in: left click targets, right click casts Polymorph, middle click Counterspell, Shift + right click Frost Nova. Every binding is editable.

## Install

From CurseForge, or copy the `Sheepdog` folder into `World of Warcraft/_anniversary_/Interface/AddOns/`.

## Commands

| Command | What it does |
| --- | --- |
| `/sheep` | Open the settings panel (also `/sheepdog`) |
| `/sheep test` | Toggle test mode with fake opponents |
| `/sheep test 5` | Test mode with 2 to 5 opponents |
| `/sheep unlock` / `/sheep lock` | Show or hide the drag box |
| `/sheep reset` | Reset the position |
| `/sheep debug` | Print status for bug reports |

## Settings

The panel opens on a Welcome tab with an annotated picture of the frame. The other tabs:

- **Layout**: lock, test mode, scale, frame size, growth direction, spacing.
- **Bars & portrait**: class color, percent or absolute health, name, bar texture, portrait style (3D, 2D, class icon), bar heights, column width.
- **Cast & CC**: cast style, bar height and colors, the interrupt flash, which auras take over the portrait, and the priority at which an aura beats a cast.
- **Diminishing returns**: which categories get a slot and in what order, reset countdown, when the reset window starts.
- **Trinket**: tracking, flash, flash color and duration.
- **Click casting**: any number of bindings mapping a modifier plus mouse button to target, focus, a spell or a macro (`%unit%` in a macro becomes the clicked unit).
- **Fonts**: font face, outline and size for every text; the CC countdown has its own.
- **Misc**: hide the default Blizzard arena frames.
- **Profiles**: standard profiles.

## Notes

- Frames are secure unit buttons, so layout and binding changes made in combat apply when combat ends.
- Diminishing returns data comes from DRList-1.0.
- Every Man for Himself is not in TBC; the trinket table lists it for later expansions only.

Developer notes are in `DEVELOPMENT.md`.

## License

MIT. Embedded libraries keep their own licenses: Ace3 and LibSharedMedia (BSD), DRList-1.0 (MIT). The bundled Oswald font is SIL OFL.

The CC countdown defaults to the FORCED SQUARE font, which Details and several SharedMedia packs provide. Without it the countdown uses Oswald.
