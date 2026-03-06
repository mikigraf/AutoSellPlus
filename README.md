<a id="readme-top"></a>

<br>

<p align="center">
  <img src="assets/icon.png" alt="AutoSellPlus" width="128">
</p>

<h1 align="center">AutoSellPlus</h1>

<p align="center">
  <b>Proactive junk control for serious farmers.</b><br>
  <sub>Mark once, farm clean &mdash; the last auto-sell addon you'll need.</sub>
</p>

<p align="center">
  <a href="#-features">Features</a> &middot;
  <a href="#-why-autosellplus">Why AutoSellPlus</a> &middot;
  <a href="#-getting-started">Getting Started</a> &middot;
  <a href="#-commands">Commands</a> &middot;
  <a href="#-configuration">Configuration</a> &middot;
  <a href="#-development">Development</a> &middot;
  <a href="#-releasing">Releasing</a>
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
  <img src="assets/screenshot.png" alt="AutoSellPlus popup" width="850">
</p>

<br>

<p align="center">
  Sick of bags overflowing mid-raid farm? AutoSellPlus marks junk at loot time,<br>
  auto-clears space during runs, and sells in one click across all your alts.<br>
  No patch surprises, no accidental transmog losses &mdash; just clean farming.
</p>

<h3 align="center">Set your junk rules once. Farm forever without bag micromanagement.</h3>

<br>

---

<br>

## &nbsp; Why AutoSellPlus

Players frequently run into the same problems with existing auto-sell addons: patch breakage, accidental BoE/transmog sales, per-character-only configs, and no way to manage inventory before reaching a vendor.

| Pain Point | Other Addons | AutoSellPlus |
| :--- | :--- | :--- |
| **Patch breakage** | Frequent breaks after expansions (10.0, 11.1.5) | Graceful feature degradation + login self-test |
| **Accidental BoE/transmog sells** | Weak defaults, no appearance checks | BoE protection, transmog source-level checks, ATT/CIMI integration |
| **Alt switching hassle** | Per-character setup only | Account-wide rules + per-character overrides + profile templates |
| **Mid-farm full bags** | Vendor required | Bag space monitoring + value-based eviction + auto-destroy safety net |
| **Transaction spam** | Per-item confirmations | Single bulk sell with undo toast |
| **Invisible marks** | Can't tell if removal took effect | Color-coded bag overlays, coin badges, tooltip lines, drag-to-mark |

AutoSellPlus is built to be **proactive rather than reactive** &mdash; handling inventory before it becomes a problem, not after.

<br>

## &nbsp; Features

### Item Marking
| | |
| :--- | :--- |
| **ALT+Click marking** | Mark any bag item as junk directly &mdash; no menus, no typing item names |
| **Drag-to-mark button** | Drag any item onto the junk target button (appears below bags) to toggle its mark |
| **ALT+Click from loot** | ALT+Click items in the loot window to pre-mark them as junk before they hit your bags |
| **Visual bag overlays** | Color-coded borders and coin badges on marked items in your bags (border / tint / full modes via `/asp overlay`) |
| **Tooltip integration** | `[Marked as Junk]` line with vendor sell price on every marked item |
| **Bulk mark mode** | `/asp mark` toggles click-to-mark without needing ALT held down |
| **Auto-mark on loot** | Automatically mark gray loot or items below an ilvl threshold as they enter your bags |
| **Persistent marks** | Junk flags survive logouts, reloads, and across sessions |

### Smart Filters
| | |
| :--- | :--- |
| **Quality filters** | Gray (default), white, green, blue, and epic &mdash; each with independent ilvl thresholds |
| **Expansion filter** | Sell items from specific expansions only (Classic through Midnight) |
| **Equipment slot filter** | Toggle specific slots on/off (e.g., sell cloaks below ilvl 200 but keep trinkets) |
| **Item category filters** | Consumables, trade goods, quest items, miscellaneous &mdash; beyond just equippable gear |
| **Only-equippable toggle** | Limit quality filters to armor and weapons only |
| **Gold value sorting** | Click column headers to sort by item name, ilvl, AH value, or vendor price |

