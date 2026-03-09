local addonName, ns = ...

-- Layout constants
local ROW_HEIGHT = 28
local POPUP_WIDTH = 580
local POPUP_HEIGHT = 694

local FLAT_BACKDROP = ns.FLAT_BACKDROP

local popup = nil
local itemRows = {}
local displayList = {}
local userUnchecked = {}
local contextMenu = nil

-- Sorting state
ns.sortColumn = "quality"
ns.sortDirection = "asc"

-- ============================================================
-- Styled UI Helpers
-- ============================================================

local function CreateStyledCheck(parent, size)
    local check = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
    check:SetSize(size, size)
    check:SetBackdrop(FLAT_BACKDROP)
    check:SetBackdropColor(0.15, 0.15, 0.15, 1)
    check:SetBackdropBorderColor(0.30, 0.30, 0.30, 1)
    check:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    local ct = check:GetCheckedTexture()
    ct:ClearAllPoints()
    ct:SetPoint("TOPLEFT", 2, -2)
    ct:SetPoint("BOTTOMRIGHT", -2, 2)
    check:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.50, 0.50, 0.50, 1)
    end)
    check:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.30, 0.30, 0.30, 1)
    end)
    return check
end

local function CreateStyledSlider(parent, minVal, maxVal, step)
    local slider = CreateFrame("Slider", nil, parent, "BackdropTemplate")
    slider:SetSize(110, 14)
    slider:SetBackdrop(FLAT_BACKDROP)
    slider:SetBackdropColor(0.12, 0.12, 0.12, 1)
    slider:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    slider:SetOrientation("HORIZONTAL")
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(10, 14)
    thumb:SetColorTexture(0.50, 0.50, 0.50, 1)
    slider:SetThumbTexture(thumb)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    return slider
end

local function CreateStyledEditBox(parent, width)
    local eb = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    eb:SetSize(width, 18)
    eb:SetBackdrop(FLAT_BACKDROP)
    eb:SetBackdropColor(0.08, 0.08, 0.08, 1)
    eb:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    eb:SetFontObject(GameFontHighlightSmall)
    eb:SetTextInsets(4, 4, 0, 0)
    eb:SetJustifyH("CENTER")
    eb:SetAutoFocus(false)
    eb:SetNumeric(true)
    eb:SetMaxLetters(3)
    eb:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(0, 0.6, 1.0, 1)
        self:HighlightText()
    end)
    eb:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        self:HighlightText(0, 0)
    end)
    return eb
end

local function CreateFlatButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    btn:SetBackdrop(FLAT_BACKDROP)
    btn:SetBackdropColor(0.18, 0.18, 0.18, 1)
    btn:SetBackdropBorderColor(0.30, 0.30, 0.30, 1)

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER")
    label:SetText(text)
    btn.label = label

    btn:SetScript("OnEnter", function(self)
        if self:IsEnabled() then
            self:SetBackdropColor(0.28, 0.28, 0.28, 1)
            self:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if self:IsEnabled() then
            self:SetBackdropColor(0.18, 0.18, 0.18, 1)
            self:SetBackdropBorderColor(0.30, 0.30, 0.30, 1)
        end
    end)
    btn:SetScript("OnMouseDown", function(self)
        if self:IsEnabled() then
            self:SetBackdropColor(0.08, 0.08, 0.08, 1)
        end
    end)
    btn:SetScript("OnMouseUp", function(self)
        if self:IsEnabled() then
            self:SetBackdropColor(0.28, 0.28, 0.28, 1)
        end
    end)
    hooksecurefunc(btn, "SetEnabled", function(self, enabled)
        if enabled then
            label:SetTextColor(1, 1, 1)
            self:SetBackdropColor(0.18, 0.18, 0.18, 1)
            self:SetBackdropBorderColor(0.30, 0.30, 0.30, 1)
        else
            label:SetTextColor(0.35, 0.35, 0.35)
            self:SetBackdropColor(0.10, 0.10, 0.10, 1)
            self:SetBackdropBorderColor(0.18, 0.18, 0.18, 1)
        end
    end)
    return btn
end

-- ============================================================
-- Context Menu
-- ============================================================

local function CreateContextMenu()
    if contextMenu then return contextMenu end

    local menu = CreateFrame("Frame", "AutoSellPlusContextMenu", UIParent, "BackdropTemplate")
    menu:SetSize(200, 130)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:SetBackdrop(FLAT_BACKDROP)
    menu:SetBackdropColor(0.08, 0.08, 0.08, 0.98)
    menu:SetBackdropBorderColor(0, 0, 0, 1)
    menu:EnableMouse(true)
    menu:Hide()

    local options = {
        { text = "Never sell (global)", action = "never_global" },
        { text = "Never sell (this char)", action = "never_char" },
        { text = "Always sell (global)", action = "always_global" },
        { text = "Always sell (this char)", action = "always_char" },
        { text = "Remove from lists", action = "remove" },
    }

    for i, opt in ipairs(options) do
        local btn = CreateFrame("Button", nil, menu)
        btn:SetSize(196, 24)
        btn:SetPoint("TOPLEFT", 2, -2 - (i - 1) * 24)
        btn.action = opt.action

        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(0.15, 0.35, 0.55, 0.6)

        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", 8, 0)
        label:SetText(opt.text)

        btn:SetScript("OnClick", function(self)
            local itemID = menu.currentItemID
            if not itemID then return end

            if self.action == "never_global" then
                ns.db.neverSellList[itemID] = true
                ns.db.alwaysSellList[itemID] = nil
                ns:Print(format("Added %s to never-sell list (global)", C_Item.GetItemNameByID(itemID) or itemID))
                ns:FlashBagItem(itemID, 0, 1, 0)
            elseif self.action == "never_char" then
                if AutoSellPlusCharDB then
                    AutoSellPlusCharDB.charNeverSellList[itemID] = true
                    AutoSellPlusCharDB.charAlwaysSellList[itemID] = nil
                end
                ns:Print(format("Added %s to never-sell list (this char)", C_Item.GetItemNameByID(itemID) or itemID))
                ns:FlashBagItem(itemID, 0, 1, 0)
            elseif self.action == "always_global" then
                ns.db.alwaysSellList[itemID] = true
                ns.db.neverSellList[itemID] = nil
                ns:Print(format("Added %s to always-sell list (global)", C_Item.GetItemNameByID(itemID) or itemID))
                ns:FlashBagItem(itemID, 0, 1, 0)
            elseif self.action == "always_char" then
                if AutoSellPlusCharDB then
                    AutoSellPlusCharDB.charAlwaysSellList[itemID] = true
                    AutoSellPlusCharDB.charNeverSellList[itemID] = nil
                end
                ns:Print(format("Added %s to always-sell list (this char)", C_Item.GetItemNameByID(itemID) or itemID))
                ns:FlashBagItem(itemID, 0, 1, 0)
            elseif self.action == "remove" then
                ns.db.neverSellList[itemID] = nil
                ns.db.alwaysSellList[itemID] = nil
                if AutoSellPlusCharDB then
                    AutoSellPlusCharDB.charNeverSellList[itemID] = nil
                    AutoSellPlusCharDB.charAlwaysSellList[itemID] = nil
                end
                ns:Print(format("Removed %s from all lists", C_Item.GetItemNameByID(itemID) or itemID))
                ns:FlashBagItem(itemID, 1, 0, 0)
            end

            menu:Hide()
            -- Refresh popup
            displayList = ns:BuildDisplayList()
            ns:ApplyFilters(displayList, userUnchecked)
            ns:RefreshPopupList()
        end)
    end

    menu:SetHeight(2 + #options * 24 + 2)

    -- Close on click elsewhere
    menu:SetScript("OnShow", function()
        menu:SetScript("OnUpdate", function()
            if not menu:IsMouseOver() and not IsMouseButtonDown("RightButton") then
                local elapsed = menu.showTime and (GetTime() - menu.showTime) or 1
                if elapsed > 0.3 then
                    menu:Hide()
                end
            end
        end)
    end)
    menu:SetScript("OnHide", function()
        menu:SetScript("OnUpdate", nil)
    end)

    contextMenu = menu
    return menu
end

local function ShowContextMenu(itemID, anchor)
    local menu = CreateContextMenu()
    menu.currentItemID = itemID
    menu.showTime = GetTime()
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 2, 0)
    menu:Show()
end

-- ============================================================
-- Row Functions
-- ============================================================

