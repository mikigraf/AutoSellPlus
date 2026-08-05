# Changelog

## Unreleased (3.7)

### Added
- **Smart Defaults Engine** (`smartDefaults`, default: on) — Learns from your sell and keep decisions. Items you consistently sell (3+ times) are auto-checked in the popup; items you consistently un-check are auto-unchecked. "Learned" and "Kept" badges shown on popup rows. Tooltip shows "ASP: Learned — usually sold/kept". Data pruned on login (30-day decay, 200 item cap per list).
- **Toast Notification System** — Non-intrusive slide-in notifications from the right screen edge. Sell summaries now appear as toasts in addition to chat. Toasts stack vertically (max 5), auto-dismiss after 5s, with type-specific accent colors (success/info/warning/danger). Frame pool recycling for zero allocation.
- **Instance-Aware Junk Detection** — Tracks items sold per instance in a persistent database. When visiting a vendor after running an instance, items previously sold in that instance are suggested for selling. Popup title shows instance name when inside. Data pruned on login (90-day decay, min 2 sells required).
- **Enhanced Compact Mode** — Compact popup now shows the 5 most valuable items with icon, name, and price below the quality breakdown, giving a quick preview without switching to full mode.
- **Unified Item Actions** — Shift+ALT+Click on bag items to add to always-sell list. Ctrl+ALT+Click to add to never-sell list. Visual flash feedback on both actions.

### Fixed
- **Undo repurchased nothing** — `UndoLastSale` read the buyback price from the wrong `GetBuybackItemInfo` return slot (`numAvailable` instead of `price`). When the client returned `nil` there, the guard rejected every entry and the undo silently did nothing. The reported cost was wrong even when it did run.
- **Undo buyback ordering** — The buyback list is now walked from the highest index down. `BuybackItem()` removes an entry and shifts every higher index down, so a single descending pass keeps the remaining indices valid. Replaces a rescan-from-index-1 loop whose comment already claimed to iterate in reverse.
- **Undo skips unaffordable items gracefully** — Buyback costs are checked against your gold and reported instead of failing silently.
- **Undo buffer was wiped by the next sale** — `undoBuffer.items` aliased `ns.lastSoldBatch`, which is wiped in place at the start of every sell. The batch is now copied into the buffer.
- **Smart Defaults could never learn** — `PruneLearnedItems` dropped every entry below the 3-occurrence threshold on each login. Since counts start at 1, nothing survived long enough to be learned unless it was sold 3+ times in a single session. Pruning is now by 30-day age decay only.
- **First-run wizard could never be replayed** — `charFirstRunComplete` was force-set to `true` on every load for any existing character, before the wizard had a chance to run. It is now only backfilled for characters saved before the flag existed; `Wizard.lua` still sets it on genuine completion.
- **Selling away from a merchant** — `ProcessNextBatch` now verifies the merchant window is open before calling `UseContainerItem`, which sells at a vendor but *uses* the item anywhere else.
- **Destruction ignored Blizzard's confirmation dialog** — Valuable items raise a typed "DELETE" confirmation. The queue previously counted them as destroyed and cleared the cursor underneath the open dialog on the next tick. Destruction now pauses and hands the item back to you. Destroyed items are also verified a tick later instead of being counted optimistically.
- **Tooltip promised "Will sell" for unsellable items** — `ClassifyItem` now mirrors `ShouldSellItem`'s `isLocked` and `hasNoValue` gates.
- **Mount equipment comment** — Corrected a stale comment that said `classID 4 = Armor` above a `classID == 15` check.
- **`/asp undo` missing from help** — The command was implemented and documented in the README but absent from `/asp help`.

### Improved
- **Vendor mount detection** — `IsVendorMount` queries the four known vendor mount IDs directly instead of walking the player's entire mount collection on every popup open.
- **Test coverage** — Added 40 tests across 7 new suites covering undo/buyback, undo buffer independence, Smart Defaults pruning, the sell-batch merchant guard, the destroy protection chain, vendor mount detection, and ClassifyItem parity. These were previously the least-covered paths despite being the ones that move or delete items.

### Removed
- **Dead code** — Unused `ns.defaults` table and an unreachable loop in the destroy confirmation dialog.

## Unreleased (3.5)

### Added
- **Tooltip item status** (`showTooltipStatus`, default: on) — Shows ASP classification in item tooltips: "Will sell (quality filter)", "Protected (uncollected transmog)", "On never-sell list", etc. Works for items in bags, equipped gear, and merchant windows. Togglable in Settings > Display.
- **Compact mode** (`compactMode`, default: off) — Condensed popup showing item count, total value, per-quality breakdown, and a one-click Sell button. Toggle between compact and detailed views via a button on either popup or `/asp compact`. All filters and protections still apply.
- **AH value protection** (`ahProtectionEnabled`, default: off) — Protects items worth more than a configurable threshold on the AH from being auto-sold. Requires TSM or Auctionator. Popup rows where AH value exceeds a configurable multiplier of vendor price are color-coded, with a tooltip showing "Worth listing: AH Xg, vendor Yg (Nx)".
- **Safe Mode template** — New profile template for new users: grays only, all protections on. Wizard defaults to Safe Mode when no template or profile is selected.
- **Destruction system v1** — Complete rewrite of the auto-destroy feature with separate destroy filters (quality, ilvl, max vendor value), a never-destroy list, countdown confirmation popup, and a bag pressure valve that auto-triggers when free slots drop below a configurable threshold. Items are destroyed one per tick with cursor verification for safety.

