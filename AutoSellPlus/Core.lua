local addonName, ns = ...

local sellQueue = {}
local sellTimer = nil
local isSelling = false
local totalSold = 0
local totalCopper = 0
local autoSellTimer = nil
local mutedSounds = false
local freeSlotAlertCooldown = 0

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

-- Vendor sell sound file IDs
local VENDOR_SELL_SOUNDS = {
    895, -- LOOT_WINDOW_COIN_SOUND
}

-- ============================================================
-- Muting
-- ============================================================

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
-- Item Evaluation
-- ============================================================

function ns:ShouldSellItem(bag, slot)
    local db = self.db
    if not db.enabled then return false end

    local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
    if not itemInfo then return false end

    local itemID = itemInfo.itemID
    local itemLink = itemInfo.hyperlink
    local quality = itemInfo.quality
    local isLocked = itemInfo.isLocked
    local hasNoValue = itemInfo.hasNoValue
    local stackCount = itemInfo.stackCount or 1

    if not itemID or not itemLink then return false end

    -- Priority 1: Never-sell list (global + per-char)
    if self:IsNeverSell(itemID) then return false end

    -- Priority 2: Always-sell list (must have sell price)
    if self:IsAlwaysSell(itemID) then
        local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(itemLink)
        if sellPrice and sellPrice > 0 then
            return true, itemLink, sellPrice, stackCount
        end
        return false
    end

    -- Priority 2b: Marked items
    if self:IsMarked(itemID) then
        local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(itemLink)
        if sellPrice and sellPrice > 0 then
            return true, itemLink, sellPrice, stackCount
        end
        return false
    end

    -- Get sell price
    local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(itemLink)
    if not sellPrice or sellPrice == 0 or hasNoValue then return false end

    -- Locked items cannot be sold
    if isLocked then return false end

    -- Equipment set protection
    if db.protectEquipmentSets and self:IsInEquipmentSet(itemID) then return false end

    -- Uncollected transmog protection (equippable only)
    if db.protectUncollectedTransmog and self:IsEquippable(itemID) then
        if self:IsUncollectedTransmog(itemID) then return false end
    end

    -- Source-level transmog protection
    if db.protectTransmogSource and self:IsEquippable(itemID) then
        if self:IsUncollectedTransmogSource(itemID) then return false end
    end

    -- Refundable protection
    if self:IsRefundable(bag, slot) then return false end

    -- BoE protection
    if db.protectBoE and not db.allowBoESell then
        if self:IsBindOnEquip(bag, slot) then return false end
    end

    -- Quality-based selling
    if quality == Enum.ItemQuality.Poor and db.sellGrays then
        return true, itemLink, sellPrice, stackCount
    end

    local isEquippable = self:IsEquippable(itemID)

    if quality == Enum.ItemQuality.Common and db.sellWhites then
        if db.onlyEquippable and not isEquippable then return false end
        local ilvl = self:GetEffectiveItemLevel(itemLink)
        if ilvl == 0 then return false end
        if db.whiteMaxIlvl > 0 and ilvl <= db.whiteMaxIlvl then
            return true, itemLink, sellPrice, stackCount
        end
        return false
    end

    if quality == Enum.ItemQuality.Uncommon and db.sellGreens then
        if db.onlyEquippable and not isEquippable then return false end
        local ilvl = self:GetEffectiveItemLevel(itemLink)
        if ilvl == 0 then return false end
        if db.greenMaxIlvl > 0 and ilvl <= db.greenMaxIlvl then
            return true, itemLink, sellPrice, stackCount
        end
        return false
    end

    if quality == Enum.ItemQuality.Rare and db.sellBlues then
        if db.onlyEquippable and not isEquippable then return false end
        local ilvl = self:GetEffectiveItemLevel(itemLink)
        if ilvl == 0 then return false end
        if db.blueMaxIlvl > 0 and ilvl <= db.blueMaxIlvl then
            return true, itemLink, sellPrice, stackCount
        end
        return false
    end

    if quality == Enum.ItemQuality.Epic and db.sellEpics then
        if db.onlyEquippable and not isEquippable then return false end
        local ilvl = self:GetEffectiveItemLevel(itemLink)
        if ilvl == 0 then return false end
        if db.epicMaxIlvl > 0 and ilvl <= db.epicMaxIlvl then
            return true, itemLink, sellPrice, stackCount
        end
        return false
    end

    -- Category selling
    local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(itemID)
    if classID == 0 and db.sellConsumables then
        return true, itemLink, sellPrice, stackCount
    end
    if classID == 7 and db.sellTradeGoods then
        return true, itemLink, sellPrice, stackCount
    end
    if classID == 12 and db.sellQuestItems then
        return true, itemLink, sellPrice, stackCount
    end
    if classID == 15 and db.sellMiscItems then
        return true, itemLink, sellPrice, stackCount
    end

    return false
