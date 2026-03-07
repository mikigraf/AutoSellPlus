<a id="readme-top"></a>

<br>

<p align="center">
  <img src="assets/icon.png" alt="AutoSellPlus" width="128">
</p>

<h1 align="center">AutoSellPlus</h1>

<p align="center">
  <b>Smart junk selling with transmog protection, bag eviction, and cross-alt profiles.</b><br>
  <sub>A World of Warcraft addon for Retail (Midnight)</sub>
</p>

<br>

<p align="center">
  <a href="#quick-start">Quick Start</a> &middot;
  <a href="#features">Features</a> &middot;
  <a href="#slash-commands">Commands</a> &middot;
  <a href="#integrations">Integrations</a> &middot;
  <a href="#development">Development</a> &middot;
  <a href="#releasing">Releasing</a>
</p>

<p align="center">
  <img src="https://img.shields.io/github/v/release/CloudsailDev/AutoSellPlus?style=for-the-badge&color=0078D4" alt="Version">
  &nbsp;
  <img src="https://img.shields.io/badge/WoW-Midnight-148EFF?style=for-the-badge&logo=battle.net&logoColor=white" alt="WoW Midnight">
  &nbsp;
  <img src="https://img.shields.io/badge/license-Proprietary-DA3B3B?style=for-the-badge" alt="License">
</p>

<br>

<p align="center">
  <img src="assets/demo.gif" alt="AutoSellPlus in action" width="640">
</p>

<p align="center">
  <img src="assets/screenshot.png" alt="AutoSellPlus popup" width="640">
</p>

<br>

AutoSellPlus sells your junk at vendors with configurable quality and ilvl filters, transmog protection, and per-character profiles. Mark items as junk while looting, preview what will be sold before confirming, and protect gear you want to keep -- including uncollected appearances, BoEs, and equipment sets. Lightweight, modular, and self-testing on login so it works through patches without manual intervention.

<br>

---

<br>

## Quick Start

