AutoSellPlus sells your junk at vendors with configurable quality and ilvl filters, transmog protection, and per-character profiles. Mark items as junk while looting, preview what will be sold before confirming, and protect gear you want to keep -- including uncollected appearances, BoEs, and equipment sets.

Lightweight, modular, and self-testing on login so it keeps working through patches.

![AutoSellPlus popup](https://media.forgecdn.net/attachments/1567/371/screenshot-2026-03-06-at-11-21-55a-am-png.png)

---

## Selling

- **Popup preview** -- sortable columns (name, ilvl, vendor price, AH value), checkboxes, one-click Sell All
- **Three sell modes** -- interactive popup (default), one-click, or fully automatic with configurable delay
- **Quality filters** -- gray through epic, each with independent ilvl thresholds
- **Category filters** -- consumables, trade goods, quest items, miscellaneous
- **Expansion and slot filters** -- narrow results by expansion or equipment slot
- **Confirmations** -- epic, high-value, and Sell All Junk show a confirmation with item count and gold total
- **Buyback safety** -- highest-value items are sold first so buyback slots hold the most valuable items
- **Dry run** -- preview what would be sold without actually selling
- **Auto-repair** -- repairs gear at vendors, guild funds first
- **Key binding** -- bind a key to open the sell popup at any vendor via WoW's Key Bindings UI

---

## Protection

- **Never-sell / Always-sell lists** -- global and per-character
- **Transmog** -- source-level appearance checking; uncollected items are never sold
- **Equipment sets** -- items in any saved gear set are protected
- **BoE** -- unbound Bind on Equip items are protected
- **Soulbound-only mode** -- optionally skip all unbound BoE items, useful for dungeon farmers keeping BoE for AH
- **Quest items** -- items in the Quest Items category are protected by default
- **Current expansion materials** -- optionally protect Trade Goods from the current expansion
- **Refundable** -- items in the vendor refund window are skipped
- **Addon hooks** -- AllTheThings and CanIMogIt integration for enhanced transmog detection

---

## Marking

- **ALT+Click** -- mark/unmark items in bags as junk (configurable overlay: border, tint, or both)
- **Drag-to-mark** -- button appears above bags
- **Auto-mark on loot** -- gray items and equippable items below an ilvl threshold
- **Bulk mark mode** -- `/asp mark` to mark multiple items without holding ALT
- **Bag addon support** -- Bagnon, AdiBags, ArkInventory, Baganator

---

## Bag Management

- **Bag space guard** -- automatically suggests selling the cheapest junk when free slots are low
- **Stack limits** -- set max quantities per item, excess goes into the sell queue
- **Free slot alerts** -- chat message or on-screen warning when bag space is low
- **Bag gold display** -- total vendor value shown above the backpack button

---

## Tracking

- **Session tracker** -- gold/hour calculation in the minimap button tooltip
- **Sale history** -- scrollable panel showing the last 200 sales; shift-click to link items in chat
- **Per-character stats** -- lifetime sales totals visible across alts
- **Undo** -- 5-minute buyback window with visual toast notification

---

## Profiles

- **Built-in templates** -- Raid Farmer, Transmog Hunter, Leveling Alt, Gold Farmer
- **Named profiles** -- save and load settings that persist across sessions
- **Auto-load** -- last loaded profile restores automatically on login
- **Instance auto-profiles** -- auto-switch profiles when entering raids, dungeons, battlegrounds, or open world
- **Import / Export** -- share never-sell and always-sell lists as strings

---

## Slash Commands

Type `/asp` or `/autosell` for the full command list. Key commands:

- `/asp config` -- Open settings
- `/asp sell` -- Sell at vendor
- `/asp preview` -- Dry run
- `/asp undo` -- Buyback last sale
- `/asp mark` -- Toggle bulk-mark mode
- `/asp template [name]` -- Apply a preset
- `/asp profile save/load [name]` -- Manage profiles
- `/asp session` -- View session stats
- `/asp log ui` -- Open sale history
- `/asp keep [id] [count]` -- Set stack limits
- `/asp wizard` -- Re-run setup wizard

---

## Integrations

- **TSM / Auctionator** -- AH price column in popup
- **Bagnon / AdiBags / ArkInventory / Baganator** -- junk mark overlays in bag frames
- **AllTheThings / CanIMogIt** -- enhanced transmog protection
- **Leatrix Plus** -- conflict detection

---

## Resilience

AutoSellPlus runs a self-test on login. If a WoW API is missing after a patch, the affected feature is disabled individually while everything else keeps working. No full addon breakage from a single API change.

---

- **Source:** [GitHub](https://github.com/mikigraf/AutoSellPlus)
- **Issues:** [GitHub Issues](https://github.com/mikigraf/AutoSellPlus/issues)
