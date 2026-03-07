local addonName, ns = ...

local wizard = nil
local currentPage = 1
local TOTAL_PAGES = 3

local FLAT_BACKDROP = ns.FLAT_BACKDROP

local function CreateWizardCheck(parent, label, tooltip, x, y, defaultVal)
    local check = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
    check:SetSize(18, 18)
    check:SetPoint("TOPLEFT", x, y)
    check:SetBackdrop(FLAT_BACKDROP)
    check:SetBackdropColor(0.15, 0.15, 0.15, 1)
    check:SetBackdropBorderColor(0.30, 0.30, 0.30, 1)
    check:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    local ct = check:GetCheckedTexture()
    ct:ClearAllPoints()
    ct:SetPoint("TOPLEFT", 2, -2)
    ct:SetPoint("BOTTOMRIGHT", -2, 2)
    check:SetChecked(defaultVal)

    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", check, "RIGHT", 6, 0)
    text:SetText(label)

    check:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.50, 0.50, 0.50, 1)
        if tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    check:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.30, 0.30, 0.30, 1)
        GameTooltip:Hide()
    end)

    return check
end

local function ShowPage(pageNum)
    if not wizard then return end
    currentPage = pageNum

    for i = 1, TOTAL_PAGES do
        if wizard.pages[i] then
            wizard.pages[i]:SetShown(i == pageNum)
        end
    end

    wizard.prevBtn:SetShown(pageNum > 1)
    wizard.nextBtn:SetShown(pageNum < TOTAL_PAGES)
    wizard.doneBtn:SetShown(pageNum == TOTAL_PAGES)
    wizard.pageText:SetText(format("Page %d of %d", pageNum, TOTAL_PAGES))
end

