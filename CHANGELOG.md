# Changelog

## Unreleased

### Added
- **Shift-click item links in history** — Shift+left-clicking a row in the sale history panel inserts the item link into chat, matching standard WoW UX patterns.
- **Sell-All confirmation dialog** — "Sell All Junk" now shows item count and total gold value before selling. Prevents accidental bulk sales.
- **Soulbound-only filter** (`onlySoulbound`) — When enabled, only soulbound (BoP or already-bound) items are eligible for selling. Unbound BoE items are always skipped. Useful for dungeon farmers keeping BoE for AH.
- **Current expansion materials protection** (`protectCurrentExpMaterials`) — Never sell Trade Goods from the current expansion (Midnight). Prevents accidental sale of valuable crafting materials.
- **Key binding support** — Bindable key in WoW's native Key Bindings UI to toggle the sell popup at a merchant.
- **Instance auto-profile switching** — Auto-load a saved profile when entering instances (raids, dungeons, battlegrounds, arenas, scenarios, open world). Configured per-character in Profiles & Templates settings.
- **Priority sell queue** (`prioritySellQueue`, default: on) — Sells highest-value items first so buyback slots contain the most valuable items for undo safety.
- **Quest item protection** (`protectQuestItems`, default: on) — Never sell items in the Quest Items category. Prevents accidental sale of quest objectives and quest-starting items.