### Improved
- **Self-test messages** — API failure messages are now user-friendly and reassuring instead of technical ("Transmog detection paused — Blizzard changed an API. Sell rules are more conservative until updated.").
- **Centralized AH lookup** — TSM/Auctionator price queries consolidated into `ns:GetAHValue()` and `ns:HasAHAddon()`, replacing duplicated code in Popup, PopupFilters, and Overlays.

### Fixed
- **Bindings.xml parsing error** — Removed invalid `header` attribute from Binding element. The section header is provided by the `BINDING_HEADER_AUTOSELLPLUS` global.
- **Mount equipment misclassified** — Mount equipment is Miscellaneous (classID 15, subclassID 6), not Armor (classID 4). Items like Light-Step Hoofplates are now correctly detected.
- **Destroy cursor safety** — Verify `GetCursorInfo` matches expected itemID before `DeleteCursorItem` to prevent accidentally destroying the wrong item when the player is dragging something.
- **CanIMogIt locale detection** — Use CanIMogIt's own `NOT_COLLECTED` constants instead of hardcoded English string matching. Fixes false positives on non-English clients.
- **Warband detection unreliable** — `GetItemInfo` bindType is unreliable for many warband items (reagents, trade goods). Added tooltip fallback via `C_TooltipInfo` using Blizzard's localized binding globals for reliable detection.
- **Undo buyback matching** — Use full item link comparison instead of name substring for more precise buyback matching.

### Added
- **Sell collected transmog** (`sellCollectedTransmog`, default: off) — Marks items with already-collected transmog appearances for selling. Items pass all existing protections before this criterion applies.
- **Sell known collectibles** (`sellKnownCollectibles`, default: off) — Marks already-known mounts, pets, and toys for selling. Uses C_MountJournal, C_PetJournal, and C_ToyBox APIs.
- **Relative ilvl threshold** (`useRelativeIlvl`, `relativeIlvlPercent`, default: off/70%) — Computes a single ilvl sell threshold as a percentage of the player's average equipped ilvl. When enabled, replaces per-quality ilvl sliders. Grays out quality ilvl controls and shows computed threshold in popup header.
- **Mount equipment protection** (`protectMountEquipment`, default: on) — Toggleable checkbox in popup filters. Never sells mount equipment items.
- **Warband item protection** (`protectWarband`, default: off) — Toggleable checkbox in popup filters. Protects all warband and account-bound items from selling. Detects bindType 7/8/9 with tooltip-based fallback.
- **Dynamic bag ID support** — Uses `NUM_TOTAL_EQUIPPED_BAG_SLOTS` for reagent bag support instead of hardcoded bag range.

### Performance
- **Deferred AH value lookup** — TSM/Auctionator price queries now only run for visible items instead of all bag items.
- **Confirm list row pooling** — Reuses hidden row frames instead of creating new ones each time the confirm list is shown.

## v3.3.0

### Fixed
- **Guild auto-repair false success** — Now checks `CanGuildBankRepair()` before attempting guild repair to avoid false positive chat messages.
- **Transmog source protection** — `IsUncollectedTransmogSource` now uses `C_TransmogCollection.GetItemInfo` to get the correct `appearanceID` before checking sources. Third-party addon integration (AllTheThings, CanIMogIt) wired into `ShouldSellItem`.
- **ALT+click hook** — No longer interferes with normal item use when merchant is closed. Only triggers when `Alt` is held at a merchant or in bulk mark mode.
- **Loot auto-mark extraction** — `CHAT_MSG_LOOT` handler now extracts item link from the chat message string instead of treating the message as a link.
- **Bag item flash leak** — Pooled flash textures and animation groups instead of creating new ones on every flash.
- **Session report net loss** — Negative gold changes now correctly display a minus sign.
- **Wizard template/profile overlap** — Template section Y offset adjusted to prevent overlap when profiles exist.
- **Selling, undo, and auto-destroy safety** — Priority sell queue sort fixed (cheapest first for LIFO buyback). Undo requires merchant open. Auto-destroy respects equipment set, transmog, BoE, and refundable protections. Re-verifies bag slots before each deletion.
- **Instance auto-profiles overfiring** — Only triggers when `instanceType` actually changes, not on every loading screen.
- **Hardcoded expansion ID** — Uses `GetExpansionLevel()` dynamically instead of hardcoded value.
- **Equipped ilvl cache staleness** — Invalidated on `PLAYER_EQUIPMENT_CHANGED` and `EQUIPMENT_SETS_CHANGED`.
- **Keybind support** — Re-added Bindings.xml to TOC load order.

