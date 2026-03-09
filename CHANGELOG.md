# Changelog

## Unreleased

### Fixed
- **Bindings.xml parsing error** — Removed invalid `header` attribute from Binding element. The section header is provided by the `BINDING_HEADER_AUTOSELLPLUS` global.
- **Mount equipment misclassified** — Mount equipment is Miscellaneous (classID 15, subclassID 6), not Armor (classID 4). Items like Light-Step Hoofplates are now correctly detected.
- **Destroy cursor safety** — Verify `GetCursorInfo` matches expected itemID before `DeleteCursorItem` to prevent accidentally destroying the wrong item when the player is dragging something.
- **CanIMogIt locale detection** — Use CanIMogIt's own `NOT_COLLECTED` constants instead of hardcoded English string matching. Fixes false positives on non-English clients.
- **Warband detection unreliable** — `GetItemInfo` bindType is unreliable for many warband items (reagents, trade goods). Added tooltip fallback via `C_TooltipInfo` using Blizzard's localized binding globals for reliable detection.
- **Undo buyback matching** — Use full item link comparison instead of name substring for more precise buyback matching.
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
- **Soulbound-only filter not working** — The filter only checked for BoE items instead of checking whether items are actually bound to the player. Now uses `C_Item.IsBound` to correctly filter all non-soulbound items.
- **Quest category checkbox not working in popup** — Quest items now appear when the category is enabled but are unchecked by default when protection is active.

### Added
- **Mount equipment protection** (`protectMountEquipment`, default: on) — Toggleable checkbox in popup filters. Never sells mount equipment items.
- **Warband item protection** (`protectWarband`, default: off) — Toggleable checkbox in popup filters. Protects all warband and account-bound items from selling. Detects bindType 7/8/9 with tooltip-based fallback.
- **Dynamic bag ID support** — Uses `NUM_TOTAL_EQUIPPED_BAG_SLOTS` for reagent bag support instead of hardcoded bag range.
- **Shift-click item links in history** — Shift+left-clicking a row in the sale history panel inserts the item link into chat, matching standard WoW UX patterns.
- **Sell-All confirmation dialog** — "Sell All Junk" now shows item count and total gold value before selling. Prevents accidental bulk sales.
- **Soulbound-only filter** (`onlySoulbound`) — When enabled, only soulbound (BoP or already-bound) items are eligible for selling. Unbound BoE items are always skipped. Useful for dungeon farmers keeping BoE for AH.
- **Current expansion materials protection** (`protectCurrentExpMaterials`) — Never sell Trade Goods from the current expansion (Midnight). Prevents accidental sale of valuable crafting materials.
- **Key binding support** — Bindable key in WoW's native Key Bindings UI to toggle the sell popup at a merchant.
- **Instance auto-profile switching** — Auto-load a saved profile when entering instances (raids, dungeons, battlegrounds, arenas, scenarios, open world). Configured per-character in Profiles & Templates settings.
- **Priority sell queue** (`prioritySellQueue`, default: on) — Sells highest-value items first so buyback slots contain the most valuable items for undo safety.
- **Quest item protection** (`protectQuestItems`, default: on) — Never sell items in the Quest Items category. Prevents accidental sale of quest objectives and quest-starting items.

### Performance
- **Deferred AH value lookup** — TSM/Auctionator price queries now only run for visible items instead of all bag items.
- **Confirm list row pooling** — Reuses hidden row frames instead of creating new ones each time the confirm list is shown.
