local addonName, ns = ...

-- ============================================================
-- Instance-Aware Junk Detection
-- Tracks items sold per instance to build a per-instance junk DB.
-- ============================================================

local PRUNE_AGE_SECONDS = 90 * 24 * 60 * 60 -- 90 days
local MIN_SELL_COUNT = 2

-- ============================================================
-- Instance Detection
-- ============================================================

function ns:GetCurrentInstanceID()
    local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    if instanceID and instanceID > 0 then
        return instanceID
    end
    return 0
end

function ns:GetCurrentInstanceName()
    local name, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    if instanceID and instanceID > 0 then
        return name or ""
    end
    return ""
end

-- ============================================================
-- Initialization
-- ============================================================

function ns:InitInstanceJunkDB()
    if AutoSellPlusDB.instanceJunkDB == nil then
        AutoSellPlusDB.instanceJunkDB = {}
    end
end

-- ============================================================
-- Recording
-- ============================================================

function ns:RecordInstanceSell(itemID)
    if not itemID then return end

    local instanceID = self:GetCurrentInstanceID()
    if instanceID == 0 then return end

    self:InitInstanceJunkDB()

    local db = AutoSellPlusDB.instanceJunkDB
    if not db[instanceID] then
        db[instanceID] = {
            name = self:GetCurrentInstanceName(),
            items = {},
        }
    end

    local instanceData = db[instanceID]
    if not instanceData.items[itemID] then
        instanceData.items[itemID] = { count = 0, lastSeen = 0 }
    end

    local entry = instanceData.items[itemID]
    instanceData.items[itemID] = {
        count = entry.count + 1,
        lastSeen = time(),
    }
end

-- ============================================================
-- Querying
-- ============================================================

function ns:GetInstanceSuggestions()
    local results = {}

    local instanceID = self:GetCurrentInstanceID()
    if instanceID == 0 then return results end

    self:InitInstanceJunkDB()

    local instanceData = AutoSellPlusDB.instanceJunkDB[instanceID]
    if not instanceData or not instanceData.items then return results end

    for bag = 0, self:GetMaxBagID() do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.itemID then
                local junkEntry = instanceData.items[itemInfo.itemID]
                if junkEntry and junkEntry.count >= MIN_SELL_COUNT then
                    results[#results + 1] = {
                        bag = bag,
                        slot = slot,
                        itemID = itemInfo.itemID,
                        itemLink = itemInfo.hyperlink,
                        count = junkEntry.count,
                    }
                end
            end
        end
    end

    return results
end

-- ============================================================
-- Cleanup
-- ============================================================

function ns:PruneInstanceJunkDB()
    self:InitInstanceJunkDB()

    local db = AutoSellPlusDB.instanceJunkDB
    local now = time()
    local cutoff = now - PRUNE_AGE_SECONDS

    local emptyInstances = {}

    for instanceID, instanceData in pairs(db) do
        if instanceData.items then
            local staleItems = {}
            for itemID, entry in pairs(instanceData.items) do
                if entry.lastSeen < cutoff or entry.count < MIN_SELL_COUNT then
                    staleItems[#staleItems + 1] = itemID
                end
            end
            for _, itemID in ipairs(staleItems) do
                instanceData.items[itemID] = nil
            end
            if not next(instanceData.items) then
                emptyInstances[#emptyInstances + 1] = instanceID
            end
        else
            emptyInstances[#emptyInstances + 1] = instanceID
        end
    end

    for _, instanceID in ipairs(emptyInstances) do
        db[instanceID] = nil
    end
end

-- ============================================================
-- Summary
-- ============================================================

function ns:GetInstanceJunkSummary()
    self:InitInstanceJunkDB()

    local db = AutoSellPlusDB.instanceJunkDB
    local instanceCount = 0
    local itemCount = 0

    for _, instanceData in pairs(db) do
        instanceCount = instanceCount + 1
        if instanceData.items then
            for _ in pairs(instanceData.items) do
                itemCount = itemCount + 1
            end
        end
    end

    return { itemCount = itemCount, instanceCount = instanceCount }
end
