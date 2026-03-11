# Changelog

## Unreleased (3.5)

### Added
- **Tooltip item status** (`showTooltipStatus`, default: on) — Shows ASP classification in item tooltips: "Will sell (quality filter)", "Protected (uncollected transmog)", "On never-sell list", etc. Works for items in bags, equipped gear, and merchant windows. Togglable in Settings > Display.
- **Compact mode** (`compactMode`, default: off) — Condensed popup showing item count, total value, per-quality breakdown, and a one-click Sell button. Toggle between compact and detailed views via a button on either popup or `/asp compact`. All filters and protections still apply.

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