local function CreatePage1(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()

    local title = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -50)
    title:SetText("|cFF00CCFFWelcome to AutoSellPlus!|r")

    local desc = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -16)
    desc:SetWidth(340)
    desc:SetJustifyH("CENTER")
    desc:SetText("AutoSellPlus helps you quickly sell junk and unwanted items when visiting merchants.\n\nLet's set up your preferences.")

    local modeLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    modeLabel:SetPoint("TOPLEFT", 40, -160)
    modeLabel:SetText("When visiting a merchant:")

    -- Mode radio buttons
    local modes = {
        { value = "popup", label = "Show item review popup (Recommended)", y = -185 },
        { value = "oneclick", label = "Show popup with prominent sell button", y = -210 },
        { value = "autosell", label = "Auto-sell immediately", y = -235 },
    }

    page.modeButtons = {}
    for _, mode in ipairs(modes) do
        local btn = CreateFrame("CheckButton", nil, page, "BackdropTemplate")
        btn:SetSize(16, 16)
        btn:SetPoint("TOPLEFT", 50, mode.y)
        btn:SetBackdrop(FLAT_BACKDROP)
        btn:SetBackdropColor(0.15, 0.15, 0.15, 1)
        btn:SetBackdropBorderColor(0.30, 0.30, 0.30, 1)
        btn:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
        local ct = btn:GetCheckedTexture()
        ct:ClearAllPoints()
        ct:SetPoint("TOPLEFT", 2, -2)
        ct:SetPoint("BOTTOMRIGHT", -2, 2)
        btn:SetChecked(mode.value == "popup")
        btn.value = mode.value

        local label = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("LEFT", btn, "RIGHT", 6, 0)
        label:SetText(mode.label)

        btn:SetScript("OnClick", function(self)
            for _, b in ipairs(page.modeButtons) do
                b:SetChecked(b == self)
            end
            ns.db.autoSellMode = self.value
        end)

        page.modeButtons[#page.modeButtons + 1] = btn
    end

    -- Saved profile picker
    page.selectedProfile = nil
    if AutoSellPlusDB and AutoSellPlusDB.profiles and next(AutoSellPlusDB.profiles) then
        local profileLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        profileLabel:SetPoint("TOPLEFT", 40, -265)
        profileLabel:SetText("Load saved profile:")

        local profileNames = {}
        for pName in pairs(AutoSellPlusDB.profiles) do
            profileNames[#profileNames + 1] = pName
        end
        table.sort(profileNames)

        local profileIdx = 0
        local profileText = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        profileText:SetPoint("TOPLEFT", 210, -265)
        profileText:SetText("|cFFAAAAAA(none)|r")

        local cycleBtn = CreateFrame("Button", nil, page, "BackdropTemplate")
        cycleBtn:SetSize(70, 20)
        cycleBtn:SetPoint("LEFT", profileText, "RIGHT", 8, 0)
        cycleBtn:SetBackdrop(FLAT_BACKDROP)
        cycleBtn:SetBackdropColor(0.18, 0.18, 0.18, 1)
        cycleBtn:SetBackdropBorderColor(0.30, 0.30, 0.30, 1)
        local cycleLbl = cycleBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        cycleLbl:SetPoint("CENTER")
        cycleLbl:SetText("Cycle")
        cycleBtn:SetScript("OnClick", function()
            profileIdx = profileIdx + 1
            if profileIdx > #profileNames then profileIdx = 0 end
            if profileIdx == 0 then
                page.selectedProfile = nil
                profileText:SetText("|cFFAAAAAA(none)|r")
            else
                page.selectedProfile = profileNames[profileIdx]
                profileText:SetText("|cFF00FF00" .. profileNames[profileIdx] .. "|r")
            end
        end)
        cycleBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.28, 0.28, 0.28, 1)
        end)
        cycleBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.18, 0.18, 0.18, 1)
        end)
    end

    -- Template quick-apply buttons
    if ns.profileTemplates then
        local tplLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tplLabel:SetPoint("TOPLEFT", 40, -270)
        tplLabel:SetText("Quick-start template (optional):")

        local tplY = -295
        for tplName, tpl in pairs(ns.profileTemplates) do
            local tplBtn = CreateFrame("Button", nil, page, "BackdropTemplate")
            tplBtn:SetSize(330, 22)
            tplBtn:SetPoint("TOPLEFT", 50, tplY)
            tplBtn:SetBackdrop(FLAT_BACKDROP)
            tplBtn:SetBackdropColor(0.14, 0.14, 0.14, 1)
            tplBtn:SetBackdropBorderColor(0.30, 0.30, 0.30, 1)

            local tplText = tplBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            tplText:SetPoint("LEFT", 8, 0)
            tplText:SetText(format("|cFF00CCFF%s|r - %s", tplName, tpl.description))
            tplText:SetWidth(314)
            tplText:SetJustifyH("LEFT")

            tplBtn:SetScript("OnClick", function()
                ns:ApplyTemplate(tplName)
                -- Update mode radio buttons to reflect template
                for _, b in ipairs(page.modeButtons) do
                    b:SetChecked(b.value == ns.db.autoSellMode)
                end
            end)
            tplBtn:SetScript("OnEnter", function(self)
                self:SetBackdropBorderColor(0.0, 0.45, 0.70, 1)
            end)
            tplBtn:SetScript("OnLeave", function(self)
                self:SetBackdropBorderColor(0.30, 0.30, 0.30, 1)
            end)

            tplY = tplY - 26
        end
    end

    return page
end