local function CreateItemRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)

    -- Alternating row background
    local altBg = row:CreateTexture(nil, "BACKGROUND")
    altBg:SetAllPoints()
    altBg:SetColorTexture(1, 1, 1, 0.03)
    altBg:Hide()
    row.altBg = altBg

    -- Hover highlight
    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.06)

    -- Checkbox
    local check = CreateStyledCheck(row, 18)
    check:SetPoint("LEFT", 4, 0)
    check:SetScript("OnClick", function(self)
        local item = self:GetParent().itemData
        if item then
            item.checked = self:GetChecked()
            local key = item.bag .. ":" .. item.slot
            if not item.checked then
                userUnchecked[key] = true
            else
                userUnchecked[key] = nil
            end
            ns:UpdateTotals()
        end
    end)
    row.check = check

    -- Icon
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("LEFT", check, "RIGHT", 6, 0)
    row.icon = icon

    -- Icon quality border
    local iconBorder = CreateFrame("Frame", nil, row, "BackdropTemplate")
    iconBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
    iconBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
    iconBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    iconBorder:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    iconBorder:EnableMouse(false)
    row.iconBorder = iconBorder

    -- Item name
    local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    name:SetWidth(200)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    row.name = name

    -- Badges (BoE, Marked)
    local badge = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    badge:SetPoint("LEFT", name, "RIGHT", 2, 0)
    badge:SetWidth(40)
    badge:SetJustifyH("LEFT")
    badge:SetTextColor(0.7, 0.7, 0.3)
    row.badge = badge

    -- Item level
    local ilvlText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ilvlText:SetPoint("LEFT", badge, "RIGHT", 2, 0)
    ilvlText:SetWidth(80)
    ilvlText:SetJustifyH("CENTER")
    ilvlText:SetTextColor(0.70, 0.70, 0.70)
    row.ilvlText = ilvlText

    -- AH value column (shown when TSM/Auctionator detected)
    local ahText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ahText:SetPoint("LEFT", ilvlText, "RIGHT", 2, 0)
    ahText:SetWidth(60)
    ahText:SetJustifyH("RIGHT")
    ahText:SetTextColor(0.3, 1, 0.3)
    row.ahText = ahText

    -- Price
    local price = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    price:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    price:SetWidth(80)
    price:SetJustifyH("RIGHT")
    price:SetTextColor(1, 0.82, 0)
    row.price = price

    -- High value warning icon
    local highValueIcon = row:CreateTexture(nil, "OVERLAY")
    highValueIcon:SetSize(14, 14)
    highValueIcon:SetPoint("RIGHT", price, "LEFT", -2, 0)
    highValueIcon:SetTexture("Interface\\Icons\\INV_Misc_Coin_02")
    highValueIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    highValueIcon:Hide()
    row.highValueIcon = highValueIcon

    -- Tooltip on hover + right-click context menu
    row:EnableMouse(true)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnEnter", function(self)
        if self.itemData and self.itemData.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemData.itemLink)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    row:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" and self.itemData then
            ShowContextMenu(self.itemData.itemID, self)
        end
    end)

    return row
end

local hasAHAddon = false

local function SetRowData(row, item)
    row.itemData = item
    row.check:SetChecked(item.checked)

    local _, _, _, _, iconPath = C_Item.GetItemInfoInstant(item.itemID)
    row.icon:SetTexture(iconPath)

    local color = ITEM_QUALITY_COLORS[item.quality]
    local itemName = C_Item.GetItemNameByID(item.itemID) or "?"
    row.name:SetText(itemName)
    if color then
        row.name:SetTextColor(color.r, color.g, color.b)
        row.iconBorder:SetBackdropBorderColor(color.r, color.g, color.b, 0.7)
    else
        row.name:SetTextColor(0.9, 0.9, 0.9)
        row.iconBorder:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    end

    -- Badges
    local badges = {}
    if item.isBoe then badges[#badges + 1] = "|cFFFFCC00BoE|r" end
    if item.isMarked then badges[#badges + 1] = "|cFFFF6600Junk|r" end
    row.badge:SetText(table.concat(badges, " "))

    -- ilvl display
    if item.ilvl and item.ilvl > 0 then
        if item.isEquippable and item.equippedIlvl and item.equippedIlvl > 0 then
            row.ilvlText:SetText(item.ilvl .. " (eq:" .. item.equippedIlvl .. ")")
        else
            row.ilvlText:SetText("ilvl " .. item.ilvl)
        end
        if item.isUpgrade then
            row.ilvlText:SetTextColor(0.1, 1.0, 0.1)
        else
            row.ilvlText:SetTextColor(0.70, 0.70, 0.70)
        end
    else
        row.ilvlText:SetText("")
        row.ilvlText:SetTextColor(0.70, 0.70, 0.70)
    end

    -- AH value
    if hasAHAddon and item.ahValue and item.ahValue > 0 then
        row.ahText:SetText(ns:FormatMoney(item.ahValue))
        if item.ahValue > item.totalPrice * 10 then
            row.ahText:SetTextColor(0.1, 1.0, 0.1)
        elseif item.ahValue > item.totalPrice * 2 then
            row.ahText:SetTextColor(1, 0.82, 0)
        else
            row.ahText:SetTextColor(0.5, 0.5, 0.5)
        end
    else
        row.ahText:SetText("")
    end

    -- Price + high value warning
    row.price:SetText(ns:FormatMoney(item.totalPrice))
    local isHighValue = ns.db.highValueConfirm and item.totalPrice >= ns.db.highValueThreshold
    row.highValueIcon:SetShown(isHighValue)

    row:Show()
end

-- ============================================================
-- List and Total Functions
-- ============================================================

function ns:RefreshPopupList()
    if not popup then return end

    local visibleItems = {}
    for _, item in ipairs(displayList) do
        if item.visible then
            visibleItems[#visibleItems + 1] = item
        end
    end

    ns:SortDisplayItems(visibleItems)

    local scrollChild = popup.scrollChild

    for _, row in ipairs(itemRows) do
        row:Hide()
    end

    for i, item in ipairs(visibleItems) do
        local row = itemRows[i]
        if not row then
            row = CreateItemRow(scrollChild, i)
            itemRows[i] = row
        end
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -(i - 1) * ROW_HEIGHT)
        row.altBg:SetShown(i % 2 == 0)
        SetRowData(row, item)
    end

    scrollChild:SetHeight(math.max(1, #visibleItems * ROW_HEIGHT))
    self:UpdateTotals()
end

function ns:UpdateTotals()
    if not popup then return end

    local totalCopper = 0
    local totalCount = 0
    for _, item in ipairs(displayList) do
        if item.visible and item.checked then
            totalCopper = totalCopper + item.totalPrice
            totalCount = totalCount + 1
        end
    end

    popup.totalText:SetText(format("Total: %s (%d item%s)", self:FormatMoney(totalCopper), totalCount, totalCount == 1 and "" or "s"))
    popup.sellBtn:SetEnabled(totalCount > 0)
    popup.sellAllBtn:SetEnabled(totalCount > 0)

    -- Session counter
    if popup.sessionText and ns.sessionData then
        if ns.sessionData.totalCopper > 0 then
            popup.sessionText:SetText(format("Session: +%s", self:FormatMoney(ns.sessionData.totalCopper)))
            popup.sessionText:Show()
        else
            popup.sessionText:Hide()
        end
    end
end

-- ============================================================
-- Filter Row Builder Helper
-- ============================================================

local function CreateQualityFilterRow(f, filterTop, label, checkKey, sliderKey, editKey, y)
    local check = CreateStyledCheck(f, 18)
    check:SetPoint("TOPLEFT", 14, filterTop + y)
    local checkLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    checkLabel:SetPoint("LEFT", check, "RIGHT", 6, 0)
    checkLabel:SetText(label)
    check:SetScript("OnClick", function(self)
        ns.db[checkKey] = self:GetChecked()
        ns:ApplyFilters(displayList, userUnchecked)
        ns:RefreshPopupList()
    end)

    if sliderKey and editKey then
        local sliderLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        sliderLabel:SetPoint("LEFT", checkLabel, "RIGHT", 12, 0)
        sliderLabel:SetText("ilvl <=")
        sliderLabel:SetTextColor(0.65, 0.65, 0.65)

        local slider = CreateStyledSlider(f, 0, 700, 5)
        slider:SetPoint("LEFT", sliderLabel, "RIGHT", 8, 0)

        local editBox = CreateStyledEditBox(f, 38)
        editBox:SetPoint("LEFT", slider, "RIGHT", 6, 0)

        local function CommitValue(self)
            local val = tonumber(self:GetText()) or 0
            val = math.max(0, math.min(700, val))
            ns.db[sliderKey] = val
            slider:SetValue(val)
            self:SetText(tostring(val))
            self:ClearFocus()
        end

        editBox:SetScript("OnEnterPressed", CommitValue)
        editBox:SetScript("OnTabPressed", CommitValue)
        editBox:SetScript("OnEscapePressed", function(self)
            self:SetText(tostring(ns.db[sliderKey]))
            self:ClearFocus()
        end)

        slider:SetScript("OnValueChanged", function(self, value)
            value = math.floor(value + 0.5)
            ns.db[sliderKey] = value
            editBox:SetText(tostring(value))
            ns:ApplyFilters(displayList, userUnchecked)
            ns:RefreshPopupList()
        end)

        return check, slider, editBox
    end

    return check
end

-- ============================================================
-- Popup Frame — Section Builders
-- ============================================================

local function CreateMainFrame()
    local f = CreateFrame("Frame", "AutoSellPlusPopup", UIParent, "BackdropTemplate")
    f:SetSize(POPUP_WIDTH, POPUP_HEIGHT)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint(1)
        ns.db.popupPoint = point
        ns.db.popupX = x
        ns.db.popupY = y
    end)
    f:SetClampedToScreen(true)

    f:SetBackdrop(FLAT_BACKDROP)
    f:SetBackdropColor(0.06, 0.06, 0.06, 0.96)
    f:SetBackdropBorderColor(0, 0, 0, 1)

    -- Outer subtle border (depth effect)
    local outerBorder = CreateFrame("Frame", nil, f, "BackdropTemplate")
    outerBorder:SetPoint("TOPLEFT", -1, 1)
    outerBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    outerBorder:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1))
    outerBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    outerBorder:SetBackdropBorderColor(0.20, 0.20, 0.20, 0.6)
    outerBorder:EnableMouse(false)

    -- Title bar strip
    local titleBg = f:CreateTexture(nil, "ARTWORK")
    titleBg:SetPoint("TOPLEFT", 1, -1)
    titleBg:SetPoint("TOPRIGHT", -1, -1)
    titleBg:SetHeight(30)
    titleBg:SetColorTexture(0.10, 0.10, 0.10, 0.8)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -8)
    title:SetText("|cFF00CCFFAutoSellPlus|r")
    f.titleText = title

    -- Close button (flat styled)
    local closeBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("TOPRIGHT", -6, -6)
    closeBtn:SetBackdrop(FLAT_BACKDROP)
    closeBtn:SetBackdropColor(0.12, 0.12, 0.12, 1)
    closeBtn:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    local closeLbl = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    closeLbl:SetPoint("CENTER", 0, 0)
    closeLbl:SetText("x")
    closeLbl:SetTextColor(0.60, 0.60, 0.60)
    closeBtn:SetScript("OnClick", function() ns:HidePopup() end)
    closeBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.7, 0.15, 0.15, 1)
        closeLbl:SetTextColor(1, 0.3, 0.3)
    end)
    closeBtn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        closeLbl:SetTextColor(0.60, 0.60, 0.60)
    end)

    -- Ctrl+Scroll to scale
    f:EnableMouseWheel(true)
    f:SetScript("OnMouseWheel", function(self, delta)
        if IsControlKeyDown() then
            local scale = self:GetScale()
            scale = scale + (delta * 0.05)
            scale = math.max(0.6, math.min(1.5, scale))
            self:SetScale(scale)
            ns.db.popupScale = scale
        end
    end)

    -- Fade-in animation
    local fadeIn = f:CreateAnimationGroup()
    local alphaIn = fadeIn:CreateAnimation("Alpha")
    alphaIn:SetFromAlpha(0)
    alphaIn:SetToAlpha(1)
    alphaIn:SetDuration(0.15)
    alphaIn:SetSmoothing("IN")
    fadeIn:SetScript("OnFinished", function()
        f:SetAlpha(1)
    end)
    f.fadeIn = fadeIn

    return f
