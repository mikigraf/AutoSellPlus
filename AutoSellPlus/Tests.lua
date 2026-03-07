local addonName, ns = ...

-- Guard: only define tests if WoWUnit is installed
if not WoWUnit then return end

local AreEqual = WoWUnit.AreEqual
local IsTrue = WoWUnit.IsTrue
local IsFalse = WoWUnit.IsFalse
local Replace = WoWUnit.Replace

-- ============================================================
-- Test Utilities
-- ============================================================

-- Mock ns.db with a simple table for isolated tests
local function MockDB(overrides)
    local db = {}
    for k, v in pairs(ns.globalDefaults) do
        db[k] = ns.DeepCopy(v)
    end
    db.neverSellList = {}
    db.alwaysSellList = {}
    db.markedItems = {}
    db.stackLimits = {}
    db.saleHistory = {}
    if overrides then
        for k, v in pairs(overrides) do
            db[k] = v
        end
    end
    return db
end

-- ============================================================
-- 1. FormatMoney Tests
-- ============================================================

local FormatMoney = WoWUnit("ASP FormatMoney")

function FormatMoney:ZeroReturnsZeroC()
    AreEqual("0c", ns:FormatMoney(0))
end

function FormatMoney:NilReturnsZeroC()
    AreEqual("0c", ns:FormatMoney(nil))
end

function FormatMoney:CopperOnly()
    AreEqual("50c", ns:FormatMoney(50))
end

function FormatMoney:SilverOnly()
    AreEqual("5s", ns:FormatMoney(500))
end

function FormatMoney:GoldOnly()
    AreEqual("1g", ns:FormatMoney(10000))
end

function FormatMoney:GoldSilverCopper()
    AreEqual("1g 50s 25c", ns:FormatMoney(15025))
end

function FormatMoney:LargeGold()
    AreEqual("100g", ns:FormatMoney(1000000))
end

function FormatMoney:NegativeValue()
    AreEqual("-5g 20s 30c", ns:FormatMoney(-52030))
end

function FormatMoney:GoldAndCopper()
    AreEqual("2g 5c", ns:FormatMoney(20005))
end

function FormatMoney:GoldAndSilver()
    AreEqual("3g 50s", ns:FormatMoney(35000))
end

function FormatMoney:SilverAndCopper()
    AreEqual("7s 42c", ns:FormatMoney(742))
end

function FormatMoney:OneCopper()
    AreEqual("1c", ns:FormatMoney(1))
end

function FormatMoney:OneSilver()
    AreEqual("1s", ns:FormatMoney(100))
end

function FormatMoney:OneGold()
    AreEqual("1g", ns:FormatMoney(10000))
end

function FormatMoney:NegativeCopper()
    AreEqual("-50c", ns:FormatMoney(-50))
end

-- ============================================================
-- 2. FormatGoldShort Tests
-- ============================================================

local FormatGoldShort = WoWUnit("ASP FormatGoldShort")

function FormatGoldShort:GoldRange()
    AreEqual("5g", ns:FormatGoldShort(50000))
end

function FormatGoldShort:SilverRange()
    AreEqual("20s", ns:FormatGoldShort(2000))
end

function FormatGoldShort:CopperRange()
    AreEqual("42c", ns:FormatGoldShort(42))
end

function FormatGoldShort:Boundary10000()
    AreEqual("1g", ns:FormatGoldShort(10000))
end

function FormatGoldShort:Boundary100()
    AreEqual("1s", ns:FormatGoldShort(100))
end

function FormatGoldShort:Below100()
    AreEqual("99c", ns:FormatGoldShort(99))
end

function FormatGoldShort:ZeroCopper()
    AreEqual("0c", ns:FormatGoldShort(0))
end

function FormatGoldShort:LargeGold()
    AreEqual("500g", ns:FormatGoldShort(5000000))
end

-- ============================================================
-- 3. DeepCopy Tests
-- ============================================================

local DeepCopy = WoWUnit("ASP DeepCopy")

function DeepCopy:CopiesPrimitive()
    AreEqual(42, ns.DeepCopy(42))
    AreEqual("hello", ns.DeepCopy("hello"))
    AreEqual(true, ns.DeepCopy(true))
end

function DeepCopy:CopiesNil()
    AreEqual(nil, ns.DeepCopy(nil))
end

function DeepCopy:CopiesTable()
    local orig = { a = 1, b = "two", c = true }
    local copy = ns.DeepCopy(orig)
    AreEqual(1, copy.a)
    AreEqual("two", copy.b)
    AreEqual(true, copy.c)
end

function DeepCopy:CopyIsIndependent()
    local orig = { x = 10 }
    local copy = ns.DeepCopy(orig)
    copy.x = 20
    AreEqual(10, orig.x)
    AreEqual(20, copy.x)
end

function DeepCopy:NestedTableIsDeep()
    local orig = { inner = { val = 99 } }
    local copy = ns.DeepCopy(orig)
    copy.inner.val = 0
    AreEqual(99, orig.inner.val)
    AreEqual(0, copy.inner.val)
end

