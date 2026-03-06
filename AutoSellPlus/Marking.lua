local addonName, ns = ...

ns.bulkMarkMode = false

-- Overlay pool for bag item marks
local overlayPool = {}
local activeOverlays = {}

-- Bag addon adapters for compatibility
local BAG_ADDON_ADAPTERS = {
    default = {
        getFrame = function(bag, slot)
            local bagFrame = _G["ContainerFrame" .. (bag + 1)]
            if not bagFrame then return nil end
            local slotName = bagFrame:GetName() .. "Item" .. slot
            return _G[slotName]
        end,
    },
    bagnon = {
        getFrame = function(bag, slot)
            -- Bagnon uses a single inventory frame with item buttons keyed by bag-slot
            local itemFrame = _G["BagnonInventoryItem" .. bag .. "_" .. slot]
                or _G["BagnonItem" .. bag .. "_" .. slot]
            return itemFrame
        end,
    },
    adibags = {
        getFrame = function(bag, slot)
            -- AdiBags uses named item buttons based on bag and slot
            local itemFrame = _G["AdiBagsItemButton" .. bag .. "_" .. slot]
            return itemFrame
        end,
    },
    arkinventory = {
        getFrame = function(bag, slot)
            -- ArkInventory stores item frames under its own naming convention
            local itemFrame = _G["ARKINV_Frame1ScrollContainerBag" .. bag .. "Item" .. slot]
            return itemFrame
        end,
    },
}

local function GetBagAdapterName()
    if Bagnon then return "bagnon" end
    if AdiBags then return "adibags" end
    if ArkInventory then return "arkinventory" end
    return "default"
end

local function GetBagItemFrame(bag, slot)
    local adapterName = GetBagAdapterName()
    local adapter = BAG_ADDON_ADAPTERS[adapterName] or BAG_ADDON_ADAPTERS.default
    return adapter.getFrame(bag, slot)
end

-- Create or reuse an overlay frame
local function GetOverlay()
    local overlay = table.remove(overlayPool)
    if not overlay then
        overlay = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        overlay:SetFrameStrata("HIGH")

        -- Red/orange border
        overlay:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 2,
        })
        overlay:SetBackdropBorderColor(1.0, 0.4, 0.0, 0.9)

        -- Coin icon in corner
        local coin = overlay:CreateTexture(nil, "OVERLAY")
        coin:SetSize(14, 14)
        coin:SetPoint("BOTTOMRIGHT", -1, 1)
        coin:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
        coin:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        overlay.coin = coin

        overlay:EnableMouse(false)
    end
    return overlay
end