end

local function CreateFilterSection(f)
    local filterTop = -56
    local filterLeft = 14
    local rowY = 0

    -- Filter section background
    local filterBg = CreateFrame("Frame", nil, f, "BackdropTemplate")
    filterBg:SetPoint("TOPLEFT", 1, filterTop + 2)
    filterBg:SetPoint("TOPRIGHT", -1, filterTop + 2)
    filterBg:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    filterBg:SetBackdropColor(0.04, 0.04, 0.04, 0.5)
    filterBg:EnableMouse(false)
    f.filterBg = filterBg

    -- Quality filter rows
    f.grayCheck = CreateQualityFilterRow(f, filterTop, "Sell Grays", "sellGrays", nil, nil, rowY)
    rowY = rowY - 22

    f.whiteCheck, f.whiteSlider, f.whiteEditBox = CreateQualityFilterRow(f, filterTop, "Sell Whites", "sellWhites", "whiteMaxIlvl", "whiteMaxIlvl", rowY)
    rowY = rowY - 22

    f.greenCheck, f.greenSlider, f.greenEditBox = CreateQualityFilterRow(f, filterTop, "Sell Greens", "sellGreens", "greenMaxIlvl", "greenMaxIlvl", rowY)
    rowY = rowY - 22

    f.blueCheck, f.blueSlider, f.blueEditBox = CreateQualityFilterRow(f, filterTop, "Sell Blues", "sellBlues", "blueMaxIlvl", "blueMaxIlvl", rowY)
    rowY = rowY - 22

    f.epicCheck, f.epicSlider, f.epicEditBox = CreateQualityFilterRow(f, filterTop, "Sell Epics", "sellEpics", "epicMaxIlvl", "epicMaxIlvl", rowY)
    rowY = rowY - 22

    f.equipCheck = CreateQualityFilterRow(f, filterTop, "Only Equippable", "onlyEquippable", nil, nil, rowY)
    rowY = rowY - 22
    rowY = rowY - 4

    -- Allow transmog checkbox (inverted: checked = protection OFF)
    local transmogCheck = CreateStyledCheck(f, 18)
    transmogCheck:SetPoint("TOPLEFT", filterLeft, filterTop + rowY)
    local transmogLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    transmogLabel:SetPoint("LEFT", transmogCheck, "RIGHT", 6, 0)
    transmogLabel:SetText("Allow Transmog")
    transmogLabel:SetTextColor(0.70, 0.70, 0.70)
    transmogCheck:SetScript("OnClick", function(self)
        local allow = self:GetChecked()
        ns.db.protectUncollectedTransmog = not allow
        ns.db.protectTransmogSource = not allow
        displayList = ns:BuildDisplayList()
        ns:ApplyFilters(displayList, userUnchecked)
        ns:RefreshPopupList()
    end)
    f.transmogCheck = transmogCheck
    rowY = rowY - 22

    -- Soulbound only checkbox
    local soulboundCheck = CreateStyledCheck(f, 18)
    soulboundCheck:SetPoint("TOPLEFT", filterLeft, filterTop + rowY)
    local soulboundLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    soulboundLabel:SetPoint("LEFT", soulboundCheck, "RIGHT", 6, 0)
    soulboundLabel:SetText("Soulbound Only")
    soulboundLabel:SetTextColor(0.70, 0.70, 0.70)
    soulboundCheck:SetScript("OnClick", function(self)
        ns.db.onlySoulbound = self:GetChecked()
        displayList = ns:BuildDisplayList()
        ns:ApplyFilters(displayList, userUnchecked)
        ns:RefreshPopupList()
    end)
    f.soulboundCheck = soulboundCheck
    rowY = rowY - 22

    -- Protect mount equipment checkbox
    local mountEquipCheck = CreateStyledCheck(f, 18)
    mountEquipCheck:SetPoint("TOPLEFT", filterLeft, filterTop + rowY)
    local mountEquipLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    mountEquipLabel:SetPoint("LEFT", mountEquipCheck, "RIGHT", 6, 0)
    mountEquipLabel:SetText("Protect Mount Equipment")
    mountEquipLabel:SetTextColor(0.70, 0.70, 0.70)
    mountEquipCheck:SetScript("OnClick", function(self)
        ns.db.protectMountEquipment = self:GetChecked()
        displayList = ns:BuildDisplayList()
        ns:ApplyFilters(displayList, userUnchecked)
        ns:RefreshPopupList()
    end)
    f.mountEquipCheck = mountEquipCheck
    rowY = rowY - 22

    -- Protect warbound checkbox
    local warboundCheck = CreateStyledCheck(f, 18)
    warboundCheck:SetPoint("TOPLEFT", filterLeft, filterTop + rowY)
    local warboundLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    warboundLabel:SetPoint("LEFT", warboundCheck, "RIGHT", 6, 0)
    warboundLabel:SetText("Protect Warbound")
    warboundLabel:SetTextColor(0.70, 0.70, 0.70)
    warboundCheck:SetScript("OnClick", function(self)
        ns.db.protectWarbound = self:GetChecked()
        displayList = ns:BuildDisplayList()
        ns:ApplyFilters(displayList, userUnchecked)
        ns:RefreshPopupList()
    end)
    f.warboundCheck = warboundCheck
    rowY = rowY - 22
    rowY = rowY - 4

    -- Category filters
    local catLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    catLabel:SetPoint("TOPLEFT", filterLeft, filterTop + rowY)
    catLabel:SetText("Categories:")
    catLabel:SetTextColor(0.60, 0.60, 0.60)

    local catX = 80
    local catNames = {
        { key = "sellConsumables", label = "Consum." },
        { key = "sellTradeGoods", label = "Trade" },
        { key = "sellQuestItems", label = "Quest" },
        { key = "sellMiscItems", label = "Misc" },
    }
    f.categoryChecks = {}
    for _, cat in ipairs(catNames) do
        local catCheck = CreateStyledCheck(f, 14)
        catCheck:SetPoint("TOPLEFT", filterLeft + catX, filterTop + rowY + 2)
        local catLbl = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        catLbl:SetPoint("LEFT", catCheck, "RIGHT", 3, 0)
        catLbl:SetText(cat.label)
        catLbl:SetTextColor(0.70, 0.70, 0.70)
        local catKey = cat.key
        catCheck:SetScript("OnClick", function(self)
            ns.db[catKey] = self:GetChecked()
            ns:ApplyFilters(displayList, userUnchecked)
            ns:RefreshPopupList()
        end)
        f.categoryChecks[cat.key] = catCheck
        catX = catX + 70
    end
    rowY = rowY - 22
    rowY = rowY - 4

    -- Expansion filter
    local expLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    expLabel:SetPoint("TOPLEFT", filterLeft, filterTop + rowY)
    expLabel:SetText("Expansion:")
    expLabel:SetTextColor(0.60, 0.60, 0.60)

    local expBtn = CreateFlatButton(f, "All", 80, 18)
    expBtn:SetPoint("LEFT", expLabel, "RIGHT", 8, 0)
    expBtn:SetScript("OnClick", function()
        local current = ns.db.filterExpansion
        current = current + 1
        if current > 12 then current = 0 end
        ns.db.filterExpansion = current
        expBtn.label:SetText(ns.EXPANSION_NAMES[current] or "All")
        ns:ApplyFilters(displayList, userUnchecked)
        ns:RefreshPopupList()
    end)
    f.expBtn = expBtn

    -- Exclude current expansion checkbox
    local exclCurCheck = CreateStyledCheck(f, 14)
    exclCurCheck:SetPoint("LEFT", expBtn, "RIGHT", 8, 0)
    local exclCurLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    exclCurLabel:SetPoint("LEFT", exclCurCheck, "RIGHT", 3, 0)
    exclCurLabel:SetText("Exclude current")
    exclCurLabel:SetTextColor(0.70, 0.70, 0.70)
    exclCurCheck:SetScript("OnClick", function(self)
        ns.db.excludeCurrentExpansion = self:GetChecked()
        ns:ApplyFilters(displayList, userUnchecked)
        ns:RefreshPopupList()
    end)
    f.exclCurCheck = exclCurCheck
    rowY = rowY - 22

    -- Equipment slot filter
    local slotLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    slotLabel:SetPoint("TOPLEFT", filterLeft, filterTop + rowY)
    slotLabel:SetText("Slots:")
    slotLabel:SetTextColor(0.60, 0.60, 0.60)

    local slotBtnX = 50
    local slotIDs = {1, 3, 5, 6, 7, 8, 9, 10, 15, 16, 17}
    local slotShortNames = {
        [1] = "H", [3] = "S", [5] = "C", [6] = "W", [7] = "L",
        [8] = "F", [9] = "Wr", [10] = "G", [15] = "Bk", [16] = "MH", [17] = "OH",
    }
    f.slotButtons = {}
    for _, slotID in ipairs(slotIDs) do
        local slotBtn = CreateFlatButton(f, slotShortNames[slotID] or "?", 24, 18)
        slotBtn:SetPoint("TOPLEFT", filterLeft + slotBtnX, filterTop + rowY)
        slotBtn.slotID = slotID
        slotBtn:SetScript("OnClick", function(self)
            local slots = ns.db.filterSlots
            if slots[slotID] then
                slots[slotID] = nil
                self:SetBackdropColor(0.18, 0.18, 0.18, 1)
                self:SetBackdropBorderColor(0.30, 0.30, 0.30, 1)
            else
                slots[slotID] = true
                self:SetBackdropColor(0.0, 0.30, 0.50, 1)
                self:SetBackdropBorderColor(0.0, 0.45, 0.70, 1)
            end
            ns:ApplyFilters(displayList, userUnchecked)
            ns:RefreshPopupList()
        end)
        slotBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(ns.SLOT_NAMES[slotID] or "Slot " .. slotID)
            GameTooltip:Show()
        end)
        slotBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        f.slotButtons[slotID] = slotBtn
        slotBtnX = slotBtnX + 28
    end
    rowY = rowY - 22

    -- Set filter background height
    local filterHeight = math.abs(rowY) + 6
    filterBg:SetHeight(filterHeight)

    return filterTop + rowY
