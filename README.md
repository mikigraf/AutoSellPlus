# AutoSellPlus

**Mass-sell low item level greens and blues in one click.**

AutoSellPlus pops up at the merchant, auto-selects every green and blue below your gear level, and lets you vendor the entire pile instantly. It knows what you're wearing, protects upgrades and uncollected transmog, and sets ilvl thresholds automatically. No setup. No accidents. Just gold.

![AutoSellPlus Demo](demo.gif)

## What it does

- Pops up at the merchant with every vendorable item laid out
- Auto-checks grays, greens, and blues below your equipped ilvl
- Protects upgrades, equipment sets, uncollected transmog, and refundable items
- Smart ilvl thresholds that adjust to your gear — no manual config needed
- One click to sell. Escape to cancel. You stay in control

## Installation

Extract to your addons folder:

```
World of Warcraft/_retail_/Interface/AddOns/AutoSellPlus/
```

Or run `./install.sh` on macOS.

## Commands

| Command | What it does |
|---------|--------------|
| `/asp` | Show help |
| `/asp toggle` | Enable / disable |
| `/asp dryrun` | Preview mode — nothing gets sold |
| `/asp config` | Open settings panel |
| `/asp add <id>` | Never sell this item |
| `/asp remove <id>` | Remove from never-sell list |
| `/asp list` | Show never-sell and always-sell lists |

`/autosell` works as an alias.

## Settings

Open with `/asp config` or **Options > AddOns > AutoSellPlus**.

**Safety** — Protect equipment sets, protect uncollected transmog
**Output** — Sale summary, itemized log, dry run mode, buyback warning

Filter controls (sell grays/greens/blues, ilvl sliders, equippable-only toggle) live on the popup itself and persist between sessions.