local function ReleaseOverlay(overlay)
    overlay:ClearAllPoints()
    overlay:SetParent(UIParent)
    overlay:Hide()
    overlayPool[#overlayPool + 1] = overlay
end

-- Refresh all bag overlays
local function RefreshOverlays()
    -- Release existing
    for _, overlay in ipairs(activeOverlays) do
        ReleaseOverlay(overlay)
    end
    wipe(activeOverlays)

    local markedItems = ns.db.markedItems
    if not markedItems then return end

    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.itemID and markedItems[itemInfo.itemID] then
                local frame = GetBagItemFrame(bag, slot)
                if frame and frame:IsShown() then
                    local overlay = GetOverlay()
                    overlay:SetParent(frame)
                    overlay:SetAllPoints(frame)
                    overlay:SetFrameLevel(frame:GetFrameLevel() + 5)
                    overlay:Show()
                    activeOverlays[#activeOverlays + 1] = overlay
                end
            end
        end
    end
end

-- Toggle mark on an item
function ns:ToggleMark(itemID)
    if not itemID then return end
    local markedItems = self.db.markedItems
    if not markedItems then return end

    if markedItems[itemID] then
        markedItems[itemID] = nil
        local itemName = C_Item.GetItemNameByID(itemID)
        self:Print(format("Unmarked %s", itemName or "item " .. itemID))
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        self:FlashBagItem(itemID, 1, 0, 0)
    else
        markedItems[itemID] = true
        local itemName = C_Item.GetItemNameByID(itemID)
        self:Print(format("Marked %s as junk", itemName or "item " .. itemID))
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        self:FlashBagItem(itemID, 0, 1, 0)
    end

    RefreshOverlays()
end

function ns:IsMarked(itemID)
    return self.db.markedItems and self.db.markedItems[itemID] or false
end

-- ALT+Click hook for bag items
local function OnModifiedClick(bag, slot)
    if not IsAltKeyDown() and not ns.bulkMarkMode then return end

    local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
    if itemInfo and itemInfo.itemID then
        ns:ToggleMark(itemInfo.itemID)
    end
end

-- Bulk mark mode toggle
function ns:ToggleBulkMarkMode()
    self.bulkMarkMode = not self.bulkMarkMode
    if self.bulkMarkMode then
        self:Print("Bulk mark mode |cFF00FF00ON|r — click items to mark/unmark")
    else
        self:Print("Bulk mark mode |cFFFF0000OFF|r")
    end
end

-- Tooltip hook: show "[Marked as Junk]" and vendor price
local function OnTooltipSetItem(tooltip, data)
    if not data or not data.id then return end
    local itemID = data.id

    -- Marked as junk indicator
    if ns:IsMarked(itemID) then
        tooltip:AddLine("|cFFFF6600[Marked as Junk]|r")
    end

    -- Vendor sell price enhancement
    local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(itemID)
    if sellPrice and sellPrice > 0 then
        -- Check for TSM market value
        local tsmValue
        if TSM_API and TSM_API.GetCustomPriceValue then
            local ok, val = pcall(TSM_API.GetCustomPriceValue, "DBMarket", "i:" .. itemID)
            if ok and val then tsmValue = val end
        end

        -- Check for Auctionator value
        local auctValue
        if Auctionator and Auctionator.API and Auctionator.API.v1 and Auctionator.API.v1.GetAuctionPriceByItemLink then
            local itemLink = select(2, C_Item.GetItemInfo(itemID))
            if itemLink then
                local ok, val = pcall(Auctionator.API.v1.GetAuctionPriceByItemLink, "AutoSellPlus", itemLink)
                if ok and val then auctValue = val end
            end
        end

        local ahValue = tsmValue or auctValue
        if ahValue and ahValue > 0 then
            tooltip:AddDoubleLine(
                "Vendor: " .. ns:FormatMoney(sellPrice),
                "AH: " .. ns:FormatMoney(ahValue),
                1, 0.82, 0, 0.3, 1, 0.3
            )
        end
    end
end

-- In-bag gold display
local bagGoldFrame = nil
local bagGoldThrottle = 0

local function UpdateBagGoldDisplay()
    if not ns.db or not ns.db.showBagGoldDisplay then
        if bagGoldFrame then bagGoldFrame:Hide() end
        return
    end

    if not bagGoldFrame then
        bagGoldFrame = CreateFrame("Frame", nil, UIParent)
        bagGoldFrame:SetSize(120, 16)
        bagGoldFrame:SetPoint("TOP", MainMenuBarBackpackButton or UIParent, "BOTTOM", 0, -2)
        bagGoldFrame:SetFrameStrata("MEDIUM")

        local text = bagGoldFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("CENTER")
        text:SetTextColor(1, 0.82, 0)
        bagGoldFrame.text = text

        bagGoldFrame:EnableMouse(true)
        bagGoldFrame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine("|cFF00CCFFBag Vendor Value|r", 1, 1, 1)
            GameTooltip:AddLine(" ")

            local qualityTotals = {}
            local markedTotal = 0
            local markedItems = ns.db.markedItems

            for bag = 0, 4 do
                local numSlots = C_Container.GetContainerNumSlots(bag)
                for slot = 1, numSlots do
                    local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
                    if itemInfo and itemInfo.hyperlink then
                        local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(itemInfo.hyperlink)
                        if sellPrice and sellPrice > 0 then
                            local value = sellPrice * (itemInfo.stackCount or 1)
                            local q = itemInfo.quality or 0
                            qualityTotals[q] = (qualityTotals[q] or 0) + value
                            if markedItems and itemInfo.itemID and markedItems[itemInfo.itemID] then
                                markedTotal = markedTotal + value
                            end
                        end
                    end
                end
            end

            local qualityNames = {
                [0] = ITEM_QUALITY0_DESC or "Poor",
                [1] = ITEM_QUALITY1_DESC or "Common",
                [2] = ITEM_QUALITY2_DESC or "Uncommon",
                [3] = ITEM_QUALITY3_DESC or "Rare",
                [4] = ITEM_QUALITY4_DESC or "Epic",
            }

            for q = 0, 4 do
                if qualityTotals[q] and qualityTotals[q] > 0 then
                    local color = ITEM_QUALITY_COLORS[q]
                    local r, g, b = 0.7, 0.7, 0.7
                    if color then r, g, b = color.r, color.g, color.b end
                    GameTooltip:AddDoubleLine(qualityNames[q] or ("Quality " .. q), ns:FormatMoney(qualityTotals[q]), r, g, b, 1, 0.82, 0)
                end
            end

            if markedTotal > 0 then
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine("Marked as Junk", ns:FormatMoney(markedTotal), 1, 0.4, 0, 1, 0.82, 0)
            end

            GameTooltip:Show()
        end)
        bagGoldFrame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    local total = ns:GetTotalBagVendorValue()
    bagGoldFrame.text:SetText(ns:FormatMoney(total))
    bagGoldFrame:Show()
end

-- Auto-mark looted items
local function OnLootReceived(_, _, itemLink)
    if not itemLink then return end
    local itemID = C_Item.GetItemInfoInstant(itemLink)
    if not itemID then return end

    -- Auto-mark gray loot
    if ns.db.autoMarkGrayLoot then
        local _, _, quality = C_Item.GetItemInfo(itemLink)
        if quality == Enum.ItemQuality.Poor then
            ns.db.markedItems[itemID] = true
            ns:DebugPrint("Auto-marked gray loot: " .. itemLink)
        end
    end

    -- Auto-mark below ilvl threshold
    if ns.db.autoMarkBelowIlvl > 0 then
        local ilvl = ns:GetEffectiveItemLevel(itemLink)
        if ilvl > 0 and ilvl < ns.db.autoMarkBelowIlvl and ns:IsEquippable(itemID) then
            ns.db.markedItems[itemID] = true
            ns:DebugPrint("Auto-marked low ilvl loot: " .. itemLink)
        end
    end
end

-- Visual flash on bag item when marking/unmarking
function ns:FlashBagItem(itemID, colorR, colorG, colorB)
    if not itemID then return end
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.itemID == itemID then
                local frame = GetBagItemFrame(bag, slot)
                if frame and frame:IsShown() then
                    local flash = frame:CreateTexture(nil, "OVERLAY")
                    flash:SetAllPoints(frame)
                    flash:SetColorTexture(colorR or 0, colorG or 1, colorB or 0, 0.5)

                    local ag = flash:GetParent():CreateAnimationGroup()
                    local alpha = ag:CreateAnimation("Alpha")
                    alpha:SetFromAlpha(0.5)
                    alpha:SetToAlpha(0)
                    alpha:SetDuration(0.5)
                    ag:SetScript("OnFinished", function()
                        flash:Hide()
                        flash:SetParent(nil)
                    end)
                    ag:Play()
                end
            end
        end
    end
end

-- Hook setup (called from Core.lua on PLAYER_LOGIN)
function ns:InitMarking()
    -- Tooltip hook
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
    end

    -- ALT+Click hook for ContainerFrame
    if hooksecurefunc then
        hooksecurefunc(C_Container, "UseContainerItem", function(bag, slot)
            if IsAltKeyDown() or ns.bulkMarkMode then
                -- Prevent the use action, just mark
            end
        end)
    end

    -- Bag update handler for overlays
    local overlayFrame = CreateFrame("Frame")
    overlayFrame:RegisterEvent("BAG_UPDATE_DELAYED")
    overlayFrame:SetScript("OnEvent", function()
        RefreshOverlays()
        -- Throttled bag gold display update
        local now = GetServerTime()
        if now > bagGoldThrottle then
            bagGoldThrottle = now + 1
            UpdateBagGoldDisplay()
        end
    end)

    -- Loot auto-marking
    local lootFrame = CreateFrame("Frame")
    lootFrame:RegisterEvent("CHAT_MSG_LOOT")
    lootFrame:SetScript("OnEvent", OnLootReceived)

    -- Initial overlay refresh
    C_Timer.After(1, RefreshOverlays)
end