## v3.0.0

### Fixed
- **Soulbound-only filter not working** — The filter only checked for BoE items instead of checking whether items are actually bound to the player. Now uses `C_Item.IsBound` to correctly filter all non-soulbound items.
- **Quest category checkbox not working in popup** — Quest items were completely excluded from the display list when quest protection was on. Quest items now appear when the category is enabled but are unchecked by default when protection is active.
- **Bindings.xml loading error** — Removed from TOC to prevent XML parse errors.

### Added
- **Settings tab in popup** — Access all addon settings directly from the vendor popup without opening the WoW Options panel.
- **Shift-click item links in history** — Shift+left-clicking a row in the sale history panel inserts the item link into chat.
- **Sell-All confirmation dialog** — "Sell All Junk" now shows item count and total gold value before selling.
- **Soulbound-only filter** (`onlySoulbound`) — When enabled, only soulbound items are eligible for selling. Useful for dungeon farmers keeping BoE for AH.
- **Current expansion materials protection** (`protectCurrentExpMaterials`) — Never sell Trade Goods from the current expansion.
- **Key binding support** — Bindable key in WoW's native Key Bindings UI to toggle the sell popup at a merchant.
- **Instance auto-profile switching** — Auto-load a saved profile when entering instances. Configured per-character.
- **Priority sell queue** (`prioritySellQueue`, default: on) — Sells highest-value items first so buyback slots contain the most valuable items for undo safety.
- **Quest item protection** (`protectQuestItems`, default: on) — Never sell items in the Quest Items category.

### Improved
- **Popup filter layout** — Brightened ilvl labels and section labels, consistent checkbox sizing for transmog/soulbound rows, visual group gaps between filter sections, fixed slot row padding overlap.

## v2.2.0

### Fixed
- **Transmog protection filtering out non-visual slots** — Trinkets, rings, and necklaces were incorrectly blocked by transmog protection despite having no visual appearance.
- **Visual layout issues** — Fixed close button positioning, context menu alignment, column widths, and minimap button border.

### Added
- **Allow Transmog checkbox** — Toggle transmog protection on/off directly from the popup filter section.
- **Confirmation dialogs** — Added confirmation prompts for clearing sale history and deleting profiles.
- **Improved chat feedback** — Clearer, more helpful messages for all slash commands and actions.

## v2.1.0

### Added
- **Confirmation item list panel** — Shows a scrollable list of items below sell confirmation dialogs with buyback limit divider, quality-colored names, and beyond-buyback red tinting.
- **WoWUnit test suite** — 100+ in-game unit tests covering money formatting, filters, protections, and sorting.
- **CurseForge description** — Added addon description page for CurseForge listing.
- **Feature documentation** — Comprehensive FEATURES.md documenting all addon capabilities.

## v2.0.0

### Added
- **Sale history UI** — Scrollable panel showing past sales with item links, prices, and timestamps.
- **Drag-to-mark junk button** — Drag items onto a target button near bags to toggle junk mark.
- **Value-based eviction** — Automatically sell cheapest items at vendor when bags are full.
- **Safety confirmations** — Confirmation dialogs for auto-sell and slash-sell paths.
- **Profile templates** — Pre-configured profiles for common playstyles (Raid Farmer, Transmog Hunter, Leveling Alt, Gold Farmer).
- **Profile auto-load** — Automatically loads last active profile on login.
- **First-run wizard** — Per-character setup wizard on first use.
- **Graceful API degradation** — Feature self-test disables features when WoW APIs are unavailable.
- **Stack limit awareness** — Set maximum stack counts for specific items in bags.
- **Drag-to-sell overlay** — Drag items onto the popup to sell them directly.
- **Loot window ALT+Click marking** — Mark items as junk directly from the loot window.
- **Progressive sell feedback** — Progress bar in popup during batch selling.
- **Undo failure guidance** — Shows Blizzard Item Restoration URL when buyback fails.
- **Minimap junk value tooltip** — Shows junk value breakdown per quality and per-alt stats.
- **Per-day session tracking** — Daily gold earned/spent stats in minimap tooltip.
- **Configurable overlay modes** — Choose between border, tint, or full overlay for marked items in bags.
- **Bag item flash** — Visual flash animation when items are added/removed from lists.
- **Bag gold display** — Tooltip showing total vendor value with per-quality breakdown.

### Fixed
- **Lua 5.1 compatibility** — Replaced goto/continue with repeat/until pattern.
- **Slider values** — Fixed incorrect default slider positions.
- **Popup item row clicks** — Fixed `RegisterForClicks` error on item rows.

### Changed
- **Minimap button** — Left-click now opens the settings panel instead of toggling the popup.
- **Settings panel** — All slash command features exposed in the Options panel.

## v1.0.0

- Initial release. Popup-based junk selling at merchants with quality filters, ilvl thresholds, transmog protection, equipment set protection, BoE protection, auto-repair, dry-run mode, never-sell and always-sell lists, and minimap button.
