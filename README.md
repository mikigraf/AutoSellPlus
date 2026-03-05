# AutoSellPlus

**Stop vendoring upgrades. Stop clicking through bags. Just sell the junk.**

AutoSellPlus pops up every time you visit a merchant and shows you exactly what's safe to sell. It knows what you're wearing, spots upgrades you shouldn't vendor, and auto-selects the junk so you can sell it all in one click.

![AutoSellPlus Demo](demo.gif)

### Why AutoSellPlus?

- **No more accidents** — It checks your equipped gear and protects anything that's an upgrade, even if it looks like junk by item level alone.
- **One click, done** — Grays are pre-checked. Greens and blues below your gear level are pre-checked. Hit "Sell Selected" and you're back to questing.
- **It learns your gear** — Thresholds auto-adjust based on what you're actually wearing. No manual setup needed.
- **You stay in control** — Everything is visible before you sell. Uncheck anything you want to keep. Nothing sells without your approval.
- **Clean, modern look** — Dark flat UI that fits right in with ElvUI and similar setups. Scales, repositions, and remembers where you left it.

---

## Features

- **Merchant popup window** — opens automatically when you visit a vendor
- **Modern flat UI** — ElvUI-inspired dark aesthetic with 1px borders, styled checkboxes, sliders, buttons, and fade-in animation
- **Filter controls** — toggle selling of gray, green, and blue items with ilvl sliders and editable number inputs
- **Smart ilvl defaults** — slider thresholds auto-set to `min(avgEquippedIlvl, lowestEquippedIlvl) - 10` on first use
- **Equipped ilvl comparison** — each equippable item shows its ilvl alongside the equipped slot's ilvl (e.g. `165 (eq:160)`)
- **Upgrade protection** — equippable items above your equipped ilvl are highlighted green and never auto-checked
- **Average equipped ilvl** displayed above the item list for quick reference
- **Scrollable item list** — see every vendorable item with checkboxes, quality-bordered icons, ilvl, and price
- **Auto-check by threshold** — greens and blues at or below the ilvl slider are pre-checked for selling
- **Select/deselect items** individually or in bulk before selling
- **Safety protections:**
  - Never sells items in equipment sets
  - Never sells uncollected transmog appearances
  - Never sells refundable items
  - Never sells items with no vendor price
  - Never sells equippable upgrades over currently worn gear
- **Never-sell and always-sell lists** managed via slash commands
- **Dry run mode** to preview what would be sold
- **Buyback warning** when selling more than 12 items
- **Throttled selling** to avoid client errors (batches of 10 with 0.2s delay)
- **Blizzard Settings panel** for safety and output options
- **All settings persist** between sessions — filter states, ilvl thresholds, popup position, and scale
- **Ctrl+Scroll to scale** the popup (0.6x to 1.5x)
- **Drag to reposition** — popup position saved across sessions

## Installation

1. Download and extract to your WoW addons folder:
   ```
   World of Warcraft/_retail_/Interface/AddOns/AutoSellPlus/
   ```
2. Ensure the folder contains: `AutoSellPlus.toc`, `Config.lua`, `Helpers.lua`, `UI.lua`, `Popup.lua`, `Core.lua`
3. Restart WoW or type `/reload` if the game is running

Alternatively, run the included install script:
```bash
./install.sh
```

## How It Works

When you open a merchant window, AutoSellPlus shows a popup with:

1. **Filter bar** at the top — styled checkboxes for gray/green/blue items, flat sliders with editable number inputs for ilvl thresholds, and an "Only Equippable" toggle
2. **Equipped ilvl info** — your average equipped ilvl displayed below the filters, with per-item equipped slot comparison in each row
3. **Scrollable item list** — all vendorable items that pass safety checks, filtered by your settings. Items are color-coded by quality with quality-bordered icons, showing ilvl and vendor price
4. **Bottom bar** — total gold and item count for checked items, plus Select All / Deselect All / Cancel / Sell Selected buttons

### Filtering and Auto-Check Logic

- **Gray items** are always pre-checked when "Sell Grays" is enabled
- **Green items** are pre-checked when their ilvl is at or below the green ilvl threshold
- **Blue items** are pre-checked when their ilvl is at or below the blue ilvl threshold
- **Upgrade protection** overrides auto-check: equippable items with ilvl higher than the equipped slot are never auto-checked, even if below the threshold. Their ilvl text is colored green to indicate they're upgrades
- **Smart defaults**: on first use (sliders at 0), thresholds auto-set to `min(avgEquippedIlvl, lowestEquippedIlvl) - 10`

Items on the never-sell list are excluded. Items on the always-sell list always appear and are pre-checked. Equipment set items, uncollected transmog, refundable items, and no-value items are automatically excluded.

Click **Sell Selected** to sell all checked items, or **Cancel** / press Escape to close without selling. Closing the merchant window also closes the popup.

## Slash Commands

| Command | Description |
|---------|-------------|
| `/asp` or `/asp help` | Show help |
| `/asp toggle` | Enable/disable the addon |
| `/asp dryrun` | Toggle dry run mode |
| `/asp config` | Open the settings panel |
| `/asp add <itemID>` | Add an item to the never-sell list |
| `/asp remove <itemID>` | Remove an item from the never-sell list |
| `/asp list` | Show never-sell and always-sell lists |

You can also use `/autosell` as an alias for `/asp`.

## Configuration

Open the settings panel with `/asp config` or navigate to **Options > AddOns > AutoSellPlus**.

### General
- **Enable AutoSellPlus** — Master toggle for the popup appearing on merchant visit

### Safety
- **Protect Equipment Sets** — Never sell items in any equipment set
- **Protect Uncollected Transmog** — Never sell items with uncollected appearances

### Output
- **Show Summary** — Print total gold earned after selling
- **Show Itemized Sales** — Print each item sold individually
- **Dry Run Mode** — Preview sales without selling
- **Buyback Warning** — Warn when exceeding the 12-item buyback limit

### Popup Filter Controls
These settings live on the popup itself and persist between sessions:
- **Sell Grays / Greens / Blues** — Toggle which quality tiers appear and auto-check
- **ilvl sliders + editable inputs** — Set max item level threshold for greens and blues (type a number or drag the slider)
- **Only Equippable** — Hide non-weapon/armor greens and blues
- **Ctrl+Scroll** — Scale the popup up or down (saved between sessions)
- **Drag** — Reposition the popup (saved between sessions)
