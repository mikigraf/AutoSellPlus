local addonName, ns = ...

-- Layout constants
local ROW_HEIGHT = 28
local POPUP_WIDTH = 540
local POPUP_HEIGHT = 500

-- Flat 1px border backdrop (ElvUI style)
local FLAT_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

local popup = nil
local itemRows = {}
local displayList = {}
local userUnchecked = {}

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
    slider:SetSize(130, 14)
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
-- Data Functions
-- ============================================================

function ns:BuildDisplayList()
    local list = {}
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo then
                local itemID = itemInfo.itemID
                local itemLink = itemInfo.hyperlink
                local quality = itemInfo.quality
                local isLocked = itemInfo.isLocked
                local hasNoValue = itemInfo.hasNoValue
                local stackCount = itemInfo.stackCount or 1

                if itemID and itemLink then
                    local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(itemLink)
                    local isAlwaysSell = self.db.alwaysSellList[itemID]

                    if not self.db.neverSellList[itemID]
                        and not isLocked
                        and not self:IsRefundable(bag, slot)
                        and (sellPrice and sellPrice > 0 or isAlwaysSell)
                        and not hasNoValue
                        and not (self.db.protectEquipmentSets and self:IsInEquipmentSet(itemID))
                        and not (self.db.protectUncollectedTransmog and self:IsEquippable(itemID) and self:IsUncollectedTransmog(itemID))
                    then
                        local ilvl = self:GetEffectiveItemLevel(itemLink)
                        local isEquippable = self:IsEquippable(itemID)
                        local equippedIlvl = isEquippable and self:GetEquippedIlvlForItem(itemID) or 0
                        list[#list + 1] = {
                            bag = bag,
                            slot = slot,
                            itemID = itemID,
                            itemLink = itemLink,
                            quality = quality,
                            ilvl = ilvl,
                            equippedIlvl = equippedIlvl,
                            sellPrice = sellPrice or 0,
                            stackCount = stackCount,
                            totalPrice = (sellPrice or 0) * stackCount,
                            isEquippable = isEquippable,
                            isAlwaysSell = isAlwaysSell,
                            checked = false,
                            visible = false,
                        }
                    end
                end
            end
        end
    end
    return list
end

function ns:ApplyFilters()
    local db = self.db
    for _, item in ipairs(displayList) do
        local visible = false
        local autoChecked = false

        item.isUpgrade = item.isEquippable and item.equippedIlvl > 0 and item.ilvl > item.equippedIlvl

        if item.isAlwaysSell then
            visible = true
            autoChecked = true
        elseif item.quality == Enum.ItemQuality.Poor then
            if db.sellGrays then
                visible = true
                autoChecked = true
            end
        elseif item.quality == Enum.ItemQuality.Uncommon then
            if db.sellGreens then
                if db.onlyEquippable and not item.isEquippable then
                    visible = false
                else
                    visible = true
                    if item.ilvl > 0 and db.greenMaxIlvl > 0 and item.ilvl <= db.greenMaxIlvl then
                        autoChecked = not item.isUpgrade
                    end
                end
            end
        elseif item.quality == Enum.ItemQuality.Rare then
            if db.sellBlues then
                if db.onlyEquippable and not item.isEquippable then
                    visible = false
                else
                    visible = true
                    if item.ilvl > 0 and db.blueMaxIlvl > 0 and item.ilvl <= db.blueMaxIlvl then
                        autoChecked = not item.isUpgrade
                    end
                end
            end
        end

        item.visible = visible

        local key = item.bag .. ":" .. item.slot
        if userUnchecked[key] then
            item.checked = false
        elseif visible then
            item.checked = autoChecked
        else
            item.checked = false
        end
    end

    self:RefreshPopupList()
end

-- ============================================================
-- Row Functions
-- ============================================================