local function CreatePage2(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()

    local title = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -50)
    title:SetText("|cFF00CCFFSafety Settings|r")

    local desc = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -12)
    desc:SetWidth(340)
    desc:SetJustifyH("CENTER")
    desc:SetText("Configure item protections to prevent accidental sales.")

    page.equipSetsCheck = CreateWizardCheck(page, "Protect Equipment Set items", "Never sell items in your equipment sets", 40, -130, true)
    page.equipSetsCheck:SetScript("OnClick", function(self) ns.db.protectEquipmentSets = self:GetChecked() end)

    page.transmogCheck = CreateWizardCheck(page, "Protect uncollected transmog", "Never sell equippable items with uncollected appearances", 40, -158, true)
    page.transmogCheck:SetScript("OnClick", function(self) ns.db.protectUncollectedTransmog = self:GetChecked() end)

    page.boeCheck = CreateWizardCheck(page, "Protect unbound BoE items", "Never sell bind-on-equip items that haven't been equipped", 40, -186, true)
    page.boeCheck:SetScript("OnClick", function(self) ns.db.protectBoE = self:GetChecked() end)

    page.highValueCheck = CreateWizardCheck(page, "Confirm high-value item sales", "Show a warning before selling expensive items", 40, -214, true)
    page.highValueCheck:SetScript("OnClick", function(self) ns.db.highValueConfirm = self:GetChecked() end)

    page.buybackCheck = CreateWizardCheck(page, "Show buyback warning (>12 items)", "Warn when selling more than the buyback limit", 40, -242, true)
    page.buybackCheck:SetScript("OnClick", function(self) ns.db.buybackWarning = self:GetChecked() end)

    page.autoRepairCheck = CreateWizardCheck(page, "Auto-repair at merchants", "Automatically repair gear when visiting repair-capable merchants", 40, -280, false)
    page.autoRepairCheck:SetScript("OnClick", function(self) ns.db.autoRepair = self:GetChecked() end)

    return page
end

local function CreatePage3(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()

    local title = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -50)
    title:SetText("|cFF00FF00Setup Complete!|r")

    local desc = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -16)
    desc:SetWidth(340)
    desc:SetJustifyH("CENTER")
    desc:SetText("You're all set! Visit a merchant to see AutoSellPlus in action.\n\nYou can change these settings at any time:")

    local tips = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    tips:SetPoint("TOP", desc, "BOTTOM", 0, -20)
    tips:SetWidth(340)
    tips:SetJustifyH("LEFT")
    tips:SetText(
        "|cFFAAAAAACommands:|r\n" ..
        "  /asp - Show help\n" ..
        "  /asp config - Open settings\n" ..
        "  /asp mark - Toggle bulk mark mode\n" ..
        "  /asp session - View session stats\n\n" ..
        "|cFFAAAAAAIn the popup:|r\n" ..
        "  Adjust quality filters and ilvl thresholds\n" ..
        "  Right-click items for never/always-sell lists\n" ..
        "  ALT+click items in bags to mark as junk"
    )

    return page
end

