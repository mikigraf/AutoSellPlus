local addonName, ns = ...

ns.bulkMarkMode = false

-- ============================================================
-- Mark Toggling
-- ============================================================

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

    ns:RefreshOverlays()
end

function ns:IsMarked(itemID)
    return self.db.markedItems and self.db.markedItems[itemID] or false
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

-- ============================================================
-- Click Handlers
-- ============================================================

-- ALT+Click hook for bag items
local function OnModifiedClick(bag, slot)
    if not IsAltKeyDown() and not ns.bulkMarkMode then return end

    local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
    if itemInfo and itemInfo.itemID then
        ns:ToggleMark(itemInfo.itemID)
    end
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

-- ============================================================
-- Setup Helpers (called from InitMarking)
-- ============================================================

local function SetupAltClickHook()
    if hooksecurefunc then
        hooksecurefunc(C_Container, "UseContainerItem", function(bag, slot)
            if IsAltKeyDown() or ns.bulkMarkMode then
                OnModifiedClick(bag, slot)
                ClearCursor()
            end
        end)
    end
end

local function SetupBagUpdateHandler()
    local overlayFrame = CreateFrame("Frame")
    overlayFrame:RegisterEvent("BAG_UPDATE_DELAYED")
    overlayFrame:SetScript("OnEvent", function()
        ns:RefreshOverlays()
        ns:ThrottledBagGoldUpdate()
    end)
end

local function SetupLootAutoMark()
    local lootFrame = CreateFrame("Frame")
    lootFrame:RegisterEvent("CHAT_MSG_LOOT")
    lootFrame:SetScript("OnEvent", OnLootReceived)
end

local function SetupLootWindowHook()
    hooksecurefunc("LootSlot", function(slot)
        if not IsAltKeyDown() then return end
        local link = GetLootSlotLink(slot)
        if not link then return end
        local itemID = C_Item.GetItemInfoInstant(link)
        if not itemID then return end
        local markedItems = ns.db.markedItems
        if not markedItems then return end
        markedItems[itemID] = true
        local itemName = C_Item.GetItemNameByID(itemID)
        ns:Print(format("Marked %s as junk from loot", itemName or "item " .. itemID))
    end)
end

local function SetupDragToMarkButton()
    local markTarget = CreateFrame("Button", "AutoSellPlusMarkTarget", UIParent, "BackdropTemplate")
    markTarget:SetSize(36, 36)
    markTarget:SetPoint("TOP", MainMenuBarBackpackButton or UIParent, "BOTTOM", 36, -4)
    markTarget:SetFrameStrata("HIGH")
    markTarget:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    markTarget:SetBackdropColor(0.10, 0.10, 0.10, 0.9)
    markTarget:SetBackdropBorderColor(1.0, 0.4, 0.0, 0.8)

    local markIcon = markTarget:CreateTexture(nil, "ARTWORK")
    markIcon:SetSize(24, 24)
    markIcon:SetPoint("CENTER")
    markIcon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
    markIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local markLabel = markTarget:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    markLabel:SetPoint("BOTTOMRIGHT", -2, 2)
    markLabel:SetText("|cFFFF6600J|r")

    markTarget:SetScript("OnReceiveDrag", function()
        if CursorHasItem() then
            local infoType, itemID = GetCursorInfo()
            if infoType == "item" and itemID then
                ClearCursor()
                ns:ToggleMark(itemID)
            end
        end
    end)

    markTarget:SetScript("OnMouseUp", function()
        if CursorHasItem() then
            local infoType, itemID = GetCursorInfo()
            if infoType == "item" and itemID then
                ClearCursor()
                ns:ToggleMark(itemID)
            end
        end
    end)

    markTarget:SetScript("OnEnter", function(btn)
        btn:SetBackdropBorderColor(1.0, 0.6, 0.0, 1)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:AddLine("|cFF00CCFFMark as Junk|r", 1, 1, 1)
        GameTooltip:AddLine("Drag an item here to toggle its junk mark.", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)

    markTarget:SetScript("OnLeave", function(btn)
        btn:SetBackdropBorderColor(1.0, 0.4, 0.0, 0.8)
        GameTooltip:Hide()
    end)

    markTarget:Hide()
    ns._markTarget = markTarget
end

local function SetupBagOpenCloseHooks()
    hooksecurefunc("OpenAllBags", function()
        if ns._markTarget then ns._markTarget:Show() end
        C_Timer.After(0.1, function() ns:RefreshOverlays() end)
    end)
    hooksecurefunc("CloseAllBags", function()
        if ns._markTarget then ns._markTarget:Hide() end
        C_Timer.After(0.1, function() ns:RefreshOverlays() end)
    end)
end

-- ============================================================
-- Main Initialization
-- ============================================================

function ns:InitMarking()
    SetupAltClickHook()
    SetupBagUpdateHandler()
    SetupLootAutoMark()
    SetupLootWindowHook()
    SetupDragToMarkButton()
    SetupBagOpenCloseHooks()
    ns:InitOverlays()
    C_Timer.After(1, function() ns:RefreshOverlays() end)
end
