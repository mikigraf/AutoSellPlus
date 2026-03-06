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
  <a href="#the-problem">The Problem</a> &middot;
  <a href="#how-it-works">How It Works</a> &middot;
  <a href="#features-at-a-glance">Features</a> &middot;
  <a href="#getting-started">Getting Started</a> &middot;
  <a href="#commands">Commands</a> &middot;
  <a href="#development">Development</a>
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

---

<br>

## The Problem

You're mid-pull in a raid farm. Bags are full. You mount up on the Bruto, open the vendor, and panic-sell everything gray. Two hours later you realize that green cloak was an uncollected transmog appearance worth 40k on the AH.

Every auto-sell addon promises to fix this. Most of them break on patch day, sell your BoEs, ignore your alts, or force you to configure everything from scratch on every character.

**AutoSellPlus takes a different approach.** Instead of reacting to full bags at the vendor, it lets you build junk rules *while you play* &mdash; marking items as they drop, protecting appearances you haven't collected, and tracking your inventory across every character. When you finally reach a vendor, there's nothing left to think about.

> **Set your rules once. Farm forever without bag micromanagement.**

<br>

---

<br>

## How It Works

AutoSellPlus follows a simple loop:

```
  MARK  ───>  FILTER  ───>  SELL  ───>  TRACK
   │            │             │           │
   │  ALT+Click │  Quality,   │  Popup,   │  Session gold,
   │  Drag-mark │  ilvl,      │  auto,    │  daily stats,
   │  Loot-mark │  transmog,  │  or CLI   │  sale history,
   │  Auto-mark │  BoE, sets  │           │  per-alt totals
   │            │             │           │
   └────────────┴─────────────┴───────────┘
              Rules persist across sessions
```

1. **Mark** items as junk while you play &mdash; in bags, at the loot window, or automatically by rules
2. **Filter** decides what's safe to sell using quality gates, ilvl thresholds, transmog checks, and protection lists
3. **Sell** happens your way &mdash; review in a popup, one-click, or fully automatic
4. **Track** everything &mdash; session income, daily totals, per-character stats, full sale history

<br>

---

<br>

## Features at a Glance

### Marking &mdash; *Flag junk while you play*

- **ALT+Click** any bag item to toggle its junk mark instantly
- **Drag-to-mark** &mdash; a target button appears below your bags; drag items onto it
- **Loot window marking** &mdash; ALT+Click items in the loot frame before they even reach your bags
- **Auto-mark** grays on loot, or anything below a configurable ilvl threshold
- **Visual overlays** on marked items in bags &mdash; choose border, tint, or full highlight mode
- **Tooltip integration** &mdash; marked items show `[Marked as Junk]` with vendor price
- **Bulk mark mode** &mdash; `/asp mark` lets you click without holding ALT
- Marks persist across logouts, reloads, and sessions

<br>

### Filtering &mdash; *Smart rules that protect what matters*

- **Quality filters** &mdash; gray through epic, each with independent ilvl thresholds
- **Expansion filter** &mdash; target items from specific expansions only (Classic through Midnight)
- **Equipment slot filter** &mdash; toggle individual slots (sell cloaks below 200 but keep trinkets)
- **Category filters** &mdash; consumables, trade goods, quest items, miscellaneous
- **Transmog protection** &mdash; source-level uncollected appearance checks, with ATT and Can I Mog It integration
- **Equipment set protection** &mdash; anything in a saved set is untouchable
- **BoE protection** &mdash; unbound bind-on-equip items are never auto-sold
- **Refundable protection** &mdash; items within the purchase refund window are skipped
- **Upgrade detection** &mdash; items above your equipped ilvl are never auto-checked
- **High-value safety lock** &mdash; confirmation dialog for items above a configurable gold threshold
- **Epic confirmation** &mdash; extra prompt before selling purple-quality items

<br>

### Selling &mdash; *Your vendor, your workflow*

Choose how you want to sell:

| Mode | Behavior |
| :--- | :--- |
| **Popup** | Full item list with checkboxes, filters, and sorting. Review everything before selling. |
| **One-click** | Popup appears, but sells immediately on a single button press. |
| **Auto-sell** | Items sell automatically when you open a vendor. Configurable delay. |

All three modes share the same filter engine and safety confirmations.

- **Progressive sell bar** &mdash; watch batch progress in real-time
- **Drag-to-sell** &mdash; drag items from bags directly onto the popup to add them to the queue
- **Sell All Junk** &mdash; one button to select and sell all grays + marked items
- **Auto-repair** &mdash; guild funds first, personal gold fallback
- **Vendor mount detection** &mdash; recognizes Mammoth, Yak, and Brutosaur with a `[Mount Vendor]` badge
- **Mute vendor sounds** &mdash; silence the sell noise during bulk sessions

