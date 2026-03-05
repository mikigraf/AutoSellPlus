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
    -- WoW API
    "CreateFrame",
    "UIParent",
    "C_Container",
    "C_Item",
    "C_Timer",
    "C_EquipmentSet",
    "C_TransmogCollection",
    "GameTooltip",
    "GetInventoryItemLink",
    "GetDetailedItemLevelInfo",
    "GetInventoryItemID",
    "EquipmentManager_UnpackLocation",
    "IsControlKeyDown",
    "ITEM_QUALITY_COLORS",
    "Enum",
    "Settings",
    "format",
    "wipe",
    "tinsert",
    "hooksecurefunc",
    "CreateColor",
    "StaticPopupDialogs",
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
}

globals = {
    "AutoSellPlusDB",
    "SlashCmdList",
    "SLASH_AUTOSELLPLUS1",
    "SLASH_AUTOSELLPLUS2",
}