end

local function CreateItemListSection(f, dividerY)
    local filterLeft = 14

    -- Divider + Avg ilvl
    local divider = f:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT", filterLeft, dividerY - 4)
    divider:SetPoint("RIGHT", f, "RIGHT", -filterLeft, 0)
    divider:SetColorTexture(0.20, 0.20, 0.20, 0.8)

    local avgIlvlText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    avgIlvlText:SetPoint("TOPLEFT", filterLeft, dividerY - 11)
    avgIlvlText:SetTextColor(0.45, 0.70, 0.90)
    f.avgIlvlText = avgIlvlText

    -- Column Headers
    local listTop = dividerY - 26

    local headerBg = f:CreateTexture(nil, "ARTWORK")
    headerBg:SetPoint("TOPLEFT", filterLeft, listTop)
    headerBg:SetPoint("RIGHT", f, "RIGHT", -filterLeft, 0)
    headerBg:SetHeight(18)
    headerBg:SetColorTexture(0.08, 0.08, 0.08, 1)

    local function CreateHeaderButton(text, col, anchorPoint, anchorTo, anchorRelPoint, xOff, width)
        local hdr = CreateFrame("Button", nil, f)
        hdr:SetSize(width, 18)
        hdr:SetPoint(anchorPoint, anchorTo or headerBg, anchorRelPoint or "LEFT", xOff, 0)
        local hdrText = hdr:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hdrText:SetPoint("LEFT")
        hdrText:SetText(text)
        hdrText:SetTextColor(0.70, 0.70, 0.55)
        hdr.hdrText = hdrText
        hdr:SetScript("OnClick", function()
            if ns.sortColumn == col then
                ns.sortDirection = ns.sortDirection == "asc" and "desc" or "asc"
            else
                ns.sortColumn = col
                ns.sortDirection = "asc"
            end
            local arrow = ns.sortDirection == "asc" and " v" or " ^"
            for _, h in ipairs(f.headerButtons) do
                h.hdrText:SetTextColor(0.70, 0.70, 0.55)
                h.hdrText:SetText(h.baseText)
            end
            hdrText:SetText(text .. arrow)
            hdrText:SetTextColor(1, 0.82, 0)
            ns:RefreshPopupList()
        end)
        hdr.baseText = text
        return hdr
    end

    f.headerButtons = {}
    local hdrItem = CreateHeaderButton("Item", "quality", "LEFT", headerBg, "LEFT", 50, 200)
    f.headerButtons[#f.headerButtons + 1] = hdrItem

    local hdrIlvl = CreateHeaderButton("ilvl", "ilvl", "LEFT", headerBg, "LEFT", 290, 80)
    f.headerButtons[#f.headerButtons + 1] = hdrIlvl

    hasAHAddon = (TSM_API ~= nil) or (Auctionator ~= nil)
    if hasAHAddon then
        local hdrAH = CreateHeaderButton("AH", "ah", "LEFT", headerBg, "LEFT", 372, 60)
        f.headerButtons[#f.headerButtons + 1] = hdrAH
    end

    local hdrPrice = CreateHeaderButton("Price", "price", "RIGHT", headerBg, "RIGHT", -6, 80)
    hdrPrice:SetPoint("RIGHT", headerBg, "RIGHT", -6, 0)
    f.headerButtons[#f.headerButtons + 1] = hdrPrice

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", filterLeft, listTop - 18)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 48)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(POPUP_WIDTH - 56, 1)
    scrollFrame:SetScrollChild(scrollChild)
    f.scrollChild = scrollChild
end

local function CreateBottomBar(f)
    local filterLeft = 14

    -- Sell progress bar (above bottom divider)
    local progressBar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    progressBar:SetHeight(14)
    progressBar:SetPoint("BOTTOMLEFT", 1, 45)
    progressBar:SetPoint("BOTTOMRIGHT", -1, 45)
    progressBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
    })
    progressBar:SetBackdropColor(0.10, 0.10, 0.10, 0.8)

    local progressFill = progressBar:CreateTexture(nil, "ARTWORK")
    progressFill:SetPoint("TOPLEFT")
    progressFill:SetPoint("BOTTOMLEFT")
    progressFill:SetWidth(0)
    progressFill:SetColorTexture(0.0, 0.45, 0.80, 0.8)
    progressBar.fill = progressFill

    local progressText = progressBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    progressText:SetPoint("CENTER")
    progressText:SetTextColor(1, 1, 1)
    progressBar.text = progressText

    progressBar:Hide()
    f.progressBar = progressBar

    -- Bottom divider
    local bottomDiv = f:CreateTexture(nil, "ARTWORK")
    bottomDiv:SetHeight(1)
    bottomDiv:SetPoint("BOTTOMLEFT", 1, 44)
    bottomDiv:SetPoint("BOTTOMRIGHT", -1, 44)
    bottomDiv:SetColorTexture(0.15, 0.15, 0.15, 1)

    local totalText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    totalText:SetPoint("BOTTOMLEFT", filterLeft, 16)
    totalText:SetText("Total: 0c (0 items)")
    totalText:SetTextColor(0.85, 0.85, 0.85)
    f.totalText = totalText

    -- Session counter (right of total)
    local sessionText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sessionText:SetPoint("LEFT", totalText, "RIGHT", 12, 0)
    sessionText:SetTextColor(0.5, 0.8, 0.5)
    sessionText:Hide()
    f.sessionText = sessionText

    -- Drag-to-sell button
    local dropBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    dropBtn:SetSize(28, 28)
    dropBtn:SetPoint("BOTTOMLEFT", 10, 9)
    dropBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    dropBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    dropBtn:SetBackdropBorderColor(0.30, 0.30, 0.30, 1)

    local dropIcon = dropBtn:CreateTexture(nil, "ARTWORK")
    dropIcon:SetSize(18, 18)
    dropIcon:SetPoint("CENTER")
    dropIcon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
    dropIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local function HandleDrop()
        if not CursorHasItem() then return end
        local infoType, itemID = GetCursorInfo()
        if infoType ~= "item" or not itemID then
            ClearCursor()
            return
        end
        -- Find the item in bags and sell it
        for bag = 0, ns:GetMaxBagID() do
            local numSlots = C_Container.GetContainerNumSlots(bag)
            for slot = 1, numSlots do
                local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
                if itemInfo and itemInfo.itemID == itemID then
                    local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(itemInfo.hyperlink or "")
                    if sellPrice and sellPrice > 0 then
                        C_Container.UseContainerItem(bag, slot)
                        local totalPrice = sellPrice * (itemInfo.stackCount or 1)
                        ns:SafeCall(function()
                            ns:RecordSale(itemInfo.hyperlink, itemID, itemInfo.stackCount or 1, totalPrice)
                        end)
                        ns:SafeCall(function()
                            ns:UpdateSession(itemInfo.stackCount or 1, totalPrice)
                        end)
                        ns:Print(format("Sold %s for %s", itemInfo.hyperlink or "?", ns:FormatMoney(totalPrice)))
                    end
                    ClearCursor()
                    -- Refresh popup
                    displayList = ns:BuildDisplayList()
                    ns:ApplyFilters(displayList, userUnchecked)
                    ns:RefreshPopupList()
                    return
                end
            end
        end
        ClearCursor()
    end

    dropBtn:SetScript("OnReceiveDrag", HandleDrop)
    dropBtn:SetScript("OnMouseUp", HandleDrop)
    dropBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.50, 0.50, 0.50, 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Drop to Sell")
        GameTooltip:AddLine("Drag an item here to sell it instantly.", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    dropBtn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.30, 0.30, 0.30, 1)
        GameTooltip:Hide()
    end)
    f.dropBtn = dropBtn

    -- Shift totalText to the right of drop button
    totalText:ClearAllPoints()
    totalText:SetPoint("LEFT", dropBtn, "RIGHT", 8, 0)

    -- Sell button (accent style)
    local sellBtn = CreateFlatButton(f, "Sell Selected", 100, 26)
    sellBtn:SetPoint("BOTTOMRIGHT", -10, 10)
    sellBtn:SetBackdropColor(0.0, 0.30, 0.50, 1)
    sellBtn:SetBackdropBorderColor(0.0, 0.45, 0.70, 1)
    sellBtn:SetScript("OnEnter", function(self)
        if self:IsEnabled() then
            self:SetBackdropColor(0.0, 0.40, 0.65, 1)
            self:SetBackdropBorderColor(0.0, 0.55, 0.90, 1)
        end
    end)
    sellBtn:SetScript("OnLeave", function(self)
        if self:IsEnabled() then
            self:SetBackdropColor(0.0, 0.30, 0.50, 1)
            self:SetBackdropBorderColor(0.0, 0.45, 0.70, 1)
        end
    end)
    sellBtn:SetScript("OnMouseDown", function(self)
        if self:IsEnabled() then
            self:SetBackdropColor(0.0, 0.20, 0.35, 1)
        end
    end)
    sellBtn:SetScript("OnMouseUp", function(self)
        if self:IsEnabled() then
            self:SetBackdropColor(0.0, 0.40, 0.65, 1)
        end
    end)
    sellBtn:SetScript("OnClick", function() ns:SellFromPopup() end)
    f.sellBtn = sellBtn

    -- Sell All Junk button
    local sellAllBtn = CreateFlatButton(f, "Sell All Junk", 90, 26)
    sellAllBtn:SetPoint("RIGHT", sellBtn, "LEFT", -4, 0)
    sellAllBtn:SetBackdropColor(0.35, 0.15, 0.0, 1)
    sellAllBtn:SetBackdropBorderColor(0.50, 0.25, 0.0, 1)
    sellAllBtn:SetScript("OnEnter", function(self)
        if self:IsEnabled() then
            self:SetBackdropColor(0.45, 0.20, 0.0, 1)
            self:SetBackdropBorderColor(0.60, 0.30, 0.0, 1)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine("Sell All Junk")
            local counts = {}
            local coppers = {}
            for _, item in ipairs(displayList) do
                if item.visible and item.checked then
                    local q = item.quality
                    counts[q] = (counts[q] or 0) + 1
                    coppers[q] = (coppers[q] or 0) + item.totalPrice
                end
            end
            for q = 0, 4 do
                if counts[q] then
                    local color = ITEM_QUALITY_COLORS[q]
                    local qName = _G["ITEM_QUALITY" .. q .. "_DESC"] or ("Quality " .. q)
                    if color then
                        GameTooltip:AddDoubleLine(qName .. ": " .. counts[q], ns:FormatMoney(coppers[q]), color.r, color.g, color.b, 1, 0.82, 0)
                    end
                end
            end
            GameTooltip:Show()
        end
    end)
    sellAllBtn:SetScript("OnLeave", function(self)
        if self:IsEnabled() then
            self:SetBackdropColor(0.35, 0.15, 0.0, 1)
            self:SetBackdropBorderColor(0.50, 0.25, 0.0, 1)
        end
        GameTooltip:Hide()
    end)
    sellAllBtn:SetScript("OnClick", function()
        for _, item in ipairs(displayList) do
            if item.visible then
                if item.quality == Enum.ItemQuality.Poor or item.isMarked then
                    item.checked = true
                    local key = item.bag .. ":" .. item.slot
                    userUnchecked[key] = nil
                end
            end
        end
        ns:RefreshPopupList()

        -- Calculate totals for confirmation
        local totalCopper = 0
        local totalCount = 0
        for _, item in ipairs(displayList) do
            if item.visible and item.checked then
                totalCopper = totalCopper + item.totalPrice
                totalCount = totalCount + 1
            end
        end

        if totalCount == 0 then return end

        StaticPopupDialogs["ASP_SELL_ALL_CONFIRM"] = {
            text = format("AutoSellPlus: Sell %d item%s for %s?",
                totalCount, totalCount == 1 and "" or "s", ns:FormatMoney(totalCopper)),
            button1 = "Sell",
            button2 = "Cancel",
            OnAccept = function()
                ns:SellFromPopup()
            end,
            OnCancel = function()
                for _, item in ipairs(displayList) do
                    if item.visible then
                        item.checked = false
                        local key = item.bag .. ":" .. item.slot
                        userUnchecked[key] = true
                    end
                end
                ns:RefreshPopupList()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("ASP_SELL_ALL_CONFIRM")
    end)
    f.sellAllBtn = sellAllBtn

    local cancelBtn = CreateFlatButton(f, "Cancel", 60, 26)
    cancelBtn:SetPoint("RIGHT", sellAllBtn, "LEFT", -4, 0)
    cancelBtn:SetScript("OnClick", function() ns:HidePopup() end)

    local deselectBtn = CreateFlatButton(f, "None", 50, 26)
    deselectBtn:SetPoint("RIGHT", cancelBtn, "LEFT", -4, 0)
    deselectBtn:SetScript("OnClick", function()
        for _, item in ipairs(displayList) do
            if item.visible then
                item.checked = false
                local key = item.bag .. ":" .. item.slot
                userUnchecked[key] = true
            end
        end
        ns:RefreshPopupList()
    end)

    local selectBtn = CreateFlatButton(f, "All", 40, 26)
    selectBtn:SetPoint("RIGHT", deselectBtn, "LEFT", -4, 0)
    selectBtn:SetScript("OnClick", function()
        for _, item in ipairs(displayList) do
            if item.visible then
                item.checked = true
                local key = item.bag .. ":" .. item.slot
                userUnchecked[key] = nil
            end
        end
        ns:RefreshPopupList()
    end)
end

-- ============================================================
-- Sync Filter Controls from DB
-- ============================================================

local function SyncFiltersFromDB(f)
    f.grayCheck:SetChecked(ns.db.sellGrays)
    if f.whiteCheck then f.whiteCheck:SetChecked(ns.db.sellWhites) end
    f.greenCheck:SetChecked(ns.db.sellGreens)
    f.blueCheck:SetChecked(ns.db.sellBlues)
    if f.epicCheck then f.epicCheck:SetChecked(ns.db.sellEpics) end
    f.equipCheck:SetChecked(ns.db.onlyEquippable)
    f.transmogCheck:SetChecked(not ns.db.protectUncollectedTransmog)
    f.soulboundCheck:SetChecked(ns.db.onlySoulbound)
    f.mountEquipCheck:SetChecked(ns.db.protectMountEquipment)
    f.warboundCheck:SetChecked(ns.db.protectWarbound)

    if f.whiteSlider then
        f.whiteSlider:SetValue(ns.db.whiteMaxIlvl)
        f.whiteEditBox:SetText(tostring(ns.db.whiteMaxIlvl))
    end
    f.greenSlider:SetValue(ns.db.greenMaxIlvl)
    f.greenEditBox:SetText(tostring(ns.db.greenMaxIlvl))
    f.blueSlider:SetValue(ns.db.blueMaxIlvl)
    f.blueEditBox:SetText(tostring(ns.db.blueMaxIlvl))
    if f.epicSlider then
        f.epicSlider:SetValue(ns.db.epicMaxIlvl)
        f.epicEditBox:SetText(tostring(ns.db.epicMaxIlvl))
    end

    if f.categoryChecks then
        for key, check in pairs(f.categoryChecks) do
            check:SetChecked(ns.db[key])
        end
    end

    if f.expBtn then
        f.expBtn.label:SetText(ns.EXPANSION_NAMES[ns.db.filterExpansion] or "All")
    end

    if f.exclCurCheck then
        f.exclCurCheck:SetChecked(ns.db.excludeCurrentExpansion)
    end

    if f.slotButtons then
        local filterSlots = ns.db.filterSlots or {}
        for slotID, btn in pairs(f.slotButtons) do
            if filterSlots[slotID] then
                btn:SetBackdropColor(0.0, 0.30, 0.50, 1)
                btn:SetBackdropBorderColor(0.0, 0.45, 0.70, 1)
            else
                btn:SetBackdropColor(0.18, 0.18, 0.18, 1)
                btn:SetBackdropBorderColor(0.30, 0.30, 0.30, 1)
            end
        end
    end
end

-- ============================================================
-- Settings Tab Helpers
-- ============================================================

local function CreateSettingsSection(parent, title, controls, y)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 14, y)
    header:SetText("|cFF00CCFF" .. title .. "|r")
    y = y - 20

    for _, ctrl in ipairs(controls) do
        if ctrl.type == "check" then
            local check = CreateStyledCheck(parent, 14)
            check:SetPoint("TOPLEFT", 14, y)
            local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            label:SetPoint("LEFT", check, "RIGHT", 4, 0)
            label:SetText(ctrl.label)
            label:SetTextColor(0.80, 0.80, 0.80)
            local key = ctrl.key
            check:SetScript("OnClick", function(self)
                ns.db[key] = self:GetChecked()
            end)
            ctrl.widget = check
            y = y - 22

        elseif ctrl.type == "slider" then
            local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            label:SetPoint("TOPLEFT", 14, y)
            label:SetText(ctrl.label)
            label:SetTextColor(0.80, 0.80, 0.80)

            local slider = CreateStyledSlider(parent, ctrl.min, ctrl.max, ctrl.step)
            slider:SetPoint("TOPLEFT", 200, y + 2)

            local editBox = CreateStyledEditBox(parent, 40)
            editBox:SetPoint("LEFT", slider, "RIGHT", 6, 0)

            if ctrl.gold then
                local goldLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                goldLabel:SetPoint("LEFT", editBox, "RIGHT", 2, 0)
                goldLabel:SetText("g")
                goldLabel:SetTextColor(1, 0.82, 0)
            end

            local key = ctrl.key
            local isGold = ctrl.gold

            local function CommitSliderValue(self)
                local val = tonumber(self:GetText()) or 0
                val = math.max(ctrl.min, math.min(ctrl.max, val))
                if isGold then
                    ns.db[key] = val * 10000
                else
                    ns.db[key] = val
                end
                slider:SetValue(val)
                self:SetText(tostring(val))
                self:ClearFocus()
            end

            editBox:SetScript("OnEnterPressed", CommitSliderValue)
            editBox:SetScript("OnTabPressed", CommitSliderValue)
            editBox:SetScript("OnEscapePressed", function(self)
                local val = isGold and math.floor(ns.db[key] / 10000) or ns.db[key]
                self:SetText(tostring(val))
                self:ClearFocus()
            end)

            slider:SetScript("OnValueChanged", function(self, value)
                value = math.floor(value + 0.5)
                if isGold then
                    ns.db[key] = value * 10000
                else
                    ns.db[key] = value
                end
                editBox:SetText(tostring(value))
            end)

            ctrl.widget = slider
            ctrl.editWidget = editBox
            y = y - 22

        elseif ctrl.type == "cycle" then
            local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            label:SetPoint("TOPLEFT", 14, y)
            label:SetText(ctrl.label)
            label:SetTextColor(0.80, 0.80, 0.80)

            local btn = CreateFlatButton(parent, "", 120, 18)
            btn:SetPoint("TOPLEFT", 200, y)

            local key = ctrl.key
            local options = ctrl.options

            local function UpdateCycleLabel()
                local current = ns.db[key]
                for _, opt in ipairs(options) do
                    if opt[1] == current then
                        btn.label:SetText(opt[2])
                        return
                    end
                end
                btn.label:SetText(tostring(current))
            end

            btn:SetScript("OnClick", function()
                local current = ns.db[key]
                local nextIdx = 1
                for i, opt in ipairs(options) do
                    if opt[1] == current then
                        nextIdx = (i % #options) + 1
                        break
                    end
                end
                ns.db[key] = options[nextIdx][1]
                UpdateCycleLabel()
            end)

            ctrl.widget = btn
            ctrl.updateLabel = UpdateCycleLabel
            y = y - 22
        end
    end

    return y - 6
end

local function SyncSettingsControls(overlay)
    for _, section in ipairs(overlay.sections) do
        for _, ctrl in ipairs(section.controls) do
            if ctrl.type == "check" and ctrl.widget then
                ctrl.widget:SetChecked(ns.db[ctrl.key])
            elseif ctrl.type == "slider" and ctrl.widget then
                local val = ctrl.gold and math.floor(ns.db[ctrl.key] / 10000) or ns.db[ctrl.key]
                ctrl.widget:SetValue(val)
                if ctrl.editWidget then
                    ctrl.editWidget:SetText(tostring(val))
                end
            elseif ctrl.type == "cycle" and ctrl.updateLabel then
                ctrl.updateLabel()
            end
        end
    end
end

local function CreateSettingsOverlay(f)
    local overlay = CreateFrame("Frame", nil, f, "BackdropTemplate")
    overlay:SetPoint("TOPLEFT", 1, -54)
    overlay:SetPoint("BOTTOMRIGHT", -1, 1)
    overlay:EnableMouse(true)
    overlay:SetBackdrop(FLAT_BACKDROP)
    overlay:SetBackdropColor(0.06, 0.06, 0.06, 0.96)
    overlay:SetBackdropBorderColor(0, 0, 0, 0)
    overlay:SetFrameLevel(f:GetFrameLevel() + 10)
    overlay:Hide()

    local scrollFrame = CreateFrame("ScrollFrame", nil, overlay, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -24, 0)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(POPUP_WIDTH - 50)
    scrollFrame:SetScrollChild(scrollChild)

    local sections = {
        {
            title = "General",
            controls = {
                { type = "check", key = "enabled", label = "Enable AutoSellPlus" },
                { type = "check", key = "showSummary", label = "Show Summary" },
                { type = "check", key = "showItemized", label = "Show Itemized Sales" },
                { type = "check", key = "dryRun", label = "Dry Run Mode" },
            },
        },
        {
            title = "Automation",
            controls = {
                { type = "cycle", key = "autoSellMode", label = "Auto-Sell Mode",
                  options = { {"popup", "Review Popup"}, {"oneclick", "One-Click"}, {"autosell", "Automatic"} } },
                { type = "slider", key = "autoSellDelay", label = "Auto-Sell Delay (sec)", min = 0, max = 10, step = 1 },
                { type = "check", key = "autoRepair", label = "Auto-Repair" },
                { type = "check", key = "autoRepairGuild", label = "Use Guild Funds" },
                { type = "check", key = "muteVendorSounds", label = "Mute Vendor Sounds" },
                { type = "check", key = "prioritySellQueue", label = "Priority Sell Queue" },
            },
        },
        {
            title = "Protection",
            controls = {
                { type = "check", key = "protectEquipmentSets", label = "Protect Equipment Sets" },
                { type = "check", key = "protectUncollectedTransmog", label = "Protect Uncollected Transmog" },
                { type = "check", key = "protectTransmogSource", label = "Protect Transmog Sources" },
                { type = "check", key = "protectBoE", label = "Protect BoE Items" },
                { type = "check", key = "allowBoESell", label = "Allow BoE Selling (Override)" },
                { type = "check", key = "onlySoulbound", label = "Soulbound Only Mode" },
                { type = "check", key = "onlyEquippable", label = "Only Equippable Items" },
                { type = "check", key = "buybackWarning", label = "Buyback Warning" },
                { type = "check", key = "epicConfirm", label = "Confirm Epic Sales" },
                { type = "check", key = "highValueConfirm", label = "Confirm High-Value Sales" },
                { type = "slider", key = "highValueThreshold", label = "High-Value Threshold",
                  min = 0, max = 100, step = 1, gold = true },
                { type = "check", key = "excludeCurrentExpansion", label = "Exclude Current Expansion" },
                { type = "check", key = "protectCurrentExpMaterials", label = "Protect Current Exp. Materials" },
                { type = "check", key = "protectQuestItems", label = "Protect Quest Items" },
            },
        },
        {
            title = "Marking",
            controls = {
                { type = "check", key = "autoMarkGrayLoot", label = "Auto-Mark Gray Loot" },
                { type = "slider", key = "autoMarkBelowIlvl", label = "Auto-Mark Below ilvl",
                  min = 0, max = 700, step = 5 },
                { type = "cycle", key = "overlayMode", label = "Overlay Visual Mode",
                  options = { {"border", "Border"}, {"tint", "Tint"}, {"full", "Border + Tint"} } },
                { type = "check", key = "showBagGoldDisplay", label = "Show Bag Gold Display" },
            },
        },
        {
            title = "Display",
            controls = {
                { type = "check", key = "showUndoToast", label = "Show Undo Toast" },
                { type = "check", key = "showMinimapButton", label = "Show Minimap Button" },
            },
        },
        {
            title = "Bag Maintenance",
            controls = {
                { type = "slider", key = "freeSlotThreshold", label = "Free Slot Threshold",
                  min = 0, max = 50, step = 1 },
                { type = "cycle", key = "freeSlotAlertMode", label = "Alert Mode",
                  options = { {"chat", "Chat"}, {"screen", "Screen"} } },
                { type = "check", key = "evictionEnabled", label = "Value-Based Eviction" },
            },
        },
        {
            title = "Auto-Destroy",
            controls = {
                { type = "check", key = "autoDestroyEnabled", label = "Enable Auto-Destroy" },
                { type = "check", key = "autoDestroyConfirm", label = "Require Confirmation" },
                { type = "cycle", key = "autoDestroyMaxQuality", label = "Max Destroy Quality",
                  options = { {0, "Poor"}, {1, "Common"}, {2, "Uncommon"}, {3, "Rare"}, {4, "Epic"} } },
                { type = "slider", key = "autoDestroyMaxValue", label = "Max Destroy Value",
                  min = 0, max = 100, step = 1, gold = true },
            },
        },
    }

    local y = -10
    for _, section in ipairs(sections) do
        y = CreateSettingsSection(scrollChild, section.title, section.controls, y)
    end

    scrollChild:SetHeight(math.abs(y) + 10)
    overlay.sections = sections

    return overlay
end

-- ============================================================
-- Assembled Popup Frame
-- ============================================================

local function CreatePopupFrame()
    local f = CreateMainFrame()

    -- Tab buttons
    local itemsTab = CreateFrame("Button", nil, f, "BackdropTemplate")
    itemsTab:SetSize(80, 22)
    itemsTab:SetPoint("TOPLEFT", 14, -32)
    itemsTab:SetBackdrop(FLAT_BACKDROP)
    local itemsTabLabel = itemsTab:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    itemsTabLabel:SetPoint("CENTER")
    itemsTabLabel:SetText("Items")
    itemsTab.label = itemsTabLabel
    f.itemsTab = itemsTab

    local settingsTab = CreateFrame("Button", nil, f, "BackdropTemplate")
    settingsTab:SetSize(80, 22)
    settingsTab:SetPoint("LEFT", itemsTab, "RIGHT", 4, 0)
    settingsTab:SetBackdrop(FLAT_BACKDROP)
    local settingsTabLabel = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    settingsTabLabel:SetPoint("CENTER")
    settingsTabLabel:SetText("Settings")
    settingsTab.label = settingsTabLabel
    f.settingsTab = settingsTab

    -- Filter section, item list, bottom bar
    local filterEndY = CreateFilterSection(f)
    CreateItemListSection(f, filterEndY)
    CreateBottomBar(f)

    -- Settings overlay
    local settingsOverlay = CreateSettingsOverlay(f)
    f.settingsOverlay = settingsOverlay

    -- Tab switching
    local function SetActiveTab(tab)
        f.activeTab = tab
        if tab == "items" then
            settingsOverlay:Hide()
            itemsTab:SetBackdropColor(0.0, 0.30, 0.50, 1)
            itemsTab:SetBackdropBorderColor(0.0, 0.45, 0.70, 1)
            itemsTabLabel:SetTextColor(1, 1, 1)
            settingsTab:SetBackdropColor(0.12, 0.12, 0.12, 1)
            settingsTab:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
            settingsTabLabel:SetTextColor(0.60, 0.60, 0.60)
        else
            settingsOverlay:Show()
            SyncSettingsControls(settingsOverlay)
            settingsTab:SetBackdropColor(0.0, 0.30, 0.50, 1)
            settingsTab:SetBackdropBorderColor(0.0, 0.45, 0.70, 1)
            settingsTabLabel:SetTextColor(1, 1, 1)
            itemsTab:SetBackdropColor(0.12, 0.12, 0.12, 1)
            itemsTab:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
            itemsTabLabel:SetTextColor(0.60, 0.60, 0.60)
        end
    end

    itemsTab:SetScript("OnClick", function()
        if f.activeTab ~= "items" then
            SetActiveTab("items")
            SyncFiltersFromDB(f)
            displayList = ns:BuildDisplayList()
            ns:ApplyFilters(displayList, userUnchecked)
            ns:RefreshPopupList()
        end
    end)
    settingsTab:SetScript("OnClick", function()
        if f.activeTab ~= "settings" then
            SetActiveTab("settings")
        end
    end)

    -- Hover effects for inactive tabs
    itemsTab:SetScript("OnEnter", function(self)
        if f.activeTab ~= "items" then
            self:SetBackdropColor(0.18, 0.18, 0.18, 1)
        end
    end)
    itemsTab:SetScript("OnLeave", function(self)
        if f.activeTab ~= "items" then
            self:SetBackdropColor(0.12, 0.12, 0.12, 1)
        end
    end)
    settingsTab:SetScript("OnEnter", function(self)
        if f.activeTab ~= "settings" then
            self:SetBackdropColor(0.18, 0.18, 0.18, 1)
        end
    end)
    settingsTab:SetScript("OnLeave", function(self)
        if f.activeTab ~= "settings" then
            self:SetBackdropColor(0.12, 0.12, 0.12, 1)
        end
    end)

    f.SetActiveTab = SetActiveTab
    SetActiveTab("items")

    tinsert(UISpecialFrames, "AutoSellPlusPopup")
    f:Hide()
    return f
end

-- ============================================================
-- Show / Hide / Sell
-- ============================================================

function ns:ShowPopup()
    if not self.db.enabled then return end

    if not popup then
        popup = CreatePopupFrame()
        if self.db.popupPoint then
            popup:ClearAllPoints()
            popup:SetPoint(self.db.popupPoint, UIParent, self.db.popupPoint, self.db.popupX or 0, self.db.popupY or 0)
        end
        if self.db.popupScale then
            popup:SetScale(self.db.popupScale)
        end
    end

    -- Vendor mount badge
    if self:IsVendorMount() then
        popup.titleText:SetText("|cFF00CCFFAutoSellPlus|r |cFFFFCC00[Mount Vendor]|r")
    else
        popup.titleText:SetText("|cFF00CCFFAutoSellPlus|r")
    end

    -- Reset to Items tab and sync filter controls
    popup.SetActiveTab("items")
    SyncFiltersFromDB(popup)

    wipe(userUnchecked)

    local ilvls, avgIlvl, minIlvl = self:GetEquippedIlvls()
    self._equippedIlvls = ilvls
    popup.avgIlvlText:SetText("Avg Equipped ilvl: " .. avgIlvl)

    local smartDefault = math.max(0, math.min(avgIlvl, minIlvl) - 10)
    if smartDefault > 0 then
        if self.db.greenMaxIlvl == 0 then
            self.db.greenMaxIlvl = smartDefault
            popup.greenSlider:SetValue(smartDefault)
            popup.greenEditBox:SetText(tostring(smartDefault))
        end
        if self.db.blueMaxIlvl == 0 then
            self.db.blueMaxIlvl = smartDefault
            popup.blueSlider:SetValue(smartDefault)
            popup.blueEditBox:SetText(tostring(smartDefault))
        end
    end

    displayList = self:BuildDisplayList()
    self:ApplyFilters(displayList, userUnchecked)
    self:RefreshPopupList()

    -- Eviction / reclaim space mode
    if self.db.evictionEnabled and ns:CountFreeSlots() == 0 then
        ns.sortColumn = "price"
        ns.sortDirection = "asc"
        for _, item in ipairs(displayList) do
            if item.visible then
                item.checked = true
                local key = item.bag .. ":" .. item.slot
                userUnchecked[key] = nil
            end
        end
        self:RefreshPopupList()
        popup.titleText:SetText("|cFF00CCFFAutoSellPlus|r |cFFFF6600[Reclaim Space]|r")
    end

    popup:SetAlpha(0)
    popup:Show()
    popup.fadeIn:Play()
end

function ns:HidePopup()
    if popup then
        popup:Hide()
    end
    if contextMenu then
        contextMenu:Hide()
    end
end

ns.sellProgress = { current = 0, total = 0 }

function ns:UpdateSellProgress()
    if not popup or not popup.progressBar then return end
    local bar = popup.progressBar
    local p = self.sellProgress
    if p.total <= 0 then
        bar:Hide()
        return
    end
    local pct = p.current / p.total
    local barWidth = bar:GetWidth()
    if barWidth <= 0 then barWidth = POPUP_WIDTH - 2 end
    bar.fill:SetWidth(math.max(1, barWidth * pct))
    bar.text:SetText(format("%d / %d", p.current, p.total))
    bar:Show()
end

function ns:HideSellProgress()
    if popup and popup.progressBar then
        popup.progressBar:Hide()
    end
    self.sellProgress.current = 0
    self.sellProgress.total = 0
end

-- Flash sell button green (verified) or red (items removed)
local function FlashSellButton(success)
    if not popup or not popup.sellBtn then return end
    local btn = popup.sellBtn
    local r, g, b = 0.1, 0.8, 0.1
    if not success then r, g, b = 0.8, 0.1, 0.1 end

    btn:SetBackdropColor(r, g, b, 1)
    btn:SetBackdropBorderColor(r + 0.2, g + 0.2, b + 0.2, 1)

    local flashGroup = btn:CreateAnimationGroup()
    local fadeOut = flashGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0.4)
    fadeOut:SetDuration(0.2)
    fadeOut:SetOrder(1)
    local fadeIn = flashGroup:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.4)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.2)
    fadeIn:SetOrder(2)
    flashGroup:SetScript("OnFinished", function()
        btn:SetBackdropColor(0.0, 0.30, 0.50, 1)
        btn:SetBackdropBorderColor(0.0, 0.45, 0.70, 1)
        btn:SetAlpha(1)
    end)
    flashGroup:Play()
