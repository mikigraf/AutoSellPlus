local addonName, ns = ...

-- Overlay pool for bag item marks
local overlayPool = {}
local activeOverlays = {}

-- ============================================================
-- Overlay Creation and Management
-- ============================================================

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

        -- Tint texture (semi-transparent color overlay)
        local tint = overlay:CreateTexture(nil, "ARTWORK")
        tint:SetAllPoints()
        tint:SetColorTexture(1.0, 0.4, 0.0, 0.25)
        overlay.tint = tint

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

local function ApplyOverlayMode(overlay)
    local mode = ns.db and ns.db.overlayMode or "border"
    if mode == "border" then
        overlay:SetBackdropBorderColor(1.0, 0.4, 0.0, 0.9)
        overlay.coin:Show()
        overlay.tint:Hide()
    elseif mode == "tint" then
        overlay:SetBackdropBorderColor(0, 0, 0, 0)
        overlay.coin:Hide()
        overlay.tint:Show()
    elseif mode == "full" then
        overlay:SetBackdropBorderColor(1.0, 0.4, 0.0, 0.9)
        overlay.coin:Show()
        overlay.tint:Show()
    end
end

local function ReleaseOverlay(overlay)
    overlay:ClearAllPoints()
    overlay:SetParent(UIParent)
    overlay:Hide()
    overlayPool[#overlayPool + 1] = overlay
end

-- Refresh all bag overlays
function ns:RefreshOverlays()
    -- Release existing
    for _, overlay in ipairs(activeOverlays) do
        ReleaseOverlay(overlay)
    end
    wipe(activeOverlays)

    -- Baganator: request corner widget refresh for pooled (Retail) buttons
    if Baganator and Baganator.API and Baganator.API.RequestItemButtonsRefresh then
        Baganator.API.RequestItemButtonsRefresh()
    end

    local markedItems = ns.db.markedItems
    if not markedItems then return end

    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.itemID and markedItems[itemInfo.itemID] then
                local frame = ns:GetBagItemFrame(bag, slot)
                if frame and frame:IsShown() then
                    local overlay = GetOverlay()
                    overlay:SetParent(frame)
                    overlay:SetAllPoints(frame)
                    overlay:SetFrameLevel(frame:GetFrameLevel() + 5)
                    ApplyOverlayMode(overlay)
                    overlay:Show()
                    activeOverlays[#activeOverlays + 1] = overlay
                end
            end
        end
    end
end

-- ============================================================
-- Tooltip Hook
-- ============================================================

local function FindItemInBags(itemID)
    for bag = 0, ns:GetMaxBagID() do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.itemID == itemID then
                return bag, slot
            end
        end
    end
    return nil, nil
end

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

    -- ASP tooltip status line
    if ns.db and ns.db.showTooltipStatus and ns.ClassifyItem then
        local bag, slot = FindItemInBags(itemID)
        local status, reason, r, g, b = ns:ClassifyItem(itemID, bag, slot)
        if status and reason then
            tooltip:AddLine("ASP: " .. reason, r or 0.7, g or 0.7, b or 0.7)
        end
    end
end

-- ============================================================
-- Bag Gold Display
-- ============================================================

local bagGoldFrame = nil
local bagGoldThrottle = 0

local function EnsureBagGoldFrame()
    if bagGoldFrame then return bagGoldFrame end

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
                    local _, _, _, _, _, _, _, _, _, _, sp = C_Item.GetItemInfo(itemInfo.hyperlink)
                    if sp and sp > 0 then
                        local value = sp * (itemInfo.stackCount or 1)
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

    return bagGoldFrame
end

function ns:UpdateBagGoldDisplay()
    if not ns.db or not ns.db.showBagGoldDisplay then
        if bagGoldFrame then bagGoldFrame:Hide() end
        return
    end

    local frame = EnsureBagGoldFrame()
    local total = ns:GetTotalBagVendorValue()
    frame.text:SetText(ns:FormatMoney(total))
    frame:Show()
end

-- Throttled update for BAG_UPDATE_DELAYED
function ns:ThrottledBagGoldUpdate()
    local now = ns:GetServerTime()
    if now > bagGoldThrottle then
        bagGoldThrottle = now + 1
        self:UpdateBagGoldDisplay()
    end
end

-- ============================================================
-- Visual Flash on Bag Item
-- ============================================================

local flashPool = {}

local function GetFlashTexture(parent)
    local flash = table.remove(flashPool)
    if not flash then
        flash = parent:CreateTexture(nil, "OVERLAY")
        flash._ag = parent:CreateAnimationGroup()
        local alpha = flash._ag:CreateAnimation("Alpha")
        alpha:SetFromAlpha(0.5)
        alpha:SetToAlpha(0)
        alpha:SetDuration(0.5)
        flash._ag:SetScript("OnFinished", function()
            flash:Hide()
            flash:ClearAllPoints()
            flashPool[#flashPool + 1] = flash
        end)
    else
        flash:SetParent(parent)
    end
    return flash
end

function ns:FlashBagItem(itemID, colorR, colorG, colorB)
    if not itemID then return end
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.itemID == itemID then
                local frame = self:GetBagItemFrame(bag, slot)
                if frame and frame:IsShown() then
                    local flash = GetFlashTexture(frame)
                    flash:SetAllPoints(frame)
                    flash:SetColorTexture(colorR or 0, colorG or 1, colorB or 0, 0.5)
                    flash:Show()
                    flash._ag:Stop()
                    flash._ag:Play()
                end
            end
        end
    end
end

-- ============================================================
-- Baganator Corner Widget
-- ============================================================

local function RegisterBaganatorWidget()
    if not (Baganator and Baganator.API and Baganator.API.RegisterCornerWidget) then return end
    pcall(function()
        Baganator.API.RegisterCornerWidget(
            "AutoSellPlus: Junk",
            "autosellplus-junk-mark",
            function(widget, data)
                if data and data.itemID and ns:IsMarked(data.itemID) then
                    return true
                end
                return false
            end,
            function(widget)
                widget:SetSize(14, 14)
                if widget.SetTexture then
                    widget:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
                    widget:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                end
            end,
            { default_position = "bottom_right", priority = 1 }
        )
        ns:DebugPrint("Registered Baganator corner widget for junk marks")
    end)
end

-- ============================================================
-- Initialization
-- ============================================================

function ns:InitOverlays()
    -- Tooltip hook
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
    end

    -- Baganator corner widget
    RegisterBaganatorWidget()
end