1. Install via [CurseForge](https://www.curseforge.com/wow/addons/autosellplus), then `/reload`
2. The setup wizard runs automatically on first login -- pick a template and configure protections
3. **ALT+Click** items in bags to mark them as junk (visual overlay appears)
4. Visit a vendor -- the popup shows everything that will be sold, with checkboxes to include or exclude items

Or skip the popup entirely: set auto-sell mode in `/asp config` and everything happens on merchant open.

> [!TIP]
> Rules are account-wide by default. Set them once on your main, every alt uses the same config. Per-character overrides are available if needed.

<br>

## Features

### Selling

- **Popup preview** with sortable columns (name, ilvl, vendor price, AH value), checkboxes, and one-click Sell All
- **Three sell modes:** interactive popup (default), one-click, or fully automatic with configurable delay
- **Quality filters** for gray through epic, each with independent ilvl thresholds (e.g. sell greens below ilvl 200)
- **Category filters** for consumables, trade goods, quest items, and miscellaneous
- **Expansion and slot filters** to narrow down exactly what shows up
- **Confirmation dialogs** for epic items and high-value sales, with a scrollable item list panel showing exactly what will be sold
- **Buyback safety** -- items beyond the 12-item buyback limit are flagged with a red divider and tinted rows
- **Dry run mode** to preview what would be sold without selling anything
- **Auto-repair** at vendors, guild funds first

### Protection

- **Never-sell and always-sell lists** (global and per-character)
- **Transmog protection** prevents selling uncollected appearances, with source-level checking
- **Equipment set protection** for items in any saved gear set
- **BoE protection** for unbound Bind on Equip items
- **Refundable protection** skips items still in the purchase refund window
- **AllTheThings and CanIMogIt integration** for enhanced transmog detection

### Marking

- **ALT+Click** items in bags to mark/unmark as junk (configurable visual overlay: border, tint, or both)
- **Drag-to-mark** button appears above bags
- **Auto-mark** gray items and equippable items below an ilvl threshold on loot
- **Bulk mark mode** (`/asp mark`) for marking multiple items without holding ALT
- Works with Bagnon, AdiBags, ArkInventory, and Baganator bag frames

### Bag Management

- **Bag space guard** automatically suggests selling the cheapest junk when free slots drop below a threshold
- **Stack limits** -- set maximum quantities per item, excess is automatically included in sell queues
- **Free slot alerts** in chat or on-screen when bag space is low
- **Bag gold display** showing total vendor value of bag contents above the backpack button

### Tracking

- **Session tracker** with gold/hour calculation, accessible from the minimap button tooltip
- **Sale history** with a scrollable UI panel (last 200 sales)
- **Per-character stats** showing lifetime sales, visible in the minimap tooltip across alts
- **Undo system** with 5-minute buyback window and visual toast notification

### Profiles

- **Four built-in templates:** Raid Farmer, Transmog Hunter, Leveling Alt, Gold Farmer
- **Save/load named profiles** that persist across sessions
- **Per-character auto-load** -- the last loaded profile restores on login
- **Import/export** never-sell and always-sell lists as shareable strings
- **First-run setup wizard** walks through configuration on each new character

### Destroy

- **Auto-destroy** junk items that have no vendor value, with configurable quality and value limits
- Confirmation dialog with safety cap of 5 items per use

<br>

## Slash Commands

All commands are available via `/asp` or `/autosell`.

| Command | Description |
| :--- | :--- |
| `/asp` | Show help |
| `/asp config` | Open settings panel |
| `/asp sell` | Sell at vendor now |
| `/asp preview` | Dry run (nothing sold) |
| `/asp undo` | Buyback last sale |
| `/asp template [name]` | Apply a preset template |
| `/asp toggle` | Enable / disable |
| `/asp mark` | Toggle bulk-mark mode |
| `/asp add <id>` | Add item to never-sell list |
| `/asp remove <id>` | Remove from never-sell list |
| `/asp list` | Show never-sell and always-sell lists |
| `/asp keep <id> <count>` | Set stack limit for item |
| `/asp profile save <name>` | Save current settings as profile |
| `/asp profile load <name>` | Load saved profile |
| `/asp session` | Show session stats |
| `/asp log ui` | Open sale history panel |
| `/asp destroy` | Destroy qualifying junk |
| `/asp wizard` | Re-run setup wizard |
| `/asp overlay` | Cycle overlay mode |

<br>

## Integrations

| Addon | Integration |
| :--- | :--- |
| **TSM / Auctionator** | AH price column in popup, value warnings |
| **Bagnon / AdiBags / ArkInventory / Baganator** | Junk mark overlays in bag frames |
| **AllTheThings / CanIMogIt** | Enhanced transmog protection |
| **Leatrix Plus** | Conflict detection and warning |
| **WoWUnit** | In-game unit test suite (development) |

<br>

## Resilience

AutoSellPlus runs a self-test on login that checks for required WoW APIs. If an API is missing (typically after a major patch), the affected feature is disabled individually while everything else keeps working. No full addon breakage from a single API change.

Checked APIs: selling, bag scanning, item info, transmog collection, equipment sets, item destruction.

<br>

---

<br>

## Development

> [!NOTE]
> See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on submitting changes.

### Project Structure

```
AutoSellPlus/
├── AutoSellPlus/            # Addon source
│   ├── AutoSellPlus.toc     # Table of contents (loaded by WoW)
│   ├── Config.lua           # Defaults, DB init, migration, profiles, templates
│   ├── Helpers.lua          # Utilities (ilvl, money formatting, bag iteration)
│   ├── Protection.lua       # Item protection (transmog, BoE, sets, ShouldSellItem)
│   ├── BagAdapters.lua      # Bag addon compatibility (Bagnon, AdiBags, etc.)
│   ├── Overlays.lua         # Bag overlays, tooltip hooks, gold display
│   ├── Marking.lua          # Mark toggling, alt-click, loot auto-mark
│   ├── History.lua          # Session tracking, sale history (data layer)
│   ├── HistoryUI.lua        # Sale history panel (UI)
│   ├── MinimapButton.lua    # Minimap button, alt stats tracking
│   ├── Wizard.lua           # First-run setup wizard
│   ├── UI.lua               # Settings panel (Options > AddOns)
│   ├── PopupFilters.lua     # Display list building, filter logic, sorting
│   ├── ConfirmList.lua      # Confirmation dialog item list panel
│   ├── Popup.lua            # Merchant popup frame, item rows, sell actions
│   ├── Selling.lua          # Sell queue, batch processing, undo, auto-sell
│   ├── Core.lua             # Event handling, slash commands, auto-repair
│   └── Tests.lua            # WoWUnit test suite (requires WoWUnit addon)
├── assets/                  # Images for README (excluded from package)
├── .pkgmeta                 # BigWigsMods packager config
├── .luacheckrc              # Luacheck linting rules
├── install.sh               # macOS install script
└── .github/workflows/       # CI/CD pipeline
```

### Local Testing

Symlink the addon into your WoW addons folder:

```bash
./install.sh
```

Or manually copy `AutoSellPlus/` to:

```
World of Warcraft/_retail_/Interface/AddOns/AutoSellPlus/
```

Reload the UI in-game with `/reload`.

### Unit Tests

The addon includes a [WoWUnit](https://github.com/Jaliborc/WoWUnit) test suite in `Tests.lua`. Install WoWUnit as a separate addon and the tests run automatically in-game. The test suite covers formatting, configuration, database migration, protection priorities, filter logic, sorting, session tracking, sale history, and more.

WoWUnit is listed as an optional dependency. Tests are guarded by `if WoWUnit then` and have zero overhead when WoWUnit is not installed.

### Linting

Run [luacheck](https://github.com/mpeterv/luacheck) locally before pushing:

```bash
luacheck AutoSellPlus/
```

CI runs luacheck automatically on every push. Zero warnings required.

<br>

## Releasing

Releases are fully automated via GitHub Actions using [BigWigsMods/packager](https://github.com/BigWigsMods/packager).

### How to Release

1. Tag the commit and push:
   ```bash
   git tag v1.2.3
   git push origin v1.2.3
   ```
2. The pipeline will automatically:
   - Run luacheck
   - Package the addon (respecting `.pkgmeta` ignores)
   - Upload to [CurseForge](https://www.curseforge.com/wow/addons)
   - Create a GitHub release with the zip attached

### Required Secrets

Set these in **GitHub > Settings > Secrets and variables > Actions**:

| Secret | Source |
| :--- | :--- |
| `CF_API_KEY` | [CurseForge API tokens](https://authors.curseforge.com) |

> [!IMPORTANT]
> `GITHUB_TOKEN` is provided automatically. Make sure **Settings > Actions > General > Workflow permissions** is set to **Read and write**.

### Version Token

The `.toc` file uses `@project-version@` which the packager replaces with the git tag at build time. Do not hardcode a version number.

<br>

---

<br>

<p align="center">
  Made by <a href="https://cloudsail.com">Cloudsail Digital Solutions</a>
</p>
