local addonName, ns = ...

local button = nil
local isDragging = false

local function GetMinimapButtonPosition(angle)
    local radian = math.rad(angle)
    local x = math.cos(radian) * 80
    local y = math.sin(radian) * 80
    return x, y
end

local function UpdatePosition()
    if not button then return end
    local angle = ns.db.minimapButtonAngle or 225
    local x, y = GetMinimapButtonPosition(angle)
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function FormatGoldShort(copper)
    if copper >= 10000 then
        return math.floor(copper / 10000) .. "g"
    elseif copper >= 100 then
        return math.floor(copper / 100) .. "s"
    else
        return copper .. "c"
    end
end

local function OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cFF00CCFFAutoSellPlus|r v" .. (ns.version or "?"), 1, 1, 1)
    GameTooltip:AddLine(" ")

    -- Session info
    if ns.sessionData then
        local s = ns.sessionData
        if s.totalCopper > 0 then
            GameTooltip:AddDoubleLine("Session income:", ns:FormatMoney(s.totalCopper), 0.7, 0.7, 0.7, 1, 0.82, 0)
            GameTooltip:AddDoubleLine("Items sold:", tostring(s.itemCount), 0.7, 0.7, 0.7, 1, 1, 1)
        end
    end

    -- Daily stats
    if ns.GetDailyStats then
        local dailyCopper, dailyItems = ns:GetDailyStats()
        if dailyItems > 0 then
            GameTooltip:AddDoubleLine("Today:", ns:FormatMoney(dailyCopper) .. " (" .. dailyItems .. " items)", 0.7, 0.7, 0.7, 1, 0.82, 0)
        end
    end

    -- Per-character stats from charStats
    local charStats = ns.db.charStats
    if charStats then
        local hasStats = false
        for charName, stats in pairs(charStats) do
            if not hasStats then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Character Stats:", 0.5, 0.8, 1)
                hasStats = true
            end
            local rightText = FormatGoldShort(stats.totalCopper or 0) .. " (" .. (stats.totalItems or 0) .. " items)"
            if stats.bagJunkValue and stats.bagJunkValue > 0 then
                rightText = rightText .. " | Junk: " .. FormatGoldShort(stats.bagJunkValue)
            end
            GameTooltip:AddDoubleLine(
                charName,
                rightText,
                0.7, 0.7, 0.7, 1, 0.82, 0
            )
        end
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cFFAAAAAALeft-click:|r Toggle popup", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("|cFFAAAAAARight-click:|r Settings", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("|cFFAAAAAAShift+click:|r Session stats", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("|cFFAAAAAAShift+Right-click:|r Sale history", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end

local function OnLeave()
    GameTooltip:Hide()
end

local function OnClick(self, btn)
    if btn == "LeftButton" then
        if IsShiftKeyDown() then
            ns:PrintSessionReport()
        else
            ns.db.enabled = not ns.db.enabled
            ns:Print("Addon " .. (ns.db.enabled and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))
        end
    elseif btn == "RightButton" then
        if IsShiftKeyDown() then
            ns:ToggleHistoryPanel()
        elseif ns.settingsCategoryID then
            Settings.OpenToCategory(ns.settingsCategoryID)
        end
    end
end

local function OnDragStart(self)
    isDragging = true
end

local function OnDragStop(self)
    isDragging = false
end

local function OnUpdate(self)
    if not isDragging then return end

    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    cx, cy = cx / scale, cy / scale

    local angle = math.deg(math.atan2(cy - my, cx - mx))
    ns.db.minimapButtonAngle = angle
    UpdatePosition()
end

function ns:CreateMinimapButton()
    if button then return end

    button = CreateFrame("Button", "AutoSellPlusMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetMovable(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    -- Icon
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.icon = icon

    -- Border ring
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(32, 32)
    border:SetPoint("CENTER")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT")

    -- Background
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(24, 24)
    bg:SetPoint("CENTER")
    bg:SetColorTexture(0, 0, 0, 0.6)

    -- Hover highlight
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(20, 20)
    highlight:SetPoint("CENTER")
    highlight:SetColorTexture(1, 1, 1, 0.15)

    button:SetScript("OnEnter", OnEnter)
    button:SetScript("OnLeave", OnLeave)
    button:SetScript("OnClick", OnClick)
    button:SetScript("OnDragStart", OnDragStart)
    button:SetScript("OnDragStop", OnDragStop)
    button:SetScript("OnUpdate", OnUpdate)

    UpdatePosition()

    if not ns.db.showMinimapButton then
        button:Hide()
    end
end

function ns:ShowMinimapButton()
    if button then button:Show() end
end

function ns:HideMinimapButton()
    if button then button:Hide() end
end

function ns:ToggleMinimapButton()
    ns.db.showMinimapButton = not ns.db.showMinimapButton
    if ns.db.showMinimapButton then
        self:ShowMinimapButton()
    else
        self:HideMinimapButton()
    end
end

-- Update current character's bag junk value for alt-tracking
function ns:UpdateCharJunkValue()
    local charName = UnitName("player")
    local realm = GetRealmName()
    local fullName = charName .. " - " .. realm

    local stats = ns.db.charStats
    if not stats then return end
    if not stats[fullName] then
        stats[fullName] = { totalCopper = 0, totalItems = 0, lastSeen = 0 }
    end

    local junkValue = 0
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.itemID and itemInfo.hyperlink then
                local quality = itemInfo.quality or 99
                local isJunk = (quality == Enum.ItemQuality.Poor)
                    or ns:IsMarked(itemInfo.itemID)
                    or ns:IsAlwaysSell(itemInfo.itemID)
                if isJunk and not ns:IsNeverSell(itemInfo.itemID) then
                    local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(itemInfo.hyperlink)
                    if sellPrice and sellPrice > 0 then
                        junkValue = junkValue + (sellPrice * (itemInfo.stackCount or 1))
                    end
                end
            end
        end
    end

    stats[fullName].bagJunkValue = junkValue
end

-- Update character stats for alt-tracking
function ns:UpdateCharStats(soldCount, copperEarned)
    local charName = UnitName("player")
    local realm = GetRealmName()
    local fullName = charName .. " - " .. realm

    local stats = ns.db.charStats
    if not stats then return end

    if not stats[fullName] then
        stats[fullName] = { totalCopper = 0, totalItems = 0, lastSeen = 0 }
    end

    stats[fullName].totalCopper = stats[fullName].totalCopper + copperEarned
    stats[fullName].totalItems = stats[fullName].totalItems + soldCount
    stats[fullName].lastSeen = GetServerTime()
end