### Protection
| | |
| :--- | :--- |
| **Upgrade detection** | Items above your equipped ilvl are never auto-checked |
| **Equipment set protection** | Items in any saved equipment set are protected |
| **Transmog protection** | Source-level uncollected appearance checks with ATT and Can I Mog It integration |
| **BoE protection** | Unbound bind-on-equip items are never auto-sold |
| **Refundable protection** | Items within the purchase refund window are skipped |
| **High-value safety lock** | Confirmation dialog for items above a configurable gold threshold |
| **Epic confirmation** | Extra confirmation before selling epic quality items |

### Vendor Interaction
| | |
| :--- | :--- |
| **Instant merchant popup** | Every vendorable item laid out the moment you talk to a vendor |
| **Smart auto-select** | Items matching your filters are pre-checked based on your equipped ilvl |
| **Auto-sell mode** | Choose between popup review, one-click, or fully automatic selling |
| **Auto-sell safety confirmations** | Epic and high-value item confirmations apply to auto-sell and `/asp sell`, not just the popup |
| **Sell All Junk button** | One click selects all gray + marked items and sells immediately |
| **Drag-to-sell overlay** | Drag items onto the sell overlay button in the popup to add them to the queue |
| **Progressive sell feedback** | Progress bar tracks batch selling progress in the popup |
| **Auto-repair** | Guild funds first, personal gold fallback &mdash; independent of auto-sell |
| **Vendor mount detection** | Detects Mammoth, Yak, and Brutosaur mounts with a `[Mount Vendor]` badge |
| **Mute vendor sounds** | Silence sell sounds during bulk vendor sessions |