end

function ns:SellFromPopup()
    local queue = {}
    local hasEpics = false
    local highValueItems = {}

    for _, item in ipairs(displayList) do
        if item.visible and item.checked then
            queue[#queue + 1] = {
                bag = item.bag,
                slot = item.slot,
                itemLink = item.itemLink,
                itemID = item.itemID,
                sellPrice = item.sellPrice,
                stackCount = item.stackCount,
                totalPrice = item.totalPrice,
            }
            if item.quality == Enum.ItemQuality.Epic then
                hasEpics = true
            end
            if item.totalPrice >= (self.db.highValueThreshold or 50000) then
                highValueItems[#highValueItems + 1] = item
            end
        end
    end

    if #queue == 0 then return end

    local beforeCount = #queue
    FlashSellButton(beforeCount > 0)

    -- Epic confirmation
    if hasEpics and self.db.epicConfirm then
        StaticPopupDialogs["ASP_EPIC_CONFIRM"] = {
            text = "AutoSellPlus: You are about to sell EPIC quality items. Continue?",
            button1 = "Sell",
            button2 = "Cancel",
            OnAccept = function()
                self:HidePopup()
                self:StartSelling(queue)
            end,
            OnHide = function()
                ns:HideConfirmList()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        local dialog = StaticPopup_Show("ASP_EPIC_CONFIRM")
        if dialog then
            self:ShowConfirmList(queue, dialog)
        end
        return
    end

    -- High value confirmation
    if #highValueItems > 0 and self.db.highValueConfirm then
        local topItems = {}
        table.sort(highValueItems, function(a, b) return a.totalPrice > b.totalPrice end)
        for i = 1, math.min(3, #highValueItems) do
            topItems[#topItems + 1] = format("%s (%s)", highValueItems[i].itemLink, self:FormatMoney(highValueItems[i].totalPrice))
        end

        StaticPopupDialogs["ASP_HIGH_VALUE_CONFIRM"] = {
            text = "AutoSellPlus: Selling high-value items:\n" .. table.concat(topItems, "\n") .. "\n\nContinue?",
            button1 = "Sell",
            button2 = "Cancel",
            OnAccept = function()
                self:HidePopup()
                self:StartSelling(queue)
            end,
            OnHide = function()
                ns:HideConfirmList()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        local dialog = StaticPopup_Show("ASP_HIGH_VALUE_CONFIRM")
        if dialog then
            self:ShowConfirmList(queue, dialog)
        end
        return
    end

    self:HidePopup()
    self:StartSelling(queue)
end
