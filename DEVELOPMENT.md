# Development

## Layout of the code

| File | Role |
| --- | --- |
| `Core.lua` | Addon object, defaults, module registry, arena and unit lifecycle, slash commands, combat-log fan-out, Blizzard frame hiding |
| `Data.lua` | Aura priority table (TBC spell IDs), trinket spells, DR slot icons, growth anchors, colors, texture crop helper |
| `Units.lua` | `FA.U`: every read of a unit goes through here so test mode can substitute fake data |
| `Frames.lua` | Anchor box, secure unit buttons, bars, portrait, layout, fonts, icon slot factory |
| `CastCC.lua` | Portrait takeover for casts and CC |
| `DR.lua` | DR tracking from `COMBAT_LOG_EVENT_UNFILTERED` with DRList-1.0 |
| `Trinket.lua` | Trinket cooldown slot and the frame flash |
| `ClickCast.lua` | Bindings to secure attributes (`type2`, `spell2`, `shift-type2`, ...) |
| `TestMode.lua` | Fake opponents and a scripted loop |
| `Options.lua` | AceConfig settings panel, Welcome tab |
| `tools/smoke.lua` | Stub-API smoke test |
| `tools/anatomy.py` | Renders `media/anatomy.tga` for the Welcome tab (needs Pillow) |
| `tools/icon.py` | Renders `media/icon.tga` and the CurseForge icon PNGs (needs Pillow) |

Modules are plain tables registered with `FA:AddModule`. Core calls hooks such as `OnFrameCreated`, `OnLayout`, `OnUnitUpdate`, `OnUnitEvent`, `OnUnitReset` and `OnCombatLog` on each module in load order.

## Local setup

Symlink the checkout into the client:

```bash
ln -s "$PWD" "/Applications/World of Warcraft/_anniversary_/Interface/AddOns/Sheepdog"
```

`/reload` after changing files. `/sheep test 5` shows the frames outside an arena.

## Smoke test

```bash
luajit tools/smoke.lua
```

Stubs the WoW API, loads the files in TOC order, enables the addon, runs test mode for a simulated 30 s, feeds combat-log events and walks every option. It catches load-order and nil errors, not visual problems.

## Release

Releases are built by the BigWigs packager through GitHub Actions on every `v*` tag and uploaded to CurseForge. See `curseforge/PUBLISHING.md` for the one-time setup.

```bash
git tag v0.1.0 && git push origin v0.1.0
```

Update `## Version` in both TOC files and `CHANGELOG.md` before tagging.
