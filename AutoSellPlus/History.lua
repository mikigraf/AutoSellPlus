local addonName, ns = ...

local MAX_HISTORY = 200

-- Session tracking (runtime only, not persisted)
ns.sessionData = {
    startTime = 0,
    startGold = 0,
    totalSold = 0,
    totalCopper = 0,
    itemCount = 0,
}

function ns:InitSession()
    self.sessionData.startTime = GetServerTime()
    self.sessionData.startGold = GetMoney()
    self.sessionData.totalSold = 0
    self.sessionData.totalCopper = 0
    self.sessionData.itemCount = 0
end

function ns:ResetSession()
    self:InitSession()
    self:Print("Session stats reset.")
end

function ns:UpdateSession(itemCount, copperEarned)
    self.sessionData.totalSold = self.sessionData.totalSold + 1
    self.sessionData.totalCopper = self.sessionData.totalCopper + copperEarned
    self.sessionData.itemCount = self.sessionData.itemCount + itemCount
end

function ns:GetSessionReport()
    local s = self.sessionData
    local elapsed = GetServerTime() - s.startTime
    local goldPerHour = 0
    if elapsed > 0 then
        goldPerHour = math.floor((s.totalCopper / elapsed) * 3600 / 10000)
    end
    local currentGold = GetMoney()
    local netGold = currentGold - s.startGold

    return {
        elapsed = elapsed,
        sellCount = s.totalSold,
        itemCount = s.itemCount,
        totalCopper = s.totalCopper,
        goldPerHour = goldPerHour,
        startGold = s.startGold,
        currentGold = currentGold,
        netGold = netGold,
    }
end

function ns:PrintSessionReport()
    local r = self:GetSessionReport()
    local mins = math.floor(r.elapsed / 60)
    local secs = r.elapsed % 60

    self:Print(format("Session Report (%dm %ds):", mins, secs))
    print(format("  Sell transactions: %d (%d items)", r.sellCount, r.itemCount))
    print(format("  Vendor income: %s", self:FormatMoney(r.totalCopper)))
    print(format("  Gold/hour: %dg", r.goldPerHour))
    print(format("  Starting gold: %s", self:FormatMoney(r.startGold)))
    print(format("  Current gold: %s", self:FormatMoney(r.currentGold)))
    print(format("  Net change: %s%s", r.netGold >= 0 and "+" or "", self:FormatMoney(math.abs(r.netGold))))

    local dailyCopper, dailyItems = self:GetDailyStats()
    if dailyItems > 0 then
        print(format("  Today: %s (%d items)", self:FormatMoney(dailyCopper), dailyItems))
    end
end

-- Sale history (persisted in AutoSellPlusDB.saleHistory)
function ns:RecordSale(itemLink, itemID, stackCount, totalPrice)
    local history = self.db.saleHistory
    if not history then return end

    history[#history + 1] = {
        link = itemLink,
        id = itemID,
        count = stackCount,
        price = totalPrice,
        time = GetServerTime(),
    }

    -- FIFO cap
    while #history > MAX_HISTORY do
        table.remove(history, 1)
    end
end

function ns:GetSaleHistory()
    return self.db.saleHistory or {}
end

function ns:GetRecentSales(minutes)
    local cutoff = GetServerTime() - (minutes * 60)
    local recent = {}
    for _, entry in ipairs(self.db.saleHistory or {}) do
        if entry.time >= cutoff then
            recent[#recent + 1] = entry
        end
    end
    return recent
end

function ns:PrintSaleLog(count)
    count = count or 10
    local history = self.db.saleHistory or {}
    local start = math.max(1, #history - count + 1)

    if #history == 0 then
        self:Print("Sale history is empty.")
        return
    end

    self:Print(format("Last %d sales:", math.min(count, #history)))
    for i = start, #history do
        local entry = history[i]
        local timeAgo = GetServerTime() - entry.time
        local agoStr
        if timeAgo < 60 then
            agoStr = timeAgo .. "s ago"
        elseif timeAgo < 3600 then
            agoStr = math.floor(timeAgo / 60) .. "m ago"
        else
            agoStr = math.floor(timeAgo / 3600) .. "h ago"
        end
        print(format("  %s x%d for %s (%s)", entry.link or "?", entry.count, self:FormatMoney(entry.price), agoStr))
    end
end

function ns:GetDailyStats()
    local now = GetServerTime()
    local todayStart = now - (now % 86400)
    local totalCopper = 0
    local itemCount = 0

    for _, entry in ipairs(self.db.saleHistory or {}) do
        if entry.time >= todayStart then
            totalCopper = totalCopper + (entry.price or 0)
            itemCount = itemCount + (entry.count or 0)
        end
    end

    return totalCopper, itemCount
end

function ns:ClearSaleHistory()
    wipe(self.db.saleHistory)
    self:Print("Sale history cleared.")
end

-- Expose session data for WeakAura integration
AutoSellPlus_SessionData = ns.sessionData
