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

`/sheep` opens the panel. Six tabs; the rarely used knobs sit under "Advanced" at the bottom of each.

- **Setup**: the annotated frame picture, test mode and opponent count, unlock and drag, reset position, size, growth direction, spacing. Advanced: hide Blizzard arena frames, show in battlegrounds, drag box width.
- **Look**: bar texture and height, health text, class color, portrait style, name, icon column width, font and outline, one text size multiplier, and the CC countdown's own font, size and color. Advanced: per-text sizes, countdown outline.
- **Tracking**: casts (style, colors, interrupt flash), which auras take over the portrait (breakable CC, stuns, roots and silences, immunities, big defensives), diminishing-returns slots and their order, trinket flash. Advanced: DR window start, tracking on/off switches.
- **Click casting**: one row per binding: modifier, mouse button, action, spell or macro (`%unit%` in a macro becomes the clicked unit).
- **Announce**: post your interrupts, your CC landing (with its real duration and DR state) and enemy trinket uses to group chat, say, or only your own chat frame. Arena-only by default. Lines look like `Kicked Thrall (Greater Heal)`, `Polymorph on Thrall 5s (1/2)`, `Thrall used trinket`.
- **Profiles**: standard profiles.

## Notes

- Frames are secure unit buttons, so layout and binding changes made in combat apply when combat ends.
- Diminishing returns data comes from DRList-1.0.
- Every Man for Himself is not in TBC; the trinket table lists it for later expansions only.

Developer notes are in `DEVELOPMENT.md`.

## License

MIT. Embedded libraries keep their own licenses: Ace3 and LibSharedMedia (BSD), DRList-1.0 (MIT). The bundled Oswald font is SIL OFL.

The CC countdown defaults to the FORCED SQUARE font, which Details and several SharedMedia packs provide. Without it the countdown uses Oswald.
