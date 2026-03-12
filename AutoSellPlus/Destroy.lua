local addonName, ns = ...

local FLAT_BACKDROP = ns.FLAT_BACKDROP

local destroyQueue = {}
local destroyTimer = nil
local isDestroying = false
local destroyedCount = 0
local destroyPressureCooldown = 0

-- ============================================================
-- ShouldDestroyItem — Protection priority chain for destruction
-- ============================================================

local function ShouldDestroyItem(bag, slot)
    local db = ns.db
    local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
    if not itemInfo then return false end

    local itemID = itemInfo.itemID
    local itemLink = itemInfo.hyperlink
    local quality = itemInfo.quality or 99
    local isLocked = itemInfo.isLocked
    local stackCount = itemInfo.stackCount or 1

    if not itemID or not itemLink then return false end
    if isLocked then return false end

    -- Never-destroy list
    if ns:IsNeverDestroy(itemID) then return false end

    -- Never-sell list also blocks destroy
    if ns:IsNeverSell(itemID) then return false end

    -- Equipment set protection
    if db.destroyProtectEquipmentSets and ns:IsInEquipmentSet(itemID) then return false end

    -- Uncollected transmog protection
    if db.destroyProtectTransmog and ns:HasTransmogAppearance(itemID) then
        if ns:IsUncollectedTransmog(itemID) then return false end
    end

    -- BoE protection
    if db.destroyProtectBoE then
        if ns:IsBindOnEquip(bag, slot) then return false end
    end

    -- Refundable: always skip
    if ns:IsRefundable(bag, slot) then return false end

    -- Quality filter
    if quality > db.destroyMaxQuality then return false end

    -- Vendor value
    local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(itemLink)
    sellPrice = sellPrice or 0
    local totalValue = sellPrice * stackCount

    -- ilvl filter
    if db.destroyMaxIlvl > 0 and ns:IsEquippable(itemID) then
        local ilvl = ns:GetEffectiveItemLevel(itemLink)
        if ilvl > 0 and ilvl > db.destroyMaxIlvl then return false end
    end

    -- Vendor value filter
    if db.destroyMaxVendorValue > 0 and totalValue > db.destroyMaxVendorValue then
        return false
    end

    return true, itemLink, totalValue, stackCount
end

-- ============================================================
-- Build Destroy Queue
-- ============================================================

local function BuildDestroyQueue()
    local items = {}
    for bag = 0, ns:GetMaxBagID() do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local shouldDestroy, itemLink, totalValue, stackCount = ShouldDestroyItem(bag, slot)
            if shouldDestroy then
                local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
                items[#items + 1] = {
                    bag = bag,
                    slot = slot,
                    itemLink = itemLink,
                    itemID = itemInfo and itemInfo.itemID,
                    value = totalValue,
                    stackCount = stackCount,
                }
            end
        end
    end
    -- Sort cheapest first
    table.sort(items, function(a, b) return a.value < b.value end)
    return items
end

-- ============================================================
-- Destroy Queue Processing
-- ============================================================

local function ProcessNextDestroy()
    if not isDestroying then return end

    if #destroyQueue == 0 then
        isDestroying = false
        destroyTimer = nil
        ns:Print(format("Destroyed %d item%s.", destroyedCount, destroyedCount == 1 and "" or "s"))
        destroyedCount = 0
        return
    end

    local item = table.remove(destroyQueue, 1)

    -- Re-verify slot
    local itemInfo = C_Container.GetContainerItemInfo(item.bag, item.slot)
    if itemInfo and itemInfo.hyperlink == item.itemLink then
        ClearCursor()
        C_Container.PickupContainerItem(item.bag, item.slot)
        local cursorType, cursorItemID = GetCursorInfo()
        if cursorType == "item" and cursorItemID == item.itemID then
            DeleteCursorItem()
            destroyedCount = destroyedCount + 1
            ns:DebugPrint(format("Destroyed %s", item.itemLink or "?"))
        else
            ClearCursor()
            ns:Print(format("|cFFFF6600Skipped %s — cursor mismatch|r", item.itemLink or "?"))
        end
    else
        ns:DebugPrint(format("Skipped %s — item moved", item.itemLink or "?"))
    end

    -- Schedule next (0.3s for safety)
    destroyTimer = C_Timer.NewTimer(0.3, ProcessNextDestroy)
end