local function CreateItemRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
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
    name:SetWidth(190)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    row.name = name

    -- Item level
    local ilvlText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ilvlText:SetPoint("LEFT", name, "RIGHT", 6, 0)
    ilvlText:SetWidth(95)
    ilvlText:SetJustifyH("CENTER")
    ilvlText:SetTextColor(0.55, 0.55, 0.55)
    row.ilvlText = ilvlText

    -- Price
    local price = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    price:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    price:SetWidth(90)
    price:SetJustifyH("RIGHT")
    price:SetTextColor(1, 0.82, 0)
    row.price = price

    -- Tooltip on hover
    row:EnableMouse(true)
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

    return row
end

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

    if item.ilvl and item.ilvl > 0 then
        if item.isEquippable and item.equippedIlvl and item.equippedIlvl > 0 then
            row.ilvlText:SetText(item.ilvl .. " (eq:" .. item.equippedIlvl .. ")")
        else
            row.ilvlText:SetText("ilvl " .. item.ilvl)
        end
        if item.isUpgrade then
            row.ilvlText:SetTextColor(0.1, 1.0, 0.1)
        else
            row.ilvlText:SetTextColor(0.55, 0.55, 0.55)
        end
    else
        row.ilvlText:SetText("")
        row.ilvlText:SetTextColor(0.55, 0.55, 0.55)
    end

    row.price:SetText(ns:FormatMoney(item.totalPrice))
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

    table.sort(visibleItems, function(a, b)
        if a.quality ~= b.quality then return a.quality < b.quality end
        if a.ilvl ~= b.ilvl then return a.ilvl < b.ilvl end
        return (a.itemLink or "") < (b.itemLink or "")
    end)

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
end

-- ============================================================
-- Main Popup Frame
-- ============================================================

