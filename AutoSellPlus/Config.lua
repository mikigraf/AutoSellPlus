local addonName, ns = ...

ns.version = "@project-version@"

local DB_VERSION = 2

-- Keys stored at the top level of AutoSellPlusDB (not inside .global)
local TOP_LEVEL_KEYS = {
    neverSellList = true,
    alwaysSellList = true,
    profiles = true,
    charStats = true,
    saleHistory = true,
    markedItems = true,
    stackLimits = true,
}

-- Default global settings (stored in AutoSellPlusDB.global)
ns.globalDefaults = {
    enabled = true,
    -- Quality filters
    sellGrays = true,
    sellWhites = false,
    sellGreens = false,
    sellBlues = false,
    sellEpics = false,
    -- ilvl thresholds
    whiteMaxIlvl = 0,
    greenMaxIlvl = 0,
    blueMaxIlvl = 0,
    epicMaxIlvl = 0,
    epicConfirm = true,
    -- Equippable filter
    onlyEquippable = true,
    -- Sell criteria
    sellCollectedTransmog = false,
    -- Category filters
    sellConsumables = false,
    sellTradeGoods = false,
    sellQuestItems = false,
    sellMiscItems = false,
    -- Expansion filter
    filterExpansion = 0,
    excludeCurrentExpansion = false,
    protectCurrentExpMaterials = false,
    -- Slot filter
    filterSlots = {},
    -- Protection
    protectEquipmentSets = true,
    protectUncollectedTransmog = true,
    protectTransmogSource = true,
    protectBoE = true,
    allowBoESell = false,
    onlySoulbound = false,
    protectQuestItems = true,
    protectMountEquipment = true,
    protectWarband = false,
    -- Display
    showSummary = true,
    showItemized = false,
    dryRun = false,
    buybackWarning = true,
    -- Automation
    autoSellMode = "popup",
    autoSellDelay = 0,
    autoRepair = false,
    autoRepairGuild = true,
    -- Marking
    autoMarkGrayLoot = false,
    autoMarkBelowIlvl = 0,
    -- Selling
    prioritySellQueue = true,
    -- Safety
    showUndoToast = true,
    highValueThreshold = 50000,
    highValueConfirm = true,
    firstRunComplete = false,
    -- Sound
    muteVendorSounds = false,
    -- Minimap
    showMinimapButton = true,
    minimapButtonAngle = 225,
    -- Bag display
    showBagGoldDisplay = false,
    overlayMode = "border",
    -- Bag maintenance
    freeSlotThreshold = 0,
    freeSlotAlertMode = "chat",
    evictionEnabled = false,
    -- Auto-destroy
    autoDestroyEnabled = false,
    autoDestroyMaxQuality = 0,
    autoDestroyMaxValue = 0,
    autoDestroyConfirm = true,
}

-- Default top-level tables in AutoSellPlusDB
ns.topLevelDefaults = {
    neverSellList = {},
    alwaysSellList = {},
    profiles = {},
    charStats = {},
    saleHistory = {},
    markedItems = {},
    stackLimits = {},
}

-- Default per-character settings (stored in AutoSellPlusCharDB)
ns.charDefaults = {
    activeProfile = "",
    overrides = {},
    charNeverSellList = {},
    charAlwaysSellList = {},
    charFirstRunComplete = false,
    instanceProfiles = {},
}

