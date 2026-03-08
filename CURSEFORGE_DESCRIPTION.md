Smart junk selling for WoW Retail. Configure quality and ilvl filters, protect uncollected transmog and BoEs, mark items as junk from your bags, and preview everything before it's sold. Profiles sync account-wide so you set up once and every alt just works.

Self-tests on login — if a WoW API changes after a patch, only the affected feature disables while everything else keeps running.

![AutoSellPlus popup](https://media.forgecdn.net/attachments/1567/371/screenshot-2026-03-06-at-11-21-55a-am-png.png)

---

&nbsp;

## Selling

<<<<<<< Updated upstream
- **Popup preview** -- sortable columns (name, ilvl, vendor price, AH value), checkboxes, one-click Sell All
- **Three sell modes** -- interactive popup (default), one-click, or fully automatic with configurable delay
- **Quality filters** -- gray through epic, each with independent ilvl thresholds
- **Category filters** -- consumables, trade goods, quest items, miscellaneous
- **Expansion and slot filters** -- narrow results by expansion or equipment slot
- **Confirmations** -- epic and high-value items show a scrollable item list of exactly what will be sold
- **Buyback safety** -- items beyond the 12-item buyback limit are flagged visually
- **Dry run** -- preview what would be sold without actually selling
- **Auto-repair** -- repairs gear at vendors, guild funds first
=======
| | |
|:---|:---|
| **Popup preview** | Sortable columns (name, ilvl, vendor price, AH value) with per-item checkboxes |
| **In-popup settings** | Items / Settings tabs — change any setting without leaving the vendor |
| **Three sell modes** | Interactive popup (default), one-click, or fully automatic with delay |
| **Quality filters** | Gray through epic, each with an independent ilvl threshold |
| **Category filters** | Consumables, trade goods, quest items, miscellaneous |
| **Expansion & slot filters** | Narrow results by expansion or equipment slot |
| **Confirmations** | Epic, high-value, and Sell All show a dialog with item count and gold total |
| **Buyback safety** | Most valuable items sold first so buyback slots hold the expensive ones |
| **Dry run** | Preview what would be sold without actually selling |
| **Auto-repair** | Repairs gear at vendors, guild funds first |
| **Key binding** | Bind a key to open the popup at any vendor |
>>>>>>> Stashed changes

---

&nbsp;

## Protection

<<<<<<< Updated upstream
- **Never-sell / Always-sell lists** -- global and per-character
- **Transmog** -- source-level appearance checking; uncollected items are never sold
- **Equipment sets** -- items in any saved gear set are protected
- **BoE** -- unbound Bind on Equip items are protected
- **Refundable** -- items in the vendor refund window are skipped
- **Addon hooks** -- AllTheThings and CanIMogIt integration for enhanced transmog detection
=======
| | |
|:---|:---|
| **Never-sell / Always-sell lists** | Global and per-character |
| **Transmog** | Source-level appearance checking — uncollected items are never sold |
| **Equipment sets** | Items in any saved gear set are protected |
| **BoE** | Unbound Bind on Equip items are protected |
| **Soulbound-only mode** | Skip all unbound BoE items — useful for keeping drops for the AH |
| **Quest items** | Quest Items category protected by default |
| **Current expansion materials** | Optionally protect Trade Goods from the current expansion |
| **Refundable** | Items in the vendor refund window are skipped |
| **Addon hooks** | AllTheThings and CanIMogIt for enhanced transmog detection |
>>>>>>> Stashed changes

---

&nbsp;

## Marking

- **ALT+Click** items in bags to mark or unmark as junk (overlay: border, tint, or both)
- **Drag-to-mark** button above bags
- **Auto-mark on loot** for gray items and equippable gear below an ilvl threshold
- **Bulk mark mode** via `/asp mark` — no need to hold ALT
- Works with **Bagnon**, **AdiBags**, **ArkInventory**, and **Baganator**

---

&nbsp;

## Bag Management

- **Bag space guard** suggests selling the cheapest junk when free slots are low
- **Stack limits** — set max quantities per item; excess goes into the sell queue
- **Free slot alerts** via chat or on-screen warning
- **Bag gold display** — total vendor value shown above the backpack button

---

&nbsp;

## Tracking

<<<<<<< Updated upstream
- **Session tracker** -- gold/hour calculation in the minimap button tooltip
- **Sale history** -- scrollable panel showing the last 200 sales
- **Per-character stats** -- lifetime sales totals visible across alts
- **Undo** -- 5-minute buyback window with visual toast notification
=======
- **Session tracker** with gold/hour calculation in the minimap tooltip
- **Sale history** — scrollable panel of the last 200 sales; shift-click to link items in chat
- **Per-character stats** — lifetime totals visible across alts
- **Undo** — 5-minute buyback window with a visual toast notification
>>>>>>> Stashed changes

---

&nbsp;

## Profiles

<<<<<<< Updated upstream
- **Built-in templates** -- Raid Farmer, Transmog Hunter, Leveling Alt, Gold Farmer
- **Named profiles** -- save and load settings that persist across sessions
- **Auto-load** -- last loaded profile restores automatically on login
- **Import / Export** -- share never-sell and always-sell lists as strings
=======
- **Built-in templates:** Raid Farmer, Transmog Hunter, Leveling Alt, Gold Farmer
- **Named profiles** that save and load across sessions
- **Auto-load** — last loaded profile restores on login
- **Instance auto-profiles** — switch automatically for raids, dungeons, battlegrounds, or open world
- **Import / Export** never-sell and always-sell lists as shareable strings
>>>>>>> Stashed changes

---

&nbsp;

## Slash Commands

Type `/asp` or `/autosell` for the full list.

| Command | |
|:---|:---|
| `/asp config` | Open settings |
| `/asp sell` | Sell at vendor |
| `/asp preview` | Dry run |
| `/asp undo` | Buyback last sale |
| `/asp mark` | Toggle bulk-mark mode |
| `/asp template [name]` | Apply a preset |
| `/asp profile save/load [name]` | Manage profiles |
| `/asp session` | View session stats |
| `/asp log ui` | Open sale history |
| `/asp keep [id] [count]` | Set stack limits |
| `/asp wizard` | Re-run setup wizard |

---

&nbsp;

## Integrations

| Addon | |
|:---|:---|
| **TSM / Auctionator** | AH price column in the popup |
| **Bagnon / AdiBags / ArkInventory / Baganator** | Junk mark overlays in bag frames |
| **AllTheThings / CanIMogIt** | Enhanced transmog protection |
| **Leatrix Plus** | Conflict detection |

---

- **Source:** [GitHub](https://github.com/mikigraf/AutoSellPlus)
- **Issues:** [GitHub Issues](https://github.com/mikigraf/AutoSellPlus/issues)
