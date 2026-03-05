local addonName, ns = ...

ns.version = "@project-version@"

ns.defaults = {
    enabled = true,
    sellGrays = true,
    sellGreens = false,
    sellBlues = false,
    greenMaxIlvl = 0,
    blueMaxIlvl = 0,
    onlyEquippable = true,
    protectEquipmentSets = true,
    protectUncollectedTransmog = true,
    showSummary = true,
    showItemized = false,
    dryRun = false,
    buybackWarning = true,
    neverSellList = {},
    alwaysSellList = {},
}

local function DeepCopy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")

    if AutoSellPlusDB == nil then
        AutoSellPlusDB = {}
    end

    for key, defaultValue in pairs(ns.defaults) do
        if AutoSellPlusDB[key] == nil then
            AutoSellPlusDB[key] = DeepCopy(defaultValue)
        end
    end

    ns.db = AutoSellPlusDB
end)