-- Profile templates for common playstyles
ns.profileTemplates = {
    ["Raid Farmer"] = {
        description = "Sell grays, whites, and greens. Protect transmog. Popup mode.",
        settings = {
            sellGrays = true,
            sellWhites = true,
            sellGreens = true,
            sellBlues = false,
            sellEpics = false,
            protectUncollectedTransmog = true,
            protectTransmogSource = true,
            protectEquipmentSets = true,
            protectBoE = true,
            autoSellMode = "popup",
            onlyEquippable = true,
        },
    },
    ["Transmog Hunter"] = {
        description = "Sell grays only. Protect all uncollected appearances.",
        settings = {
            sellGrays = true,
            sellWhites = false,
            sellGreens = false,
            sellBlues = false,
            sellEpics = false,
            protectUncollectedTransmog = true,
            protectTransmogSource = true,
            protectBoE = true,
            autoSellMode = "popup",
        },
    },
    ["Leveling Alt"] = {
        description = "Sell grays through blues. Auto-sell with 2s delay.",
        settings = {
            sellGrays = true,
            sellWhites = true,
            sellGreens = true,
            sellBlues = true,
            sellEpics = false,
            protectUncollectedTransmog = false,
            protectBoE = true,
            autoSellMode = "autosell",
            autoSellDelay = 2,
            onlyEquippable = true,
        },
    },
    ["Gold Farmer"] = {
        description = "Aggressive selling. Protect BoE. Sell consumables.",
        settings = {
            sellGrays = true,
            sellWhites = true,
            sellGreens = true,
            sellBlues = true,
            sellEpics = false,
            sellConsumables = true,
            sellTradeGoods = true,
            protectUncollectedTransmog = false,
            protectBoE = true,
            onlyEquippable = false,
            autoSellMode = "popup",
        },
    },
}

function ns:ApplyTemplate(name)
    -- Case-insensitive match
    local matchedName
    for tplName in pairs(self.profileTemplates) do
        if tplName:lower() == name:lower() then
            matchedName = tplName
            break
        end
    end
    if not matchedName then
        self:Print(format("Template '%s' not found. Use /asp template list.", name))
        return false
    end
    local template = self.profileTemplates[matchedName]

    -- Reset to defaults then apply overrides
    for key, value in pairs(ns.globalDefaults) do
        AutoSellPlusDB.global[key] = ns.DeepCopy(value)
    end
    for key, value in pairs(template.settings) do
        AutoSellPlusDB.global[key] = ns.DeepCopy(value)
    end
    self:Print(format("Applied template: |cFF00FF00%s|r — all settings reset to template defaults.", matchedName))
    return true
end

function ns:ListTemplates()
    self:Print("Available templates:")
    for name, tpl in pairs(self.profileTemplates) do
        print(format("  |cFF00CCFF%s|r - %s", name, tpl.description))
    end
end

-- Legacy flat defaults for migration detection
ns.defaults = {}
for k, v in pairs(ns.globalDefaults) do ns.defaults[k] = v end
ns.defaults.neverSellList = {}
ns.defaults.alwaysSellList = {}

local function DeepCopy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

ns.DeepCopy = DeepCopy

local function ValidateDB(db, defaults)
    if type(db) ~= "table" then return end
    for key, defaultValue in pairs(defaults) do
        if db[key] == nil then
            db[key] = DeepCopy(defaultValue)
        elseif type(db[key]) ~= type(defaultValue) then
            db[key] = DeepCopy(defaultValue)
        end
    end
end

ns.ValidateDB = ValidateDB

local function MigrateDB(db)
    local version = db.dbVersion or 0

    if version < 1 then
        -- Migration from flat structure to global subtable
        if db.global == nil then
            db.global = {}
            for key in pairs(ns.globalDefaults) do
                if db[key] ~= nil then
                    db.global[key] = db[key]
                    db[key] = nil
                end
            end
            -- Move lists to top-level (they already are, just ensure they exist)
            if db.neverSellList == nil then db.neverSellList = {} end
            if db.alwaysSellList == nil then db.alwaysSellList = {} end
        end
    end

    if version < 2 then
        -- Ensure new top-level tables exist
        for key, defaultValue in pairs(ns.topLevelDefaults) do
            if db[key] == nil then
                db[key] = DeepCopy(defaultValue)
            end
        end
    end

    db.dbVersion = DB_VERSION
end

