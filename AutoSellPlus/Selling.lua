local addonName, ns = ...

local sellQueue = {}
local sellTimer = nil
local isSelling = false
local totalSold = 0
local totalCopper = 0
local autoSellTimer = nil
local mutedSounds = false

-- Undo buffer
ns.undoBuffer = {}
ns.lastSoldBatch = {}

-- Exposed globals for WeakAura / addon integration
AutoSellPlus_LastEvent = ""
AutoSellPlus_LastSellCount = 0
AutoSellPlus_Events = {}

local function FireEvent(eventName, data)
    AutoSellPlus_LastEvent = eventName
    AutoSellPlus_Events[eventName] = data or true
end

-- ============================================================
-- Sound Muting
-- ============================================================

local VENDOR_SELL_SOUNDS = {
    895, -- LOOT_WINDOW_COIN_SOUND
}

local function MuteVendorSounds()
    if mutedSounds then return end
    for _, soundID in ipairs(VENDOR_SELL_SOUNDS) do
        MuteSoundFile(soundID)
    end
    mutedSounds = true
end

local function UnmuteVendorSounds()
    if not mutedSounds then return end
    for _, soundID in ipairs(VENDOR_SELL_SOUNDS) do
        UnmuteSoundFile(soundID)
    end
    mutedSounds = false
end

-- ============================================================
-- Sell Queue
-- ============================================================

function ns:BuildSellQueue()
    local queue = {}
    for bag = 0, self:GetMaxBagID() do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local shouldSell, itemLink, sellPrice, stackCount = self:ShouldSellItem(bag, slot)
            if shouldSell then
                local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
                queue[#queue + 1] = {
                    bag = bag,
                    slot = slot,
                    itemLink = itemLink,
                    itemID = itemInfo and itemInfo.itemID,
                    quality = itemInfo and itemInfo.quality,
                    sellPrice = sellPrice,
                    stackCount = stackCount,
                    totalPrice = sellPrice * stackCount,
                }
            end
        end
    end
    return queue
end

