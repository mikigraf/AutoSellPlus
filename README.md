# AutoSellPlus

**Mass-sell low item level greens and blues in one click.**

AutoSellPlus pops up at the merchant, auto-selects every green and blue below your gear level, and lets you vendor the entire pile instantly. It knows what you're wearing, protects upgrades and uncollected transmog, and sets ilvl thresholds automatically. No setup. No accidents. Just gold.

<br>

<p align="center">
  <img src="demo.gif" alt="AutoSellPlus in action" width="600">
</p>

<br>

## Features

- **Instant merchant popup** — every vendorable item laid out the moment you talk to a merchant
- **Smart auto-select** — grays, greens, and blues below your equipped ilvl are pre-checked
- **Upgrade protection** — never sells upgrades, equipment sets, uncollected transmog, or refundable items
- **Auto ilvl thresholds** — adapts to your gear automatically, no manual config needed
- **Full control** — one click to sell, Escape to cancel, uncheck anything you want to keep

<br>

## Installation

Extract to your addons folder:

```
World of Warcraft/_retail_/Interface/AddOns/AutoSellPlus/
```

Or run `./install.sh` on macOS.

<br>

## Commands

| Command | Description |
| --- | --- |
| `/asp` | Show help |
| `/asp toggle` | Enable / disable |
| `/asp dryrun` | Preview mode — nothing gets sold |
| `/asp config` | Open settings panel |
| `/asp add <id>` | Never sell this item |
| `/asp remove <id>` | Remove from never-sell list |
| `/asp list` | Show never-sell and always-sell lists |

> `/autosell` works as an alias for `/asp`.

<br>

## Settings

Open with `/asp config` or navigate to **Options > AddOns > AutoSellPlus**.

| Category | Options |
| --- | --- |
| **Safety** | Protect equipment sets, protect uncollected transmog |
| **Output** | Sale summary, itemized log, dry run mode, buyback warning |

Filter controls (sell grays / greens / blues, ilvl sliders, equippable-only toggle) live directly on the popup and persist between sessions.
