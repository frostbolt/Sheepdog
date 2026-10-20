# Publishing to CurseForge

One-time setup, then every release is a git tag.

## 1. Create the project

1. https://www.curseforge.com/wow/create-project (sign in as the account that will own it).
2. Name: **Sheepdog Arena Frames**. Category: PvP (also Unit Frames). License: MIT.
3. Game versions: WoW Classic, TBC Anniversary (2.5.6).
4. Upload `curseforge/icon-512.png` as the project avatar.
5. Paste `curseforge/description.md` into the description. CurseForge accepts Markdown in the editor.
6. Note the **Project ID** on the project's overview page.

## 2. Wire the repo to it

1. Add `## X-Curse-Project-ID: <id>` to both `Sheepdog.toc` and `Sheepdog_TBC.toc`.
2. CurseForge account > My API Tokens > create a token.
3. GitHub repo > Settings > Secrets and variables > Actions > New repository secret: `CF_API_KEY` = the token.

## 3. Screenshots

CurseForge wants at least one. Suggested set, 1920x1080 or a clean crop:

- `/sheep test 3` with the frames over an arena background, one enemy sheeped (big countdown visible), one casting.
- The DR column with a yellow and a red border.
- The settings panel on the Welcome tab.
- The Click casting tab.

Take them in game with the default UI hidden (Alt+Z) and the frames at scale 1.2 or higher so the text reads at thumbnail size.

## 4. Release

```bash
git tag v0.1.0
git push origin v0.1.0
```

The GitHub Action builds the zip with the BigWigs packager (excluding `tools`, `curseforge`, `.github`), attaches it to a GitHub release, and uploads it to CurseForge with the changelog from `CHANGELOG.md`. The first upload shows up in the project's Files tab for review.

Bump `## Version` in both TOCs and add a `CHANGELOG.md` entry before each tag.