-- Pre-sell verification pass
local function VerifyQueue(queue)
    local verified = {}
    local removed = 0
    for _, item in ipairs(queue) do
        local itemInfo = C_Container.GetContainerItemInfo(item.bag, item.slot)
        if itemInfo and itemInfo.hyperlink == item.itemLink then
            if not ns:IsNeverSell(itemInfo.itemID) then
                verified[#verified + 1] = item
            else
                removed = removed + 1
            end
        else
            removed = removed + 1
        end
    end
    return verified, removed
end

-- ============================================================
-- Selling Process
-- ============================================================

function ns:StartSelling(explicitQueue)
    if not self:IsFeatureAvailable("selling") then
        self:Print("|cFFFF0000Selling is disabled:|r Required API (C_Container.UseContainerItem) is unavailable.")
        return
    end
    if isSelling then return end

    sellQueue = explicitQueue or self:BuildSellQueue()

    -- Priority sell queue: sell cheapest first so valuable items stay in buyback (LIFO)
    if self.db.prioritySellQueue then
        table.sort(sellQueue, function(a, b) return a.totalPrice < b.totalPrice end)
    end

    -- Pre-sell verification
    local removed
    sellQueue, removed = VerifyQueue(sellQueue)
    if removed > 0 then
        self:DebugPrint(format("Removed %d invalid items from sell queue", removed))
    end

    if #sellQueue == 0 then return end

    -- Buyback warning
    if self.db.buybackWarning and #sellQueue > 12 then
        self:Print(format("Selling %d items. Some may not appear in buyback (max 12).", #sellQueue))
    end

    -- Dry run mode
    if self.db.dryRun then
        local dryTotal = 0
        self:Print("Dry run - would sell:")
        for _, item in ipairs(sellQueue) do
            self:Print(format("  %s x%d (%s)", item.itemLink, item.stackCount, self:FormatMoney(item.totalPrice)))
            dryTotal = dryTotal + item.totalPrice
        end
        self:Print(format("Total: %s (%d items)", self:FormatMoney(dryTotal), #sellQueue))
        return
    end

    -- Mute vendor sounds if enabled
    if self.db.muteVendorSounds then
        MuteVendorSounds()
    end

    isSelling = true
    totalSold = 0
    totalCopper = 0
    wipe(ns.lastSoldBatch)

    -- Initialize progress
    ns.sellProgress.current = 0
    ns.sellProgress.total = #sellQueue
    ns:SafeCall(function() ns:UpdateSellProgress() end)

    self:ProcessNextBatch()
end

function ns:ProcessNextBatch()
    if not isSelling then return end

    local processed = 0
    while #sellQueue > 0 and processed < 10 do
        local item = table.remove(sellQueue, 1)

        -- Re-verify slot still contains expected item
        local itemInfo = C_Container.GetContainerItemInfo(item.bag, item.slot)
        if itemInfo and itemInfo.hyperlink == item.itemLink then
            C_Container.UseContainerItem(item.bag, item.slot)
            totalSold = totalSold + 1
            totalCopper = totalCopper + item.totalPrice

            -- Record in history
            ns:SafeCall(function()
                ns:RecordSale(item.itemLink, itemInfo.itemID, item.stackCount, item.totalPrice)
            end)

            -- Update session
            ns:SafeCall(function()
                ns:UpdateSession(item.stackCount, item.totalPrice)
            end)

            -- Track for undo (store full link for matching)
            ns.lastSoldBatch[#ns.lastSoldBatch + 1] = {
                itemLink = item.itemLink,
                itemID = itemInfo.itemID,
                stackCount = item.stackCount,
                totalPrice = item.totalPrice,
                time = self:GetServerTime(),
            }

            if self.db.showItemized then
                self:Print(format("Sold %s x%d for %s", item.itemLink, item.stackCount, self:FormatMoney(item.totalPrice)))
            end

            -- Update progress bar
            ns.sellProgress.current = ns.sellProgress.current + 1
            ns:SafeCall(function() ns:UpdateSellProgress() end)
        end

        processed = processed + 1
    end

    if #sellQueue > 0 then
        sellTimer = C_Timer.NewTimer(0.2, function()
            self:ProcessNextBatch()
        end)
    else
        self:FinishSelling()
    end
end

function ns:FinishSelling()
    isSelling = false
    sellTimer = nil

    -- Hide progress bar
    ns:SafeCall(function() ns:HideSellProgress() end)

    -- Unmute
    if mutedSounds then
        UnmuteVendorSounds()
    end

    if self.db.showSummary and totalSold > 0 then
        self:Print(format("Sold %d item%s for %s",
            totalSold,
            totalSold == 1 and "" or "s",
            self:FormatMoney(totalCopper)))
    end

    -- Update character stats and exposed globals
    if totalSold > 0 then
        AutoSellPlus_LastSellCount = totalSold
        FireEvent("SELL_COMPLETE", { count = totalSold, copper = totalCopper })
        ns:SafeCall(function()
            ns:UpdateCharStats(totalSold, totalCopper)
        end)
    end

    -- Populate undo buffer with 5-min expiry
    if #ns.lastSoldBatch > 0 then
        ns.undoBuffer = {
            items = ns.lastSoldBatch,
            totalCopper = totalCopper,
            totalCount = totalSold,
            expiry = self:GetServerTime() + 300,
        }

        -- Show undo toast
        if self.db.showUndoToast and totalSold > 0 then
            self:ShowUndoToast(totalSold, totalCopper)
        end
    end

    totalSold = 0
    totalCopper = 0
    sellQueue = {}
end

function ns:StopSelling()
    if not isSelling then return end

    if sellTimer then
        sellTimer:Cancel()
        sellTimer = nil
    end

    isSelling = false

    -- Hide progress bar
    ns:SafeCall(function() ns:HideSellProgress() end)

    -- Unmute
    if mutedSounds then
        UnmuteVendorSounds()
    end

    if self.db.showSummary and totalSold > 0 then
        self:Print(format("Merchant closed. Sold %d item%s for %s (interrupted)",
            totalSold,
            totalSold == 1 and "" or "s",
            self:FormatMoney(totalCopper)))
    end

    -- Update character stats even on interruption
    if totalSold > 0 then
        ns:SafeCall(function()
            ns:UpdateCharStats(totalSold, totalCopper)
        end)
    end

    totalSold = 0
    totalCopper = 0
    sellQueue = {}
end

-- ============================================================
-- Undo Toast
-- ============================================================

local undoToast = nil

function ns:ShowUndoToast(count, copper)
    if not undoToast then
        undoToast = CreateFrame("Frame", "AutoSellPlusUndoToast", UIParent, "BackdropTemplate")
        undoToast:SetSize(320, 40)
        undoToast:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 120)
        undoToast:SetFrameStrata("DIALOG")
        undoToast:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        undoToast:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
        undoToast:SetBackdropBorderColor(0.0, 0.45, 0.70, 1)

        local text = undoToast:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("LEFT", 12, 0)
        undoToast.text = text

        local undoBtn = CreateFrame("Button", nil, undoToast, "BackdropTemplate")
        undoBtn:SetSize(50, 24)
        undoBtn:SetPoint("RIGHT", -8, 0)
        undoBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        undoBtn:SetBackdropColor(0.50, 0.25, 0.0, 1)
        undoBtn:SetBackdropBorderColor(0.70, 0.35, 0.0, 1)
        local undoLbl = undoBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        undoLbl:SetPoint("CENTER")
        undoLbl:SetText("Undo")
        undoBtn:SetScript("OnClick", function()
            ns:UndoLastSale()
            undoToast:Hide()
        end)
        undoBtn:SetScript("OnEnter", function(btn)
            btn:SetBackdropColor(0.60, 0.30, 0.0, 1)
        end)
        undoBtn:SetScript("OnLeave", function(btn)
            btn:SetBackdropColor(0.50, 0.25, 0.0, 1)
        end)
    end

    undoToast.text:SetText(format("Sold %d item%s for %s", count, count == 1 and "" or "s", self:FormatMoney(copper)))

    if count > 12 then
        undoToast.text:SetText(undoToast.text:GetText() .. " |cFFFF6600(>12, partial buyback)|r")
    end

    undoToast:Show()

    -- Auto-fade after 8 seconds
    if not undoToast._fadeOut then
        undoToast._fadeOut = undoToast:CreateAnimationGroup()
        local alpha = undoToast._fadeOut:CreateAnimation("Alpha")
        alpha:SetFromAlpha(1)
        alpha:SetToAlpha(0)
        alpha:SetDuration(0.5)
        undoToast._fadeOut:SetScript("OnFinished", function()
            undoToast:Hide()
            undoToast:SetAlpha(1)
        end)
    end
    C_Timer.After(8, function()
        if undoToast and undoToast:IsShown() then
            undoToast._fadeOut:Stop()
            undoToast._fadeOut:Play()
        end
    end)
end

function ns:UndoLastSale()
    if not ns.isMerchantOpen then
        self:Print("You must be at a merchant to undo a sale.")
        return
    end

    local buffer = self.undoBuffer
    if not buffer or not buffer.items or #buffer.items == 0 then
        self:Print("Nothing to undo.")
        return
    end

    if buffer.expiry and self:GetServerTime() > buffer.expiry then
        local timestamp = date("!%Y-%m-%d %H:%M", time())
        self:Print(format("Undo expired (5 min limit). Use Blizzard Item Restoration: https://battle.net/support/restoration (%s UTC)", timestamp))
        wipe(self.undoBuffer)
        return
    end

    -- Try buyback matching (reverse iterate to handle index shifting)
    local repurchased = 0
    local repurchaseCost = 0
    local numBuyback = GetNumBuybackItems()

    -- Build a lookup of sold item names with counts
    local soldLookup = {}
    for _, sold in ipairs(buffer.items) do
        for i = 1, numBuyback do
            local name, _, _, qty, price = GetBuybackItemInfo(i)
            local buybackLink = GetBuybackItemLink(i)
            if name and price and buybackLink then
                -- Match using full item link for precision
                if buybackLink == sold.itemLink then
                    BuybackItem(i)
                    repurchased = repurchased + 1
                    repurchaseCost = repurchaseCost + price
                    break
                end
            end
        end
    end

    if repurchased > 0 then
        self:Print(format("Repurchased %d item%s for %s", repurchased, repurchased == 1 and "" or "s", self:FormatMoney(repurchaseCost)))
    else
        local timestamp = date("!%Y-%m-%d %H:%M", time())
        self:Print(format("Could not find items in buyback. Use Blizzard Item Restoration: https://battle.net/support/restoration (%s UTC)", timestamp))
    end

    wipe(self.undoBuffer)
end

-- ============================================================
-- Auto-Sell Safety Confirmations
-- ============================================================

function ns:ConfirmAndSell(queue)
    if #queue == 0 then return end

    local hasEpics = false
    local highValueItems = {}

    for _, item in ipairs(queue) do
        if item.itemLink then
            local _, _, quality = C_Item.GetItemInfo(item.itemLink)
            if quality == Enum.ItemQuality.Epic then
                hasEpics = true
            end
        end
        if item.totalPrice >= (self.db.highValueThreshold or 50000) then
            highValueItems[#highValueItems + 1] = item
        end
    end

    -- Epic confirmation
    if hasEpics and self.db.epicConfirm then
        StaticPopupDialogs["ASP_AUTOSELL_EPIC_CONFIRM"] = {
            text = format("AutoSellPlus: Auto-sell includes EPIC quality items (%d total). Continue?", #queue),
            button1 = "Sell",
            button2 = "Cancel",
            OnAccept = function()
                if #highValueItems > 0 and ns.db.highValueConfirm then
                    ns:_ShowHighValueConfirm(queue, highValueItems)
                else
                    ns:StartSelling(queue)
                end
            end,
            OnCancel = function()
                ns:Print("Auto-sell cancelled.")
            end,
            OnHide = function()
                ns:HideConfirmList()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        local dialog = StaticPopup_Show("ASP_AUTOSELL_EPIC_CONFIRM")
        if dialog then
            ns:ShowConfirmList(queue, dialog)
        end
        return
    end

    -- High value confirmation
    if #highValueItems > 0 and self.db.highValueConfirm then
        self:_ShowHighValueConfirm(queue, highValueItems)
        return
    end

    -- No confirmations needed
    self:StartSelling(queue)
end

function ns:_ShowHighValueConfirm(queue, highValueItems)
    local topItems = {}
    table.sort(highValueItems, function(a, b) return a.totalPrice > b.totalPrice end)
    for i = 1, math.min(3, #highValueItems) do
        topItems[#topItems + 1] = format("%s (%s)", highValueItems[i].itemLink or "?", self:FormatMoney(highValueItems[i].totalPrice))
    end

    StaticPopupDialogs["ASP_AUTOSELL_HIGHVALUE_CONFIRM"] = {
        text = "AutoSellPlus: Auto-sell includes high-value items:\n" .. table.concat(topItems, "\n") .. "\n\nContinue?",
        button1 = "Sell",
        button2 = "Cancel",
        OnAccept = function()
            ns:StartSelling(queue)
        end,
        OnCancel = function()
            ns:Print("Auto-sell cancelled.")
        end,
        OnHide = function()
            ns:HideConfirmList()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    local dialog = StaticPopup_Show("ASP_AUTOSELL_HIGHVALUE_CONFIRM")
    if dialog then
        ns:ShowConfirmList(queue, dialog)
    end
end

-- ============================================================
-- Value-Based Eviction
-- ============================================================

function ns:EvictAtVendor()
    if not self.db.evictionEnabled then return end
    local threshold = self.db.freeSlotThreshold
    if threshold <= 0 then return end

    local freeSlots = self:CountFreeSlots()
    if freeSlots >= threshold then return end

    local slotsNeeded = threshold - freeSlots
    local candidates = {}

    for bag = 0, self:GetMaxBagID() do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.itemID and itemInfo.hyperlink then
                local quality = itemInfo.quality or 99
                local isLocked = itemInfo.isLocked

                if not isLocked and (quality == Enum.ItemQuality.Poor or self:IsMarked(itemInfo.itemID)) then
                    if not self:IsNeverSell(itemInfo.itemID) then
                        if not self:IsRefundable(bag, slot) then
                            if not (self.db.protectEquipmentSets and self:IsInEquipmentSet(itemInfo.itemID)) then
                                local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(itemInfo.hyperlink)
                                if sellPrice and sellPrice > 0 then
                                    local stackCount = itemInfo.stackCount or 1
                                    candidates[#candidates + 1] = {
                                        bag = bag,
                                        slot = slot,
                                        itemLink = itemInfo.hyperlink,
                                        itemID = itemInfo.itemID,
                                        sellPrice = sellPrice,
                                        stackCount = stackCount,
                                        totalPrice = sellPrice * stackCount,
                                    }
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if #candidates == 0 then return end

    -- Sort cheapest first
    table.sort(candidates, function(a, b) return a.totalPrice < b.totalPrice end)

    -- Take only what we need
    local evictList = {}
    local evictTotal = 0
    for i = 1, math.min(slotsNeeded, #candidates) do
        evictList[#evictList + 1] = candidates[i]
        evictTotal = evictTotal + candidates[i].totalPrice
    end

    -- Show confirmation
    local itemNames = {}
    for _, item in ipairs(evictList) do
        itemNames[#itemNames + 1] = format("  %s (%s)", item.itemLink, self:FormatMoney(item.totalPrice))
    end

    StaticPopupDialogs["ASP_EVICT_CONFIRM"] = {
        text = format(
            "AutoSellPlus: Sell %d item%s to free bag space?\n%s\n\nTotal: %s",
            #evictList, #evictList == 1 and "" or "s",
            table.concat(itemNames, "\n"),
            ns:FormatMoney(evictTotal)
        ),
        button1 = "Sell",
        button2 = "Cancel",
        OnAccept = function()
            ns:StartSelling(evictList)
        end,
        OnHide = function()
            ns:HideConfirmList()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    local dialog = StaticPopup_Show("ASP_EVICT_CONFIRM")
    if dialog then
        ns:ShowConfirmList(evictList, dialog)
    end
end

-- ============================================================
-- Auto-Sell Modes
-- ============================================================

function ns:HandleAutoSell()
    -- Suppress auto-sell during Postal mail processing
    if Postal and Postal.OpenAll and Postal.OpenAll.isRunning then
        ns:DebugPrint("Auto-sell suppressed: Postal is processing mail.")
        return
    end

    local mode = ns.db.autoSellMode
    if mode == "autosell" then
        local delay = ns.db.autoSellDelay or 0
        if delay > 0 then
            ns:Print(format("Auto-selling in %ds... (close merchant to cancel)", delay))
            autoSellTimer = C_Timer.NewTimer(delay, function()
                autoSellTimer = nil
                local queue = ns:BuildSellQueue()
                if #queue > 0 then
                    ns:ConfirmAndSell(queue)
                end
            end)
        else
            local queue = ns:BuildSellQueue()
            if #queue > 0 then
                ns:ConfirmAndSell(queue)
            end
        end
    elseif mode == "oneclick" then
        ns:ShowPopup()
    else
        -- "popup" mode (default)
        ns:ShowPopup()
    end
end

function ns:CancelAutoSell()
    if autoSellTimer then
        autoSellTimer:Cancel()
        autoSellTimer = nil
        ns:DebugPrint("Auto-sell cancelled.")
    end
end

-- ============================================================
-- Auto-Destroy (safety-gated)
-- ============================================================

function ns:DestroyJunk()
    if not self:IsFeatureAvailable("destroying") then
        self:Print("|cFFFF0000Destroying is disabled:|r Required API (C_Container.PickupContainerItem) is unavailable.")
        return
    end
    if not self.db.autoDestroyEnabled then
        self:Print("Auto-destroy is disabled. Enable it in settings first.")
        return
    end

    local items = {}
    for bag = 0, self:GetMaxBagID() do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.itemID then
                local quality = itemInfo.quality or 99
                local maxQ = self.db.autoDestroyMaxQuality or 0

                if quality <= maxQ then
                    -- Skip protected items
                    if self:IsNeverSell(itemInfo.itemID) then
                        -- skip
                    elseif self.db.protectEquipmentSets and self:IsInEquipmentSet(itemInfo.itemID) then
                        -- skip
                    elseif self.db.protectUncollectedTransmog and self:HasTransmogAppearance(itemInfo.itemID)
                        and self:IsUncollectedTransmog(itemInfo.itemID) then
                        -- skip
                    elseif self.db.protectBoE and not self.db.allowBoESell
                        and self:IsBindOnEquip(bag, slot) then
                        -- skip
                    elseif self:IsRefundable(bag, slot) then
                        -- skip
                    else
                        local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(itemInfo.hyperlink or "")
                        sellPrice = sellPrice or 0
                        local totalValue = sellPrice * (itemInfo.stackCount or 1)

                        local maxValue = self.db.autoDestroyMaxValue or 0
                        if maxValue == 0 or totalValue <= maxValue then
                            local withinLimit = false
                            if self:ExceedsStackLimit(itemInfo.itemID) == 0 then
                                local limits = self.db.stackLimits
                                if limits and limits[itemInfo.itemID] then
                                    withinLimit = true
                                end
                            end
                            if not withinLimit then
                                items[#items + 1] = {
                                    bag = bag,
                                    slot = slot,
                                    itemLink = itemInfo.hyperlink,
                                    value = totalValue,
                                }
                            end
                        end
                    end
                end
            end
        end
    end

    if #items == 0 then
        self:Print("No items to destroy.")
        return
    end

    local count = math.min(5, #items)

    if self.db.autoDestroyConfirm then
        local itemList = {}
        for i = 1, count do
            itemList[#itemList + 1] = "  " .. (items[i].itemLink or "?")
        end

        StaticPopupDialogs["ASP_DESTROY_CONFIRM"] = {
            text = format("AutoSellPlus: Destroy %d item%s?\n%s", count, count == 1 and "" or "s", table.concat(itemList, "\n")),
            button1 = "Destroy",
            button2 = "Cancel",
            OnAccept = function()
                for i = 1, count do
                    local item = items[i]
                    ClearCursor()
                    C_Container.PickupContainerItem(item.bag, item.slot)
                    local cursorType, cursorItemID = GetCursorInfo()
                    if cursorType == "item" and cursorItemID == item.itemID then
                        DeleteCursorItem()
                        ns:Print(format("Destroyed %s", item.itemLink or "?"))
                    else
                        ClearCursor()
                        ns:Print(format("|cFFFF6600Skipped %s — item moved or cursor mismatch|r", item.itemLink or "?"))
                    end
                end
                ClearCursor()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("ASP_DESTROY_CONFIRM")
    else
        for i = 1, count do
            local item = items[i]
            ClearCursor()
            C_Container.PickupContainerItem(item.bag, item.slot)
            local cursorType, cursorItemID = GetCursorInfo()
            if cursorType == "item" and cursorItemID == item.itemID then
                DeleteCursorItem()
                self:Print(format("Destroyed %s", item.itemLink or "?"))
            else
                ClearCursor()
                self:Print(format("|cFFFF6600Skipped %s — item moved or cursor mismatch|r", item.itemLink or "?"))
            end
        end
        ClearCursor()
    end
end

-- Export FireEvent for Core.lua usage
ns._FireEvent = FireEvent
-- Export isSelling check
function ns:IsSelling()
    return isSelling
end