local function CreateWizardFrame()
    local f = CreateFrame("Frame", "AutoSellPlusWizard", UIParent, "BackdropTemplate")
    f:SetSize(420, 480)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)

    f:SetBackdrop(FLAT_BACKDROP)
    f:SetBackdropColor(0.06, 0.06, 0.06, 0.98)
    f:SetBackdropBorderColor(0, 0, 0, 1)

    -- Outer border
    local outerBorder = CreateFrame("Frame", nil, f, "BackdropTemplate")
    outerBorder:SetPoint("TOPLEFT", -1, 1)
    outerBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    outerBorder:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1))
    outerBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    outerBorder:SetBackdropBorderColor(0.20, 0.20, 0.20, 0.6)
    outerBorder:EnableMouse(false)

    -- Title bar
    local titleBg = f:CreateTexture(nil, "ARTWORK")
    titleBg:SetPoint("TOPLEFT", 1, -1)
    titleBg:SetPoint("TOPRIGHT", -1, -1)
    titleBg:SetHeight(26)
    titleBg:SetColorTexture(0.10, 0.10, 0.10, 0.8)

    local titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOP", 0, -6)
    titleText:SetText("|cFF00CCFFAutoSellPlus Setup|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn:SetBackdrop(FLAT_BACKDROP)
    closeBtn:SetBackdropColor(0.12, 0.12, 0.12, 1)
    closeBtn:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    local closeLbl = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    closeLbl:SetPoint("CENTER")
    closeLbl:SetText("x")
    closeLbl:SetTextColor(0.60, 0.60, 0.60)
    closeBtn:SetScript("OnClick", function()
        f:Hide()
        ns.db.firstRunComplete = true
        AutoSellPlusCharDB.charFirstRunComplete = true
    end)
    closeBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.7, 0.15, 0.15, 1)
        closeLbl:SetTextColor(1, 0.3, 0.3)
    end)
    closeBtn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        closeLbl:SetTextColor(0.60, 0.60, 0.60)
    end)

    -- Pages
    f.pages = {
        CreatePage1(f),
        CreatePage2(f),
        CreatePage3(f),
    }

    -- Bottom navigation
    local pageText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pageText:SetPoint("BOTTOM", 0, 14)
    pageText:SetTextColor(0.50, 0.50, 0.50)
    f.pageText = pageText

    -- Previous button
    local prevBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    prevBtn:SetSize(80, 26)
    prevBtn:SetPoint("BOTTOMLEFT", 10, 8)
    prevBtn:SetBackdrop(FLAT_BACKDROP)
    prevBtn:SetBackdropColor(0.18, 0.18, 0.18, 1)
    prevBtn:SetBackdropBorderColor(0.30, 0.30, 0.30, 1)
    local prevLbl = prevBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    prevLbl:SetPoint("CENTER")
    prevLbl:SetText("< Back")
    prevBtn:SetScript("OnClick", function()
        if currentPage > 1 then ShowPage(currentPage - 1) end
    end)
    prevBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.28, 0.28, 0.28, 1)
    end)
    prevBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.18, 0.18, 0.18, 1)
    end)
    f.prevBtn = prevBtn

    -- Next button
    local nextBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    nextBtn:SetSize(80, 26)
    nextBtn:SetPoint("BOTTOMRIGHT", -10, 8)
    nextBtn:SetBackdrop(FLAT_BACKDROP)
    nextBtn:SetBackdropColor(0.0, 0.30, 0.50, 1)
    nextBtn:SetBackdropBorderColor(0.0, 0.45, 0.70, 1)
    local nextLbl = nextBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nextLbl:SetPoint("CENTER")
    nextLbl:SetText("Next >")
    nextBtn:SetScript("OnClick", function()
        if currentPage < TOTAL_PAGES then ShowPage(currentPage + 1) end
    end)
    nextBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.0, 0.40, 0.65, 1)
    end)
    nextBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.0, 0.30, 0.50, 1)
    end)
    f.nextBtn = nextBtn

    -- Done button
    local doneBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    doneBtn:SetSize(80, 26)
    doneBtn:SetPoint("BOTTOMRIGHT", -10, 8)
    doneBtn:SetBackdrop(FLAT_BACKDROP)
    doneBtn:SetBackdropColor(0.0, 0.40, 0.15, 1)
    doneBtn:SetBackdropBorderColor(0.0, 0.60, 0.25, 1)
    local doneLbl = doneBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    doneLbl:SetPoint("CENTER")
    doneLbl:SetText("Done!")
    doneBtn:SetScript("OnClick", function()
        -- Load selected profile if any
        local page1 = f.pages[1]
        if page1 and page1.selectedProfile then
            ns:LoadProfile(page1.selectedProfile)
        end
        ns.db.firstRunComplete = true
        AutoSellPlusCharDB.charFirstRunComplete = true
        f:Hide()
        ns:Print("Setup complete! Visit a merchant to get started.")
    end)
    doneBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.0, 0.50, 0.20, 1)
    end)
    doneBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.0, 0.40, 0.15, 1)
    end)
    f.doneBtn = doneBtn

    tinsert(UISpecialFrames, "AutoSellPlusWizard")
    f:Hide()
    return f
end

function ns:ShowWizard()
    if not wizard then
        wizard = CreateWizardFrame()
    end
    currentPage = 1
    ShowPage(1)
    wizard:Show()
end