function DeepCopy:CopiesArray()
    local orig = { 1, 2, 3 }
    local copy = ns.DeepCopy(orig)
    AreEqual(3, #copy)
    AreEqual(1, copy[1])
    AreEqual(2, copy[2])
    AreEqual(3, copy[3])
end

-- ============================================================
-- 4. ValidateDB Tests
-- ============================================================

local ValidateDB = WoWUnit("ASP ValidateDB")

function ValidateDB:FillsMissingKeys()
    local db = {}
    local defaults = { enabled = true, threshold = 50 }
    ns.ValidateDB(db, defaults)
    AreEqual(true, db.enabled)
    AreEqual(50, db.threshold)
end

function ValidateDB:PreservesExistingValues()
    local db = { enabled = false, threshold = 100 }
    local defaults = { enabled = true, threshold = 50 }
    ns.ValidateDB(db, defaults)
    AreEqual(false, db.enabled)
    AreEqual(100, db.threshold)
end

function ValidateDB:ResetsTypeMismatch()
    local db = { enabled = "yes", threshold = "abc" }
    local defaults = { enabled = true, threshold = 50 }
    ns.ValidateDB(db, defaults)
    AreEqual(true, db.enabled)
    AreEqual(50, db.threshold)
end

function ValidateDB:HandlesNilDB()
    -- Should not error on nil input
    ns.ValidateDB(nil, { x = 1 })
end

function ValidateDB:TableTypeMismatchResets()
    local db = { settings = "not_a_table" }
    local defaults = { settings = { a = 1 } }
    ns.ValidateDB(db, defaults)
    AreEqual(1, db.settings.a)
end

-- ============================================================
-- 5. MigrateDB Tests
-- ============================================================

local MigrateDB = WoWUnit("ASP MigrateDB")

function MigrateDB:V0FlatToGlobal()
    local db = {
        enabled = false,
        sellGrays = true,
        neverSellList = { [123] = true },
    }
    ns.MigrateDB(db)
    -- Settings should be moved to db.global
    AreEqual(false, db.global.enabled)
    AreEqual(true, db.global.sellGrays)
    -- Lists stay at top level
    IsTrue(db.neverSellList[123])
    AreEqual(2, db.dbVersion)
end

function MigrateDB:V0CreatesTopLevelTables()
    local db = {}
    ns.MigrateDB(db)
    IsTrue(db.profiles ~= nil)
    IsTrue(db.charStats ~= nil)
    IsTrue(db.saleHistory ~= nil)
    IsTrue(db.markedItems ~= nil)
    IsTrue(db.stackLimits ~= nil)
    AreEqual(2, db.dbVersion)
end

function MigrateDB:V1ToV2AddsNewTables()
    local db = {
        dbVersion = 1,
        global = { enabled = true },
        neverSellList = {},
        alwaysSellList = {},
    }
    ns.MigrateDB(db)
    IsTrue(db.profiles ~= nil)
    IsTrue(db.stackLimits ~= nil)
    AreEqual(2, db.dbVersion)
end

function MigrateDB:AlreadyCurrentNoOp()
    local db = {
        dbVersion = 2,
        global = { enabled = true },
        neverSellList = {},
        alwaysSellList = {},
        profiles = {},
        charStats = {},
        saleHistory = {},
        markedItems = {},
        stackLimits = {},
    }
    ns.MigrateDB(db)
    AreEqual(2, db.dbVersion)
    AreEqual(true, db.global.enabled)
end

-- ============================================================
-- 6. NeverSell / AlwaysSell List Tests
-- ============================================================

local ListChecks = WoWUnit("ASP ListChecks")

function ListChecks:NeverSellGlobalHit()
    AutoSellPlusDB.neverSellList[99999] = true
    IsTrue(ns:IsNeverSell(99999))
    AutoSellPlusDB.neverSellList[99999] = nil
end

function ListChecks:NeverSellGlobalMiss()
    IsFalse(ns:IsNeverSell(88888))
end

function ListChecks:NeverSellCharHit()
    AutoSellPlusCharDB.charNeverSellList[77777] = true
    IsTrue(ns:IsNeverSell(77777))
    AutoSellPlusCharDB.charNeverSellList[77777] = nil
end

function ListChecks:AlwaysSellGlobalHit()
    AutoSellPlusDB.alwaysSellList[66666] = true
    IsTrue(ns:IsAlwaysSell(66666))
    AutoSellPlusDB.alwaysSellList[66666] = nil
end

function ListChecks:AlwaysSellGlobalMiss()
    IsFalse(ns:IsAlwaysSell(55555))
end

function ListChecks:AlwaysSellCharHit()
    AutoSellPlusCharDB.charAlwaysSellList[44444] = true
    IsTrue(ns:IsAlwaysSell(44444))
    AutoSellPlusCharDB.charAlwaysSellList[44444] = nil
end

-- ============================================================
-- 7. Serialize / Deserialize Tests
-- ============================================================

local Serialize = WoWUnit("ASP Serialize")

function Serialize:SerializeNever()
    AutoSellPlusDB.neverSellList[100] = true
    AutoSellPlusDB.neverSellList[200] = true
    local result = ns:SerializeList("never")
    IsTrue(result:find("NEVER:"))
    IsTrue(result:find("100"))
    IsTrue(result:find("200"))
    IsFalse(result:find("ALWAYS:"))
    AutoSellPlusDB.neverSellList[100] = nil
    AutoSellPlusDB.neverSellList[200] = nil
end

function Serialize:SerializeAlways()
    AutoSellPlusDB.alwaysSellList[300] = true
    local result = ns:SerializeList("always")
    IsTrue(result:find("ALWAYS:"))
    IsTrue(result:find("300"))
    IsFalse(result:find("NEVER:"))
    AutoSellPlusDB.alwaysSellList[300] = nil
end

function Serialize:SerializeAll()
    AutoSellPlusDB.neverSellList[100] = true
    AutoSellPlusDB.alwaysSellList[200] = true
    local result = ns:SerializeList("all")
    IsTrue(result:find("NEVER:"))
    IsTrue(result:find("ALWAYS:"))
    AutoSellPlusDB.neverSellList[100] = nil
    AutoSellPlusDB.alwaysSellList[200] = nil
end

function Serialize:SerializeEmptyReturnsEmpty()
    -- Clear lists temporarily
    local savedN = ns.DeepCopy(AutoSellPlusDB.neverSellList)
    local savedA = ns.DeepCopy(AutoSellPlusDB.alwaysSellList)
    wipe(AutoSellPlusDB.neverSellList)
    wipe(AutoSellPlusDB.alwaysSellList)
    local result = ns:SerializeList("all")
    AreEqual("", result)
    -- Restore
    for k, v in pairs(savedN) do AutoSellPlusDB.neverSellList[k] = v end
    for k, v in pairs(savedA) do AutoSellPlusDB.alwaysSellList[k] = v end
end

function Serialize:DeserializeValid()
    local ok, count = ns:DeserializeList("NEVER:500,600;ALWAYS:700")
    IsTrue(ok)
    AreEqual(3, count)
    IsTrue(AutoSellPlusDB.neverSellList[500])
    IsTrue(AutoSellPlusDB.neverSellList[600])
    IsTrue(AutoSellPlusDB.alwaysSellList[700])
    AutoSellPlusDB.neverSellList[500] = nil
    AutoSellPlusDB.neverSellList[600] = nil
    AutoSellPlusDB.alwaysSellList[700] = nil
end

function Serialize:DeserializeEmpty()
    local ok = ns:DeserializeList("")
    IsFalse(ok)
end

function Serialize:DeserializeNil()
    local ok = ns:DeserializeList(nil)
    IsFalse(ok)
end

function Serialize:DeserializeMalformedIgnored()
    local ok, count = ns:DeserializeList("GARBAGE")
    IsFalse(ok)
end

function Serialize:RoundTrip()
    AutoSellPlusDB.neverSellList[1001] = true
    AutoSellPlusDB.alwaysSellList[2002] = true
    local serialized = ns:SerializeList("all")
    -- Clear and re-import
    AutoSellPlusDB.neverSellList[1001] = nil
    AutoSellPlusDB.alwaysSellList[2002] = nil
    local ok, count = ns:DeserializeList(serialized)
    IsTrue(ok)
    IsTrue(AutoSellPlusDB.neverSellList[1001])
    IsTrue(AutoSellPlusDB.alwaysSellList[2002])
    AutoSellPlusDB.neverSellList[1001] = nil
    AutoSellPlusDB.alwaysSellList[2002] = nil
end

-- ============================================================
-- 8. ExceedsStackLimit Tests
-- ============================================================

local StackLimit = WoWUnit("ASP StackLimit")

function StackLimit:NoLimitReturnsZero()
    AreEqual(0, ns:ExceedsStackLimit(99999))
end

function StackLimit:UnderLimitReturnsZero()
    AutoSellPlusDB.stackLimits[12345] = 20
    Replace(ns, "GetItemCount", function() return 10 end)
    AreEqual(0, ns:ExceedsStackLimit(12345))
    AutoSellPlusDB.stackLimits[12345] = nil
end

function StackLimit:AtLimitReturnsZero()
    AutoSellPlusDB.stackLimits[12345] = 20
    Replace(ns, "GetItemCount", function() return 20 end)
    AreEqual(0, ns:ExceedsStackLimit(12345))
    AutoSellPlusDB.stackLimits[12345] = nil
end

function StackLimit:OverLimitReturnsExcess()
    AutoSellPlusDB.stackLimits[12345] = 20
    Replace(ns, "GetItemCount", function() return 35 end)
    AreEqual(15, ns:ExceedsStackLimit(12345))
    AutoSellPlusDB.stackLimits[12345] = nil
end

-- ============================================================
-- 9. Profile Management Tests
-- ============================================================

local Profiles = WoWUnit("ASP Profiles")

function Profiles:SaveCreatesProfile()
    local result = ns:SaveProfile("TestProfile")
    IsTrue(result)
    IsTrue(AutoSellPlusDB.profiles["TestProfile"] ~= nil)
    AutoSellPlusDB.profiles["TestProfile"] = nil
end

function Profiles:SaveEmptyNameFails()
    local result = ns:SaveProfile("")
    IsFalse(result)
end

function Profiles:SaveNilNameFails()
    local result = ns:SaveProfile(nil)
    IsFalse(result)
end

function Profiles:LoadExistingProfile()
    AutoSellPlusDB.profiles["LoadTest"] = ns.DeepCopy(ns.globalDefaults)
    AutoSellPlusDB.profiles["LoadTest"].sellWhites = true
    local result = ns:LoadProfile("LoadTest")
    IsTrue(result)
    AreEqual(true, AutoSellPlusDB.global.sellWhites)
    AreEqual("LoadTest", AutoSellPlusCharDB.activeProfile)
    -- Reset
    AutoSellPlusDB.global.sellWhites = false
    AutoSellPlusDB.profiles["LoadTest"] = nil
    AutoSellPlusCharDB.activeProfile = ""
end

function Profiles:LoadMissingFails()
    local result = ns:LoadProfile("NonExistent")
    IsFalse(result)
end

function Profiles:DeleteExistingProfile()
    AutoSellPlusDB.profiles["DelTest"] = { enabled = true }
    local result = ns:DeleteProfile("DelTest")
    IsTrue(result)
    IsFalse(AutoSellPlusDB.profiles["DelTest"] ~= nil)
end

function Profiles:DeleteMissingFails()
    local result = ns:DeleteProfile("Ghost")
    IsFalse(result)
end

function Profiles:SavedProfileIsDeepCopy()
    AutoSellPlusDB.global.sellBlues = true
    ns:SaveProfile("CopyTest")
    AutoSellPlusDB.global.sellBlues = false
    AreEqual(true, AutoSellPlusDB.profiles["CopyTest"].sellBlues)
    AutoSellPlusDB.profiles["CopyTest"] = nil
end

-- ============================================================
-- 10. ApplyTemplate Tests
-- ============================================================

local Templates = WoWUnit("ASP Templates")

function Templates:ApplyRaidFarmer()
    local result = ns:ApplyTemplate("Raid Farmer")
    IsTrue(result)
    AreEqual(true, AutoSellPlusDB.global.sellGrays)
    AreEqual(true, AutoSellPlusDB.global.sellWhites)
    AreEqual(true, AutoSellPlusDB.global.sellGreens)
    AreEqual(false, AutoSellPlusDB.global.sellBlues)
    AreEqual("popup", AutoSellPlusDB.global.autoSellMode)
end

function Templates:ApplyTransmogHunter()
    local result = ns:ApplyTemplate("Transmog Hunter")
    IsTrue(result)
    AreEqual(true, AutoSellPlusDB.global.sellGrays)
    AreEqual(false, AutoSellPlusDB.global.sellWhites)
    AreEqual(true, AutoSellPlusDB.global.protectTransmogSource)
end

function Templates:ApplyLevelingAlt()
    local result = ns:ApplyTemplate("Leveling Alt")
    IsTrue(result)
    AreEqual(true, AutoSellPlusDB.global.sellBlues)
    AreEqual("autosell", AutoSellPlusDB.global.autoSellMode)
    AreEqual(2, AutoSellPlusDB.global.autoSellDelay)
end

function Templates:ApplyGoldFarmer()
    local result = ns:ApplyTemplate("Gold Farmer")
    IsTrue(result)
    AreEqual(true, AutoSellPlusDB.global.sellConsumables)
    AreEqual(true, AutoSellPlusDB.global.sellTradeGoods)
    AreEqual(false, AutoSellPlusDB.global.onlyEquippable)
end

function Templates:ApplyCaseInsensitive()
    local result = ns:ApplyTemplate("raid farmer")
    IsTrue(result)
end

function Templates:ApplyNonExistentFails()
    local result = ns:ApplyTemplate("Nonexistent Template")
    IsFalse(result)
end

function Templates:ApplyResetsToDefaultsFirst()
    AutoSellPlusDB.global.sellEpics = true
    ns:ApplyTemplate("Transmog Hunter")
    AreEqual(false, AutoSellPlusDB.global.sellEpics)
end

-- ============================================================
-- 11. Marking System Tests
-- ============================================================

local Marking = WoWUnit("ASP Marking")

function Marking:IsMarkedFalseByDefault()
    IsFalse(ns:IsMarked(11111))
end

function Marking:IsMarkedAfterSet()
    AutoSellPlusDB.markedItems[22222] = true
    IsTrue(ns:IsMarked(22222))
    AutoSellPlusDB.markedItems[22222] = nil
end

function Marking:BulkMarkModeToggle()
    ns.bulkMarkMode = false
    ns:ToggleBulkMarkMode()
    IsTrue(ns.bulkMarkMode)
    ns:ToggleBulkMarkMode()
    IsFalse(ns.bulkMarkMode)
end

-- ============================================================
-- 12. Session Tracking Tests
-- ============================================================

local Session = WoWUnit("ASP Session")

function Session:InitSessionResetsCounters()
    ns.sessionData.totalSold = 99
    ns.sessionData.totalCopper = 999999
    ns.sessionData.itemCount = 50
    Replace("GetServerTime", function() return 1000000 end)
    Replace("GetMoney", function() return 500000 end)
    ns:InitSession()
    AreEqual(0, ns.sessionData.totalSold)
    AreEqual(0, ns.sessionData.totalCopper)
    AreEqual(0, ns.sessionData.itemCount)
    AreEqual(1000000, ns.sessionData.startTime)
    AreEqual(500000, ns.sessionData.startGold)
end

function Session:UpdateSessionAccumulates()
    ns.sessionData.totalSold = 0
    ns.sessionData.totalCopper = 0
    ns.sessionData.itemCount = 0
    ns:UpdateSession(3, 15000)
    AreEqual(1, ns.sessionData.totalSold)
    AreEqual(15000, ns.sessionData.totalCopper)
    AreEqual(3, ns.sessionData.itemCount)
    ns:UpdateSession(2, 5000)
    AreEqual(2, ns.sessionData.totalSold)
    AreEqual(20000, ns.sessionData.totalCopper)
    AreEqual(5, ns.sessionData.itemCount)
end

function Session:GetSessionReportCalculation()
    ns.sessionData.startTime = 1000
    ns.sessionData.totalSold = 5
    ns.sessionData.totalCopper = 360000
    ns.sessionData.itemCount = 10
    ns.sessionData.startGold = 100000
    Replace("GetServerTime", function() return 1360 end)
    Replace("GetMoney", function() return 460000 end)
    local r = ns:GetSessionReport()
    AreEqual(360, r.elapsed)
    AreEqual(5, r.sellCount)
    AreEqual(10, r.itemCount)
    AreEqual(360000, r.totalCopper)
    AreEqual(360, r.goldPerHour)
    AreEqual(100000, r.startGold)
    AreEqual(460000, r.currentGold)
    AreEqual(360000, r.netGold)
end

function Session:GetSessionReportZeroElapsed()
    ns.sessionData.startTime = 1000
    ns.sessionData.totalCopper = 50000
    Replace("GetServerTime", function() return 1000 end)
    Replace("GetMoney", function() return 50000 end)
    local r = ns:GetSessionReport()
    AreEqual(0, r.elapsed)
    AreEqual(0, r.goldPerHour)
end

-- ============================================================
-- 13. Sale History Tests
-- ============================================================

local History = WoWUnit("ASP History")

function History:RecordSaleAddsEntry()
    local savedHistory = ns.DeepCopy(AutoSellPlusDB.saleHistory)
    wipe(AutoSellPlusDB.saleHistory)

    Replace("GetServerTime", function() return 2000 end)
    ns:RecordSale("|cff1eff00[Test Item]|r", 12345, 3, 9000)

    local h = AutoSellPlusDB.saleHistory
    AreEqual(1, #h)
    AreEqual("|cff1eff00[Test Item]|r", h[1].link)
    AreEqual(12345, h[1].id)
    AreEqual(3, h[1].count)
    AreEqual(9000, h[1].price)
    AreEqual(2000, h[1].time)

    -- Restore
    wipe(AutoSellPlusDB.saleHistory)
    for _, v in ipairs(savedHistory) do AutoSellPlusDB.saleHistory[#AutoSellPlusDB.saleHistory + 1] = v end
end

function History:RecordSaleFIFOCap()
    local savedHistory = ns.DeepCopy(AutoSellPlusDB.saleHistory)
    wipe(AutoSellPlusDB.saleHistory)

    Replace("GetServerTime", function() return 3000 end)
    for i = 1, 205 do
        ns:RecordSale("item" .. i, i, 1, 100)
    end
    -- Should be capped at 200
    local h = AutoSellPlusDB.saleHistory
    AreEqual(200, #h)
    -- First entry should be item6 (items 1-5 evicted)
    AreEqual("item6", h[1].link)
    AreEqual("item205", h[200].link)

    -- Restore
    wipe(AutoSellPlusDB.saleHistory)
    for _, v in ipairs(savedHistory) do AutoSellPlusDB.saleHistory[#AutoSellPlusDB.saleHistory + 1] = v end
end

function History:GetSaleHistoryReturnsTable()
    local h = ns:GetSaleHistory()
    IsTrue(type(h) == "table")
end

function History:GetRecentSalesFilters()
    local savedHistory = ns.DeepCopy(AutoSellPlusDB.saleHistory)
    wipe(AutoSellPlusDB.saleHistory)

    AutoSellPlusDB.saleHistory = {
        { link = "old", id = 1, count = 1, price = 100, time = 1000 },
        { link = "recent", id = 2, count = 1, price = 200, time = 5000 },
    }

    Replace("GetServerTime", function() return 5060 end)
    local recent = ns:GetRecentSales(2) -- last 2 minutes (120 seconds)
    AreEqual(1, #recent)
    AreEqual("recent", recent[1].link)

    -- Restore
    wipe(AutoSellPlusDB.saleHistory)
    for _, v in ipairs(savedHistory) do AutoSellPlusDB.saleHistory[#AutoSellPlusDB.saleHistory + 1] = v end
end

function History:GetDailyStatsCalculation()
    local savedHistory = ns.DeepCopy(AutoSellPlusDB.saleHistory)
    wipe(AutoSellPlusDB.saleHistory)

    local now = 100000
    local todayStart = now - (now % 86400)
    Replace("GetServerTime", function() return now end)

    AutoSellPlusDB.saleHistory = {
        { link = "yesterday", id = 1, count = 2, price = 500, time = todayStart - 100 },
        { link = "today1", id = 2, count = 3, price = 1000, time = todayStart + 10 },
        { link = "today2", id = 3, count = 1, price = 2000, time = todayStart + 50 },
    }

    local copper, items = ns:GetDailyStats()
    AreEqual(3000, copper)
    AreEqual(4, items)

    -- Restore
    wipe(AutoSellPlusDB.saleHistory)
    for _, v in ipairs(savedHistory) do AutoSellPlusDB.saleHistory[#AutoSellPlusDB.saleHistory + 1] = v end
end

-- ============================================================
-- 14. Equipment Set Cache Tests
-- ============================================================

local EquipSets = WoWUnit("ASP EquipmentSets")

function EquipSets:IsInEquipmentSetFalseByDefault()
    IsFalse(ns:IsInEquipmentSet(33333))
end

function EquipSets:IsInEquipmentSetTrueWhenCached()
    ns.equipmentSetItems[44444] = true
    IsTrue(ns:IsInEquipmentSet(44444))
    ns.equipmentSetItems[44444] = nil
end

-- ============================================================
-- 15. Feature Availability Tests
-- ============================================================

local Features = WoWUnit("ASP Features")

function Features:AllFeaturesDefaultTrue()
    IsTrue(ns:IsFeatureAvailable("selling"))
    IsTrue(ns:IsFeatureAvailable("scanning"))
    IsTrue(ns:IsFeatureAvailable("itemInfo"))
    IsTrue(ns:IsFeatureAvailable("transmog"))
    IsTrue(ns:IsFeatureAvailable("equipSets"))
    IsTrue(ns:IsFeatureAvailable("destroying"))
end

function Features:DisabledFeatureReturnsFalse()
    local saved = ns.features.transmog
    ns.features.transmog = false
    IsFalse(ns:IsFeatureAvailable("transmog"))
    ns.features.transmog = saved
end

function Features:UnknownFeatureReturnsFalse()
    IsFalse(ns:IsFeatureAvailable("nonexistent") == false)
end

-- ============================================================
-- 16. ApplyFilters Tests
-- ============================================================

local Filters = WoWUnit("ASP Filters")

-- Helper to create a display list item
local function MakeItem(overrides)
    local item = {
        bag = 0, slot = 1,
        itemID = 100, itemLink = "|cff9d9d9d[Broken Tooth]|r",
        quality = 0, ilvl = 10, equippedIlvl = 0,
        sellPrice = 50, stackCount = 1, totalPrice = 50,
        isEquippable = false, isAlwaysSell = false,
        isMarked = false, isBoe = false,
        classID = 15, expansionID = 11,
        ahValue = 0, checked = false, visible = false,
    }
    if overrides then
        for k, v in pairs(overrides) do item[k] = v end
    end
    return item
end

function Filters:GrayItemVisible()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.sellGrays = true
    local items = { MakeItem({ quality = 0 }) }
    ns:ApplyFilters(items, {})
    IsTrue(items[1].visible)
    IsTrue(items[1].checked)
    -- Restore
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function Filters:GrayItemHiddenWhenDisabled()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.sellGrays = false
    local items = { MakeItem({ quality = 0 }) }
    ns:ApplyFilters(items, {})
    IsFalse(items[1].visible)
    IsFalse(items[1].checked)
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function Filters:AlwaysSellItemAlwaysVisible()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.sellGrays = false
    AutoSellPlusDB.global.sellWhites = false
    local items = { MakeItem({ quality = 1, isAlwaysSell = true }) }
    ns:ApplyFilters(items, {})
    IsTrue(items[1].visible)
    IsTrue(items[1].checked)
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function Filters:MarkedItemAlwaysVisible()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.sellGrays = false
    local items = { MakeItem({ quality = 2, isMarked = true }) }
    ns:ApplyFilters(items, {})
    IsTrue(items[1].visible)
    IsTrue(items[1].checked)
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function Filters:GreenWithIlvlFilterChecked()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.sellGreens = true
    AutoSellPlusDB.global.greenMaxIlvl = 200
    AutoSellPlusDB.global.onlyEquippable = false
    local items = { MakeItem({
        quality = 2, ilvl = 150, isEquippable = true, equippedIlvl = 300,
    }) }
    ns:ApplyFilters(items, {})
    IsTrue(items[1].visible)
    IsTrue(items[1].checked)
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function Filters:GreenAboveIlvlNotChecked()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.sellGreens = true
    AutoSellPlusDB.global.greenMaxIlvl = 100
    AutoSellPlusDB.global.onlyEquippable = false
    local items = { MakeItem({
        quality = 2, ilvl = 150, isEquippable = true, equippedIlvl = 300,
    }) }
    ns:ApplyFilters(items, {})
    IsTrue(items[1].visible)
    IsFalse(items[1].checked)
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function Filters:UpgradeNotAutoChecked()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.sellGreens = true
    AutoSellPlusDB.global.greenMaxIlvl = 300
    AutoSellPlusDB.global.onlyEquippable = false
    local items = { MakeItem({
        quality = 2, ilvl = 250, isEquippable = true, equippedIlvl = 200,
    }) }
    ns:ApplyFilters(items, {})
    IsTrue(items[1].visible)
    -- isUpgrade should be detected, so NOT auto-checked
    IsFalse(items[1].checked)
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function Filters:OnlyEquippableHidesNonGear()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.sellWhites = true
    AutoSellPlusDB.global.onlyEquippable = true
    local items = { MakeItem({ quality = 1, isEquippable = false }) }
    ns:ApplyFilters(items, {})
    IsFalse(items[1].visible)
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function Filters:CategoryConsumablesFilter()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.sellConsumables = true
    local items = { MakeItem({ quality = 1, classID = 0, isEquippable = false }) }
    ns:ApplyFilters(items, {})
    IsTrue(items[1].visible)
    IsTrue(items[1].checked)
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function Filters:CategoryTradeGoodsFilter()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.sellTradeGoods = true
    local items = { MakeItem({ quality = 1, classID = 7 }) }
    ns:ApplyFilters(items, {})
    IsTrue(items[1].visible)
    IsTrue(items[1].checked)
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function Filters:ExpansionFilterHidesMismatch()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.sellGrays = true
    AutoSellPlusDB.global.filterExpansion = 10 -- DF
    local items = { MakeItem({ quality = 0, expansionID = 11 }) } -- TWW
    ns:ApplyFilters(items, {})
    IsFalse(items[1].visible)
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function Filters:ExpansionFilterShowsMatch()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.sellGrays = true
    AutoSellPlusDB.global.filterExpansion = 11
    local items = { MakeItem({ quality = 0, expansionID = 11 }) }
    ns:ApplyFilters(items, {})
    IsTrue(items[1].visible)
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function Filters:ExcludeCurrentExpansion()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.sellGrays = true
    AutoSellPlusDB.global.excludeCurrentExpansion = true
    local items = { MakeItem({ quality = 0, expansionID = ns.CURRENT_EXPANSION }) }
    ns:ApplyFilters(items, {})
    IsFalse(items[1].visible)
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function Filters:UserUncheckedOverrides()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.sellGrays = true
    local items = { MakeItem({ quality = 0, bag = 0, slot = 3 }) }
    ns:ApplyFilters(items, { ["0:3"] = true })
    IsTrue(items[1].visible)
    IsFalse(items[1].checked) -- user unchecked
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function Filters:EpicFilterDisabledHidesEpic()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.sellEpics = false
    local items = { MakeItem({ quality = 4, isEquippable = true }) }
    ns:ApplyFilters(items, {})
    IsFalse(items[1].visible)
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function Filters:BlueWithIlvlFilterAndOnlyEquippable()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.sellBlues = true
    AutoSellPlusDB.global.blueMaxIlvl = 300
    AutoSellPlusDB.global.onlyEquippable = true
    local items = { MakeItem({
        quality = 3, ilvl = 200, isEquippable = true, equippedIlvl = 400,
    }) }
    ns:ApplyFilters(items, {})
    IsTrue(items[1].visible)
    IsTrue(items[1].checked)
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

-- ============================================================
-- 17. SortDisplayItems Tests
-- ============================================================

local Sort = WoWUnit("ASP Sort")

function Sort:SortByQualityAsc()
    ns.sortColumn = "quality"
    ns.sortDirection = "asc"
    local items = {
        MakeItem({ quality = 3, ilvl = 100 }),
        MakeItem({ quality = 0, ilvl = 50 }),
        MakeItem({ quality = 2, ilvl = 80 }),
    }
    ns:SortDisplayItems(items)
    AreEqual(0, items[1].quality)
    AreEqual(2, items[2].quality)
    AreEqual(3, items[3].quality)
end

function Sort:SortByQualityDesc()
    ns.sortColumn = "quality"
    ns.sortDirection = "desc"
    local items = {
        MakeItem({ quality = 0, ilvl = 50 }),
        MakeItem({ quality = 3, ilvl = 100 }),
        MakeItem({ quality = 2, ilvl = 80 }),
    }
    ns:SortDisplayItems(items)
    AreEqual(3, items[1].quality)
    AreEqual(2, items[2].quality)
    AreEqual(0, items[3].quality)
end

function Sort:SortByIlvlAsc()
    ns.sortColumn = "ilvl"
    ns.sortDirection = "asc"
    local items = {
        MakeItem({ ilvl = 300, quality = 2 }),
        MakeItem({ ilvl = 100, quality = 0 }),
        MakeItem({ ilvl = 200, quality = 1 }),
    }
    ns:SortDisplayItems(items)
    AreEqual(100, items[1].ilvl)
    AreEqual(200, items[2].ilvl)
    AreEqual(300, items[3].ilvl)
end

function Sort:SortByPriceDesc()
    ns.sortColumn = "price"
    ns.sortDirection = "desc"
    local items = {
        MakeItem({ totalPrice = 100 }),
        MakeItem({ totalPrice = 5000 }),
        MakeItem({ totalPrice = 500 }),
    }
    ns:SortDisplayItems(items)
    AreEqual(5000, items[1].totalPrice)
    AreEqual(500, items[2].totalPrice)
    AreEqual(100, items[3].totalPrice)
end

function Sort:SortByAhValue()
    ns.sortColumn = "ah"
    ns.sortDirection = "desc"
    local items = {
        MakeItem({ ahValue = 0, totalPrice = 100 }),
        MakeItem({ ahValue = 50000, totalPrice = 200 }),
        MakeItem({ ahValue = 10000, totalPrice = 300 }),
    }
    ns:SortDisplayItems(items)
    AreEqual(50000, items[1].ahValue)
    AreEqual(10000, items[2].ahValue)
    AreEqual(0, items[3].ahValue)
end

function Sort:SortByQualityThenIlvl()
    ns.sortColumn = "quality"
    ns.sortDirection = "asc"
    local items = {
        MakeItem({ quality = 2, ilvl = 300 }),
        MakeItem({ quality = 2, ilvl = 100 }),
        MakeItem({ quality = 2, ilvl = 200 }),
    }
    ns:SortDisplayItems(items)
    AreEqual(100, items[1].ilvl)
    AreEqual(200, items[2].ilvl)
    AreEqual(300, items[3].ilvl)
end

-- ============================================================
-- 18. ShouldSellItem Tests (with mocked WoW APIs)
-- ============================================================

local ShouldSell = WoWUnit("ASP ShouldSellItem")

-- Set up common mocks for ShouldSellItem tests
local function SetupShouldSellMocks(itemOverrides)
    local itemInfo = {
        itemID = 50000,
        hyperlink = "|cff9d9d9d[Gray Junk]|r",
        quality = 0,
        isLocked = false,
        hasNoValue = false,
        stackCount = 1,
    }
    if itemOverrides then
        for k, v in pairs(itemOverrides) do itemInfo[k] = v end
    end

    Replace(C_Container, "GetContainerItemInfo", function(bag, slot)
        return itemInfo
    end)
    Replace(C_Item, "GetItemInfo", function(link)
        return "Gray Junk", nil, 0, 10, nil, nil, nil, nil, nil, nil, 50
    end)
    Replace(C_Item, "GetItemInfoInstant", function(id)
        return nil, nil, nil, nil, nil, 15 -- classID 15 = Misc
    end)
    Replace(ns, "IsRefundable", function() return false end)
    Replace(ns, "IsBindOnEquip", function() return false end)
    Replace(ns, "IsUncollectedTransmog", function() return false end)
    Replace(ns, "IsUncollectedTransmogSource", function() return false end)
    Replace(ns, "GetEffectiveItemLevel", function() return 10 end)

    return itemInfo
end

function ShouldSell:DisabledAddonReturnsNil()
    local saved = AutoSellPlusDB.global.enabled
    AutoSellPlusDB.global.enabled = false
    SetupShouldSellMocks()
    IsFalse(ns:ShouldSellItem(0, 1))
    AutoSellPlusDB.global.enabled = saved
end

function ShouldSell:EmptySlotReturnsNil()
    Replace(C_Container, "GetContainerItemInfo", function() return nil end)
    IsFalse(ns:ShouldSellItem(0, 1))
end

function ShouldSell:GrayItemWithSellPrice()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.enabled = true
    AutoSellPlusDB.global.sellGrays = true
    SetupShouldSellMocks()
    local shouldSell, link, price, count = ns:ShouldSellItem(0, 1)
    IsTrue(shouldSell)
    AreEqual("|cff9d9d9d[Gray Junk]|r", link)
    AreEqual(50, price)
    AreEqual(1, count)
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function ShouldSell:GrayDisabledSkips()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.enabled = true
    AutoSellPlusDB.global.sellGrays = false
    SetupShouldSellMocks()
    IsFalse(ns:ShouldSellItem(0, 1))
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function ShouldSell:NeverSellBlocksAll()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.enabled = true
    AutoSellPlusDB.global.sellGrays = true
    SetupShouldSellMocks()
    AutoSellPlusDB.neverSellList[50000] = true
    IsFalse(ns:ShouldSellItem(0, 1))
    AutoSellPlusDB.neverSellList[50000] = nil
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function ShouldSell:AlwaysSellForcesSale()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.enabled = true
    AutoSellPlusDB.global.sellGrays = false
    SetupShouldSellMocks({ quality = 2 }) -- green, but grays off, greens off
    AutoSellPlusDB.alwaysSellList[50000] = true
    local shouldSell = ns:ShouldSellItem(0, 1)
    IsTrue(shouldSell)
    AutoSellPlusDB.alwaysSellList[50000] = nil
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function ShouldSell:MarkedItemForcesSale()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.enabled = true
    AutoSellPlusDB.global.sellGrays = false
    SetupShouldSellMocks({ quality = 1 })
    AutoSellPlusDB.markedItems[50000] = true
    local shouldSell = ns:ShouldSellItem(0, 1)
    IsTrue(shouldSell)
    AutoSellPlusDB.markedItems[50000] = nil
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function ShouldSell:LockedItemSkipped()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.enabled = true
    AutoSellPlusDB.global.sellGrays = true
    SetupShouldSellMocks({ isLocked = true })
    IsFalse(ns:ShouldSellItem(0, 1))
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function ShouldSell:NoSellPriceSkipped()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.enabled = true
    AutoSellPlusDB.global.sellGrays = true
    SetupShouldSellMocks()
    Replace(C_Item, "GetItemInfo", function()
        return "Junk", nil, 0, 10, nil, nil, nil, nil, nil, nil, 0
    end)
    IsFalse(ns:ShouldSellItem(0, 1))
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function ShouldSell:HasNoValueFlagSkipped()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.enabled = true
    AutoSellPlusDB.global.sellGrays = true
    SetupShouldSellMocks({ hasNoValue = true })
    IsFalse(ns:ShouldSellItem(0, 1))
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function ShouldSell:EquipmentSetProtected()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.enabled = true
    AutoSellPlusDB.global.sellGrays = true
    AutoSellPlusDB.global.protectEquipmentSets = true
    SetupShouldSellMocks()
    ns.equipmentSetItems[50000] = true
    IsFalse(ns:ShouldSellItem(0, 1))
    ns.equipmentSetItems[50000] = nil
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function ShouldSell:RefundableProtected()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.enabled = true
    AutoSellPlusDB.global.sellGrays = true
    SetupShouldSellMocks()
    Replace(ns, "IsRefundable", function() return true end)
    IsFalse(ns:ShouldSellItem(0, 1))
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function ShouldSell:BoEProtected()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.enabled = true
    AutoSellPlusDB.global.sellGrays = true
    AutoSellPlusDB.global.protectBoE = true
    AutoSellPlusDB.global.allowBoESell = false
    SetupShouldSellMocks()
    Replace(ns, "IsBindOnEquip", function() return true end)
    IsFalse(ns:ShouldSellItem(0, 1))
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function ShouldSell:NeverSellOverridesAlwaysSell()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.enabled = true
    SetupShouldSellMocks()
    AutoSellPlusDB.neverSellList[50000] = true
    AutoSellPlusDB.alwaysSellList[50000] = true
    IsFalse(ns:ShouldSellItem(0, 1))
    AutoSellPlusDB.neverSellList[50000] = nil
    AutoSellPlusDB.alwaysSellList[50000] = nil
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function ShouldSell:CategoryConsumableSold()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.enabled = true
    AutoSellPlusDB.global.sellConsumables = true
    SetupShouldSellMocks({ quality = 1 })
    Replace(C_Item, "GetItemInfoInstant", function()
        return nil, nil, nil, nil, nil, 0 -- classID 0 = Consumable
    end)
    local shouldSell = ns:ShouldSellItem(0, 1)
    IsTrue(shouldSell)
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function ShouldSell:StackCountPassedThrough()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.enabled = true
    AutoSellPlusDB.global.sellGrays = true
    SetupShouldSellMocks({ stackCount = 5 })
    local shouldSell, link, price, count = ns:ShouldSellItem(0, 1)
    IsTrue(shouldSell)
    AreEqual(5, count)
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

-- ============================================================
-- 19. Expansion Constants Tests
-- ============================================================

local Constants = WoWUnit("ASP Constants")

function Constants:CurrentExpansionIsMidnight()
    AreEqual(12, ns.CURRENT_EXPANSION)
end

function Constants:ExpansionNamesExist()
    AreEqual("Classic", ns.EXPANSION_NAMES[1])
    AreEqual("Midnight", ns.EXPANSION_NAMES[12])
    AreEqual("All", ns.EXPANSION_NAMES[0])
end

function Constants:SlotNamesPopulated()
    AreEqual("Head", ns.SLOT_NAMES[1])
    AreEqual("Chest", ns.SLOT_NAMES[5])
    AreEqual("Main Hand", ns.SLOT_NAMES[16])
    AreEqual("Off Hand", ns.SLOT_NAMES[17])
end

function Constants:EquipLocToSlotsMapping()
    AreEqual(1, ns.EQUIP_LOC_TO_SLOTS.INVTYPE_HEAD[1])
    AreEqual(16, ns.EQUIP_LOC_TO_SLOTS.INVTYPE_WEAPON[1])
    -- Dual-slot items
    AreEqual(11, ns.EQUIP_LOC_TO_SLOTS.INVTYPE_FINGER[1])
    AreEqual(12, ns.EQUIP_LOC_TO_SLOTS.INVTYPE_FINGER[2])
    AreEqual(13, ns.EQUIP_LOC_TO_SLOTS.INVTYPE_TRINKET[1])
    AreEqual(14, ns.EQUIP_LOC_TO_SLOTS.INVTYPE_TRINKET[2])
end

function Constants:FlatBackdropDefined()
    IsTrue(ns.FLAT_BACKDROP ~= nil)
    IsTrue(ns.FLAT_BACKDROP.bgFile ~= nil)
    IsTrue(ns.FLAT_BACKDROP.edgeFile ~= nil)
    AreEqual(1, ns.FLAT_BACKDROP.edgeSize)
end

-- ============================================================
-- 20. DB Proxy Tests
-- ============================================================

local DBProxy = WoWUnit("ASP DBProxy")

function DBProxy:ReadsGlobalSetting()
    AutoSellPlusDB.global.sellGrays = true
    AreEqual(true, ns.db.sellGrays)
end

function DBProxy:ReadsTopLevelKey()
    AutoSellPlusDB.neverSellList[11111] = true
    IsTrue(ns.db.neverSellList[11111])
    AutoSellPlusDB.neverSellList[11111] = nil
end

function DBProxy:CharOverrideTakesPrecedence()
    AutoSellPlusDB.global.dryRun = false
    AutoSellPlusCharDB.overrides.dryRun = true
    AreEqual(true, ns.db.dryRun)
    AutoSellPlusCharDB.overrides.dryRun = nil
end

function DBProxy:WritesToGlobal()
    local saved = AutoSellPlusDB.global.dryRun
    ns.db.dryRun = true
    AreEqual(true, AutoSellPlusDB.global.dryRun)
    AutoSellPlusDB.global.dryRun = saved
end

function DBProxy:WritesTopLevelKey()
    ns.db.markedItems[99998] = true
    IsTrue(AutoSellPlusDB.markedItems[99998])
    AutoSellPlusDB.markedItems[99998] = nil
end

-- ============================================================
-- 21. FormatTimeAgo Tests
-- ============================================================

local TimeAgo = WoWUnit("ASP FormatTimeAgo")

function TimeAgo:Seconds()
    Replace("GetServerTime", function() return 1000 end)
    AreEqual("30s ago", ns:FormatTimeAgo(970))
end

function TimeAgo:Minutes()
    Replace("GetServerTime", function() return 1000 end)
    AreEqual("5m ago", ns:FormatTimeAgo(700))
end

function TimeAgo:Hours()
    Replace("GetServerTime", function() return 10000 end)
    AreEqual("2h ago", ns:FormatTimeAgo(2800))
end

function TimeAgo:Days()
    Replace("GetServerTime", function() return 200000 end)
    AreEqual("1d ago", ns:FormatTimeAgo(100000))
end

function TimeAgo:ZeroSeconds()
    Replace("GetServerTime", function() return 1000 end)
    AreEqual("0s ago", ns:FormatTimeAgo(1000))
end

-- ============================================================
-- 22. Global Defaults Integrity Tests
-- ============================================================

local Defaults = WoWUnit("ASP Defaults")

function Defaults:GlobalDefaultsComplete()
    IsTrue(ns.globalDefaults.enabled ~= nil)
    IsTrue(ns.globalDefaults.sellGrays ~= nil)
    IsTrue(ns.globalDefaults.protectEquipmentSets ~= nil)
    IsTrue(ns.globalDefaults.autoSellMode ~= nil)
    IsTrue(ns.globalDefaults.highValueThreshold ~= nil)
    IsTrue(ns.globalDefaults.overlayMode ~= nil)
end

function Defaults:GlobalDefaultValues()
    AreEqual(true, ns.globalDefaults.enabled)
    AreEqual(true, ns.globalDefaults.sellGrays)
    AreEqual(false, ns.globalDefaults.sellWhites)
    AreEqual(false, ns.globalDefaults.sellGreens)
    AreEqual(false, ns.globalDefaults.sellBlues)
    AreEqual(false, ns.globalDefaults.sellEpics)
    AreEqual(0, ns.globalDefaults.whiteMaxIlvl)
    AreEqual(true, ns.globalDefaults.epicConfirm)
    AreEqual(true, ns.globalDefaults.onlyEquippable)
    AreEqual("popup", ns.globalDefaults.autoSellMode)
    AreEqual(50000, ns.globalDefaults.highValueThreshold)
    AreEqual("border", ns.globalDefaults.overlayMode)
end

function Defaults:CharDefaultValues()
    AreEqual("", ns.charDefaults.activeProfile)
    AreEqual(false, ns.charDefaults.charFirstRunComplete)
end

function Defaults:TopLevelDefaultsAreEmptyTables()
    for key, val in pairs(ns.topLevelDefaults) do
        AreEqual("table", type(val))
    end
end

function Defaults:AllTemplatesHaveSettings()
    for name, tpl in pairs(ns.profileTemplates) do
        IsTrue(tpl.description ~= nil)
        IsTrue(tpl.settings ~= nil)
        IsTrue(type(tpl.settings) == "table")
    end
end

-- ============================================================
-- 23. Transmog Protection Tests
-- ============================================================

local Transmog = WoWUnit("ASP Transmog")

function Transmog:DisabledFeatureReturnsFalse()
    local saved = ns.features.transmog
    ns.features.transmog = false
    IsFalse(ns:IsUncollectedTransmog(12345))
    ns.features.transmog = saved
end

function Transmog:CollectedReturnsFalse()
    local saved = ns.features.transmog
    ns.features.transmog = true
    Replace(C_TransmogCollection, "PlayerHasTransmog", function() return true end)
    IsFalse(ns:IsUncollectedTransmog(12345))
    ns.features.transmog = saved
end

function Transmog:UncollectedReturnsTrue()
    local saved = ns.features.transmog
    ns.features.transmog = true
    Replace(C_TransmogCollection, "PlayerHasTransmog", function() return false end)
    IsTrue(ns:IsUncollectedTransmog(12345))
    ns.features.transmog = saved
end

-- ============================================================
-- 24. IsEquippable Tests
-- ============================================================

local Equippable = WoWUnit("ASP IsEquippable")

function Equippable:WeaponIsEquippable()
    Replace(C_Item, "GetItemInfoInstant", function()
        return nil, nil, nil, nil, nil, Enum.ItemClass.Weapon
    end)
    IsTrue(ns:IsEquippable(12345))
end

function Equippable:ArmorIsEquippable()
    Replace(C_Item, "GetItemInfoInstant", function()
        return nil, nil, nil, nil, nil, Enum.ItemClass.Armor
    end)
    IsTrue(ns:IsEquippable(12345))
end

function Equippable:ConsumableNotEquippable()
    Replace(C_Item, "GetItemInfoInstant", function()
        return nil, nil, nil, nil, nil, 0 -- Consumable
    end)
    IsFalse(ns:IsEquippable(12345))
end

function Equippable:NilClassIDNotEquippable()
    Replace(C_Item, "GetItemInfoInstant", function()
        return nil, nil, nil, nil, nil, nil
    end)
    IsFalse(ns:IsEquippable(12345))
end

-- ============================================================
-- 25. Multiple Quality Filters Integration Test
-- ============================================================

local MultiFilter = WoWUnit("ASP MultiFilter")

function MultiFilter:MixedQualityBatch()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.sellGrays = true
    AutoSellPlusDB.global.sellWhites = true
    AutoSellPlusDB.global.sellGreens = false
    AutoSellPlusDB.global.onlyEquippable = false

    local items = {
        MakeItem({ quality = 0, bag = 0, slot = 1 }),
        MakeItem({ quality = 1, bag = 0, slot = 2, ilvl = 0 }),
        MakeItem({ quality = 2, bag = 0, slot = 3 }),
        MakeItem({ quality = 0, bag = 0, slot = 4, isMarked = true }),
    }

    ns:ApplyFilters(items, {})

    -- Gray visible+checked
    IsTrue(items[1].visible)
    IsTrue(items[1].checked)
    -- White visible (but not auto-checked since ilvl=0 and whiteMaxIlvl=0)
    IsTrue(items[2].visible)
    -- Green NOT visible (filter off)
    IsFalse(items[3].visible)
    -- Marked item always visible+checked
    IsTrue(items[4].visible)
    IsTrue(items[4].checked)

    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

-- ============================================================
-- 26. ConfirmList API Tests
-- ============================================================

local ConfirmList = WoWUnit("ASP ConfirmList")

function ConfirmList:ShowWithEmptyQueueNoops()
    -- Should not error
    ns:ShowConfirmList({}, nil)
    ns:ShowConfirmList(nil, nil)
end

function ConfirmList:HideWithNoFrameNoops()
    -- Should not error even if never shown
    ns:HideConfirmList()
end

-- ============================================================
-- 27. Protection Priority Integration Tests
-- ============================================================

local Priority = WoWUnit("ASP ProtectionPriority")

function Priority:NeverSellBlocksMarked()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.enabled = true
    SetupShouldSellMocks()
    AutoSellPlusDB.neverSellList[50000] = true
    AutoSellPlusDB.markedItems[50000] = true
    IsFalse(ns:ShouldSellItem(0, 1))
    AutoSellPlusDB.neverSellList[50000] = nil
    AutoSellPlusDB.markedItems[50000] = nil
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function Priority:NeverSellBlocksEquipSetProtection()
    -- Never-sell is checked BEFORE equipment set protection
    -- An item on never-sell should be blocked regardless
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.enabled = true
    AutoSellPlusDB.global.sellGrays = true
    AutoSellPlusDB.global.protectEquipmentSets = false
    SetupShouldSellMocks()
    AutoSellPlusDB.neverSellList[50000] = true
    IsFalse(ns:ShouldSellItem(0, 1))
    AutoSellPlusDB.neverSellList[50000] = nil
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function Priority:AlwaysSellBypassesQualityFilter()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.enabled = true
    AutoSellPlusDB.global.sellEpics = false
    SetupShouldSellMocks({ quality = 4 })
    AutoSellPlusDB.alwaysSellList[50000] = true
    IsTrue(ns:ShouldSellItem(0, 1))
    AutoSellPlusDB.alwaysSellList[50000] = nil
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end

function Priority:AlwaysSellWithZeroPriceSkipped()
    local saved = ns.DeepCopy(AutoSellPlusDB.global)
    AutoSellPlusDB.global.enabled = true
    SetupShouldSellMocks()
    AutoSellPlusDB.alwaysSellList[50000] = true
    Replace(C_Item, "GetItemInfo", function()
        return "Item", nil, 0, 10, nil, nil, nil, nil, nil, nil, 0
    end)
    IsFalse(ns:ShouldSellItem(0, 1))
    AutoSellPlusDB.alwaysSellList[50000] = nil
    for k, v in pairs(saved) do AutoSellPlusDB.global[k] = v end
end