local function SetupDBProxy()
    ns.db = setmetatable({}, {
        __index = function(_, key)
            if TOP_LEVEL_KEYS[key] then
                return AutoSellPlusDB[key]
            end
            local charDb = AutoSellPlusCharDB
            if charDb and charDb.overrides and charDb.overrides[key] ~= nil then
                return charDb.overrides[key]
            end
            return AutoSellPlusDB.global[key]
        end,
        __newindex = function(_, key, value)
            if TOP_LEVEL_KEYS[key] then
                AutoSellPlusDB[key] = value
            else
                AutoSellPlusDB.global[key] = value
            end
        end,
    })
    ns.charDb = AutoSellPlusCharDB
end

-- Merged list checks (global + per-character)
function ns:IsNeverSell(itemID)
    if AutoSellPlusDB.neverSellList[itemID] then return true end
    if AutoSellPlusCharDB and AutoSellPlusCharDB.charNeverSellList and AutoSellPlusCharDB.charNeverSellList[itemID] then return true end
    return false
end

function ns:IsAlwaysSell(itemID)
    if AutoSellPlusDB.alwaysSellList[itemID] then return true end
    if AutoSellPlusCharDB and AutoSellPlusCharDB.charAlwaysSellList and AutoSellPlusCharDB.charAlwaysSellList[itemID] then return true end
    return false
end

-- Profile management
function ns:SaveProfile(name)
    if not name or name == "" then return false end
    AutoSellPlusDB.profiles[name] = DeepCopy(AutoSellPlusDB.global)
    self:Print(format("Profile '%s' saved.", name))
    return true
end

function ns:LoadProfile(name)
    local profile = AutoSellPlusDB.profiles[name]
    if not profile then
        self:Print(format("Profile '%s' not found.", name))
        return false
    end
    AutoSellPlusDB.global = DeepCopy(profile)
    if AutoSellPlusCharDB then
        AutoSellPlusCharDB.activeProfile = name
    end
    self:Print(format("Profile '%s' loaded.", name))
    return true
end

function ns:DeleteProfile(name)
    if not AutoSellPlusDB.profiles[name] then
        self:Print(format("Profile '%s' not found.", name))
        return false
    end
    AutoSellPlusDB.profiles[name] = nil
    self:Print(format("Profile '%s' deleted.", name))
    return true
end

function ns:ListProfiles()
    local count = 0
    self:Print("Saved profiles:")
    for name in pairs(AutoSellPlusDB.profiles) do
        local active = (AutoSellPlusCharDB and AutoSellPlusCharDB.activeProfile == name) and " |cFF00FF00(active)|r" or ""
        print(format("  %s%s", name, active))
        count = count + 1
    end
    if count == 0 then print("  (none)") end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")

    -- Initialize account-wide DB
    if AutoSellPlusDB == nil then
        AutoSellPlusDB = {
            dbVersion = DB_VERSION,
            global = DeepCopy(ns.globalDefaults),
        }
        for key, defaultValue in pairs(ns.topLevelDefaults) do
            AutoSellPlusDB[key] = DeepCopy(defaultValue)
        end
    else
        MigrateDB(AutoSellPlusDB)
        if AutoSellPlusDB.global == nil then
            AutoSellPlusDB.global = {}
        end
        ValidateDB(AutoSellPlusDB.global, ns.globalDefaults)
        for key, defaultValue in pairs(ns.topLevelDefaults) do
            if AutoSellPlusDB[key] == nil then
                AutoSellPlusDB[key] = DeepCopy(defaultValue)
            end
        end
    end

    -- Initialize per-character DB
    if AutoSellPlusCharDB == nil then
        AutoSellPlusCharDB = DeepCopy(ns.charDefaults)
    else
        ValidateDB(AutoSellPlusCharDB, ns.charDefaults)
        AutoSellPlusCharDB.charFirstRunComplete = true
    end

    SetupDBProxy()
end)
