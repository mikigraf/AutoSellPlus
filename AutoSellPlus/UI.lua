local addonName, ns = ...

local function RegisterSettingsPanel()
    local category = Settings.RegisterVerticalLayoutCategory(addonName)
    ns.settingsCategoryID = category:GetID()

    local function AddBoolSetting(variableKey, name, tooltip)
        local setting = Settings.RegisterAddOnSetting(category, variableKey, variableKey, AutoSellPlusDB, Settings.VarType.Boolean, name, ns.defaults[variableKey])
        Settings.CreateCheckbox(category, setting, tooltip)
        return setting
    end

    AddBoolSetting("enabled", "Enable AutoSellPlus", "Toggle whether the sell popup appears when visiting a merchant.")
    AddBoolSetting("protectEquipmentSets", "Protect Equipment Sets", "Never sell items that are part of an equipment set.")
    AddBoolSetting("protectUncollectedTransmog", "Protect Uncollected Transmog", "Never sell equippable items whose appearance has not been collected.")
    AddBoolSetting("showSummary", "Show Summary", "Print a summary of total gold earned after selling.")
    AddBoolSetting("showItemized", "Show Itemized Sales", "Print each item sold individually in chat.")
    AddBoolSetting("dryRun", "Dry Run Mode", "Preview what would be sold without actually selling anything.")
    AddBoolSetting("buybackWarning", "Buyback Warning", "Warn when selling more than 12 items (buyback limit).")

    Settings.RegisterAddOnCategory(category)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    self:UnregisterEvent("PLAYER_LOGIN")
    RegisterSettingsPanel()
end)