end

function ns:BuildSellQueue()
    local queue = {}
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local shouldSell, itemLink, sellPrice, stackCount = self:ShouldSellItem(bag, slot)
            if shouldSell then
                queue[#queue + 1] = {
                    bag = bag,
                    slot = slot,
                    itemLink = itemLink,
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
            -- Re-check never-sell
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

function ns:StartSelling(explicitQueue)
    if isSelling then return end

    sellQueue = explicitQueue or self:BuildSellQueue()

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

            -- Track for undo
            ns.lastSoldBatch[#ns.lastSoldBatch + 1] = {
                itemLink = item.itemLink,
                itemID = itemInfo.itemID,
                stackCount = item.stackCount,
                totalPrice = item.totalPrice,
                time = GetServerTime(),
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
            expiry = GetServerTime() + 300,
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
    C_Timer.After(8, function()
        if undoToast and undoToast:IsShown() then
            local fadeOut = undoToast:CreateAnimationGroup()
            local alpha = fadeOut:CreateAnimation("Alpha")
            alpha:SetFromAlpha(1)
            alpha:SetToAlpha(0)
            alpha:SetDuration(0.5)
            fadeOut:SetScript("OnFinished", function()
                undoToast:Hide()
                undoToast:SetAlpha(1)
            end)
            fadeOut:Play()
        end
    end)
end

function ns:UndoLastSale()
    local buffer = self.undoBuffer
    if not buffer or not buffer.items or #buffer.items == 0 then
        self:Print("Nothing to undo.")
        return
    end

    if buffer.expiry and GetServerTime() > buffer.expiry then
        local timestamp = date("!%Y-%m-%d %H:%M", time())
        self:Print(format("Undo expired (5 min limit). Use Blizzard Item Restoration: https://battle.net/support/restoration (%s UTC)", timestamp))
        wipe(self.undoBuffer)
        return
    end

    -- Try buyback matching
    local numBuyback = GetNumBuybackItems()
    local repurchased = 0
    local repurchaseCost = 0

    for _, sold in ipairs(buffer.items) do
        for i = 1, numBuyback do
            local name, _, _, qty, price = GetBuybackItemInfo(i)
            if name and price then
                -- Match by checking if buyback item matches our sold item
                local soldName = sold.itemLink and sold.itemLink:match("%[(.-)%]")
                if soldName and name == soldName then
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
-- Auto-Repair
-- ============================================================

local function DoAutoRepair()
    if not ns.db.autoRepair then return end
    if not CanMerchantRepair() then return end

    local repairCost, canRepair = GetRepairAllCost()
    if not canRepair or repairCost == 0 then return end

    -- Try guild funds first
    if ns.db.autoRepairGuild and IsInGuild() then
        local guildOk = pcall(function()
            if CanGuildBankRepair() then
                RepairAllItems(true)
            end
        end)
        if guildOk then
            ns:Print(format("Auto-repaired for %s (guild funds)", ns:FormatMoney(repairCost)))
            return
        end
    end

    -- Personal funds
    if GetMoney() >= repairCost then
        RepairAllItems(false)
        ns:Print(format("Auto-repaired for %s", ns:FormatMoney(repairCost)))
    else
        ns:Print("Not enough gold to auto-repair.")
    end
end

-- ============================================================
-- Auto-Sell Modes
-- ============================================================

local function HandleAutoSell()
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
                    ns:StartSelling(queue)
                end
            end)
        else
            local queue = ns:BuildSellQueue()
            if #queue > 0 then
                ns:StartSelling(queue)
            end
        end
    elseif mode == "oneclick" then
        ns:ShowPopup()
    else
        -- "popup" mode (default)
        ns:ShowPopup()
    end
end

local function CancelAutoSell()
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
    if not self.db.autoDestroyEnabled then
        self:Print("Auto-destroy is disabled. Enable it in settings first.")
        return
    end

    local items = {}
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.itemID then
                local quality = itemInfo.quality or 99
                local maxQ = self.db.autoDestroyMaxQuality or 0

                -- Only destroy items at or below max quality
                if quality <= maxQ then
                    local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(itemInfo.hyperlink or "")
                    sellPrice = sellPrice or 0
                    local totalValue = sellPrice * (itemInfo.stackCount or 1)

                    -- Only destroy items at or below max value
                    if totalValue <= (self.db.autoDestroyMaxValue or 0) then
                        if not self:IsNeverSell(itemInfo.itemID) then
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

    if #items == 0 then
        self:Print("No items to destroy.")
        return
    end

    -- Max 5 items per batch
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
                    C_Container.PickupContainerItem(item.bag, item.slot)
                    DeleteCursorItem()
                    ns:Print(format("Destroyed %s", item.itemLink or "?"))
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
            C_Container.PickupContainerItem(item.bag, item.slot)
            DeleteCursorItem()
            self:Print(format("Destroyed %s", item.itemLink or "?"))
        end
        ClearCursor()
    end
end

-- ============================================================
-- Bag Space Monitoring
-- ============================================================

local function CheckBagSpace()
    local threshold = ns.db.freeSlotThreshold
    if threshold <= 0 then return end

    local now = GetServerTime()
    if now < freeSlotAlertCooldown then return end

    local freeSlots = ns:CountFreeSlots()
    if freeSlots < threshold then
        freeSlotAlertCooldown = now + 60
        local mode = ns.db.freeSlotAlertMode or "chat"
        local msg = format("Low bag space! %d free slot%s (threshold: %d)", freeSlots, freeSlots == 1 and "" or "s", threshold)
        if mode == "chat" then
            ns:Print(msg)
        elseif mode == "screen" then
            if UIErrorsFrame then
                UIErrorsFrame:AddMessage(msg, 1, 0.5, 0, 1)
            end
        end
    end
end

-- ============================================================
-- Conflict Detection
-- ============================================================

local function DetectConflicts()
    -- Leatrix Plus auto-sell junk conflict
    if LeaPlusDB and LeaPlusDB.AutoSellJunk and LeaPlusDB.AutoSellJunk == "On" then
        ns:Print("|cFFFF6600Warning:|r Leatrix Plus auto-sell junk is enabled. This may conflict with AutoSellPlus.")
    end

    -- Postal detection (informational)
    if Postal then
        ns:DebugPrint("Postal detected. Auto-sell will be suppressed during mail processing.")
    end
end

-- ============================================================
-- Login Self-Test
-- ============================================================

local function RunSelfTest()
    local missing = {}
    if not C_Container or not C_Container.GetContainerNumSlots then
        missing[#missing + 1] = "C_Container.GetContainerNumSlots"
    end
    if not C_Item or not C_Item.GetItemInfo then
        missing[#missing + 1] = "C_Item.GetItemInfo"
    end
    if not C_Container or not C_Container.UseContainerItem then
        missing[#missing + 1] = "C_Container.UseContainerItem"
    end

    if #missing > 0 then
        ns:Print("|cFFFF0000Warning:|r Missing WoW APIs: " .. table.concat(missing, ", "))
        ns:Print("Some features may not work correctly.")
    end
end

-- ============================================================
-- Slash Command Handler
-- ============================================================

local function HandleSlashCommand(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        args[#args + 1] = word:lower()
    end

    local cmd = args[1]

    if not cmd or cmd == "help" then
        ns:Print("v" .. ns.version .. " - Commands:")
        print("  /asp toggle - Enable/disable addon")
        print("  /asp dryrun - Toggle dry run mode")
        print("  /asp config - Open settings panel")
        print("  /asp sell - Sell immediately (at merchant)")
        print("  /asp preview - One-shot dry run")
        print("  /asp mark - Toggle bulk mark mode")
        print("  /asp debug - Toggle debug output")
        print("  /asp session - View session stats")
        print("  /asp session reset - Reset session")
        print("  /asp log - Show last 10 sales")
        print("  /asp log clear - Clear sale history")
        print("  /asp add <itemID> - Add to never-sell list")
        print("  /asp remove <itemID> - Remove from never-sell list")
        print("  /asp list - Show never-sell and always-sell lists")
        print("  /asp export - Export lists")
        print("  /asp import - Import lists")
        print("  /asp overlay - Cycle overlay visual mode")
        print("  /asp destroy - Destroy junk items")
        print("  /asp profile save|load|list|delete <name>")
        print("  /asp wizard - Re-run setup wizard")
        print("  /asp reset - Reset all settings (with confirm)")
        print("  /asp reset lists - Clear all lists")
        return
    end

    if cmd == "config" or cmd == "options" then
        Settings.OpenToCategory(ns.settingsCategoryID)
        return
    end

    if cmd == "toggle" then
        ns.db.enabled = not ns.db.enabled
        ns:Print("Addon " .. (ns.db.enabled and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))
        return
    end

    if cmd == "dryrun" then
        ns.db.dryRun = not ns.db.dryRun
        ns:Print("Dry run " .. (ns.db.dryRun and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))
        return
    end

    if cmd == "debug" then
        ns.debugMode = not ns.debugMode
        ns:Print("Debug mode " .. (ns.debugMode and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))
        return
    end

    if cmd == "sell" then
        local queue = ns:BuildSellQueue()
        if #queue > 0 then
            ns:StartSelling(queue)
        else
            ns:Print("Nothing to sell.")
        end
        return
    end

    if cmd == "preview" then
        local origDryRun = ns.db.dryRun
        ns.db.dryRun = true
        local queue = ns:BuildSellQueue()
        if #queue > 0 then
            ns:StartSelling(queue)
        else
            ns:Print("Nothing would be sold.")
        end
        ns.db.dryRun = origDryRun
        return
    end

    if cmd == "mark" then
        ns:ToggleBulkMarkMode()
        return
    end

    if cmd == "session" then
        if args[2] == "reset" then
            ns:ResetSession()
        elseif args[2] == "export" then
            local r = ns:GetSessionReport()
            ns:Print(format("Session export: %d items, %s, %dg/hr", r.itemCount, ns:FormatMoney(r.totalCopper), r.goldPerHour))
        else
            ns:PrintSessionReport()
        end
        return
    end

    if cmd == "log" then
        if args[2] == "clear" then
            ns:ClearSaleHistory()
        else
            ns:PrintSaleLog(tonumber(args[2]) or 10)
        end
        return
    end

    if cmd == "add" then
        local itemID = tonumber(args[2])
        if not itemID then
            ns:Print("Usage: /asp add <itemID>")
            return
        end
        ns.db.neverSellList[itemID] = true
        local itemName = C_Item.GetItemNameByID(itemID)
        ns:Print(format("Added %s (ID: %d) to never-sell list", itemName or "Unknown", itemID))
        return
    end

    if cmd == "remove" then
        local itemID = tonumber(args[2])
        if not itemID then
            ns:Print("Usage: /asp remove <itemID>")
            return
        end
        ns.db.neverSellList[itemID] = nil
        local itemName = C_Item.GetItemNameByID(itemID)
        ns:Print(format("Removed %s (ID: %d) from never-sell list", itemName or "Unknown", itemID))
        return
    end

    if cmd == "list" then
        ns:Print("Never-sell list (global):")
        local count = 0
        for itemID in pairs(ns.db.neverSellList) do
            local itemName = C_Item.GetItemNameByID(itemID)
            print(format("  [%d] %s", itemID, itemName or "Unknown"))
            count = count + 1
        end
        if count == 0 then print("  (empty)") end

        if AutoSellPlusCharDB and AutoSellPlusCharDB.charNeverSellList then
            ns:Print("Never-sell list (this char):")
            count = 0
            for itemID in pairs(AutoSellPlusCharDB.charNeverSellList) do
                local itemName = C_Item.GetItemNameByID(itemID)
                print(format("  [%d] %s", itemID, itemName or "Unknown"))
                count = count + 1
            end
            if count == 0 then print("  (empty)") end
        end

        ns:Print("Always-sell list (global):")
        count = 0
        for itemID in pairs(ns.db.alwaysSellList) do
            local itemName = C_Item.GetItemNameByID(itemID)
            print(format("  [%d] %s", itemID, itemName or "Unknown"))
            count = count + 1
        end
        if count == 0 then print("  (empty)") end

        if AutoSellPlusCharDB and AutoSellPlusCharDB.charAlwaysSellList then
            ns:Print("Always-sell list (this char):")
            count = 0
            for itemID in pairs(AutoSellPlusCharDB.charAlwaysSellList) do
                local itemName = C_Item.GetItemNameByID(itemID)
                print(format("  [%d] %s", itemID, itemName or "Unknown"))
                count = count + 1
            end
            if count == 0 then print("  (empty)") end
        end
        return
    end

    if cmd == "export" then
        if ns.ShowExportFrame then
            ns.ShowExportFrame()
        else
            local data = ns:SerializeList("all")
            ns:Print("Export data: " .. data)
        end
        return
    end

    if cmd == "import" then
        if ns.ShowImportFrame then
            ns.ShowImportFrame()
        else
            ns:Print("Usage: Paste import data after /asp import <data>")
            if args[2] then
                local data = table.concat(args, " ", 2)
                local ok, count = ns:DeserializeList(data)
                if ok then
                    ns:Print(format("Imported %d items.", count))
                else
                    ns:Print("Import failed.")
                end
            end
        end
        return
    end

    if cmd == "destroy" then
        ns:DestroyJunk()
        return
    end

    if cmd == "profile" then
        local sub = args[2]
        local name = args[3]
        if sub == "save" and name then
            ns:SaveProfile(name)
        elseif sub == "load" and name then
            ns:LoadProfile(name)
        elseif sub == "delete" and name then
            ns:DeleteProfile(name)
        elseif sub == "list" then
            ns:ListProfiles()
        else
            ns:Print("Usage: /asp profile save|load|list|delete <name>")
        end
        return
    end

    if cmd == "wizard" then
        ns:ShowWizard()
        return
    end

    if cmd == "reset" then
        if args[2] == "lists" then
            wipe(ns.db.neverSellList)
            wipe(ns.db.alwaysSellList)
            if AutoSellPlusCharDB then
                wipe(AutoSellPlusCharDB.charNeverSellList)
                wipe(AutoSellPlusCharDB.charAlwaysSellList)
            end
            ns:Print("All lists cleared.")
            return
        end

        StaticPopupDialogs["ASP_RESET_CONFIRM"] = {
            text = "AutoSellPlus: Reset ALL settings to defaults?",
            button1 = "Reset",
            button2 = "Cancel",
            OnAccept = function()
                for key, value in pairs(ns.globalDefaults) do
                    AutoSellPlusDB.global[key] = ns.DeepCopy(value)
                end
                ns:Print("All settings reset to defaults.")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("ASP_RESET_CONFIRM")
        return
    end

    if cmd == "overlay" then
        local modes = { "border", "tint", "full" }
        local current = ns.db.overlayMode or "border"
        local nextIdx = 1
        for i, m in ipairs(modes) do
            if m == current then
                nextIdx = (i % #modes) + 1
                break
            end
        end
        ns.db.overlayMode = modes[nextIdx]
        ns:Print(format("Overlay mode: |cFF00FF00%s|r", ns.db.overlayMode))
        ns:SafeCall(function() ns:InitMarking() end)
        return
    end

    if cmd == "undo" then
        ns:UndoLastSale()
        return
    end

    ns:Print("Unknown command. Type /asp help for usage.")
end

SLASH_AUTOSELLPLUS1 = "/asp"
SLASH_AUTOSELLPLUS2 = "/autosell"
SlashCmdList["AUTOSELLPLUS"] = HandleSlashCommand

-- ============================================================
-- Event Frame
-- ============================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("MERCHANT_CLOSED")
eventFrame:RegisterEvent("EQUIPMENT_SETS_CHANGED")
eventFrame:RegisterEvent("UI_ERROR_MESSAGE")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        ns:RebuildEquipmentSetCache()
        ns:Print(format("v%s loaded. Type /asp for commands.", ns.version))

        -- Self-test
        ns:SafeCall(RunSelfTest)

        -- Initialize session
        ns:SafeCall(function() ns:InitSession() end)

        -- Initialize marking system
        ns:SafeCall(function() ns:InitMarking() end)

        -- Create minimap button
        ns:SafeCall(function() ns:CreateMinimapButton() end)

        -- Update junk value for alt tracking
        ns:SafeCall(function() ns:UpdateCharJunkValue() end)

        -- Conflict detection
        ns:SafeCall(DetectConflicts)

        -- First-run wizard (per-character)
        if not AutoSellPlusCharDB.charFirstRunComplete then
            C_Timer.After(2, function()
                ns:ShowWizard()
            end)
        end

        FireEvent("LOADED")

    elseif event == "MERCHANT_SHOW" then
        if ns.db.enabled then
            -- Auto-repair first
            ns:SafeCall(DoAutoRepair)

            -- Then handle sell mode
            HandleAutoSell()

            -- Check if bags are full and eviction enabled
            if ns.db.evictionEnabled and ns:CountFreeSlots() == 0 then
                ns:DebugPrint("Bags full, entering eviction mode")
            end
        end

    elseif event == "MERCHANT_CLOSED" then
        ns:HidePopup()
        ns:StopSelling()
        CancelAutoSell()

    elseif event == "EQUIPMENT_SETS_CHANGED" then
        ns:RebuildEquipmentSetCache()

    elseif event == "UI_ERROR_MESSAGE" then
        if isSelling then
            ns:StopSelling()
        end

    elseif event == "BAG_UPDATE_DELAYED" then
        -- Check bag space
        ns:SafeCall(CheckBagSpace)
        -- Update junk value
        ns:SafeCall(function() ns:UpdateCharJunkValue() end)
    end
end)
