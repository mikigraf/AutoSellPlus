<a id="readme-top"></a>

<br>

<p align="center">
  <img src="assets/icon.png" alt="AutoSellPlus" width="128">
</p>

<h1 align="center">AutoSellPlus</h1>

<p align="center">
  <b>Mark junk at loot. Farm without full bags. Sell in one click across alts.</b><br>
  <sub>A World of Warcraft addon</sub>
</p>

<br>

<p align="center">
  Tired of Scrap/Aardvark breaking every patch? Or hopping vendors mid-farm because your bags<br>
  exploded from old raid greens? AutoSellPlus marks while you loot, auto-keeps space open,<br>
  and sells safe—no more accidental BoE/transmog losses.
</p>

<h3 align="center">Midnight ready &bull; Works post-patch &bull; Farmer approved</h3>

<br>

<p align="center">
  <a href="#-why-this-over-scrapaardvarklegacy-vendor">Why AutoSellPlus</a> &middot;
  <a href="#-quick-start">Quick Start</a> &middot;
  <a href="#-key-features">Features</a> &middot;
  <a href="#-slash-commands">Commands</a> &middot;
  <a href="#-integrations">Integrations</a> &middot;
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
  <img src="assets/screenshot.png" alt="AutoSellPlus popup" width="640">
</p>

<br>

<p align="center">
  Tired of Scrap/Aardvark breaking every patch? Or hopping vendors mid-farm because your bags<br>
  exploded from old raid greens? AutoSellPlus marks while you loot, auto-keeps space open,<br>
  and sells safe—no more accidental BoE/transmog losses.
</p>

<h3 align="center">Midnight ready &bull; Works post-patch &bull; Farmer approved</h3>

<br>

---

<br>

## &nbsp; Why This Over Scrap/Aardvark/Legacy Vendor?

| Issue | AutoSellPlus | Others |
| :--- | :--- | :--- |
| **Patch breaks** | Self-tests on login, API fallbacks | Dies every xpack |
| **Full bags mid-run** | Auto-evict junk to keep slots free | Vendor babysitting |
| **Alt hassle** | Sync rules account-wide | Per-char redo |
| **Oops sells** | Loot-mark + ATT exclude | Weak safeties |
| **Spam popups** | One-click bulk | Transaction hell |

> *"Set once on main. Every alt farms clean."* – Real farmer QoL.

<br>

## &nbsp; Quick Start

1. Install via [CurseForge](https://www.curseforge.com/wow/addons/autosellplus) or [Wago](https://addons.wago.io) &rarr; `/reload`
2. `/asp config` &rarr; Pick **"Raid Farmer"** template
3. **ALT+Click** loot/bags to mark junk (glows red)
4. Visit a vendor &rarr; One button **Sell All** (preview first)

Minimap button for stats/toggle. Rules stick across chars/sessions.

<br>

## &nbsp; Key Features

### Mark Junk Fast

- **ALT+Click** bags/loot &rarr; Instant mark (visual glow/border)
- **Drag** to target button under bags
- Auto-mark grays/low-ilvl on pickup
- Bulk `/asp mark` mode (no ALT needed)

### Smart Sell Rules

- ilvl/quality/expansion filters (e.g. sell TBC greens <180)
- Protect transmog (ATT/CanIMogIt hooks)
- BoE/sets/refundables safe
- Epic/high-gold confirm dialogs

### Vendor Flow

- Popup preview &rarr; checkboxes/sort &rarr; **Sell Selected**
- One-click auto-sell on open
- Auto-repair (guild first)
- Mute vendor mount spam

### Farmer Tools

- **Bag space guard:** Auto-sell cheapest junk at threshold
- **Alt totals:** Minimap tooltip shows "Bag junk: 2k gold ready"
- **Undo buyback** (5 min window)
- **Session GPH tracker**

<br>

## &nbsp; Slash Commands

| Command | Description |
| :--- | :--- |
| `/asp` | Show help |
| `/asp config` | Open settings panel |
| `/asp sell` | Sell at vendor now |
| `/asp preview` | Dry run (nothing sold) |
| `/asp undo` | Buyback last sale |
| `/asp template` | Load preset (raidfarmer/transmoghunter/etc) |
| `/asp toggle` | Enable / disable |
| `/asp mark` | Toggle bulk-mark mode |
| `/asp add <id>` | Never sell this item |
| `/asp remove <id>` | Remove from never-sell list |
| `/asp list` | Show never-sell and always-sell lists |
| `/asp profile save <name>` | Save current settings as profile |

> [!TIP]
> `/autosell` works as an alias for `/asp`

<br>

## &nbsp; Integrations

| Addon | Integration |
| :--- | :--- |
| **TSM / Auctionator** | AH price warnings in tooltips |
| **Bagnon / AdiBags / ArkInventory / Baganator** | Mark overlays in bag frames |
| **AllTheThings / CanIMogIt** | Transmog protection hooks |
| **Leatrix Plus** | No conflicts |

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
│   ├── Popup.lua            # Merchant popup frame, item rows, sell actions
│   ├── Selling.lua          # Sell queue, batch processing, undo, auto-sell
│   └── Core.lua             # Event handling, slash commands, auto-repair
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

### Linting

Run [luacheck](https://github.com/mpeterv/luacheck) locally before pushing:

```bash
luacheck AutoSellPlus/
```

The CI pipeline runs luacheck automatically on every push.

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
