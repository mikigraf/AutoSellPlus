local addonName, ns = ...

-- ============================================================
-- Confirmation Item List Panel
-- Shows a scrollable list of items below confirmation dialogs
-- so the user can see exactly what they're about to sell.
-- ============================================================

local BUYBACK_LIMIT = 12
local ROW_HEIGHT = 24
local MAX_VISIBLE_ROWS = 10
local PANEL_WIDTH = 300
local PANEL_PADDING = 8

-- ============================================================
-- Panel Creation (lazy, one-time)
-- ============================================================

local confirmListFrame

local function GetOrCreatePanel()
    if confirmListFrame then return confirmListFrame end

    local f = CreateFrame("Frame", "ASPConfirmListFrame", UIParent, "BackdropTemplate")
    f:SetSize(PANEL_WIDTH, 60)
    f:SetBackdrop(ns.FLAT_BACKDROP)
    f:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    f:SetBackdropBorderColor(0.30, 0.30, 0.30, 1)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:EnableMouse(true)
    f:Hide()

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", PANEL_PADDING, -PANEL_PADDING)
    title:SetText("Items to sell:")
    title:SetTextColor(1, 0.82, 0)
    f.title = title

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", PANEL_PADDING, -(PANEL_PADDING + 18))
    scrollFrame:SetPoint("TOPRIGHT", f, "TOPRIGHT", -(PANEL_PADDING + 18), -(PANEL_PADDING + 18))
    f.scrollFrame = scrollFrame

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(PANEL_WIDTH - PANEL_PADDING * 2 - 18)
    scrollFrame:SetScrollChild(scrollChild)
    f.scrollChild = scrollChild

    -- Total bar
    local totalBar = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    totalBar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PANEL_PADDING, PANEL_PADDING)
    totalBar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PANEL_PADDING, PANEL_PADDING)
    totalBar:SetJustifyH("LEFT")
    f.totalBar = totalBar

    -- Buyback warning line
    local buybackWarn = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    buybackWarn:SetPoint("BOTTOMLEFT", totalBar, "TOPLEFT", 0, 2)
    buybackWarn:SetPoint("BOTTOMRIGHT", totalBar, "TOPRIGHT", 0, 2)
    buybackWarn:SetJustifyH("LEFT")
    buybackWarn:SetTextColor(1, 0.3, 0.3)
    buybackWarn:Hide()
    f.buybackWarn = buybackWarn

    f.rows = {}
    confirmListFrame = f
    return f
end

-- ============================================================
-- Row Creation
-- ============================================================

local function CreateRow(parent, index)
    local contentWidth = parent:GetWidth()
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(contentWidth, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)

    -- Background for red tint on beyond-buyback items
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.5, 0.05, 0.05, 0)
    row.bg = bg

    -- Icon
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ROW_HEIGHT - 4, ROW_HEIGHT - 4)
    icon:SetPoint("LEFT", row, "LEFT", 2, 0)
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
    name:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    name:SetPoint("RIGHT", row, "RIGHT", -60, 0)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    row.name = name

    -- Price
    local price = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    price:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    price:SetJustifyH("RIGHT")
    price:SetTextColor(1, 0.82, 0)
    row.price = price

    -- Tooltip
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        if self.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemLink)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return row
end

-- ============================================================
-- Divider Row (Beyond Buyback Limit)
-- ============================================================

local function CreateDividerRow(parent, index)
    local contentWidth = parent:GetWidth()
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(contentWidth, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
    row.isDivider = true

    local line = row:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("LEFT", row, "LEFT", 4, 0)
    line:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    line:SetColorTexture(0.8, 0.2, 0.2, 0.8)
    row.line = line

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER", row, "CENTER", 0, 0)
    label:SetText("-- Beyond Buyback Limit --")
    label:SetTextColor(1, 0.3, 0.3)
    row.label = label

    return row
end

-- ============================================================
-- Public API
-- ============================================================

function ns:ShowConfirmList(queue, parentFrame)
    if not queue or #queue == 0 then return end

    local f = GetOrCreatePanel()

    -- Clear old rows
    for _, row in ipairs(f.rows) do
        row:Hide()
        row:SetParent(nil)
    end
    wipe(f.rows)

    local scrollChild = f.scrollChild
    local totalCopper = 0
    local beyondBuyback = 0
    local rowIndex = 0

    for i, item in ipairs(queue) do
        -- Insert divider before item 13
        if i == BUYBACK_LIMIT + 1 then
            rowIndex = rowIndex + 1
            local divider = CreateDividerRow(scrollChild, rowIndex)
            f.rows[#f.rows + 1] = divider
            divider:Show()
        end

        rowIndex = rowIndex + 1
        local row = CreateRow(scrollChild, rowIndex)
        f.rows[#f.rows + 1] = row

        -- Icon
        local _, _, _, _, iconPath = C_Item.GetItemInfoInstant(item.itemID)
        row.icon:SetTexture(iconPath)

        -- Quality color
        local quality = item.quality
        if not quality and item.itemLink then
            _, _, quality = C_Item.GetItemInfo(item.itemLink)
        end
        local color = ITEM_QUALITY_COLORS[quality or 1]

        local itemName = C_Item.GetItemNameByID(item.itemID) or "?"
        row.name:SetText(itemName)
        if color then
            row.name:SetTextColor(color.r, color.g, color.b)
            row.iconBorder:SetBackdropBorderColor(color.r, color.g, color.b, 0.7)
        else
            row.name:SetTextColor(0.9, 0.9, 0.9)
            row.iconBorder:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        end

        -- Price
        local itemTotal = item.totalPrice or 0
        row.price:SetText(ns:FormatMoney(itemTotal))
        totalCopper = totalCopper + itemTotal

        -- Store link for tooltip
        row.itemLink = item.itemLink

        -- Red tint for beyond-buyback items
        if i > BUYBACK_LIMIT then
            row.bg:SetColorTexture(0.5, 0.05, 0.05, 0.25)
            beyondBuyback = beyondBuyback + 1
        else
            row.bg:SetColorTexture(0.5, 0.05, 0.05, 0)
        end

        row:Show()
    end

    -- Size the scroll child
    scrollChild:SetHeight(rowIndex * ROW_HEIGHT)

    -- Total bar
    f.totalBar:SetText(format("Total: %s (%d item%s)",
        ns:FormatMoney(totalCopper),
        #queue,
        #queue == 1 and "" or "s"))

    -- Buyback warning
    if beyondBuyback > 0 then
        f.buybackWarn:SetText(format("|cFFFF4D4D%d beyond buyback limit|r", beyondBuyback))
        f.buybackWarn:Show()
    else
        f.buybackWarn:Hide()
    end

    -- Calculate panel height
    local visibleRows = math.min(rowIndex, MAX_VISIBLE_ROWS)
    local scrollHeight = visibleRows * ROW_HEIGHT
    local bottomExtra = PANEL_PADDING + 14 -- totalBar
    if beyondBuyback > 0 then
        bottomExtra = bottomExtra + 14 -- buybackWarn
    end
    local panelHeight = PANEL_PADDING + 18 + scrollHeight + bottomExtra + PANEL_PADDING
    f:SetHeight(panelHeight)

    -- Set scroll frame height
    f.scrollFrame:SetHeight(scrollHeight)

    -- Anchor below the parent StaticPopup dialog
    f:ClearAllPoints()
    if parentFrame then
        f:SetPoint("TOP", parentFrame, "BOTTOM", 0, -4)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
    end

    f:Show()
end

function ns:HideConfirmList()
    if confirmListFrame then
        confirmListFrame:Hide()
    end
end
