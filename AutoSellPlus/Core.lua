local addonName, ns = ...

local sellQueue = {}
local sellTimer = nil
local isSelling = false
local totalSold = 0
local totalCopper = 0

-- Item evaluation: returns true if item should be sold
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

    -- Priority 1: Never-sell list
    if db.neverSellList[itemID] then return false end

    -- Priority 2: Always-sell list (must have sell price)
    if db.alwaysSellList[itemID] then
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

    -- Uncollected transmog protection (only for equippable items)
    if db.protectUncollectedTransmog and self:IsEquippable(itemID) then
        if self:IsUncollectedTransmog(itemID) then return false end
    end

    -- Refundable protection
    if self:IsRefundable(bag, slot) then return false end

    -- Quality-based selling
    if quality == Enum.ItemQuality.Poor and db.sellGrays then
        return true, itemLink, sellPrice, stackCount
    end

    if quality == Enum.ItemQuality.Uncommon and db.sellGreens then
        if db.onlyEquippable and not self:IsEquippable(itemID) then return false end
        local ilvl = self:GetEffectiveItemLevel(itemLink)
        if ilvl == 0 then return false end
        if db.greenMaxIlvl > 0 and ilvl <= db.greenMaxIlvl then
            return true, itemLink, sellPrice, stackCount
        end
        return false
    end

    if quality == Enum.ItemQuality.Rare and db.sellBlues then
        if db.onlyEquippable and not self:IsEquippable(itemID) then return false end
        local ilvl = self:GetEffectiveItemLevel(itemLink)
        if ilvl == 0 then return false end
        if db.blueMaxIlvl > 0 and ilvl <= db.blueMaxIlvl then
            return true, itemLink, sellPrice, stackCount
        end
        return false
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

function ns:StartSelling(explicitQueue)
    if isSelling then return end

    sellQueue = explicitQueue or self:BuildSellQueue()
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

    isSelling = true
    totalSold = 0
    totalCopper = 0

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

            if self.db.showItemized then
                self:Print(format("Sold %s x%d for %s", item.itemLink, item.stackCount, self:FormatMoney(item.totalPrice)))
            end
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

    if self.db.showSummary and totalSold > 0 then
        self:Print(format("Sold %d item%s for %s",
            totalSold,
            totalSold == 1 and "" or "s",
            self:FormatMoney(totalCopper)))
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

    if self.db.showSummary and totalSold > 0 then
        self:Print(format("Merchant closed. Sold %d item%s for %s (interrupted)",
            totalSold,
            totalSold == 1 and "" or "s",
            self:FormatMoney(totalCopper)))
    end

    totalSold = 0
    totalCopper = 0
    sellQueue = {}
end

-- Slash command handler
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
        print("  /asp add <itemID> - Add item to never-sell list")
        print("  /asp remove <itemID> - Remove item from never-sell list")
        print("  /asp list - Show never-sell and always-sell lists")
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
        ns:Print("Never-sell list:")
        local count = 0
        for itemID in pairs(ns.db.neverSellList) do
            local itemName = C_Item.GetItemNameByID(itemID)
            print(format("  [%d] %s", itemID, itemName or "Unknown"))
            count = count + 1
        end
        if count == 0 then print("  (empty)") end

        ns:Print("Always-sell list:")
        count = 0
        for itemID in pairs(ns.db.alwaysSellList) do
            local itemName = C_Item.GetItemNameByID(itemID)
            print(format("  [%d] %s", itemID, itemName or "Unknown"))
            count = count + 1
        end
        if count == 0 then print("  (empty)") end
        return
    end

    ns:Print("Unknown command. Type /asp help for usage.")
end

SLASH_AUTOSELLPLUS1 = "/asp"
SLASH_AUTOSELLPLUS2 = "/autosell"
SlashCmdList["AUTOSELLPLUS"] = HandleSlashCommand

-- Event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("MERCHANT_CLOSED")
eventFrame:RegisterEvent("EQUIPMENT_SETS_CHANGED")
eventFrame:RegisterEvent("UI_ERROR_MESSAGE")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        ns:RebuildEquipmentSetCache()
        ns:Print(format("v%s loaded. Type /asp for commands.", ns.version))

    elseif event == "MERCHANT_SHOW" then
        if ns.db.enabled then ns:ShowPopup() end

    elseif event == "MERCHANT_CLOSED" then
        ns:HidePopup()
        ns:StopSelling()

    elseif event == "EQUIPMENT_SETS_CHANGED" then
        ns:RebuildEquipmentSetCache()

    elseif event == "UI_ERROR_MESSAGE" then
        if isSelling then
            ns:StopSelling()
        end
    end
end)