<br>

### Safety &mdash; *Mistakes are reversible*

- **Dry run mode** &mdash; see exactly what would sell without selling anything
- **Undo toast** &mdash; bottom-of-screen notification with a one-click Undo button after every sale
- **Smart buyback** &mdash; 5-minute recall window that auto-repurchases from the buyback tab
- **Buyback warning** &mdash; alerts when selling more than 12 items (WoW's buyback limit)
- **Pre-sell verification** &mdash; every queued item is re-checked before the sell action fires
- **Item Restoration link** &mdash; if undo fails, the error message links directly to Blizzard's restoration page

<br>

### Profiles &mdash; *One setup, every character*

- **Account-wide rules** &mdash; filters and lists shared across all characters by default
- **Per-character overrides** &mdash; opt specific characters into custom settings
- **Named profiles** &mdash; save, load, and delete with `/asp profile`
- **Auto-load on login** &mdash; your active profile restores silently when you log in

Four built-in templates get you started instantly:

| Template | Style |
| :--- | :--- |
| **Raid Farmer** | Grays, whites, greens. Protect transmog. Popup review. |
| **Transmog Hunter** | Grays only. Protect every uncollected appearance. |
| **Leveling Alt** | Grays through blues. Auto-sell with a 2-second delay. |
| **Gold Farmer** | Aggressive. Consumables and trade goods included. Protect BoE. |

Apply with `/asp template <name>` or pick one in the first-run wizard.

<br>

### Bag Maintenance &mdash; *Stay ahead of full bags*

- **Free slot threshold** &mdash; set a target number of open slots; get warned when bags fill past it
- **Value-based eviction** &mdash; at a vendor, automatically identifies and offers to sell the cheapest junk to reclaim space
- **Stack limits** &mdash; cap how many of a specific item you keep (`/asp keep <id> <count>`); excess is auto-sold
- **Auto-destroy** &mdash; safety-gated destruction of gray/zero-value junk away from vendors (disabled by default, requires confirmation)

<br>

### Tracking &mdash; *Know where your gold comes from*

- **Session tracker** &mdash; running total of vendor income with gold-per-hour
- **Daily stats** &mdash; today's totals persist across sessions
- **Sale history panel** &mdash; scrollable UI with item icons, links, quantities, prices, and time-ago (`/asp log ui`)
- **Per-character stats** &mdash; minimap tooltip shows every alt's lifetime earnings and current bag junk value
- **In-bag gold display** &mdash; total vendor value on the bag bar with a per-quality tooltip breakdown

<br>

### Integrations

- **TSM / Auctionator** &mdash; AH price column in popup, highlighted when AH value exceeds 10x vendor price
- **Bagnon / AdiBags / ArkInventory** &mdash; bag overlay adapters for popular bag addons
- **All The Things / Can I Mog It** &mdash; transmog wishlist integration for dynamic exclusion
- **Leatrix Plus** &mdash; conflict detection when Leatrix auto-sell is active
- **Postal** &mdash; auto-sell suppressed during mail processing
- **WeakAuras** &mdash; `AutoSellPlus_SessionData` and `AutoSellPlus_LastSellCount` globals for custom triggers

<br>

### Resilience

- **Graceful degradation** &mdash; missing WoW APIs disable individual features instead of crashing the addon
- **Login self-test** &mdash; reports disabled features on login so you know what's available
- **Conflict detection** &mdash; warns about known addon conflicts and suppresses actions accordingly

<br>

---

<br>

## Getting Started

### Install

Drop the `AutoSellPlus` folder into your addons directory:

```
World of Warcraft/_retail_/Interface/AddOns/AutoSellPlus/
```

Or on macOS:

```bash
./install.sh
```

### First Launch

1. Log in &mdash; the setup wizard walks you through mode selection, filters, and an optional profile pick
2. Visit any merchant &mdash; the popup appears with your junk pre-selected
3. Review, uncheck anything you want to keep, and hit **Sell Selected**

From there, ALT+Click items in your bags anytime to refine your junk rules. Everything persists.

### Settings

Open the full settings panel anytime:
- `/asp config`
- **Options > AddOns > AutoSellPlus**
- Left-click the minimap button

No merchant required &mdash; preset your rules from anywhere.

<br>

---

<br>

## Commands

All commands use `/asp` (or the alias `/autosell`).

### Core

| Command | What it does |
| :--- | :--- |
| `/asp` | Show help |
| `/asp toggle` | Enable or disable the addon |
| `/asp config` | Open settings panel |
| `/asp sell` | Sell immediately at a merchant (with safety confirmations) |
| `/asp preview` | One-shot dry run |
| `/asp dryrun` | Toggle persistent dry run mode |
| `/asp undo` | Repurchase last sold items from buyback |
| `/asp debug` | Toggle debug output |

### Marking

| Command | What it does |
| :--- | :--- |
| `/asp mark` | Toggle bulk mark mode (click without ALT) |
| `/asp overlay` | Cycle overlay visual mode (border / tint / full) |

### Lists

| Command | What it does |
| :--- | :--- |
| `/asp add <id>` | Add item to never-sell list |
| `/asp remove <id>` | Remove from never-sell list |
| `/asp list` | Show all never-sell and always-sell entries |
| `/asp keep <id> <count>` | Set stack limit for an item |
| `/asp keep list` | Show all stack limits |
| `/asp keep clear [id]` | Clear stack limit(s) |
| `/asp export` | Export lists to a copyable string |
| `/asp import` | Import lists from a string |

### Profiles

| Command | What it does |
| :--- | :--- |
| `/asp profile save <name>` | Save current settings as a named profile |
| `/asp profile load <name>` | Load a saved profile |
| `/asp profile list` | List all saved profiles |
| `/asp profile delete <name>` | Delete a saved profile |
| `/asp template <name>` | Apply a built-in template |
| `/asp template list` | List available templates |

### History & Stats

| Command | What it does |
| :--- | :--- |
| `/asp session` | View session stats |
| `/asp session reset` | Reset session counter |
| `/asp session export` | Print session summary to chat |
| `/asp log` | Show last 10 sales in chat |
| `/asp log ui` | Open the sale history panel |
| `/asp log clear` | Clear sale history |

### Other

| Command | What it does |
| :--- | :--- |
| `/asp wizard` | Re-run the first-run setup wizard |
| `/asp destroy` | Destroy junk items (safety-gated) |
| `/asp reset` | Reset all settings (with confirmation) |
| `/asp reset lists` | Clear all never-sell and always-sell lists |

<br>

### Minimap Button

| Action | Result |
| :--- | :--- |
| **Left-click** | Open settings panel |
| **Right-click** | Toggle addon on/off |
| **Shift+click** | Print session stats |
| **Shift+right-click** | Open sale history panel |
| **Drag** | Reposition around the minimap |

<br>

---

<br>

## Development

> [!NOTE]
> See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on submitting changes.

### Project Structure

```
AutoSellPlus/
├── AutoSellPlus/
│   ├── AutoSellPlus.toc       # Loaded by WoW client
│   ├── Config.lua             # Defaults, saved variables, profiles, templates
│   ├── Helpers.lua            # Item evaluation (ilvl, transmog, BoE, formatting)
│   ├── History.lua            # Sale history log, daily stats, history panel
│   ├── Marking.lua            # Junk marks, bag overlays, tooltip hooks
│   ├── MinimapButton.lua      # Minimap icon, per-alt stats tooltip
│   ├── Wizard.lua             # First-run setup wizard
│   ├── UI.lua                 # Full settings panel (Options > AddOns)
│   ├── Popup.lua              # Merchant popup, filters, sorting, sell logic
│   └── Core.lua               # Events, sell queue, undo, auto-repair, CLI
├── .luacheckrc
├── .pkgmeta
├── install.sh
└── .github/workflows/
```

Files load in the order listed in `AutoSellPlus.toc`. Each file registers onto the shared `ns` namespace passed by WoW's addon loader.

### Linting

```bash
luacheck AutoSellPlus/
```

CI enforces zero warnings on every push.

### Local Testing

```bash
./install.sh        # symlinks into WoW addons folder (macOS)
/reload             # in-game: reload the UI
```

<br>

## Releasing

Releases are automated via GitHub Actions with [BigWigsMods/packager](https://github.com/BigWigsMods/packager).

```bash
git tag v1.2.3 && git push origin v1.2.3
```

The pipeline runs luacheck, packages the addon, and uploads to [CurseForge](https://www.curseforge.com/wow/addons) and [Wago](https://addons.wago.io).

| Secret | Source |
| :--- | :--- |
| `CF_API_KEY` | [CurseForge API tokens](https://authors.curseforge.com) |
| `WAGO_API_TOKEN` | [Wago developer settings](https://addons.wago.io) |

> [!IMPORTANT]
> `GITHUB_TOKEN` is provided automatically. Ensure **Settings > Actions > General > Workflow permissions** is set to **Read and write**.

The `.toc` uses `@project-version@` which the packager replaces with the git tag. Do not hardcode a version number.

<br>

---

<br>

<p align="center">
  Made by <a href="https://cloudsail.com">Cloudsail Digital Solutions</a>
</p>
