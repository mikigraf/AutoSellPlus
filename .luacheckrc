std = "lua51"
max_line_length = false

exclude_files = {
    "Libs/",
    ".release/",
}

ignore = {
    "211", -- unused local
    "212", -- unused arg
    "213", -- unused loop var
    "311", -- value assigned never accessed
    "42.", -- shadowing
    "542", -- empty if
}

read_globals = {
    -- WoW API: Core
    "CreateFrame",
    "UIParent",
    "C_Container",
    "C_Item",
    "C_Timer",
    "C_EquipmentSet",
    "C_TransmogCollection",
    "C_MountJournal",
    "C_PetJournal",
    "C_ToyBox",
    "PlayerHasToy",
    "GameTooltip",
    "GetInventoryItemLink",
    "GetDetailedItemLevelInfo",
    "GetInventoryItemID",
    "EquipmentManager_UnpackLocation",
    "IsControlKeyDown",
    "IsAltKeyDown",
    "IsShiftKeyDown",
    "IsMouseButtonDown",
    "ITEM_QUALITY_COLORS",
    "Enum",
    "Settings",
    "format",
    "wipe",
    "tinsert",
    "hooksecurefunc",
    "CreateColor",
    "GameFontNormal",
    "GameFontNormalLarge",
    "GameFontHighlight",
    "GameFontHighlightSmall",
    "SOUNDKIT",
    "PlaySound",
    "BackdropTemplateMixin",
    "Mixin",
    "UISpecialFrames",
    "UIPanelScrollFrameTemplate",

    -- WoW API: Money & Repair
    "GetMoney",
    "CanMerchantRepair",
    "GetRepairAllCost",
    "RepairAllItems",
    "IsInGuild",
    "CanGuildBankRepair",

    -- WoW API: Buyback
    "BuybackItem",
    "GetBuybackItemInfo",
    "GetNumBuybackItems",

    -- WoW API: Sound
    "MuteSoundFile",
    "UnmuteSoundFile",

    -- WoW API: Item Location
    "ItemLocation",

    -- WoW API: Destroy
    "DeleteCursorItem",
    "ClearCursor",

    -- WoW API: Mount & Unit
    "IsMounted",
    "UnitName",
    "GetRealmName",

    -- WoW API: Minimap
    "Minimap",
    "GetCursorPosition",
    "MainMenuBarBackpackButton",
    "GetTime",

    -- WoW API: Tooltip
    "TooltipDataProcessor",
    "C_TooltipInfo",

    -- WoW API: Binding globals (localized by Blizzard)
    "ITEM_BIND_TO_BNETACCOUNT",
    "ITEM_BNETACCOUNTBOUND",
    "ITEM_ACCOUNTBOUND",
    "ITEM_BIND_TO_ACCOUNT",

    -- WoW API: Chat
    "ChatEdit_InsertLink",

    -- WoW API: Static Popup
    "StaticPopup_Show",
    "StaticPopup_Hide",

    -- WoW API: UI
    "UIErrorsFrame",
    "MinimalSliderWithSteppersMixin",

    -- WoW API: Inventory
    "GetInventorySlotInfo",

    -- WoW API: Instance
    "GetInstanceInfo",
    "GetExpansionLevel",
    "NUM_TOTAL_EQUIPPED_BAG_SLOTS",
    "C_DateAndTime",

    -- WoW API: Misc
    "strsplit",
    "strtrim",
    "pcall",
    "setmetatable",
    "GetAddOnMetadata",
    "date",
    "time",
    "GetBuybackItemLink",
    "GetLootSlotLink",
    "LootSlot",
    "CursorHasItem",
    "GetCursorInfo",
    "OpenAllBags",
    "CloseAllBags",

    -- Testing
    "WoWUnit",

    -- Third-party addon globals (read-only detection)
    "AllTheThings",
    "CanIMogIt",
    "TSM_API",
    "Auctionator",
    "Bagnon",
    "Baganator",
    "AdiBags",
    "ArkInventory",
    "LeaPlusDB",
    "Postal",

    -- Quality description globals
    "ITEM_QUALITY0_DESC",
    "ITEM_QUALITY1_DESC",
    "ITEM_QUALITY2_DESC",
    "ITEM_QUALITY3_DESC",
    "ITEM_QUALITY4_DESC",
}

globals = {
    "StaticPopupDialogs",
    "AutoSellPlusDB",
    "AutoSellPlusCharDB",
    "SlashCmdList",
    "SLASH_AUTOSELLPLUS1",
    "SLASH_AUTOSELLPLUS2",
    "AutoSellPlus_SessionData",
    "AutoSellPlus_LastEvent",
    "AutoSellPlus_LastSellCount",
    "AutoSellPlus_Events",
    "BINDING_HEADER_AUTOSELLPLUS",
    "BINDING_NAME_ASP_TOGGLE_POPUP",
    "AutoSellPlus_KeybindSell",
}
