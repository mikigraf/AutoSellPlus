<h1 align="center">AutoSellPlus for World of Warcraft</h1>

<p align="center">
  <b>Mass-sell low item level greens and blues in one click.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/github/v/tag/CloudsailDev/AutoSellPlus?label=version&style=flat-square&color=0078D4" alt="Version">
  <img src="https://img.shields.io/badge/WoW-Retail-blue?style=flat-square" alt="WoW Retail">
  <img src="https://img.shields.io/badge/license-Proprietary-red?style=flat-square" alt="License">
</p>

<br>

<p align="center">
  <img src="demo.gif" alt="AutoSellPlus in action" width="600">
</p>

<br>

<p align="center">
  AutoSellPlus pops up the moment you open a merchant and lays out every green and blue below your gear level — pre-checked and ready to vendor. It knows what you're wearing, protects upgrades and uncollected transmog, and sets ilvl thresholds automatically.<br><b>No setup. No accidents. Just gold.</b>
</p>

<br>

---

<br>

## Features

|                            |                                                                                 |
| -------------------------- | ------------------------------------------------------------------------------- |
| **Instant merchant popup** | Every vendorable item laid out the moment you talk to a vendor                  |
| **Smart auto-select**      | Grays, greens, and blues below your equipped ilvl are pre-checked               |
| **Upgrade protection**     | Never sells upgrades, equipment sets, uncollected transmog, or refundable items |
| **Auto ilvl thresholds**   | Adapts to your gear automatically — no manual config needed                     |
| **Full control**           | One click to sell, Escape to cancel, uncheck anything you want to keep          |

<br>

## Getting Started

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

<br>

## Commands

| Command            | Description                           |
| :----------------- | :------------------------------------ |
| `/asp`             | Show help                             |
| `/asp toggle`      | Enable / disable                      |
| `/asp dryrun`      | Preview mode — nothing gets sold      |
| `/asp config`      | Open settings panel                   |
| `/asp add <id>`    | Never sell this item                  |
| `/asp remove <id>` | Remove from never-sell list           |
| `/asp list`        | Show never-sell and always-sell lists |

> `/autosell` works as an alias for `/asp`

<br>

## Configuration

Open with `/asp config` or **Options > AddOns > AutoSellPlus**.

| Category   | Options                                                   |
| :--------- | :-------------------------------------------------------- |
| **Safety** | Protect equipment sets, protect uncollected transmog      |
| **Output** | Sale summary, itemized log, dry run mode, buyback warning |

Filter controls — sell grays / greens / blues, ilvl sliders, equippable-only toggle — live directly on the popup and persist between sessions.

<br>

---

<p align="center">
  Made by <a href="https://github.com/CloudsailDev">Cloudsail Digital Solutions</a>
</p>
