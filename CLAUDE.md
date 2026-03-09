# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AutoSellPlus is a World of Warcraft addon (Lua 5.1) that shows a popup when visiting a merchant to review and sell junk items. It targets the Midnight expansion (Interface 120001), has zero external dependencies, and is distributed via CurseForge.

## Commands

```bash
# Lint (CI enforces zero warnings)
luacheck AutoSellPlus/

# Install to WoW AddOns folder (macOS)
./install.sh

# Test in-game: /reload then visit a merchant
# Slash commands: /asp, /autosellplus

# Release (maintainers only) — tag triggers CI build + upload
git tag v1.2.3 && git push origin v1.2.3
```

## Code Conventions

- **Lua 5.1 only** — WoW limitation, no later Lua features
- **Zero dependencies** — no external libraries
- **Namespace** — all code lives under the `ns` table passed by WoW's addon loader; no new globals
- **Naming** — `PascalCase` functions, `camelCase` locals, `UPPER_SNAKE` constants
- **Formatting** — 4 spaces, UTF-8, LF line endings (see `.editorconfig`)
- **New WoW API usage** — add the function to `read_globals` in `.luacheckrc`
- **New files** — add to `AutoSellPlus.toc` in the correct load order
- **Do not** bump the version in `.toc` — the packager replaces `@project-version@` from git tags

## Architecture

### Load Order (defined in AutoSellPlus.toc)

1. **Config.lua** — Default settings, `AutoSellPlusDB` saved variable initialization
2. **Helpers.lua** — Utility functions (item level calculation, transmog checks, equipment sets, money formatting)
3. **UI.lua** — Settings panel registered under Options > AddOns
4. **Popup.lua** — Merchant popup frame, quality/ilvl filters, item row rendering, sell action (most complex file, ~880 lines)
5. **Core.lua** — Event handling, sell queue processing, slash commands

### Data Flow

```
MERCHANT_SHOW event
  → ns:ShowPopup()         [Popup.lua] creates popup with smart ilvl defaults
  → ns:BuildDisplayList()  [Popup.lua] scans all vendorable bag items
  → ns:ApplyFilters()      [Popup.lua] marks items to auto-check by quality/ilvl/protections
  → User selects/deselects items in popup
  → ns:SellFromPopup()     [Popup.lua] builds sell queue from checked items
  → ns:StartSelling()      [Core.lua] initiates selling (or dry-run)
  → ns:ProcessNextBatch()  [Core.lua] sells 10 items per tick, 0.2s delay
  → ns:FinishSelling()     [Core.lua] prints summary
MERCHANT_CLOSED → stops selling
```

### Item Protection Priority (in ShouldSellItem)

1. Never-sell list (manual blacklist)
2. Always-sell list (manual whitelist)
3. Equipment set items (if enabled)
4. Uncollected transmog (if enabled)
5. Refundable items (purchase window active)
6. Quality/ilvl filters (user-configurable per visit)

## CI/CD

GitHub Actions (`.github/workflows/release.yml`) runs on push to `main` and version tags:
1. Runs luacheck (zero warnings required)
2. Packages with BigWigsMods/packager respecting `.pkgmeta`
3. Uploads to CurseForge (on tags)

Secrets: `CF_API_KEY`, `GITHUB_TOKEN` (needs read+write permissions).
