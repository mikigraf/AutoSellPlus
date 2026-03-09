local addonName, ns = ...

-- Shared flat 1px border backdrop (ElvUI style)
ns.FLAT_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

function ns:GetEffectiveItemLevel(itemLink)
    if not itemLink then return 0 end
    local effectiveIlvl = GetDetailedItemLevelInfo(itemLink)
    return effectiveIlvl or 0
end

-- Get item expansion from expacID (15th return of GetItemInfo)
function ns:GetItemExpansion(itemLink)
    if not itemLink then return 0 end
    local info = {C_Item.GetItemInfo(itemLink)}
    return info[15] or 0
end

-- Get item category classID
function ns:GetItemClassID(itemID)
    local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(itemID)
    return classID or -1
end

function ns:FormatMoney(copper)
    if not copper or copper == 0 then return "0c" end

    local negative = copper < 0
    if negative then copper = -copper end

    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop = copper % 100

    local parts = {}
    if gold > 0 then parts[#parts + 1] = gold .. "g" end
    if silver > 0 then parts[#parts + 1] = silver .. "s" end
    if cop > 0 then parts[#parts + 1] = cop .. "c" end

    local result = table.concat(parts, " ")
    if negative then result = "-" .. result end
    return result
end

function ns:Print(msg)
    print("|cFF00CCFFAutoSellPlus|r: " .. tostring(msg))
end

-- Error suppression framework
function ns:SafeCall(func, ...)
    local ok, result = pcall(func, ...)
    if not ok then
        ns:DebugPrint("Error: " .. tostring(result))
    end
    return ok, result
end

ns.debugMode = false

function ns:DebugPrint(msg)
    if self.debugMode then
        print("|cFFFFFF00[ASP Debug]|r " .. tostring(msg))
    end
end

-- Mapping from itemEquipLoc to inventory slot ID(s)
local EQUIP_LOC_TO_SLOTS = {
    INVTYPE_HEAD = {1},
    INVTYPE_NECK = {2},
    INVTYPE_SHOULDER = {3},
    INVTYPE_CHEST = {5},
    INVTYPE_ROBE = {5},
    INVTYPE_WAIST = {6},
    INVTYPE_LEGS = {7},
    INVTYPE_FEET = {8},
    INVTYPE_WRIST = {9},
    INVTYPE_HAND = {10},
    INVTYPE_FINGER = {11, 12},
    INVTYPE_TRINKET = {13, 14},
    INVTYPE_CLOAK = {15},
    INVTYPE_WEAPON = {16},
    INVTYPE_WEAPONMAINHAND = {16},
    INVTYPE_2HWEAPON = {16},
    INVTYPE_RANGED = {16},
    INVTYPE_RANGEDRIGHT = {16},
    INVTYPE_WEAPONOFFHAND = {17},
    INVTYPE_SHIELD = {17},
    INVTYPE_HOLDABLE = {17},
}

ns.EQUIP_LOC_TO_SLOTS = EQUIP_LOC_TO_SLOTS

local GEAR_SLOTS = {1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17}

-- Slot names for equipment slot filter UI
ns.SLOT_NAMES = {
    [1] = "Head", [2] = "Neck", [3] = "Shoulder", [5] = "Chest",
    [6] = "Waist", [7] = "Legs", [8] = "Feet", [9] = "Wrist",
    [10] = "Hands", [11] = "Ring 1", [12] = "Ring 2",
    [13] = "Trinket 1", [14] = "Trinket 2", [15] = "Back",
    [16] = "Main Hand", [17] = "Off Hand",
}

-- Current expansion ID (Midnight)
ns.CURRENT_EXPANSION = 12

-- Expansion names
ns.EXPANSION_NAMES = {
    [0] = "All",
    [1] = "Classic",
    [2] = "TBC",
    [3] = "WotLK",
    [4] = "Cata",
    [5] = "MoP",
    [6] = "WoD",
    [7] = "Legion",
    [8] = "BfA",
    [9] = "SL",
    [10] = "DF",
    [11] = "TWW",
    [12] = "Midnight",
}

function ns:GetEquippedIlvls()
    local ilvls = {}
    local total = 0
    local count = 0
    for _, slotID in ipairs(GEAR_SLOTS) do
        local link = GetInventoryItemLink("player", slotID)
        if link then
            local ilvl = GetDetailedItemLevelInfo(link)
            ilvls[slotID] = ilvl or 0
            if ilvl and ilvl > 0 then
                total = total + ilvl
                count = count + 1
            end
        else
            ilvls[slotID] = 0
        end
    end
    local avgIlvl = count > 0 and math.floor(total / count) or 0
    local minIlvl = 0
    for _, slotID in ipairs(GEAR_SLOTS) do
        local v = ilvls[slotID]
        if v and v > 0 then
            if minIlvl == 0 or v < minIlvl then
                minIlvl = v
            end
        end
    end
    return ilvls, avgIlvl, minIlvl
end

function ns:GetEquippedIlvlForItem(itemID)
    local _, _, _, itemEquipLoc = C_Item.GetItemInfoInstant(itemID)
    if not itemEquipLoc then return 0 end

    local slots = EQUIP_LOC_TO_SLOTS[itemEquipLoc]
    if not slots then return 0 end

    if not self._equippedIlvls then
        self._equippedIlvls = self:GetEquippedIlvls()
    end

    if #slots == 1 then
        return self._equippedIlvls[slots[1]] or 0
    else
        -- For dual-slot items (rings/trinkets), return the lower ilvl
        local ilvl1 = self._equippedIlvls[slots[1]] or 0
        local ilvl2 = self._equippedIlvls[slots[2]] or 0
        return math.min(ilvl1, ilvl2)
    end
end

-- Vendor mount detection
local VENDOR_MOUNT_IDS = {
    [284] = true,  -- Traveler's Tundra Mammoth (Alliance)
    [312] = true,  -- Traveler's Tundra Mammoth (Horde)
    [460] = true,  -- Grand Expedition Yak
    [1039] = true, -- Mighty Caravan Brutosaur
}

function ns:IsVendorMount()
    if not IsMounted() then return false end
    local mountIDs = C_MountJournal.GetMountIDs()
    if not mountIDs then return false end
    for _, mountID in ipairs(mountIDs) do
        local _, _, _, isActive = C_MountJournal.GetMountInfoByID(mountID)
        if isActive and VENDOR_MOUNT_IDS[mountID] then
            return true
        end
    end
    return false
end

-- List serialization for import/export
function ns:SerializeList(listType)
    local parts = {}
    if listType == "never" or listType == "all" then
        local ids = {}
        for itemID in pairs(self.db.neverSellList) do
            ids[#ids + 1] = tostring(itemID)
        end
        if #ids > 0 then
            parts[#parts + 1] = "NEVER:" .. table.concat(ids, ",")
        end
    end
    if listType == "always" or listType == "all" then
        local ids = {}
        for itemID in pairs(self.db.alwaysSellList) do
            ids[#ids + 1] = tostring(itemID)
        end
        if #ids > 0 then
            parts[#parts + 1] = "ALWAYS:" .. table.concat(ids, ",")
        end
    end
    return table.concat(parts, ";")
end

function ns:DeserializeList(str)
    if not str or str == "" then return false end
    local imported = 0

    for segment in str:gmatch("[^;]+") do
        local listType, idsStr = segment:match("^(%u+):(.+)$")
        if listType and idsStr then
            local targetList
            if listType == "NEVER" then
                targetList = self.db.neverSellList
            elseif listType == "ALWAYS" then
                targetList = self.db.alwaysSellList
            end

            if targetList then
                for idStr in idsStr:gmatch("[^,]+") do
                    local itemID = tonumber(strtrim(idStr))
                    if itemID then
                        targetList[itemID] = true
                        imported = imported + 1
                    end
                end
            end
        end
    end

    return imported > 0, imported
end

function ns:GetMaxBagID()
    -- On Retail/Midnight, bag 5 is the reagent bag.
    -- Future-proofing: use NUM_TOTAL_EQUIPPED_BAG_SLOTS if available (Modern WoW).
    return (NUM_TOTAL_EQUIPPED_BAG_SLOTS or 5)
end

function ns:GetServerTime()
    return C_DateAndTime and C_DateAndTime.GetServerTime() or GetServerTime()
end

-- Count free bag slots
function ns:CountFreeSlots()
    local free = 0
    for bag = 0, self:GetMaxBagID() do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if not itemInfo then
                free = free + 1
            end
        end
    end
    return free
end

-- Count total quantity of an item across all bags
function ns:GetItemCount(itemID)
    local count = 0
    for bag = 0, self:GetMaxBagID() do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.itemID == itemID then
                count = count + (itemInfo.stackCount or 1)
            end
        end
    end
    return count
end

function ns:GetTotalBagVendorValue()
    local total = 0
    for bag = 0, self:GetMaxBagID() do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.hyperlink then
                local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(itemInfo.hyperlink)
                if sellPrice and sellPrice > 0 then
                    total = total + (sellPrice * (itemInfo.stackCount or 1))
                end
            end
        end
    end
    return total
end

-- Iterate all bag items. Callback receives (bag, slot, itemInfo). Return true to stop.
function ns:IterateBagItems(callback)
    for bag = 0, self:GetMaxBagID() do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo then
                if callback(bag, slot, itemInfo) then
                    return
                end
            end
        end
    end
end

-- Format a timestamp as "Xs ago", "Xm ago", "Xh ago", "Xd ago"
function ns:FormatTimeAgo(timestamp)
    local elapsed = self:GetServerTime() - timestamp
    if elapsed < 60 then
        return elapsed .. "s ago"
    elseif elapsed < 3600 then
        return math.floor(elapsed / 60) .. "m ago"
    elseif elapsed < 86400 then
        return math.floor(elapsed / 3600) .. "h ago"
    else
        return math.floor(elapsed / 86400) .. "d ago"
    end
end

-- Format copper as short gold string ("5g", "20s", "42c")
function ns:FormatGoldShort(copper)
    if copper >= 10000 then
        return math.floor(copper / 10000) .. "g"
    elseif copper >= 100 then
        return math.floor(copper / 100) .. "s"
    else
        return copper .. "c"
    end
end