local function StartDestroying(queue)
    if isDestroying then return end
    destroyQueue = queue
    isDestroying = true
    destroyedCount = 0
    ProcessNextDestroy()
end

local function StopDestroying()
    if not isDestroying then return end
    if destroyTimer then
        destroyTimer:Cancel()
        destroyTimer = nil
    end
    isDestroying = false
    ClearCursor()
    if destroyedCount > 0 then
        ns:Print(format("Destruction stopped. Destroyed %d item%s.", destroyedCount, destroyedCount == 1 and "" or "s"))
    end
    destroyedCount = 0
    destroyQueue = {}
end

-- ============================================================
-- Countdown Confirmation Frame
-- ============================================================

local destroyConfirmFrame = nil

local function HideDestroyConfirm()
    if destroyConfirmFrame then
        destroyConfirmFrame:Hide()
    end
end

local function ShowDestroyConfirmation(queue)
    if not destroyConfirmFrame then
        local f = CreateFrame("Frame", "AutoSellPlusDestroyConfirm", UIParent, "BackdropTemplate")
        f:SetSize(340, 300)
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
        f:SetBackdropBorderColor(0.7, 0.15, 0.15, 1)

        -- Title
        local titleBg = f:CreateTexture(nil, "ARTWORK")
        titleBg:SetPoint("TOPLEFT", 1, -1)
        titleBg:SetPoint("TOPRIGHT", -1, -1)
        titleBg:SetHeight(26)
        titleBg:SetColorTexture(0.4, 0.08, 0.08, 0.8)

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, -6)
        f.titleText = title

        -- Close button
        local closeBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
        closeBtn:SetSize(22, 22)
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

        -- Item list area
        local listArea = CreateFrame("Frame", nil, f)
        listArea:SetPoint("TOPLEFT", 10, -34)
        listArea:SetPoint("TOPRIGHT", -10, -34)
        listArea:SetHeight(200)
        f.listArea = listArea

        -- Total value label
        local totalLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        totalLabel:SetPoint("BOTTOMLEFT", 10, 38)
        f.totalLabel = totalLabel

        -- Destroy button
        local destroyBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
        destroyBtn:SetSize(120, 28)
        destroyBtn:SetPoint("BOTTOMRIGHT", -10, 8)
        destroyBtn:SetBackdrop(FLAT_BACKDROP)
        destroyBtn:SetBackdropColor(0.5, 0.1, 0.1, 1)
        destroyBtn:SetBackdropBorderColor(0.7, 0.15, 0.15, 1)
        local destroyLbl = destroyBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        destroyLbl:SetPoint("CENTER")
        f.destroyBtn = destroyBtn
        f.destroyLbl = destroyLbl

        -- Cancel button
        local cancelBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
        cancelBtn:SetSize(80, 28)
        cancelBtn:SetPoint("BOTTOMLEFT", 10, 8)
        cancelBtn:SetBackdrop(FLAT_BACKDROP)
        cancelBtn:SetBackdropColor(0.18, 0.18, 0.18, 1)
        cancelBtn:SetBackdropBorderColor(0.30, 0.30, 0.30, 1)
        local cancelLbl = cancelBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        cancelLbl:SetPoint("CENTER")
        cancelLbl:SetText("Cancel")
        cancelBtn:SetScript("OnClick", function() f:Hide() end)
        cancelBtn:SetScript("OnEnter", function(btn) btn:SetBackdropColor(0.28, 0.28, 0.28, 1) end)
        cancelBtn:SetScript("OnLeave", function(btn) btn:SetBackdropColor(0.18, 0.18, 0.18, 1) end)

        tinsert(UISpecialFrames, "AutoSellPlusDestroyConfirm")
        f:Hide()
        destroyConfirmFrame = f
    end

    local f = destroyConfirmFrame

    -- Populate
    f.titleText:SetText(format("|cFFFF4444Destroy %d item%s?|r", #queue, #queue == 1 and "" or "s"))

    -- Clear old item rows
    if f.itemRows then
        for _, row in ipairs(f.itemRows) do row:Hide() end
    end
    f.itemRows = f.itemRows or {}

    local totalValue = 0
    local maxDisplay = math.min(#queue, 10)
    for i = 1, maxDisplay do
        local item = queue[i]
        totalValue = totalValue + (item.value or 0)

        if not f.itemRows[i] then
            local row = f.listArea:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row:SetPoint("TOPLEFT", 0, -((i - 1) * 18))
            row:SetWidth(300)
            row:SetJustifyH("LEFT")
            f.itemRows[i] = row
        end
        f.itemRows[i]:SetText(format("  %s x%d  (%s)", item.itemLink or "?", item.stackCount or 1, ns:FormatMoney(item.value or 0)))
        f.itemRows[i]:Show()
    end

    -- Add remaining count for items beyond display
    for i = #queue + 1, maxDisplay do
        totalValue = totalValue + (queue[i] and queue[i].value or 0)
    end
    if #queue > maxDisplay then
        -- Accumulate remaining values
        for i = maxDisplay + 1, #queue do
            totalValue = totalValue + (queue[i].value or 0)
        end
        if not f.itemRows[maxDisplay + 1] then
            local row = f.listArea:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row:SetPoint("TOPLEFT", 0, -(maxDisplay * 18))
            row:SetWidth(300)
            row:SetJustifyH("LEFT")
            f.itemRows[maxDisplay + 1] = row
        end
        f.itemRows[maxDisplay + 1]:SetText(format("  |cFFAAAAAA... and %d more|r", #queue - maxDisplay))
        f.itemRows[maxDisplay + 1]:Show()
    end

    f.totalLabel:SetText(format("Vendor value lost: |cFFFF4444%s|r", ns:FormatMoney(totalValue)))

    -- Countdown logic
    local countdown = ns.db.destroyConfirmCountdown or 3
    local remaining = countdown
    f.destroyBtn:Disable()
    f.destroyLbl:SetText(format("Destroy (%d)", remaining))
    f.destroyBtn:SetBackdropColor(0.3, 0.1, 0.1, 1)

    if f._countdownTicker then
        f._countdownTicker:Cancel()
    end

    f._countdownTicker = C_Timer.NewTicker(1, function()
        remaining = remaining - 1
        if remaining <= 0 then
            f.destroyLbl:SetText("Destroy")
            f.destroyBtn:Enable()
            f.destroyBtn:SetBackdropColor(0.5, 0.1, 0.1, 1)
            if f._countdownTicker then
                f._countdownTicker:Cancel()
                f._countdownTicker = nil
            end
        else
            f.destroyLbl:SetText(format("Destroy (%d)", remaining))
        end
    end, countdown)

    f.destroyBtn:SetScript("OnClick", function()
        f:Hide()
        StartDestroying(queue)
    end)
    f.destroyBtn:SetScript("OnEnter", function(btn)
        if btn:IsEnabled() then
            btn:SetBackdropColor(0.6, 0.15, 0.15, 1)
        end
    end)
    f.destroyBtn:SetScript("OnLeave", function(btn)
        if btn:IsEnabled() then
            btn:SetBackdropColor(0.5, 0.1, 0.1, 1)
        end
    end)

    f:SetScript("OnHide", function()
        if f._countdownTicker then
            f._countdownTicker:Cancel()
            f._countdownTicker = nil
        end
    end)

    f:Show()
end

-- ============================================================
-- Pressure Valve
-- ============================================================

function ns:CheckDestroyPressureValve()
    local db = self.db
    if not db.destroyEnabled then return end
    if db.destroyFreeSlotTrigger <= 0 then return end
    if isDestroying then return end

    local now = self:GetServerTime()
    if now < destroyPressureCooldown then return end

    local freeSlots = self:CountFreeSlots()
    if freeSlots > db.destroyFreeSlotTrigger then return end

    destroyPressureCooldown = now + 60

    local queue = BuildDestroyQueue()
    if #queue == 0 then return end

    ShowDestroyConfirmation(queue)
end

-- ============================================================
-- Public Entry Point
-- ============================================================

function ns:DestroyJunk()
    if not self:IsFeatureAvailable("destroying") then
        self:Print("|cFFFFCC00Destruction paused|r — Blizzard changed a required API. No items will be destroyed until we update.")
        return
    end
    if not self.db.destroyEnabled then
        self:Print("Destruction is disabled. Enable it in settings first.")
        return
    end

    local queue = BuildDestroyQueue()
    if #queue == 0 then
        self:Print("No items to destroy.")
        return
    end

    ShowDestroyConfirmation(queue)
end

function ns:IsDestroying()
    return isDestroying
end

function ns:StopDestroying()
    StopDestroying()
end