### Safety & Undo
| | |
| :--- | :--- |
| **Dry run preview** | See exactly what would be sold without selling anything |
| **Undo toast** | Bottom-of-screen notification after selling with a one-click Undo button |
| **Smart undo buffer** | 5-minute buyback recall &mdash; auto-repurchases matching items from buyback tab |
| **Buyback warning** | Alerts when selling more than 12 items (WoW's buyback limit) |
| **Pre-sell verification** | Re-checks every queued item before selling &mdash; removes invalid entries |
| **Sale history log** | Last 200 transactions with `/asp log` or visual panel via `/asp log ui` |

### Multi-Character & Profiles
| | |
| :--- | :--- |
| **Account-wide rules** | One set of filters and lists shared across all characters by default |
| **Per-character overrides** | Opt specific characters into custom settings via `AutoSellPlusCharDB` |
| **Named profiles** | Save, load, and delete named profiles (`/asp profile save\|load\|list\|delete`) |
| **Profile templates** | Four built-in presets (Raid Farmer, Transmog Hunter, Leveling Alt, Gold Farmer) via `/asp template` |
| **Profile auto-load** | Active profile is automatically restored on login; new characters can pick a profile in the wizard |
| **Global + per-char lists** | Never-sell and always-sell lists at both account and character level |
| **Alts-at-a-glance** | Minimap button tooltip shows per-character sell stats across all alts |
| **Import/export lists** | Share never-sell and always-sell lists between players via string copy-paste |

### Bag Maintenance
| | |
| :--- | :--- |
| **Free slot threshold** | Configure a target number of free bag slots &mdash; get alerts when bags fill past it |
| **Value-based eviction** | Automatically sells cheapest junk at the vendor to free slots when bags are full (confirmation dialog with item list and total value) |
| **Reclaim Space mode** | Popup switches to eviction view sorting by price ascending when bags are full |
| **Stack limits** | Set per-item quantity caps (`/asp keep <id> <count>`) &mdash; excess stacks are auto-sold |
| **Auto-destroy** | Safety-gated destroy of gray/zero-value junk away from vendors (disabled by default, confirmation required) |

### Integrations
| | |
| :--- | :--- |
| **TSM / Auctionator** | AH price column in popup &mdash; green if AH value is 10x+ vendor price |
| **Bagnon / AdiBags / ArkInventory** | Bag overlay adapters for popular bag replacement addons |
| **Leatrix Plus** | Conflict detection and warning if Leatrix auto-sell is active |
| **Postal** | Auto-sell suppressed during mail processing |
| **WeakAura** | `AutoSellPlus_SessionData` and `AutoSellPlus_LastSellCount` globals for custom triggers |
| **All The Things / Can I Mog It** | Transmog wishlist integration for dynamic exclusion |

### Resilience
| | |
| :--- | :--- |
| **Graceful feature degradation** | Missing WoW APIs disable individual features (selling, transmog, equip sets, destroying) instead of crashing the addon |
| **Login self-test** | Reports any disabled features on login so you know exactly what's available |
| **Conflict detection** | Warns about Leatrix Plus auto-sell conflicts; suppresses auto-sell during Postal mail processing |

### UX
| | |
| :--- | :--- |
| **First-run wizard** | 3-page setup wizard with safe defaults, profile picker, and template quick-start on first install |
| **Minimap button** | Draggable coin icon &mdash; left-click toggles, right-click opens settings, shift-click shows session stats, shift-right-click opens sale history |
| **Sale history panel** | Visual scrollable panel with item icons, links, quantities, prices, and time-ago &mdash; accessible via `/asp log ui` or minimap button |
| **Session gold tracker** | Running total of vendor income with gold/hour, daily stats, exportable via `/asp session` |
| **In-bag gold display** | Total vendor value of all bag contents shown on the bag bar with per-quality tooltip breakdown |
| **Tooltip sell price** | Vendor price on all item tooltips, with AH comparison when TSM/Auctionator is installed |

<br>

## &nbsp; Getting Started

### Installation

Drop the `AutoSellPlus` folder into your addons directory:

```
World of Warcraft/_retail_/Interface/AddOns/AutoSellPlus/
```

Or run the install script on macOS:

```bash
./install.sh
```

### Usage

1. Visit any merchant
2. AutoSellPlus popup appears with your junk pre-selected
3. Review, uncheck anything you want to keep
4. Hit **Sell Selected**

ALT+Click items in your bags anytime to mark or unmark them as junk. Marked items show up pre-checked at the next vendor visit.

<br>

## &nbsp; Commands

| Command | Description |
| :--- | :--- |
| `/asp` | Show help |
| `/asp toggle` | Enable / disable |
| `/asp config` | Open settings panel |
| `/asp sell` | Sell immediately at merchant (with safety confirmations) |
| `/asp preview` | One-shot dry run |
| `/asp mark` | Toggle bulk mark mode |
| `/asp overlay` | Cycle overlay visual mode (border / tint / full) |
| `/asp dryrun` | Toggle persistent dry run mode |
| `/asp debug` | Toggle debug output |
| `/asp session` | View session stats |
| `/asp session reset` | Reset session counter |
| `/asp session export` | Print session summary to chat |
| `/asp log` | Show last 10 sales |
| `/asp log ui` | Open sale history panel |
| `/asp log clear` | Clear sale history |
| `/asp add <id>` | Add item to never-sell list |
| `/asp remove <id>` | Remove from never-sell list |
| `/asp list` | Show all never-sell and always-sell lists |
| `/asp export` | Export lists to copyable string |
| `/asp import` | Import lists from string |
| `/asp keep <id> <count>` | Set stack limit for an item |
| `/asp keep list` | Show all stack limits |
| `/asp keep clear [id]` | Clear stack limit(s) |
| `/asp destroy` | Destroy junk items (safety-gated) |
| `/asp profile save\|load\|list\|delete <name>` | Manage named profiles |
| `/asp template [name\|list]` | Apply a preset template or list available templates |
| `/asp wizard` | Re-run the first-run setup wizard |
| `/asp reset` | Reset all settings (with confirmation) |
| `/asp reset lists` | Clear all never-sell and always-sell lists |
| `/asp undo` | Repurchase last sold items from buyback |

> [!TIP]
> `/autosell` works as an alias for `/asp`

<br>

## &nbsp; Configuration

Open with `/asp config` or **Options > AddOns > AutoSellPlus**.

Settings are organized into sub-categories:

| Category | Options |
| :--- | :--- |
| **General** | Enable/disable, sale summary, itemized log, dry run mode |
| **Protection** | Equipment sets, uncollected transmog, transmog sources, BoE items, buyback warning, high-value confirmation, epic confirmation |
| **Automation** | Auto-sell mode (popup / one-click / autosell), auto-sell delay, auto-repair, guild fund priority, mute vendor sounds |
| **Marking** | Auto-mark gray loot, auto-mark below ilvl, overlay mode, bag gold display |
| **Display** | Undo toast, minimap button |
| **Bag Maintenance** | Free slot threshold, alert mode, value-based eviction, stack limits |
| **Safety** | Auto-destroy enable, max quality, max value, confirmation |

Filter controls (quality checkboxes, ilvl sliders, expansion filter, equipment slot toggles, category filters) live directly on the popup and persist between sessions. Right-click items in the popup to add them to never-sell or always-sell lists.

### Profile Templates

Apply a full configuration preset with `/asp template <name>`:

| Template | Behavior |
| :--- | :--- |
| **Raid Farmer** | Sells grays, whites, greens. Protects transmog. Popup mode. |
| **Transmog Hunter** | Sells grays only. Protects all uncollected appearances. |
| **Leveling Alt** | Sells grays through blues. Auto-sell with 2s delay. |
| **Gold Farmer** | Aggressive selling including consumables and trade goods. Protects BoE. |

Templates are also available as quick-start buttons in the first-run wizard.

<br>

---

<br>

## &nbsp; Development

> [!NOTE]
> See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on submitting changes.

### Project Structure

```
AutoSellPlus/
├── AutoSellPlus/            # Addon source
│   ├── AutoSellPlus.toc     # Table of contents (loaded by WoW)
│   ├── Config.lua           # Defaults, saved variables, DB migration, profiles
│   ├── Helpers.lua          # Utility functions (ilvl, transmog, BoE, formatting, mount detection)
│   ├── History.lua          # Sale history log and session gold tracking
│   ├── Marking.lua          # Item marking, bag overlays, tooltip hooks, bag addon adapters
│   ├── MinimapButton.lua    # Minimap icon with alt-tracking tooltip
│   ├── Wizard.lua           # First-run setup wizard
│   ├── UI.lua               # Settings panel (Options > AddOns, sub-categories)
│   ├── Popup.lua            # Merchant popup frame, filters, sorting, context menu
│   └── Core.lua             # Event handling, sell queue, undo, auto-repair, slash commands
├── assets/                  # Images for README (excluded from package)
├── .pkgmeta                 # BigWigsMods packager config
├── .luacheckrc              # Luacheck linting rules
├── install.sh               # macOS install script
└── .github/workflows/       # CI/CD pipeline
```

### Load Order

Files are loaded in the order listed in `AutoSellPlus.toc`:

1. **Config.lua** &mdash; SavedVariables initialization, DB migration, profile management
2. **Helpers.lua** &mdash; Item evaluation utilities (ilvl, transmog, BoE, equipment sets, formatting)
3. **History.lua** &mdash; Sale history (200-entry FIFO) and session gold tracking
4. **Marking.lua** &mdash; Item marking system, bag overlays, tooltip hooks, bag addon adapters
5. **MinimapButton.lua** &mdash; Minimap button with per-character stats tooltip
6. **Wizard.lua** &mdash; First-run 3-page setup wizard
7. **UI.lua** &mdash; Settings panel registered under Options > AddOns
8. **Popup.lua** &mdash; Merchant popup with filters, sorting, context menu, sell logic
9. **Core.lua** &mdash; Event handling, sell queue, undo buffer, auto-repair, slash commands

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

### Linting

Run [luacheck](https://github.com/mpeterv/luacheck) locally before pushing:

```bash
luacheck AutoSellPlus/
```

CI enforces zero warnings on every push.

<br>

## &nbsp; Releasing

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
   - Upload to [CurseForge](https://www.curseforge.com/wow/addons) and [Wago](https://addons.wago.io)
   - Create a GitHub release with the zip attached

### Required Secrets

Set these in **GitHub > Settings > Secrets and variables > Actions**:

| Secret | Source |
| :--- | :--- |
| `CF_API_KEY` | [CurseForge API tokens](https://authors.curseforge.com) |
| `WAGO_API_TOKEN` | [Wago developer settings](https://addons.wago.io) |

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
