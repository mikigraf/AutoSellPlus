# AutoSellPlus - Complete Feature Documentation

AutoSellPlus is a World of Warcraft addon that shows a popup when visiting a merchant to review and sell junk items. It targets the Midnight expansion (Interface 120001), has zero external dependencies, and is distributed via CurseForge.

---

## Table of Contents

1. [Auto-Sell Modes](#auto-sell-modes)
2. [Merchant Popup Panel](#merchant-popup-panel)
3. [Quality & Item Level Filters](#quality--item-level-filters)
4. [Category Filters](#category-filters)
5. [Expansion & Slot Filters](#expansion--slot-filters)
6. [Item Protection System](#item-protection-system)
7. [Junk Marking System](#junk-marking-system)
8. [Confirmation Dialogs & Item List](#confirmation-dialogs--item-list)
9. [Selling Process](#selling-process)
10. [Undo System](#undo-system)
11. [Sale History](#sale-history)
12. [Session Tracking](#session-tracking)
13. [Stack Limits](#stack-limits)
14. [Value-Based Eviction](#value-based-eviction)
15. [Auto-Repair](#auto-repair)
16. [Destruction System](#destruction-system)
17. [Bag Space Monitoring](#bag-space-monitoring)
18. [Minimap Button](#minimap-button)
19. [Bag Gold Display](#bag-gold-display)
20. [Profiles & Templates](#profiles--templates)
21. [Never-Sell & Always-Sell Lists](#never-sell--always-sell-lists)
22. [Setup Wizard](#setup-wizard)
23. [Settings Panel](#settings-panel)
24. [Third-Party Addon Integration](#third-party-addon-integration)
25. [WeakAura Integration](#weakaura-integration)
26. [Slash Commands](#slash-commands)
27. [All Settings Reference](#all-settings-reference)
28. [Data Structures](#data-structures)
29. [Shift-Click Item Links in History](#shift-click-item-links-in-history)
30. [Sell-All Confirmation Dialog](#sell-all-confirmation-dialog)
31. [Soulbound-Only Filter](#soulbound-only-filter)
32. [Current Expansion Materials Protection](#current-expansion-materials-protection)
33. [Key Bindings](#key-bindings)
34. [Instance Auto-Profile Switching](#instance-auto-profile-switching)
35. [Priority Sell Queue](#priority-sell-queue)
36. [Quest Item Protection](#quest-item-protection)
37. [Tooltip Item Status](#tooltip-item-status)
38. [Compact Mode](#compact-mode)
39. [AH Value Protection](#ah-value-protection)
40. [Safe Mode Template](#safe-mode-template)
41. [Destruction System](#destruction-system)

---

## Auto-Sell Modes

The addon supports three modes of operation, configurable via settings or the setup wizard.

### Popup Mode (Default)
When visiting a vendor, a full interactive popup appears showing all sellable items. The user reviews items, selects/deselects them, and clicks "Sell Selected" or "Sell All". This is the safest mode, giving full control before any sale.

### One-Click Mode
Similar to popup mode but with a prominent sell button for quick selling after a brief visual review. The popup still appears but is optimized for fast interaction.

### Auto-Sell Mode
Items are sold automatically when visiting any vendor. An optional delay (0-10 seconds) can be configured to give time to cancel. Auto-sell can be cancelled by closing the merchant window before the delay expires. A countdown message is shown during the delay.

---

## Merchant Popup Panel

The popup is the primary UI for reviewing items before selling. It appears when visiting a merchant (in popup/oneclick modes).

### Dimensions & Behavior
- Default size: 580x620 pixels
- Draggable by title bar
- Resizable via Ctrl+Scroll (scale range 0.6x to 1.5x)
- Flat 1px border aesthetic (ElvUI-style)

### Filter Controls (Top Section)
Quality checkboxes with per-quality item level threshold sliders and input fields. Additional toggles for "Only Equippable", "Allow Transmog" (disables transmog protection so uncollected appearances can be sold), "Soulbound Only" (skip all unbound BoE items), category filters, expansion filter dropdown, and equipment slot filter buttons.

### Item List (Middle Section)
Sortable columns:
- **Item Name** (default sort) - quality-colored text with icon
- **Item Level** - shows effective ilvl with equipped comparison (e.g. "439 (eq:421)")
- **AH Price** - auction house value if TSM or Auctionator is installed
- **Vendor Price** - sell price at merchant

Each row displays:
- Item icon with quality-colored border
- Status badges: "BoE" (bind-on-equip), "Junk" (manually marked)
- Green text for upgrades, gray for downgrades (ilvl comparison)
- Green AH value if >10x vendor price, yellow if >2x, gray otherwise
- Coin warning icon on high-value items
- Checkbox for selection
- Hover tooltip with full item details
- Right-click context menu for list management

### Right-Click Context Menu
When right-clicking an item row:
- Add to never-sell list (global, account-wide)
- Add to never-sell list (this character only)
- Add to always-sell list (global, account-wide)
- Add to always-sell list (this character only)
- Remove from all lists
- The bag item flashes briefly to confirm the action

### Drag-to-Sell Button
Located bottom-left of the popup. Drag any item from bags onto this button to sell it instantly. The sale is recorded in history and session stats.

### Bottom Bar
- Total gold and item count for selected/visible items
- Session earnings display (updates in real-time)
- Sell progress bar during active selling (shows percentage)

### Control Buttons
- **Sell Selected** - sell only checked items
- **Sell All** - check all gray/marked items and show a confirmation dialog with total count and gold value before selling
- **Select All** - check all visible items
- **Clear Selection** - uncheck all items
- **Close (X)** - dismiss popup

---

## Quality & Item Level Filters

Each quality tier has an independent enable toggle and item level threshold.

| Quality | Setting | Default | iLvl Threshold | Default |
|---------|---------|---------|----------------|---------|
| Poor (Gray) | `sellGrays` | On | N/A | N/A |
| Common (White) | `sellWhites` | Off | `whiteMaxIlvl` | 0 (all) |
| Uncommon (Green) | `sellGreens` | Off | `greenMaxIlvl` | 0 (all) |
| Rare (Blue) | `sellBlues` | Off | `blueMaxIlvl` | 0 (all) |
| Epic (Purple) | `sellEpics` | Off | `epicMaxIlvl` | 0 (all) |

When a quality is enabled with an ilvl threshold > 0, only items at or below that ilvl are included. A threshold of 0 means all items of that quality are included (no ilvl restriction).

The **"Only Equippable"** toggle (`onlyEquippable`, default: true) limits non-gray quality filters to armor and weapons only, preventing accidental sale of valuable non-gear items.

### Relative iLvl Threshold

When **"Relative iLvl"** (`useRelativeIlvl`, default: off) is enabled, a single ilvl threshold is computed as a percentage of the player's average equipped ilvl (`relativeIlvlPercent`, default: 70%). This replaces all per-quality ilvl sliders with one unified threshold that auto-adjusts as gear improves.

- Example: avg equipped ilvl 620 at 70% → sell threshold is 434
- The popup header shows the computed threshold when active
- Per-quality ilvl sliders are grayed out while relative mode is on
- The slider ranges from 10% to 100% in steps of 5

---

## Category Filters

Additional item category toggles for non-equipment items:

| Category | Setting | Default | Item ClassID |
|----------|---------|---------|-------------|
| Consumables | `sellConsumables` | Off | 0 |
| Trade Goods | `sellTradeGoods` | Off | 7 |
| Quest Items | `sellQuestItems` | Off | 12 |
| Miscellaneous | `sellMiscItems` | Off | 15 |

These allow selling non-gear items that pass the other filter criteria.

---

## Expansion & Slot Filters

### Expansion Filter
Filter items by which WoW expansion they belong to. Options: All (0), Classic (1), TBC (2), WotLK (3), Cata (4), MoP (5), WoD (6), Legion (7), BfA (8), SL (9), DF (10), TWW (11), Midnight (12).

An additional "Exclude Current Expansion" checkbox hides items from the current expansion (Midnight) from the popup entirely.

### Equipment Slot Filter
Toggle which equipment slots appear in the popup. Buttons are displayed as compact labels: H (Head), S (Shoulder), C (Chest), W (Waist), L (Legs), F (Feet), Wr (Wrist), G (Hands), Bk (Back), MH (Main Hand), OH (Off Hand). Rings, Trinkets, and Neck are also included as slot IDs.

---

## Item Protection System

Items are evaluated against protection rules in strict priority order. The first matching rule wins.

### Protection Priority (in ShouldSellItem)

1. **Never-Sell List** - items on the global or per-character never-sell list are always skipped
2. **Always-Sell List** - items on the global or per-character always-sell list are always sold (if they have a vendor price)
3. **Marked Items** - items manually marked as junk are sold (if they have a vendor price)
4. **Sell Price Check** - items with no vendor price are skipped
5. **Locked Items** - locked items are skipped
6. **Equipment Set Protection** (`protectEquipmentSets`, default: on) - items in any active equipment set are skipped
7. **Uncollected Transmog** (`protectUncollectedTransmog`, default: on) - items with visual transmog appearances that are uncollected are skipped (trinkets, rings, and necklaces are excluded from this check since they have no visual appearance)
8. **Transmog Source Protection** (`protectTransmogSource`, default: on) - enhanced source-level transmog checking (distinguishes same-appearance items from different sources)
9. **Refundable Items** - items within the vendor buyback/refund window are skipped
10. **Quest Item Protection** (`protectQuestItems`, default: on) - items in the Quest Items category (classID 12) are skipped
11. **Bind-on-Equip Protection** (`protectBoE`, default: on) - unbound BoE items are skipped (overridable via `allowBoESell`)
12. **Soulbound-Only Mode** (`onlySoulbound`, default: off) - when enabled, unbound BoE items are always skipped
13. **Current Expansion Materials** (`protectCurrentExpMaterials`, default: off) - Trade Goods from the current expansion are skipped
14. **Sell Collected Transmog** (`sellCollectedTransmog`, default: off) - items with already-collected transmog appearances are sold
15. **Sell Known Collectibles** (`sellKnownCollectibles`, default: off) - already-known mounts, pets, and toys are sold
16. **Quality Filters** - items matching enabled quality tiers (and within ilvl thresholds) are included
17. **Category Filters** - items matching enabled category toggles are included

---

## Junk Marking System

Allows manual marking of specific items as junk for targeted selling.

### How to Mark Items
1. **ALT+Click** an item in your bags to toggle its junk mark
2. **Drag** an item to the "Mark as Junk" button (appears above bags when open)
3. **Right-click** an item in the popup and select "Always sell"
4. **Auto-mark gray loot** when looted (`autoMarkGrayLoot`, default: off)
5. **Auto-mark below ilvl** when looting equippable items below a threshold (`autoMarkBelowIlvl`, default: 0/off)

### Bulk Mark Mode
Toggle with `/asp mark`. While active, clicking items in bags marks/unmarks them without needing to hold ALT. Useful for marking many items quickly.

### Visual Indicators
- Marked items display an orange/gold coin icon overlay in bags
- Overlay mode is configurable: `"border"` (outline only), `"tint"` (color wash), or `"full"` (both)
- Cycle modes with `/asp overlay`
- Baganator addon: corner widget integration for marked items
- Tooltips show "[Marked as Junk]" indicator on marked items

---

## Confirmation Dialogs & Item List

Safety confirmation popups appear before selling in certain conditions. Each dialog now shows an **item list panel** anchored below it.

### Confirmation Triggers

| Dialog | Trigger | Context |
|--------|---------|---------|
| ASP_SELL_ALL_CONFIRM | "Sell All Junk" button clicked | Popup sell-all |
| ASP_EPIC_CONFIRM | Queue contains epic items | Popup sell |
| ASP_HIGH_VALUE_CONFIRM | Items exceed `highValueThreshold` | Popup sell |
| ASP_AUTOSELL_EPIC_CONFIRM | Queue contains epic items | Auto-sell |
| ASP_AUTOSELL_HIGHVALUE_CONFIRM | Items exceed `highValueThreshold` | Auto-sell |
| ASP_EVICT_CONFIRM | Eviction suggests selling items | Bags-full eviction |

### Confirmation Item List Panel
When any sell confirmation dialog appears, a scrollable item list panel appears anchored below it:

- **Title:** "Items to sell:"
- **Item rows (24px each):** icon with quality-colored border, quality-colored item name, vendor price in gold
- **Tooltip on hover:** full item tooltip via GameTooltip
- **Buyback limit divider:** a red "-- Beyond Buyback Limit --" divider is inserted before item 13
- **Red-tinted rows:** items 13 and beyond get a red background tint (these items cannot be repurchased from the vendor's buyback tab)
- **Total bar:** "Total: Xg Xs (N items)" with count
- **Buyback warning:** "N beyond buyback limit" in red text when applicable
- **Scrollable:** max 10 visible rows before scrolling kicks in
- **Width:** ~300px, anchored below the active StaticPopup dialog
- **Auto-cleanup:** panel hides when the dialog is dismissed (accept, cancel, escape, or merchant closed)

### Settings
- `epicConfirm` (default: on) - require confirmation before selling epic items
- `highValueConfirm` (default: on) - require confirmation for high-value items
- `highValueThreshold` (default: 50000 copper / 5g) - price threshold for high-value warning
- `buybackWarning` (default: on) - warn when selling more than 12 items

---

## Selling Process

The complete sell flow works as follows:

1. **Build Sell Queue** - iterate all bag slots, apply protection rules and filters to determine sellable items
2. **Priority Sort** - if `prioritySellQueue` is enabled (default), sort queue by total value descending so the most valuable items occupy the 12 buyback slots
3. **Verify Queue** - re-check that items are still present in bags before proceeding
4. **Show Confirmations** - if epic or high-value items are in the queue, display confirmation dialogs with the item list panel
4. **Mute Sounds** - silence vendor sell sounds during bulk selling (if `muteVendorSounds` enabled)
5. **Process Batches** - sell 10 items per tick with 0.2 second delay between batches (prevents server throttling)
6. **Record History** - add each sold item to the sale history table
7. **Update Session** - increment session copper and item counters
8. **Show Progress** - update the popup's selling progress bar with percentage
9. **Finish** - print summary to chat, create undo buffer, update per-character stats, fire WeakAura event

### Dry Run Mode
When `dryRun` is enabled, the entire sell process runs but no items are actually sold. The addon prints what would have been sold with full details. Useful for testing filter configurations.

---

## Undo System

After selling, an undo notification toast appears (if `showUndoToast` is on).

- Displays for 8 seconds after selling completes
- Shows item count and total gold earned
- "Undo" button repurchases items from the vendor's buyback tab
- Undo buffer expires after 5 minutes
- Limited to 12 items (WoW buyback limit)
- If items can't be repurchased, a link to Blizzard's item restoration page is provided
- Triggered via `/asp undo` or the toast button

---

## Sale History

Persistent record of recent sales stored in `AutoSellPlusDB.saleHistory`.

### Storage
- Maximum 200 entries (FIFO - oldest removed first)
- Each entry records: item link, item ID, quantity, total price, timestamp

### History Panel UI
Scrollable list with reverse-chronological sorting:
- Item icon
- Item name/link (clickable)
- Quantity sold
- Total sale price (gold-colored text)
- Time elapsed ("Xs ago", "Xm ago", "Xh ago", "Xd ago")
- Summary bar showing total sales count and combined gold
- Tooltip on hover showing full item details (when item link is available)
- Shift+left-click a row to insert the item link into chat
- Clear button with confirmation dialog to wipe all history
- Access via `/asp log ui` or Shift+Right-click minimap button

### Chat Commands
- `/asp log` - print last 10 sales to chat
- `/asp log 20` - print last 20 sales
- `/asp log clear` - wipe all history

---

## Session Tracking

Tracks selling activity for the current play session.

### Tracked Data
- Total items sold this session
- Total copper earned this session
- Session start time
- Gold per hour calculation

### Access
- `/asp session` - print session stats to chat
- `/asp session reset` - reset session counters
- `/asp session export` - export formatted summary
- Minimap button tooltip shows session stats
- Popup bottom bar shows session earnings in real-time

---

## Stack Limits

Set maximum quantities per item. Excess is automatically included in sell queues.

### How It Works
When a stack limit is set for an item, any quantity above the limit is flagged for selling. For example, setting a limit of 20 for an item means if you have 35, the excess 15 will be sold.

### Commands
- `/asp keep <itemID> <count>` - set limit (e.g. `/asp keep 12345 20`)
- `/asp keep list` - show all configured limits
- `/asp keep clear` - clear all limits
- `/asp keep clear <itemID>` - clear limit for one item

---

## Value-Based Eviction

Automatically suggests selling cheapest items when bags are full at a vendor.

### How It Works
1. Checks if free bag slots are below `freeSlotThreshold`
2. Scans bags for sellable items (poor quality and marked items only)
3. Sorts candidates by total price ascending (cheapest first)
4. Selects the minimum number of items needed to reach the threshold
5. Shows a confirmation dialog with the eviction list and item list panel

### Settings
- `evictionEnabled` (default: off)
- `freeSlotThreshold` (default: 0 / disabled) - minimum free slots to maintain

### Protections
Eviction candidates must pass: not locked, not in never-sell list, not refundable, not in equipment sets, must have a vendor sell price.

---

## Auto-Repair

Automatically repairs all gear when visiting a repair-capable merchant.

### Behavior
1. Checks if merchant can repair (`CanMerchantRepair()`)
2. If guild repair is enabled and player is in a guild, attempts guild bank repair first
3. Falls back to personal gold if guild repair unavailable or fails
4. Prints repair cost to chat (or shows needed vs available gold if insufficient)

### Settings
- `autoRepair` (default: off)
- `autoRepairGuild` (default: on) - prefer guild funds

---

## Destruction System

Complete item destruction system for clearing worthless items when not at a vendor.

### Protection Chain
Items pass through a separate destruction protection chain before being eligible:
1. Never-destroy list (manual blacklist)
2. Never-sell list (also blocks destruction)
3. Equipment set items (if `destroyProtectEquipmentSets` enabled)
4. Uncollected transmog (if `destroyProtectTransmog` enabled)
5. BoE items (if `destroyProtectBoE` enabled)
6. Refundable items (always skipped)
7. Quality filter (`destroyMaxQuality`)
8. Item level filter (`destroyMaxIlvl`)
9. Vendor value filter (`destroyMaxVendorValue`)

### Countdown Confirmation
Before destroying, a confirmation popup appears with:
- Red-themed dialog listing items to destroy (up to 10 shown, remainder counted)
- Vendor value being lost
- Countdown timer on the Destroy button (configurable, default 3 seconds)
- Cancel button to abort

### Cursor Safety
Each item is destroyed one at a time (0.3s per tick) with full cursor verification:
1. `ClearCursor()` to ensure clean state
2. `PickupContainerItem()` to pick up the item
3. `GetCursorInfo()` to verify the correct item is on the cursor
4. `DeleteCursorItem()` only if itemID matches
5. Skips with a warning if cursor has wrong item (e.g., player dragging something)

### Bag Pressure Valve
Automatically triggers the destruction confirmation when free bag slots drop below a configured threshold:
- Fires on `BAG_UPDATE_DELAYED` events
- 60-second cooldown between triggers to avoid spam
- Only triggers when destruction is enabled and not already in progress
- Shows the same confirmation popup (never auto-destroys silently)

### Never-Destroy List
Separate per-item blacklist for destruction (independent from never-sell list):
- `/asp neverdestroy add <ItemLink>` — add item to never-destroy list
- `/asp neverdestroy remove <ItemLink>` — remove item
- `/asp neverdestroy list` — show all items on the list
- Also manageable via Settings > Lists > Never-Destroy tab

### Settings
- `destroyEnabled` (default: off) — enable destruction feature
- `destroyMaxQuality` (default: 0 / Poor only) — max quality to destroy (0-4)
- `destroyMaxIlvl` (default: 0 / disabled) — max ilvl for equippable items
- `destroyMaxVendorValue` (default: 0 / unlimited) — max total vendor value (copper)
- `destroyConfirmCountdown` (default: 3) — seconds before Destroy button activates
- `destroyFreeSlotTrigger` (default: 0 / disabled) — bag pressure valve threshold
- `destroyProtectTransmog` (default: on) — protect uncollected transmog
- `destroyProtectBoE` (default: on) — protect bind-on-equip items
- `destroyProtectEquipmentSets` (default: on) — protect equipment set items

### Command
- `/asp destroy` — trigger item destruction

---

## Bag Space Monitoring

Real-time monitoring of free bag slots with alerts.

### Behavior
When free slots drop below the configured threshold, an alert is triggered. Alerts have a 60-second cooldown to avoid spam.

### Alert Modes
- `"chat"` - prints message to chat window
- `"screen"` - displays on-screen error frame message (red text)

### Settings
- `freeSlotThreshold` (default: 0 / disabled)
- `freeSlotAlertMode` (default: "chat")

---

## Minimap Button

A draggable button on the minimap border providing quick access.

### Tooltip Information
- AutoSellPlus version
- Current session income and items sold
- Today's totals
- Per-character statistics (if multiple alts tracked)
- Interaction hints

### Interactions
| Action | Result |
|--------|--------|
| Left-Click | Open settings panel |
| Shift+Left-Click | Print session stats |
| Right-Click | Toggle addon enabled/disabled |
| Shift+Right-Click | Open sale history panel |
| Drag | Reposition around minimap |

### Settings
- `showMinimapButton` (default: on)
- `minimapButtonAngle` (default: 225) - position in degrees around minimap

---

## Bag Gold Display

Optional floating text above the backpack button showing total vendor value of all bag contents.

### Display
- Shows total vendor value formatted as gold
- Hover tooltip breaks down value by quality tier
- Shows marked item total separately
- Auto-updates when bags change

### Settings
- `showBagGoldDisplay` (default: off)

---

## Profiles & Templates

### Profiles
Save, load, and manage named setting configurations.

- `/asp profile save <name>` - save current settings
- `/asp profile load <name>` - load saved profile
- `/asp profile delete <name>` - delete profile
- `/asp profile list` - list all profiles
- Per-character auto-load: the last loaded profile is restored on login (with chat notification)
- Instance auto-profiles: automatically load a profile when entering a specific instance type (raid, dungeon, pvp, arena, scenario, open world)
- Delete profile from the settings UI shows a confirmation dialog

### Templates
Pre-built setting bundles for common playstyles:

| Template | Description |
|----------|-------------|
| **Raid Farmer** | Aggressively sells grays, whites, and greens. Protects transmog, equipment sets, and BoE. Popup mode. |
| **Transmog Hunter** | Conservative - only sells grays. Maximum transmog protection (appearance + source level). Protects BoE. |
| **Leveling Alt** | Fast auto-selling for alts. Sells grays through blues. Auto-sell with 2-second delay. Protects BoE. |
| **Gold Farmer** | Maximum income. Sells grays through blues. Includes consumables and trade goods. No transmog protection. Non-equippable items allowed. |

- `/asp template list` - list available templates
- `/asp template "Raid Farmer"` - apply template (resets all settings to template defaults)

---

## Never-Sell & Always-Sell Lists

### Never-Sell List
Items that are never sold regardless of any filter settings.

- **Global (account-wide):** stored in `AutoSellPlusDB.neverSellList`
- **Per-character:** stored in `AutoSellPlusCharDB.charNeverSellList`
- Takes highest priority in protection checks

### Always-Sell List
Items that are always sold (if they have a vendor price), bypassing quality/ilvl filters.

- **Global (account-wide):** stored in `AutoSellPlusDB.alwaysSellList`
- **Per-character:** stored in `AutoSellPlusCharDB.charAlwaysSellList`
- Second priority after never-sell

### Management
- Right-click items in popup to add/remove from lists
- `/asp add <itemID>` - add to global never-sell
- `/asp remove <itemID>` - remove from global never-sell
- `/asp list` - display all lists
- `/asp reset lists` - clear all lists
- `/asp export` / `/asp import` - serialize/deserialize lists for sharing

### Import/Export Format
Lists are serialized as: `NEVER:id1,id2,id3;ALWAYS:id4,id5`

---

## Setup Wizard

A three-page first-run configuration guide shown once per character.

### Page 1: Auto-Sell Mode
- Radio buttons: "Review Popup", "One-Click Popup", "Fully Automatic"
- Profile picker with cycle button
- Quick-start template selector with descriptions

### Page 2: Safety Settings
- Checkboxes for protection options (equipment sets, transmog, BoE)
- Epic and high-value confirmations
- Auto-repair toggle

### Page 3: Summary
- Completion message
- Command hints and tips
- "Done!" button

### Re-run
- `/asp wizard` - show the wizard again at any time

---

## Settings Panel

Full configuration interface registered under **WoW Settings > AddOns > AutoSellPlus**.

### Sections
1. **General** - enabled, summary, itemized output, dry-run
2. **Automation** - auto-sell mode, delay, repair, sound muting, priority sell queue
3. **Protection** - all item safety toggles (transmog, BoE, soulbound-only, quest items, expansion materials)
4. **Marking** - auto-mark settings, overlay mode, bag gold display
5. **Display** - undo toast, minimap button
6. **Bag Maintenance** - free slot alerts, eviction
7. **Auto-Destroy** - destruction settings
8. **Profiles & Templates** - manage saved profiles, apply templates, instance auto-profiles
9. **Lists** - manage never-sell, always-sell, and stack-limit lists
10. **Quick Actions** - buttons for common operations (reset, clear lists)

Access via `/asp config` or minimap button left-click.

---

## Third-Party Addon Integration

### Bag Addons
The addon detects and adapts to these bag replacements for overlay rendering:
1. Default Blizzard bags
2. **Baganator** - includes corner widget integration for marked item indicators
3. **Bagnon**
4. **AdiBags**
5. **ArkInventory**

### Transmog Addons
1. **Blizzard UI** (primary, via `C_TransmogCollection`)
2. **AllTheThings** - uses its collection data for enhanced transmog detection
3. **CanIMogIt** - uses its source-level checking

### Auction House Addons
1. **TradeSkillMaster (TSM)** - reads `DBMarket` prices, shows AH value column in popup
2. **Auctionator** - fallback AH price source if TSM is not available

### Conflict Detection
- **Leatrix Plus** - warns if its auto-sell junk feature is enabled (can conflict)
- **Postal** - detects and suppresses auto-sell during mail processing

---

## WeakAura Integration

The addon exposes global variables for custom WeakAura triggers and displays:

| Variable | Type | Description |
|----------|------|-------------|
| `AutoSellPlus_SessionData` | table | Session statistics (items, copper, start time) |
| `AutoSellPlus_LastEvent` | string | Name of last fired addon event |
| `AutoSellPlus_LastSellCount` | number | Number of items in last sell batch |
| `AutoSellPlus_Events` | table | Event history |

### Custom Events
- `LOADED` - addon fully initialized
- `SELL_COMPLETE` - selling finished (includes count and copper data)

---

## Slash Commands

All commands use `/asp` or `/autosell` as prefix.

| Command | Description |
|---------|-------------|
| `/asp` or `/asp help` | Show command list |
| `/asp config` | Open settings panel |
| `/asp toggle` | Enable/disable addon |
| `/asp dryrun` | Toggle dry-run mode |
| `/asp debug` | Toggle debug output |
| `/asp sell` | Sell all qualifying items now (at merchant) |
| `/asp preview` | One-shot dry-run preview |
| `/asp mark` | Toggle bulk mark mode |
| `/asp session` | Show session statistics |
| `/asp session reset` | Reset session counters |
| `/asp session export` | Export session stats |
| `/asp log` | Show last 10 sales in chat |
| `/asp log <N>` | Show last N sales |
| `/asp log ui` | Open sale history panel |
| `/asp log clear` | Clear all sale history |
| `/asp add <itemID>` | Add item to never-sell list |
| `/asp remove <itemID>` | Remove item from never-sell list |
| `/asp list` | Display all lists |
| `/asp export` | Export lists as string |
| `/asp import <data>` | Import lists from string |
| `/asp overlay` | Cycle overlay mode (border -> tint -> full) |
| `/asp keep <itemID> <count>` | Set stack limit for item |
| `/asp keep list` | Show all stack limits |
| `/asp keep clear` | Clear all stack limits |
| `/asp keep clear <itemID>` | Clear limit for one item |
| `/asp destroy` | Destroy qualifying junk items |
| `/asp profile save <name>` | Save current settings as profile |
| `/asp profile load <name>` | Load saved profile |
| `/asp profile list` | List all profiles |
| `/asp profile delete <name>` | Delete profile |
| `/asp template list` | List available templates |
| `/asp template <name>` | Apply a preset template |
| `/asp wizard` | Re-run setup wizard |
| `/asp reset` | Reset all settings (with confirmation) |
| `/asp reset lists` | Clear all never-sell and always-sell lists |
| `/asp undo` | Repurchase last sold items from vendor |

---

## All Settings Reference

### General
| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `enabled` | bool | true | Master toggle |
| `showSummary` | bool | true | Print sale summary after selling |
| `showItemized` | bool | false | Print each item sold individually |
| `dryRun` | bool | false | Preview mode (no actual selling) |

### Quality Filters
| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `sellGrays` | bool | true | Sell poor quality items |
| `sellWhites` | bool | false | Sell common quality items |
| `sellGreens` | bool | false | Sell uncommon quality items |
| `sellBlues` | bool | false | Sell rare quality items |
| `sellEpics` | bool | false | Sell epic quality items |
| `whiteMaxIlvl` | int | 0 | Max ilvl for whites (0 = all) |
| `greenMaxIlvl` | int | 0 | Max ilvl for greens (0 = all) |
| `blueMaxIlvl` | int | 0 | Max ilvl for blues (0 = all) |
| `epicMaxIlvl` | int | 0 | Max ilvl for epics (0 = all) |
| `onlyEquippable` | bool | true | Limit non-gray filters to armor/weapons |
| `useRelativeIlvl` | bool | false | Use % of avg equipped ilvl as threshold |
| `relativeIlvlPercent` | int | 70 | Percentage for relative ilvl (10-100) |

### Sell Criteria
| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `sellCollectedTransmog` | bool | false | Sell items with already-collected appearances |
| `sellKnownCollectibles` | bool | false | Sell already-known mounts, pets, and toys |

### Category Filters
| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `sellConsumables` | bool | false | Sell consumable items |
| `sellTradeGoods` | bool | false | Sell trade goods |
| `sellQuestItems` | bool | false | Sell quest items |
| `sellMiscItems` | bool | false | Sell miscellaneous items |

### Expansion & Slot Filters
| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `filterExpansion` | int | 0 | Filter by expansion (0 = all) |
| `excludeCurrentExpansion` | bool | false | Hide current expansion items |
| `filterSlots` | table | all true | Which equipment slots to show |

### Protection
| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `protectEquipmentSets` | bool | true | Never sell equipment set items |
| `protectUncollectedTransmog` | bool | true | Never sell uncollected appearances |
| `protectTransmogSource` | bool | true | Source-level transmog checking |
| `protectBoE` | bool | true | Never sell unbound BoE items |
| `allowBoESell` | bool | false | Override BoE protection |
| `onlySoulbound` | bool | false | Only sell soulbound items, skip all unbound BoE |
| `protectQuestItems` | bool | true | Never sell Quest Items category |
| `protectCurrentExpMaterials` | bool | false | Never sell current expansion Trade Goods |
| `protectMountEquipment` | bool | true | Never sell mount equipment items |
| `protectWarband` | bool | false | Protect warband and account-bound items |
| `sellCollectedTransmog` | bool | false | Sell items with already-collected transmog |
| `sellKnownCollectibles` | bool | false | Sell already-known mounts, pets, and toys |

### Safety & Confirmation
| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `epicConfirm` | bool | true | Confirm before selling epics |
| `highValueConfirm` | bool | true | Confirm for high-value items |
| `highValueThreshold` | int | 50000 | High-value threshold (copper) |
| `buybackWarning` | bool | true | Warn when selling >12 items |
| `showUndoToast` | bool | true | Show undo notification after selling |

### Automation
| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `autoSellMode` | string | "popup" | Mode: "popup", "oneclick", "autosell" |
| `autoSellDelay` | int | 0 | Delay before auto-sell (seconds) |
| `autoRepair` | bool | false | Auto-repair at merchants |
| `autoRepairGuild` | bool | true | Prefer guild funds for repair |
| `muteVendorSounds` | bool | false | Silence sell sounds during bulk sell |
| `prioritySellQueue` | bool | true | Sell highest-value items first for buyback safety |

### Marking
| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `autoMarkGrayLoot` | bool | false | Auto-mark looted gray items |
| `autoMarkBelowIlvl` | int | 0 | Auto-mark equippable below this ilvl |
| `overlayMode` | string | "border" | Overlay style: "border", "tint", "full" |

### Display
| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `showMinimapButton` | bool | true | Show minimap button |
| `minimapButtonAngle` | float | 225 | Minimap button position (degrees) |
| `showBagGoldDisplay` | bool | false | Show vendor value above bags |
| `showTooltipStatus` | bool | true | Show ASP classification in item tooltips |
| `compactMode` | bool | false | Use condensed popup with one-click sell |

### Bag Maintenance
| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `freeSlotThreshold` | int | 0 | Alert below this many free slots |
| `freeSlotAlertMode` | string | "chat" | Alert mode: "chat" or "screen" |
| `evictionEnabled` | bool | false | Enable value-based eviction |

### Destruction
| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `destroyEnabled` | bool | false | Enable destruction feature |
| `destroyMaxQuality` | int | 0 | Max quality to destroy (0-4) |
| `destroyMaxIlvl` | int | 0 | Max ilvl for equippable items (0 = disabled) |
| `destroyMaxVendorValue` | int | 0 | Max total vendor value in copper (0 = unlimited) |
| `destroyConfirmCountdown` | int | 3 | Seconds before Destroy button activates |
| `destroyFreeSlotTrigger` | int | 0 | Free slot threshold for pressure valve (0 = disabled) |
| `destroyProtectTransmog` | bool | true | Protect uncollected transmog from destruction |
| `destroyProtectBoE` | bool | true | Protect bind-on-equip items from destruction |
| `destroyProtectEquipmentSets` | bool | true | Protect equipment set items from destruction |

### AH Value Protection
| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `ahProtectionEnabled` | bool | false | Protect items worth listing on AH |
| `ahProtectionThreshold` | int | 10000 | AH value threshold in copper |
| `ahHighlightMultiplier` | int | 2 | AH/vendor ratio to color-code popup rows |

---

## Data Structures

### Sell Queue Item
```lua
{
    bag = int,               -- Bag index (0-4)
    slot = int,              -- Slot within bag
    itemID = int,            -- WoW item ID
    itemLink = string,       -- Full item link with color codes
    quality = int,           -- 0=Poor, 1=Common, 2=Uncommon, 3=Rare, 4=Epic
    ilvl = int,              -- Effective item level
    equippedIlvl = int,      -- Equipped ilvl in same slot
    sellPrice = int,         -- Vendor price per unit (copper)
    stackCount = int,        -- Quantity in stack
    totalPrice = int,        -- sellPrice * stackCount
    isEquippable = bool,     -- Is armor or weapon
    isAlwaysSell = bool,     -- On always-sell list
    isMarked = bool,         -- Manually marked as junk
    isBoe = bool,            -- Unbound bind-on-equip
    classID = int,           -- Item class ID
    expansionID = int,       -- Expansion ID
    ahValue = int,           -- Auction house value (if available)
    checked = bool,          -- Selected for selling in popup
    visible = bool,          -- Passes current filters
    isUpgrade = bool,        -- ilvl > equipped ilvl
}
```

### Sale History Entry
```lua
{
    link = string,           -- Item link
    id = int,                -- Item ID
    count = int,             -- Quantity sold
    price = int,             -- Total copper earned
    time = int,              -- Unix timestamp
}
```

### Character Stats
```lua
charStats["Charactername - Realmname"] = {
    totalCopper = int,       -- Lifetime copper earned from selling
    totalItems = int,        -- Lifetime items sold
    lastSeen = int,          -- Last login timestamp
    bagJunkValue = int,      -- Estimated junk value in bags
}
```

---

## Architecture

### File Load Order (AutoSellPlus.toc)

1. **Config.lua** - Default settings, `AutoSellPlusDB` saved variable initialization, database validation

*Note: `Bindings.xml` (key binding definitions) is auto-detected by the WoW client and is not listed in the .toc file.*
2. **Helpers.lua** - Utility functions (ilvl calculation, transmog checks, equipment sets, money formatting, vendor mount detection, list serialization)
3. **Protection.lua** - Item protection logic (never-sell, always-sell, equipment sets, transmog, BoE, refundable)
4. **BagAdapters.lua** - Bag addon detection and frame resolution (Blizzard, Baganator, Bagnon, AdiBags, ArkInventory)
5. **Overlays.lua** - Visual overlays for marked items in bags
6. **Marking.lua** - Junk marking system, bulk mark mode, tooltip integration, auto-mark on loot
7. **History.lua** - Sale history recording, session tracking, per-character stats
8. **HistoryUI.lua** - Sale history scrollable panel UI
9. **MinimapButton.lua** - Minimap button creation and interaction
10. **Wizard.lua** - First-run setup wizard UI
11. **UI.lua** - Settings panel under WoW Options > AddOns
12. **PopupFilters.lua** - Popup filter logic and smart defaults
13. **ConfirmList.lua** - Confirmation dialog item list panel
14. **Popup.lua** - Merchant popup frame, item row rendering, sell action
15. **Selling.lua** - Auto-sell logic, confirmations, eviction
16. **Destroy.lua** - Item destruction system, countdown confirmation, bag pressure valve
17. **Core.lua** - Event handling, sell queue processing, slash commands

### Event Flow
```
MERCHANT_SHOW event
  -> DoAutoRepair()           [Core.lua]
  -> EvictAtVendor()          [Selling.lua] if eviction enabled
  -> HandleAutoSell()         [Selling.lua] based on autoSellMode
    -> ShowPopup()            [Popup.lua] in popup/oneclick mode
    -> BuildSellQueue()       [Selling.lua] in autosell mode
    -> ConfirmAndSell()       [Selling.lua] with confirmations
    -> StartSelling()         [Selling.lua] begins batch processing
    -> ProcessNextBatch()     [Selling.lua] sells 10 items per 0.2s tick
    -> FinishSelling()        [Selling.lua] summary and cleanup

MERCHANT_CLOSED event
  -> HidePopup()              [Popup.lua]
  -> HideConfirmList()        [ConfirmList.lua]
  -> StopSelling()            [Selling.lua]
  -> CancelAutoSell()         [Selling.lua]
```

### Graceful Degradation
Missing WoW APIs are detected at login and features are disabled individually:
- `C_Container.UseContainerItem` missing -> selling disabled
- `C_Container.GetContainerNumSlots` missing -> scanning disabled
- `C_Item.GetItemInfo` missing -> item info disabled
- `C_TransmogCollection` missing -> transmog checks disabled
- `C_EquipmentSet` missing -> equipment set checks disabled
- `C_Container.PickupContainerItem` missing -> destroy disabled

---

## Shift-Click Item Links in History

Shift+left-clicking a row in the sale history panel inserts the item link into the active chat edit box. This follows the standard WoW UX pattern for item link insertion.

---

## Sell-All Confirmation Dialog

When clicking "Sell All Junk" in the popup, a confirmation dialog appears showing the total item count and gold value before selling proceeds. This prevents accidental bulk sales. The dialog is automatically dismissed when the merchant window closes.

---

## Soulbound-Only Filter

When enabled (`onlySoulbound`, default: off), only soulbound items (BoP or already-bound) are eligible for selling. All unbound BoE items are skipped regardless of other filter settings. Useful for dungeon farmers who want to keep BoE drops for the auction house.

Available as a checkbox in the popup filter section and a toggle in Protection settings.

---

## Current Expansion Materials Protection

When enabled (`protectCurrentExpMaterials`, default: off), Trade Goods (classID 7) from the current expansion (Midnight, ID 12) are never sold. Prevents accidental sale of valuable crafting materials.

Available as a toggle in Protection settings.

---

## Key Bindings

AutoSellPlus registers a bindable key in WoW's native Key Bindings UI under the "AutoSellPlus" header.

| Binding | Action |
|---------|--------|
| Toggle Sell Popup | Opens the sell popup when a merchant window is open |

Access via Game Menu > Key Bindings > AutoSellPlus.

---

## Instance Auto-Profile Switching

Automatically load a saved profile when entering an instance type. Per-character setting mapping instance types to profile names.

### Instance Types
| Type | Description |
|------|-------------|
| `none` | Open world |
| `party` | 5-man dungeons |
| `raid` | Raids |
| `pvp` | Battlegrounds |
| `arena` | Arena |
| `scenario` | Scenarios |

### Configuration
Configure in Settings > Profiles & Templates > Instance Auto-Profiles. Enter a saved profile name for each instance type.

---

## Priority Sell Queue

When enabled (`prioritySellQueue`, default: on), items are sold in descending order of total value. This ensures the 12 buyback slots contain the most valuable items, maximizing the safety window if the user needs to undo a sale.

Previously, items were sold in bag order, which could waste buyback slots on cheap items.

---

## Quest Item Protection

When enabled (`protectQuestItems`, default: on), items in the Quest Items category (classID 12) are never sold. This prevents accidental sale of quest objectives and quest-starting items during dailies or leveling.

Respects the always-sell list override for intentional sales.

---

## Tooltip Item Status

When enabled (`showTooltipStatus`, default: on), AutoSellPlus adds a colored status line to item tooltips showing how the addon classifies each item:

- **Green** — "ASP: Will sell (quality filter)", "ASP: Will sell (collected transmog)", "ASP: On always-sell list"
- **Red** — "ASP: Protected (uncollected transmog)", "ASP: Protected (equipment set)", "ASP: Protected (bind on equip)"
- **Yellow** — "ASP: On never-sell list"
- **Gray** — "ASP: Skipped (not soulbound)"

Works for items in bags (full classification including BoE, refundable, warband checks), equipped gear, and merchant windows (itemID-based checks only). Does not duplicate the existing `[Marked as Junk]` tooltip line.

Toggle in Settings > Display or the in-popup Settings tab.

---

## Compact Mode

When enabled (`compactMode`, default: off), the merchant popup is replaced with a condensed view showing:

- **Item count** — Total number of items matching current filters
- **Total value** — Combined vendor value of all matched items
- **Per-quality breakdown** — Color-coded count per quality tier (e.g., "5 Poor  3 Uncommon  1 Rare")
- **One-click Sell button** — Sells all matched items with a single click

Compact mode trusts your filter configuration and auto-checks all visible items. All protections (transmog, equipment sets, BoE, quest items, never-sell list, etc.) still apply. Epic and high-value confirmation dialogs still fire when applicable.

### Switching Between Modes

- **From detailed popup**: Click the "Compact" button next to the Settings tab
- **From compact popup**: Click the "Expand" button in the title bar
- **Slash command**: `/asp compact` toggles the setting
- **Settings panel**: Settings > Display > Compact Mode

The compact popup has independent position and scale saved separately from the full popup.

---

## AH Value Protection

When enabled (`ahProtectionEnabled`, default: off), items worth more than a configurable threshold on the auction house are protected from being auto-sold. Requires TradeSkillMaster (TSM) or Auctionator.

### How It Works
1. During sell evaluation, each item's AH market value is looked up via TSM's `DBMarket` or Auctionator's price API
2. If the AH value exceeds `ahProtectionThreshold` (default: 1g), the item is protected from selling
3. In the popup, rows where AH value exceeds `ahHighlightMultiplier` times the vendor price are color-coded in light blue
4. Hovering a color-coded row shows a tooltip: "Worth listing: AH Xg, vendor Yg (Nx)"

### Settings
- `ahProtectionEnabled` (default: off) — enable AH value protection
- `ahProtectionThreshold` (default: 10000 copper / 1g) — minimum AH value to trigger protection
- `ahHighlightMultiplier` (default: 2) — AH/vendor price ratio for popup row coloring

### Requirements
- TSM or Auctionator must be installed and have price data available
- Without either addon, AH protection is silently skipped (items sell normally)

---

## Safe Mode Template

A new profile template designed for new users or anyone who wants maximum safety.

### Settings Applied
- **Quality**: Grays only (whites, greens, blues, epics all disabled)
- **Protections**: All protections enabled (transmog, equipment sets, BoE, quest items, mount equipment, warband, current expansion materials)
- **Confirmations**: Epic confirm and high-value confirm enabled (threshold: 1g)
- **Mode**: Popup mode with buyback warning
- **Categories**: Only equippable items (no consumables, trade goods, quest items, misc)

### Wizard Integration
- Safe Mode is rendered first in the wizard template list with a green accent
- If the user completes the wizard without selecting any template or profile, Safe Mode is automatically applied as the default

---

## Competitive Analysis & Roadmap

AutoSellPlus is already exceptionally comprehensive, covering 90%+ of player wishlists from recent [r/wowaddons](https://www.reddit.com/r/wowaddons/comments/1qtqsze/legacy_vendor_a_simple_addon_to_clean_up_old/) threads (filters, marking, safeties, profiles). It outclasses Aardvark, Scrap, and Legacy Vendor in proactive tools like eviction and loot-marking previews.

### What AutoSellPlus Already Does Better Than Competitors

| Feature | AutoSellPlus | Competitors Miss |
|---------|-------------|------------------|
| **Loot Pre-Mark** | Auto-mark on loot (gray/low-ilvl) | Manual drag only (Aardvark/Peddler) ([ref](https://www.reddit.com/r/wowaddons/comments/nqokho/autosell_addon/)) |
| **Eviction** | Value-based proactive eviction at vendor | Vendor-only reaction ([ref](https://www.reddit.com/r/wownoob/comments/17x9byd/is_there_an_addon_that_can_autosell_junk_items/)) |
| **Cross-Alt Sync** | Global profiles, per-char overrides | Per-char only ([ref](https://www.reddit.com/r/wowaddons/comments/1qtqsze/legacy_vendor_a_simple_addon_to_clean_up_old/)) |
| **Buyback Safety** | Visual divider + red-tinted rows for items 13+ | Basic count warning at best ([ref](https://www.reddit.com/r/wownoob/comments/17x9byd/is_there_an_addon_that_can_autosell_junk_items/)) |
| **Per-Char Stats** | Minimap tooltip with multi-alt tracking | None ([ref](https://www.reddit.com/r/woweconomy/comments/yigelr/autoselling_addons_broken_after_100/)) |
| **Graceful Degradation** | Per-feature API detection, survives patches | Breaks entirely on API changes ([ref](https://www.reddit.com/r/woweconomy/comments/yigelr/autoselling_addons_broken_after_100/)) |

### Most Requested Additions (Top Player Pains)

Players repeatedly request these for farming and alts (2025-2026 threads). The current feature set misses explicit loot-time automation and instance-based rules. ([ref](https://www.reddit.com/r/wowaddons/comments/1ls8u67/good_addon_for_auto_selling_only_low_ilvl/))

#### 1. Loot Frame ALT+Mark (Core UX Gap)

**Priority: Must-have**

ALT+Click in the loot window should mark items *before* they enter bags, preventing clutter entirely. Visual: red glow on loot roll frame. Combine with existing auto-mark gray/low-ilvl toggles.

- "Mark while waiting RP between bosses" is an exact player quote ([ref](https://www.reddit.com/r/wowaddons/comments/1mtwi4e/looking_for_a_vendor_addon_that_allows_me_to_mark/))
- No competitor offers this; Aardvark and Peddler require manual drag after looting ([ref](https://www.reddit.com/r/wowaddons/comments/nqokho/autosell_addon/))

#### 2. Adventure Guide / Instance Auto-Lists (Farmer Killer Feature)

**Priority: High demand**

A button in the popup: "Sell [Current Raid]" that auto-adds known junk from the current instance (e.g. Naxx trash, Ulduar greens). Farmers running 40+ characters hate building manual lists per instance. Aardvark does this manually; AutoSellPlus could automate it via the Adventure Guide API.

- Legacy Vendor is the closest competitor but only filters by expansion, not instance ([ref](https://www.reddit.com/r/wowaddons/comments/1qtqsze/legacy_vendor_a_simple_addon_to_clean_up_old/))
- High demand in farming communities ([ref](https://www.reddit.com/r/wowaddons/comments/1ls8u67/good_addon_for_auto_selling_only_low_ilvl/))

#### 3. Enchanter / Professions Destroy Override (Niche but Vocal)

**Priority: Medium**

Toggle: "Destroy mats instead of sell" when enchanting/alchemy is detected on the character. Profession-specific profiles (e.g. "Enchanter: Destroy greens for materials").

- "As enchanter, destroy not sell" is a common request ([ref](https://www.reddit.com/r/wowaddons/comments/1rjt3kk/autosell_addon/))

#### 4. Dynamic iLvl Relative to Equipped

Filter: "Below X% of equipped avg ilvl" (e.g. <80% of your gear). Solves "soulbound 10 ilvls below equipped" wishlists without hardcoding thresholds.

- Frequently requested ([ref](https://www.reddit.com/r/wowaddons/comments/1rjt3kk/autosell_addon/))
- The infrastructure already exists (`GetEquippedIlvls`, `GetEquippedIlvlForItem`) and the popup already shows equipped ilvl comparison per item

#### 5. Zone / Instance Profile Auto-Switch

Detect zone (e.g. "Naxxramas") and automatically load a named profile (e.g. "Aggressive Farm"). Eliminates manual profile switching when moving between content types.

- Event farming across 40 characters needs this ([ref](https://www.reddit.com/r/wowaddons/comments/1ls8u67/good_addon_for_auto_selling_only_low_ilvl/))

#### 6. Guild Bank Mats Auto-Send (Bonus Unique)

Post-sell option to `/send` guild materials to a banker alt. ArkInventory handles categories; AutoSellPlus could integrate with Postal for full mail automation.

- Requested in farming/economy threads ([ref](https://www.reddit.com/r/wowaddons/comments/1ls8u67/good_addon_for_auto_selling_only_low_ilvl/))

### vNext Priority

| Priority | Feature | Impact |
|----------|---------|--------|
| 1 | Loot ALT+Mark | UX must-have, no competitor offers it |
| 2 | Instance Auto-List | Killer feature for farmers |
| 3 | Prof Destroy Override | Niche but vocal demand |
