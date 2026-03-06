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

-- ============================================================
-- Sale History UI Panel
-- ============================================================

local FLAT_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

local historyPanel = nil
local historyRows = {}
local ROW_HEIGHT = 24
local VISIBLE_ROWS = 16

local function FormatTimeAgo(timestamp)
    local elapsed = GetServerTime() - timestamp
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

local function CreateHistoryRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(410, ROW_HEIGHT)

    -- Alternating background
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    if index % 2 == 0 then
        bg:SetColorTexture(0.12, 0.12, 0.12, 0.5)
    else
        bg:SetColorTexture(0.08, 0.08, 0.08, 0.3)
    end

    -- Icon
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("LEFT", 4, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon

    -- Item name
    local itemText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    itemText:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    itemText:SetWidth(170)
    itemText:SetJustifyH("LEFT")
    row.itemText = itemText

    -- Quantity
    local qtyText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    qtyText:SetPoint("LEFT", row, "LEFT", 210, 0)
    qtyText:SetWidth(40)
    qtyText:SetJustifyH("CENTER")
    row.qtyText = qtyText

    -- Price
    local priceText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    priceText:SetPoint("LEFT", row, "LEFT", 260, 0)
    priceText:SetWidth(80)
    priceText:SetJustifyH("RIGHT")
    priceText:SetTextColor(1, 0.82, 0)
    row.priceText = priceText

    -- Time
    local timeText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    timeText:SetPoint("LEFT", row, "LEFT", 350, 0)
    timeText:SetWidth(60)
    timeText:SetJustifyH("RIGHT")
    timeText:SetTextColor(0.6, 0.6, 0.6)
    row.timeText = timeText

    row:Hide()
    return row
end

local function RefreshHistoryPanel()
    if not historyPanel then return end

    local history = ns.db.saleHistory or {}
    local totalCopper = 0
    local totalCount = #history

    -- Hide all rows first
    for _, row in ipairs(historyRows) do
        row:Hide()
    end

    -- Populate rows in reverse chronological order
    local rowIndex = 0
    for i = #history, 1, -1 do
        rowIndex = rowIndex + 1
        local entry = history[i]
        totalCopper = totalCopper + (entry.price or 0)

        -- Create row if needed
        if not historyRows[rowIndex] then
            historyRows[rowIndex] = CreateHistoryRow(historyPanel.content, rowIndex)
        end

        local row = historyRows[rowIndex]
        row:SetPoint("TOPLEFT", 0, -((rowIndex - 1) * ROW_HEIGHT))

        -- Icon from itemID
        if entry.id then
            local iconTexture = C_Item.GetItemIconByID(entry.id)
            if iconTexture then
                row.icon:SetTexture(iconTexture)
                row.icon:Show()
            else
                row.icon:Hide()
            end
        else
            row.icon:Hide()
        end

        -- Item link or name
        row.itemText:SetText(entry.link or "?")

        -- Quantity
        row.qtyText:SetText("x" .. (entry.count or 1))

        -- Price
        row.priceText:SetText(ns:FormatMoney(entry.price or 0))

        -- Time ago
        row.timeText:SetText(FormatTimeAgo(entry.time or 0))

        row:Show()
    end

    -- Update content height for scrolling
    historyPanel.content:SetHeight(math.max(1, rowIndex * ROW_HEIGHT))

    -- Update summary
    historyPanel.summaryText:SetText(format("%d sale%s | Total: %s",
        totalCount, totalCount == 1 and "" or "s", ns:FormatMoney(totalCopper)))
end

local function CreateHistoryPanel()
    local f = CreateFrame("Frame", "AutoSellPlusHistoryPanel", UIParent, "BackdropTemplate")
    f:SetSize(450, 500)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)

    f:SetBackdrop(FLAT_BACKDROP)
    f:SetBackdropColor(0.06, 0.06, 0.06, 0.98)
    f:SetBackdropBorderColor(0, 0, 0, 1)

    -- Outer border
    local outerBorder = CreateFrame("Frame", nil, f, "BackdropTemplate")
    outerBorder:SetPoint("TOPLEFT", -1, 1)
    outerBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    outerBorder:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1))
    outerBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    outerBorder:SetBackdropBorderColor(0.20, 0.20, 0.20, 0.6)
    outerBorder:EnableMouse(false)

    -- Title bar
    local titleBg = f:CreateTexture(nil, "ARTWORK")
    titleBg:SetPoint("TOPLEFT", 1, -1)
    titleBg:SetPoint("TOPRIGHT", -1, -1)
    titleBg:SetHeight(26)
    titleBg:SetColorTexture(0.10, 0.10, 0.10, 0.8)

    local titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOP", 0, -6)
    titleText:SetText("|cFF00CCFFSale History|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    closeBtn:SetSize(18, 18)
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn:SetBackdrop(FLAT_BACKDROP)
    closeBtn:SetBackdropColor(0.12, 0.12, 0.12, 1)
    closeBtn:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    local closeLbl = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    closeLbl:SetPoint("CENTER")
    closeLbl:SetText("x")
    closeLbl:SetTextColor(0.60, 0.60, 0.60)
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    closeBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropBorderColor(0.7, 0.15, 0.15, 1)
        closeLbl:SetTextColor(1, 0.3, 0.3)
    end)
    closeBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        closeLbl:SetTextColor(0.60, 0.60, 0.60)
    end)

    -- Column headers
    local headerBg = f:CreateTexture(nil, "ARTWORK")
    headerBg:SetPoint("TOPLEFT", 1, -28)
    headerBg:SetPoint("TOPRIGHT", -1, -28)
    headerBg:SetHeight(20)
    headerBg:SetColorTexture(0.14, 0.14, 0.14, 0.8)

    local headers = {
        { text = "Item", x = 30, width = 170 },
        { text = "Qty", x = 210, width = 40 },
        { text = "Price", x = 260, width = 80 },
        { text = "When", x = 350, width = 60 },
    }
    for _, h in ipairs(headers) do
        local ht = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        ht:SetPoint("TOPLEFT", h.x, -30)
        ht:SetWidth(h.width)
        ht:SetJustifyH(h.text == "Item" and "LEFT" or (h.text == "Qty" and "CENTER" or "RIGHT"))
        ht:SetText("|cFFAAAAAA" .. h.text .. "|r")
    end

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "AutoSellPlusHistoryScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 45)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(410, 1)
    scrollFrame:SetScrollChild(content)
    f.content = content

    -- Summary bar
    local summaryText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    summaryText:SetPoint("BOTTOMLEFT", 12, 14)
    summaryText:SetTextColor(0.7, 0.7, 0.7)
    f.summaryText = summaryText

    -- Clear button
    local clearBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    clearBtn:SetSize(60, 22)
    clearBtn:SetPoint("BOTTOMRIGHT", -10, 10)
    clearBtn:SetBackdrop(FLAT_BACKDROP)
    clearBtn:SetBackdropColor(0.40, 0.12, 0.12, 1)
    clearBtn:SetBackdropBorderColor(0.60, 0.20, 0.20, 1)
    local clearLbl = clearBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    clearLbl:SetPoint("CENTER")
    clearLbl:SetText("Clear")
    clearBtn:SetScript("OnClick", function()
        ns:ClearSaleHistory()
        RefreshHistoryPanel()
    end)
    clearBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.55, 0.15, 0.15, 1)
    end)
    clearBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.40, 0.12, 0.12, 1)
    end)

    tinsert(UISpecialFrames, "AutoSellPlusHistoryPanel")
    f:Hide()
    return f
end

function ns:ShowHistoryPanel()
    if not historyPanel then
        historyPanel = CreateHistoryPanel()
    end
    RefreshHistoryPanel()
    historyPanel:Show()
end

function ns:HideHistoryPanel()
    if historyPanel then
        historyPanel:Hide()
    end
end

function ns:ToggleHistoryPanel()
    if historyPanel and historyPanel:IsShown() then
        self:HideHistoryPanel()
    else
        self:ShowHistoryPanel()
    end
end

-- Expose session data for WeakAura integration
AutoSellPlus_SessionData = ns.sessionData