local function CreatePopupFrame()
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

    -- Flat dark backdrop with black 1px border
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

    -- Close button (flat styled)
    local closeBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    closeBtn:SetSize(18, 18)
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

    -- ============================================================
    -- Filter Section
    -- ============================================================
    local filterTop = -36
    local filterLeft = 14

    -- Filter section background
    local filterBg = CreateFrame("Frame", nil, f, "BackdropTemplate")
    filterBg:SetPoint("TOPLEFT", 1, filterTop + 2)
    filterBg:SetPoint("TOPRIGHT", -1, filterTop + 2)
    filterBg:SetHeight(98)
    filterBg:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    filterBg:SetBackdropColor(0.04, 0.04, 0.04, 0.5)
    filterBg:EnableMouse(false)

    -- Row 1: Sell Grays
    local grayCheck = CreateStyledCheck(f, 18)
    grayCheck:SetPoint("TOPLEFT", filterLeft, filterTop)
    local grayLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    grayLabel:SetPoint("LEFT", grayCheck, "RIGHT", 6, 0)
    grayLabel:SetText("Sell Grays")
    grayCheck:SetScript("OnClick", function(self)
        ns.db.sellGrays = self:GetChecked()
        ns:ApplyFilters()
    end)
    f.grayCheck = grayCheck

    -- Row 2: Sell Greens + slider + editbox
    local greenCheck = CreateStyledCheck(f, 18)
    greenCheck:SetPoint("TOPLEFT", filterLeft, filterTop - 24)
    local greenLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    greenLabel:SetPoint("LEFT", greenCheck, "RIGHT", 6, 0)
    greenLabel:SetText("Sell Greens")
    greenCheck:SetScript("OnClick", function(self)
        ns.db.sellGreens = self:GetChecked()
        ns:ApplyFilters()
    end)
    f.greenCheck = greenCheck

    local greenSliderLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    greenSliderLabel:SetPoint("LEFT", greenLabel, "RIGHT", 12, 0)
    greenSliderLabel:SetText("ilvl <=")
    greenSliderLabel:SetTextColor(0.50, 0.50, 0.50)

    local greenSlider = CreateStyledSlider(f, 0, 700, 5)
    greenSlider:SetPoint("LEFT", greenSliderLabel, "RIGHT", 8, 0)
    f.greenSlider = greenSlider

    local greenEditBox = CreateStyledEditBox(f, 40)
    greenEditBox:SetPoint("LEFT", greenSlider, "RIGHT", 6, 0)
    local function CommitGreenValue(self)
        local val = tonumber(self:GetText()) or 0
        val = math.max(0, math.min(700, val))
        ns.db.greenMaxIlvl = val
        f.greenSlider:SetValue(val)
        self:SetText(tostring(val))
        self:ClearFocus()
    end
    greenEditBox:SetScript("OnEnterPressed", CommitGreenValue)
    greenEditBox:SetScript("OnTabPressed", CommitGreenValue)
    greenEditBox:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(ns.db.greenMaxIlvl))
        self:ClearFocus()
    end)
    f.greenEditBox = greenEditBox

    greenSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        ns.db.greenMaxIlvl = value
        f.greenEditBox:SetText(tostring(value))
        ns:ApplyFilters()
    end)

    -- Row 3: Sell Blues + slider + editbox
    local blueCheck = CreateStyledCheck(f, 18)
    blueCheck:SetPoint("TOPLEFT", filterLeft, filterTop - 48)
    local blueLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    blueLabel:SetPoint("LEFT", blueCheck, "RIGHT", 6, 0)
    blueLabel:SetText("Sell Blues")
    blueCheck:SetScript("OnClick", function(self)
        ns.db.sellBlues = self:GetChecked()
        ns:ApplyFilters()
    end)
    f.blueCheck = blueCheck

    local blueSliderLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    blueSliderLabel:SetPoint("LEFT", blueLabel, "RIGHT", 16, 0)
    blueSliderLabel:SetText("ilvl <=")
    blueSliderLabel:SetTextColor(0.50, 0.50, 0.50)

    local blueSlider = CreateStyledSlider(f, 0, 700, 5)
    blueSlider:SetPoint("LEFT", blueSliderLabel, "RIGHT", 8, 0)
    f.blueSlider = blueSlider

    local blueEditBox = CreateStyledEditBox(f, 40)
    blueEditBox:SetPoint("LEFT", blueSlider, "RIGHT", 6, 0)
    local function CommitBlueValue(self)
        local val = tonumber(self:GetText()) or 0
        val = math.max(0, math.min(700, val))
        ns.db.blueMaxIlvl = val
        f.blueSlider:SetValue(val)
        self:SetText(tostring(val))
        self:ClearFocus()
    end
    blueEditBox:SetScript("OnEnterPressed", CommitBlueValue)
    blueEditBox:SetScript("OnTabPressed", CommitBlueValue)
    blueEditBox:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(ns.db.blueMaxIlvl))
        self:ClearFocus()
    end)
    f.blueEditBox = blueEditBox

    blueSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        ns.db.blueMaxIlvl = value
        f.blueEditBox:SetText(tostring(value))
        ns:ApplyFilters()
    end)

    -- Row 4: Only Equippable
    local equipCheck = CreateStyledCheck(f, 18)
    equipCheck:SetPoint("TOPLEFT", filterLeft, filterTop - 72)
    local equipLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    equipLabel:SetPoint("LEFT", equipCheck, "RIGHT", 6, 0)
    equipLabel:SetText("Only Equippable")
    equipCheck:SetScript("OnClick", function(self)
        ns.db.onlyEquippable = self:GetChecked()
        ns:ApplyFilters()
    end)
    f.equipCheck = equipCheck

    -- ============================================================
    -- Divider + Avg ilvl
    -- ============================================================

    local divider = f:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT", filterLeft, filterTop - 96)
    divider:SetPoint("RIGHT", f, "RIGHT", -filterLeft, 0)
    divider:SetColorTexture(0.20, 0.20, 0.20, 0.8)

    local avgIlvlText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    avgIlvlText:SetPoint("TOPLEFT", filterLeft, filterTop - 103)
    avgIlvlText:SetTextColor(0.45, 0.70, 0.90)
    f.avgIlvlText = avgIlvlText

    -- ============================================================
    -- Column Headers + Scroll Area
    -- ============================================================

    local listTop = filterTop - 118

    -- Header background
    local headerBg = f:CreateTexture(nil, "ARTWORK")
    headerBg:SetPoint("TOPLEFT", filterLeft, listTop)
    headerBg:SetPoint("RIGHT", f, "RIGHT", -filterLeft, 0)
    headerBg:SetHeight(18)
    headerBg:SetColorTexture(0.08, 0.08, 0.08, 1)

    local hdrName = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hdrName:SetPoint("LEFT", headerBg, "LEFT", 50, 0)
    hdrName:SetText("Item")
    hdrName:SetTextColor(0.70, 0.70, 0.55)

    local hdrIlvl = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hdrIlvl:SetPoint("LEFT", headerBg, "LEFT", 258, 0)
    hdrIlvl:SetText("ilvl")
    hdrIlvl:SetTextColor(0.70, 0.70, 0.55)

    local hdrPrice = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hdrPrice:SetPoint("RIGHT", headerBg, "RIGHT", -6, 0)
    hdrPrice:SetText("Price")
    hdrPrice:SetTextColor(0.70, 0.70, 0.55)

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", filterLeft, listTop - 18)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 48)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(POPUP_WIDTH - 56, 1)
    scrollFrame:SetScrollChild(scrollChild)
    f.scrollChild = scrollChild

    -- ============================================================
    -- Bottom Bar
    -- ============================================================

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

    -- Sell button (accent style)
    local sellBtn = CreateFlatButton(f, "Sell Selected", 110, 26)
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

    local cancelBtn = CreateFlatButton(f, "Cancel", 70, 26)
    cancelBtn:SetPoint("RIGHT", sellBtn, "LEFT", -4, 0)
    cancelBtn:SetScript("OnClick", function() ns:HidePopup() end)

    local deselectBtn = CreateFlatButton(f, "Deselect All", 90, 26)
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

    local selectBtn = CreateFlatButton(f, "Select All", 80, 26)
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

    -- Escape closes popup
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
        -- Restore saved position
        if self.db.popupPoint then
            popup:ClearAllPoints()
            popup:SetPoint(self.db.popupPoint, UIParent, self.db.popupPoint, self.db.popupX or 0, self.db.popupY or 0)
        end
        -- Restore saved scale
        if self.db.popupScale then
            popup:SetScale(self.db.popupScale)
        end
    end

    -- Sync filter controls with saved settings
    popup.grayCheck:SetChecked(self.db.sellGrays)
    popup.greenCheck:SetChecked(self.db.sellGreens)
    popup.blueCheck:SetChecked(self.db.sellBlues)
    popup.equipCheck:SetChecked(self.db.onlyEquippable)
    popup.greenSlider:SetValue(self.db.greenMaxIlvl)
    popup.greenEditBox:SetText(tostring(self.db.greenMaxIlvl))
    popup.blueSlider:SetValue(self.db.blueMaxIlvl)
    popup.blueEditBox:SetText(tostring(self.db.blueMaxIlvl))

    -- Reset manual unchecks for new merchant visit
    wipe(userUnchecked)

    -- Refresh equipped ilvl cache
    local ilvls, avgIlvl, minIlvl = self:GetEquippedIlvls()
    self._equippedIlvls = ilvls
    popup.avgIlvlText:SetText("Avg Equipped ilvl: " .. avgIlvl)

    -- Set smart ilvl defaults: min(avg, lowestEquipped) - 10
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

    -- Scan bags and apply filters
    displayList = self:BuildDisplayList()
    self:ApplyFilters()

    -- Show with fade-in
    popup:SetAlpha(0)
    popup:Show()
    popup.fadeIn:Play()
end

function ns:HidePopup()
    if popup then
        popup:Hide()
    end
end

function ns:SellFromPopup()
    local queue = {}
    for _, item in ipairs(displayList) do
        if item.visible and item.checked then
            queue[#queue + 1] = {
                bag = item.bag,
                slot = item.slot,
                itemLink = item.itemLink,
                sellPrice = item.sellPrice,
                stackCount = item.stackCount,
                totalPrice = item.totalPrice,
            }
        end
    end

    if #queue == 0 then return end

    self:HidePopup()
    self:StartSelling(queue)
end
