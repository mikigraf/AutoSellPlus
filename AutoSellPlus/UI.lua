local addonName, ns = ...

local FLAT_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

-- ============================================================
-- Import / Export Frame (reusable)
-- ============================================================

local function CreateImportExportFrame(title, mode)
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetSize(400, 250)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop(FLAT_BACKDROP)
    f:SetBackdropColor(0.06, 0.06, 0.06, 0.98)
    f:SetBackdropBorderColor(0, 0, 0, 1)

    local titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOP", 0, -10)
    titleText:SetText("|cFF00CCFF" .. title .. "|r")

    local editBox = CreateFrame("EditBox", nil, f, "BackdropTemplate")
    editBox:SetMultiLine(true)
    editBox:SetSize(370, 170)
    editBox:SetPoint("TOP", 0, -35)
    editBox:SetBackdrop(FLAT_BACKDROP)
    editBox:SetBackdropColor(0.08, 0.08, 0.08, 1)
    editBox:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetTextInsets(8, 8, 8, 8)
    editBox:SetAutoFocus(true)
    f.editBox = editBox

    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", editBox, "TOPLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", editBox, "BOTTOMRIGHT", -4, 4)
    scrollFrame:SetScrollChild(editBox)

    if mode == "export" then
        local data = ns:SerializeList("all")
        editBox:SetText(data)
        editBox:HighlightText()
        editBox:SetScript("OnEscapePressed", function() f:Hide() end)
    else
        editBox:SetText("")
        editBox:SetScript("OnEscapePressed", function() f:Hide() end)
    end

    local closeBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    closeBtn:SetSize(70, 22)
    closeBtn:SetPoint("BOTTOMRIGHT", -10, 8)
    closeBtn:SetBackdrop(FLAT_BACKDROP)
    closeBtn:SetBackdropColor(0.18, 0.18, 0.18, 1)
    closeBtn:SetBackdropBorderColor(0.30, 0.30, 0.30, 1)
    local closeLbl = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    closeLbl:SetPoint("CENTER")
    closeLbl:SetText("Close")
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    if mode == "import" then
        local importBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
        importBtn:SetSize(70, 22)
        importBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)
        importBtn:SetBackdrop(FLAT_BACKDROP)
        importBtn:SetBackdropColor(0.0, 0.30, 0.50, 1)
        importBtn:SetBackdropBorderColor(0.0, 0.45, 0.70, 1)
        local importLbl = importBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        importLbl:SetPoint("CENTER")
        importLbl:SetText("Import")
        importBtn:SetScript("OnClick", function()
            local text = editBox:GetText()
            local ok, count = ns:DeserializeList(text)
            if ok then
                ns:Print(format("Imported %d items.", count))
            else
                ns:Print("Import failed. Check the format.")
            end
            f:Hide()
        end)
    end

    f:Show()
    return f
end

-- ============================================================
-- Canvas Helpers
-- ============================================================

local function CreateCanvasButton(parent, text, width, r, g, b)
    r = r or 0.18
    g = g or 0.18
    b = b or 0.18
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width or 100, 24)
    btn:SetBackdrop(FLAT_BACKDROP)
    btn:SetBackdropColor(r, g, b, 1)
    btn:SetBackdropBorderColor(r + 0.15, g + 0.15, b + 0.15, 1)
    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lbl:SetPoint("CENTER")
    lbl:SetText(text)
    btn.label = lbl
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(r + 0.10, g + 0.10, b + 0.10, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(r, g, b, 1)
    end)
    return btn
end

local function CreateCanvasInput(parent, width)
    local input = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    input:SetSize(width or 120, 22)
    input:SetBackdrop(FLAT_BACKDROP)
    input:SetBackdropColor(0.08, 0.08, 0.08, 1)
    input:SetBackdropBorderColor(0.30, 0.30, 0.30, 1)
    input:SetFontObject(GameFontHighlightSmall)
    input:SetTextInsets(6, 6, 0, 0)
    input:SetAutoFocus(false)
    input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    input:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    return input
end

local function CreateSectionHeader(parent, text, x, y)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", x, y)
    header:SetText("|cFF00CCFF" .. text .. "|r")
    return header
end

-- ============================================================
-- Canvas: Profiles & Templates
-- ============================================================

local function CreateProfilesCanvas()
    local f = CreateFrame("Frame")
    f:Hide()

    local MAX_PROFILE_ROWS = 20
    local profileRows = {}

    local function RefreshProfiles()
        -- Active profile
        local active = AutoSellPlusCharDB and AutoSellPlusCharDB.activeProfile or ""
        if active == "" then active = "(none)" end
        f.activeLabel:SetText("Active profile: |cFF00FF00" .. active .. "|r")

        -- Profile list
        local profiles = AutoSellPlusDB and AutoSellPlusDB.profiles or {}
        local names = {}
        for name in pairs(profiles) do
            names[#names + 1] = name
        end
        table.sort(names)

        for i = 1, MAX_PROFILE_ROWS do
            if profileRows[i] then
                profileRows[i]:Hide()
            end
        end

        for i, name in ipairs(names) do
            if i > MAX_PROFILE_ROWS then break end
            if not profileRows[i] then
                local row = CreateFrame("Frame", nil, f.listArea)
                row:SetSize(500, 22)
                row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                row.nameText:SetPoint("LEFT", 4, 0)
                row.nameText:SetWidth(300)
                row.nameText:SetJustifyH("LEFT")

                row.loadBtn = CreateCanvasButton(row, "Load", 55, 0.0, 0.30, 0.50)
                row.loadBtn:SetPoint("RIGHT", row, "RIGHT", -70, 0)

                row.deleteBtn = CreateCanvasButton(row, "Delete", 55, 0.40, 0.12, 0.12)
                row.deleteBtn:SetPoint("RIGHT", row, "RIGHT", -8, 0)

                profileRows[i] = row
            end

            local row = profileRows[i]
            local isActive = (AutoSellPlusCharDB and AutoSellPlusCharDB.activeProfile == name)
            row.nameText:SetText(name .. (isActive and " |cFF00FF00(active)|r" or ""))
            row:SetPoint("TOPLEFT", f.listArea, "TOPLEFT", 0, -((i - 1) * 24))

            row.loadBtn:SetScript("OnClick", function()
                ns:LoadProfile(name)
                RefreshProfiles()
            end)
            row.deleteBtn:SetScript("OnClick", function()
                ns:DeleteProfile(name)
                RefreshProfiles()
            end)
            row:Show()
        end

        if #names == 0 then
            f.emptyLabel:Show()
        else
            f.emptyLabel:Hide()
        end
    end

    -- Title
    CreateSectionHeader(f, "Templates", 16, -16)

    local tplY = -40
    if ns.profileTemplates then
        for tplName, tpl in pairs(ns.profileTemplates) do
            local btn = CreateCanvasButton(f, tplName, 140, 0.12, 0.25, 0.40)
            btn:SetPoint("TOPLEFT", 20, tplY)
            btn:SetScript("OnEnter", function(self)
                self:SetBackdropColor(0.18, 0.35, 0.55, 1)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(tplName, 1, 1, 1)
                GameTooltip:AddLine(tpl.description, 0.7, 0.7, 0.7, true)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function(self)
                self:SetBackdropColor(0.12, 0.25, 0.40, 1)
                GameTooltip:Hide()
            end)
            btn:SetScript("OnClick", function()
                ns:ApplyTemplate(tplName)
                RefreshProfiles()
            end)
            tplY = tplY - 28
        end
    end

    -- Saved Profiles section
    local profilesY = tplY - 16
    CreateSectionHeader(f, "Saved Profiles", 16, profilesY)

    local activeLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    activeLabel:SetPoint("TOPLEFT", 20, profilesY - 20)
    f.activeLabel = activeLabel

    local listArea = CreateFrame("Frame", nil, f)
    listArea:SetPoint("TOPLEFT", 20, profilesY - 44)
    listArea:SetSize(500, MAX_PROFILE_ROWS * 24)
    f.listArea = listArea

    local emptyLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    emptyLabel:SetPoint("TOPLEFT", listArea, "TOPLEFT", 4, 0)
    emptyLabel:SetText("|cFFAAAAAA(no saved profiles)|r")
    emptyLabel:Hide()
    f.emptyLabel = emptyLabel

    -- Save section
    local saveY = profilesY - 52 - (MAX_PROFILE_ROWS * 24)
    local saveLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    saveLabel:SetPoint("TOPLEFT", 20, saveY)
    saveLabel:SetText("Save current settings as profile:")

    local saveInput = CreateCanvasInput(f, 160)
    saveInput:SetPoint("TOPLEFT", 20, saveY - 18)
    f.saveInput = saveInput

    local saveBtn = CreateCanvasButton(f, "Save", 60, 0.0, 0.35, 0.15)
    saveBtn:SetPoint("LEFT", saveInput, "RIGHT", 6, 0)
    saveBtn:SetScript("OnClick", function()
        local name = saveInput:GetText()
        if name and name ~= "" then
            ns:SaveProfile(name)
            saveInput:SetText("")
            saveInput:ClearFocus()
            RefreshProfiles()
        end
    end)

    f:SetScript("OnShow", RefreshProfiles)
    return f
end

-- ============================================================
-- Canvas: Lists (Never-Sell, Always-Sell, Stack Limits)
-- ============================================================

local function CreateListsCanvas()
    local f = CreateFrame("Frame")
    f:Hide()

    local MAX_LIST_ROWS = 20
    local listRows = {}
    local activeTab = "never"

    local function GetActiveList()
        if activeTab == "never" then
            return AutoSellPlusDB.neverSellList or {}, "neverSellList"
        elseif activeTab == "always" then
            return AutoSellPlusDB.alwaysSellList or {}, "alwaysSellList"
        else
            return AutoSellPlusDB.stackLimits or {}, "stackLimits"
        end
    end

    local function RefreshList()
        local list = GetActiveList()
        local items = {}
        for itemID, val in pairs(list) do
            items[#items + 1] = { id = itemID, value = val }
        end
        table.sort(items, function(a, b) return a.id < b.id end)

        for i = 1, MAX_LIST_ROWS do
            if listRows[i] then listRows[i]:Hide() end
        end

        for i, item in ipairs(items) do
            if i > MAX_LIST_ROWS then break end
            if not listRows[i] then
                local row = CreateFrame("Frame", nil, f.listArea)
                row:SetSize(520, 22)

                local bg = row:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints()
                bg:SetColorTexture(1, 1, 1, i % 2 == 0 and 0.03 or 0)
                row.bg = bg

                row.idText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                row.idText:SetPoint("LEFT", 4, 0)
                row.idText:SetWidth(60)
                row.idText:SetJustifyH("LEFT")
                row.idText:SetTextColor(0.6, 0.6, 0.6)

                row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                row.nameText:SetPoint("LEFT", 70, 0)
                row.nameText:SetWidth(280)
                row.nameText:SetJustifyH("LEFT")

                row.valueText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                row.valueText:SetPoint("LEFT", 360, 0)
                row.valueText:SetWidth(60)
                row.valueText:SetJustifyH("RIGHT")
                row.valueText:SetTextColor(1, 0.82, 0)

                row.removeBtn = CreateCanvasButton(row, "X", 24, 0.40, 0.12, 0.12)
                row.removeBtn:SetPoint("RIGHT", -4, 0)

                listRows[i] = row
            end

            local row = listRows[i]
            row.idText:SetText(tostring(item.id))
            local itemName = C_Item.GetItemNameByID(item.id)
            row.nameText:SetText(itemName or "Loading...")
            row:SetPoint("TOPLEFT", f.listArea, "TOPLEFT", 0, -((i - 1) * 22))

            if activeTab == "stack" then
                row.valueText:SetText("x" .. tostring(item.value))
                row.valueText:Show()
            else
                row.valueText:Hide()
            end

            -- Update alternating bg
            row.bg:SetColorTexture(1, 1, 1, i % 2 == 0 and 0.03 or 0)

            local itemID = item.id
            row.removeBtn:SetScript("OnClick", function()
                local activeList = GetActiveList()
                activeList[itemID] = nil
                RefreshList()
            end)
            row:Show()
        end

        -- Count label
        local count = 0
        for _ in pairs(list) do count = count + 1 end
        f.countLabel:SetText(format("%d item%s", count, count == 1 and "" or "s"))

        if count == 0 then
            f.emptyLabel:Show()
        else
            f.emptyLabel:Hide()
        end

        -- Show/hide stack count input
        if activeTab == "stack" then
            f.countInput:Show()
            f.countInputLabel:Show()
        else
            f.countInput:Hide()
            f.countInputLabel:Hide()
        end
    end

    local function SetTab(tab)
        activeTab = tab
        for _, btn in pairs(f.tabButtons) do
            if btn.tabKey == tab then
                btn:SetBackdropColor(0.0, 0.35, 0.55, 1)
                btn:SetBackdropBorderColor(0.0, 0.50, 0.75, 1)
            else
                btn:SetBackdropColor(0.18, 0.18, 0.18, 1)
                btn:SetBackdropBorderColor(0.33, 0.33, 0.33, 1)
            end
        end
        RefreshList()
    end

    -- Tab buttons
    f.tabButtons = {}
    local tabs = {
        { key = "never", label = "Never-Sell", x = 16 },
        { key = "always", label = "Always-Sell", x = 126 },
        { key = "stack", label = "Stack Limits", x = 236 },
    }
    for _, tab in ipairs(tabs) do
        local btn = CreateCanvasButton(f, tab.label, 100)
        btn:SetPoint("TOPLEFT", tab.x, -16)
        btn.tabKey = tab.key
        btn:SetScript("OnClick", function() SetTab(tab.key) end)
        f.tabButtons[tab.key] = btn
    end

    -- Column headers
    local headerY = -48
    local hdrId = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hdrId:SetPoint("TOPLEFT", 20, headerY)
    hdrId:SetText("|cFFAAAAAAAAID|r")
    local hdrName = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hdrName:SetPoint("TOPLEFT", 86, headerY)
    hdrName:SetText("|cFFAAAAAAName|r")
    local hdrVal = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hdrVal:SetPoint("TOPLEFT", 376, headerY)
    hdrVal:SetText("|cFFAAAAAALimit|r")
    f.hdrVal = hdrVal

    -- List area
    local listArea = CreateFrame("Frame", nil, f)
    listArea:SetPoint("TOPLEFT", 16, -64)
    listArea:SetSize(520, MAX_LIST_ROWS * 22)
    f.listArea = listArea

    local emptyLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    emptyLabel:SetPoint("TOPLEFT", listArea, "TOPLEFT", 4, 0)
    emptyLabel:SetText("|cFFAAAAAA(empty)|r")
    emptyLabel:Hide()
    f.emptyLabel = emptyLabel

    -- Count label
    local countLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    countLabel:SetPoint("TOPLEFT", 16, -68 - (MAX_LIST_ROWS * 22))
    countLabel:SetTextColor(0.6, 0.6, 0.6)
    f.countLabel = countLabel

    -- Add section
    local addY = -86 - (MAX_LIST_ROWS * 22)
    local addLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    addLabel:SetPoint("TOPLEFT", 16, addY)
    addLabel:SetText("Item ID:")

    local addInput = CreateCanvasInput(f, 100)
    addInput:SetPoint("TOPLEFT", 72, addY + 2)
    f.addInput = addInput

    local countInputLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    countInputLabel:SetPoint("LEFT", addInput, "RIGHT", 8, 0)
    countInputLabel:SetText("Keep:")
    countInputLabel:Hide()
    f.countInputLabel = countInputLabel

    local countInput = CreateCanvasInput(f, 50)
    countInput:SetPoint("LEFT", countInputLabel, "RIGHT", 4, 0)
    countInput:Hide()
    f.countInput = countInput

    local addBtn = CreateCanvasButton(f, "Add", 50, 0.0, 0.35, 0.15)
    addBtn:SetPoint("TOPLEFT", 316, addY + 2)
    addBtn:SetScript("OnClick", function()
        local itemID = tonumber(addInput:GetText())
        if not itemID then
            ns:Print("Enter a valid item ID.")
            return
        end
        if activeTab == "never" then
            AutoSellPlusDB.neverSellList[itemID] = true
            ns:Print(format("Added %d to never-sell list.", itemID))
        elseif activeTab == "always" then
            AutoSellPlusDB.alwaysSellList[itemID] = true
            ns:Print(format("Added %d to always-sell list.", itemID))
        elseif activeTab == "stack" then
            local count = tonumber(countInput:GetText())
            if not count or count < 1 then
                ns:Print("Enter a valid stack count.")
                return
            end
            AutoSellPlusDB.stackLimits[itemID] = count
            ns:Print(format("Set stack limit for %d to %d.", itemID, count))
            countInput:SetText("")
        end
        addInput:SetText("")
        addInput:ClearFocus()
        RefreshList()
    end)

    -- Import / Export buttons
    local actionY = addY - 30
    local importBtn = CreateCanvasButton(f, "Import Lists", 100, 0.0, 0.30, 0.50)
    importBtn:SetPoint("TOPLEFT", 16, actionY)
    importBtn:SetScript("OnClick", function()
        CreateImportExportFrame("Import Lists", "import")
    end)

    local exportBtn = CreateCanvasButton(f, "Export Lists", 100, 0.0, 0.30, 0.50)
    exportBtn:SetPoint("LEFT", importBtn, "RIGHT", 8, 0)
    exportBtn:SetScript("OnClick", function()
        CreateImportExportFrame("Export Lists", "export")
    end)

    f:SetScript("OnShow", function()
        SetTab(activeTab)
    end)

    return f
end

-- ============================================================
-- Canvas: Quick Actions
-- ============================================================

local function CreateActionsCanvas()
    local f = CreateFrame("Frame")
    f:Hide()

    CreateSectionHeader(f, "Quick Actions", 16, -16)

    local actions = {
        { label = "Open Session Stats", y = -44, r = 0.0, g = 0.30, b = 0.50,
            click = function() ns:PrintSessionReport() end },
        { label = "Open Sale History", y = -72, r = 0.0, g = 0.30, b = 0.50,
            click = function() ns:ShowHistoryPanel() end },
        { label = "Run Setup Wizard", y = -100, r = 0.0, g = 0.30, b = 0.50,
            click = function()
                Settings.OpenToCategory(ns.settingsCategoryID)
                C_Timer.After(0.1, function() ns:ShowWizard() end)
            end },
    }

    for _, action in ipairs(actions) do
        local btn = CreateCanvasButton(f, action.label, 180, action.r, action.g, action.b)
        btn:SetPoint("TOPLEFT", 20, action.y)
        btn:SetScript("OnClick", action.click)
    end

    CreateSectionHeader(f, "Reset (Destructive)", 16, -144)

    local resetBtn = CreateCanvasButton(f, "Reset All Settings", 160, 0.40, 0.12, 0.12)
    resetBtn:SetPoint("TOPLEFT", 20, -168)
    resetBtn:SetScript("OnClick", function()
        StaticPopupDialogs["ASP_UI_RESET_CONFIRM"] = {
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
        StaticPopup_Show("ASP_UI_RESET_CONFIRM")
    end)

    local resetListsBtn = CreateCanvasButton(f, "Clear All Lists", 160, 0.40, 0.12, 0.12)
    resetListsBtn:SetPoint("TOPLEFT", 20, -196)
    resetListsBtn:SetScript("OnClick", function()
        StaticPopupDialogs["ASP_UI_RESETLISTS_CONFIRM"] = {
            text = "AutoSellPlus: Clear ALL never-sell, always-sell, and stack limit lists?",
            button1 = "Clear",
            button2 = "Cancel",
            OnAccept = function()
                wipe(AutoSellPlusDB.neverSellList)
                wipe(AutoSellPlusDB.alwaysSellList)
                wipe(AutoSellPlusDB.stackLimits)
                if AutoSellPlusCharDB then
                    wipe(AutoSellPlusCharDB.charNeverSellList)
                    wipe(AutoSellPlusCharDB.charAlwaysSellList)
                end
                ns:Print("All lists cleared.")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("ASP_UI_RESETLISTS_CONFIRM")
    end)

    local resetSessionBtn = CreateCanvasButton(f, "Reset Session Stats", 160, 0.35, 0.22, 0.05)
    resetSessionBtn:SetPoint("TOPLEFT", 20, -228)
    resetSessionBtn:SetScript("OnClick", function()
        ns:ResetSession()
    end)

    local clearHistoryBtn = CreateCanvasButton(f, "Clear Sale History", 160, 0.35, 0.22, 0.05)
    clearHistoryBtn:SetPoint("TOPLEFT", 20, -256)
    clearHistoryBtn:SetScript("OnClick", function()
        ns:ClearSaleHistory()
    end)

    return f
end

-- ============================================================
-- Settings Panel Registration
-- ============================================================

local function RegisterSettingsPanel()
    local category = Settings.RegisterVerticalLayoutCategory(addonName)
    ns.settingsCategoryID = category:GetID()

    local globalDB = AutoSellPlusDB.global

    -- Gold proxy: sliders show gold instead of copper
    local goldProxy = setmetatable({}, {
        __index = function(_, key)
            return math.floor((globalDB[key] or 0) / 10000)
        end,
        __newindex = function(_, key, value)
            globalDB[key] = (value or 0) * 10000
        end,
    })

    -- ── Helpers ──

    local function AddBool(cat, key, name, tooltip)
        local setting = Settings.RegisterAddOnSetting(cat, key, key, globalDB, Settings.VarType.Boolean, name, ns.globalDefaults[key])
        Settings.CreateCheckbox(cat, setting, tooltip)
        return setting
    end

    local function AddSlider(cat, key, name, tooltip, minVal, maxVal, step, db, defaultOverride, formatter)
        db = db or globalDB
        local def = defaultOverride or ns.globalDefaults[key] or 0
        local setting = Settings.RegisterAddOnSetting(cat, key, key, db, Settings.VarType.Number, name, def)
        local options = Settings.CreateSliderOptions(minVal, maxVal, step)
        if formatter then
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, formatter)
        else
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(val)
                return tostring(val)
            end)
        end
        Settings.CreateSlider(cat, setting, options, tooltip)
        return setting
    end

    local function AddDropdown(cat, key, name, tooltip, opts)
        local varType = type(ns.globalDefaults[key]) == "number" and Settings.VarType.Number or Settings.VarType.String
        local setting = Settings.RegisterAddOnSetting(cat, key, key, globalDB, varType, name, ns.globalDefaults[key])
        Settings.CreateDropdown(cat, setting, function()
            local container = Settings.CreateControlTextContainer()
            for _, opt in ipairs(opts) do
                container:Add(opt[1], opt[2])
            end
            return container:GetData()
        end, tooltip)
        return setting
    end

    -- ══════════════════════════════════════════
    -- General
    -- ══════════════════════════════════════════

    AddBool(category, "enabled", "Enable AutoSellPlus",
        "Toggle whether the addon is active.")
    AddBool(category, "showSummary", "Show Summary",
        "Print a summary of total gold earned after selling.")
    AddBool(category, "showItemized", "Show Itemized Sales",
        "Print each item sold individually in chat.")
    AddBool(category, "dryRun", "Dry Run Mode",
        "Preview what would be sold without actually selling anything.")

    -- ══════════════════════════════════════════
    -- Automation
    -- ══════════════════════════════════════════

    local automationCat = Settings.RegisterVerticalLayoutSubcategory(category, "Automation")

    AddDropdown(automationCat, "autoSellMode", "Auto-Sell Mode",
        "How AutoSellPlus behaves when visiting a merchant.",
        { {"popup", "Review Popup"}, {"oneclick", "One-Click Popup"}, {"autosell", "Fully Automatic"} })

    AddSlider(automationCat, "autoSellDelay", "Auto-Sell Delay (seconds)",
        "Seconds to wait before auto-selling (autosell mode only). Set 0 for immediate.",
        0, 10, 1, nil, nil, function(val) return val .. "s" end)

    AddBool(automationCat, "autoRepair", "Auto-Repair",
        "Automatically repair gear at merchants.")
    AddBool(automationCat, "autoRepairGuild", "Use Guild Funds for Repair",
        "Try guild bank funds first when auto-repairing.")
    AddBool(automationCat, "muteVendorSounds", "Mute Vendor Sounds",
        "Silence vendor sell sounds during bulk selling.")

    -- ══════════════════════════════════════════
    -- Protection
    -- ══════════════════════════════════════════

    local protectionCat = Settings.RegisterVerticalLayoutSubcategory(category, "Protection")

    AddBool(protectionCat, "protectEquipmentSets", "Protect Equipment Sets",
        "Never sell items that are part of an equipment set.")
    AddBool(protectionCat, "protectUncollectedTransmog", "Protect Uncollected Transmog",
        "Never sell equippable items whose appearance has not been collected.")
    AddBool(protectionCat, "protectTransmogSource", "Protect Transmog Sources",
        "Enhanced transmog source-level protection.")
    AddBool(protectionCat, "protectBoE", "Protect BoE Items",
        "Never sell unbound bind-on-equip items.")
    AddBool(protectionCat, "allowBoESell", "Allow BoE Selling (Override)",
        "Allow selling BoE items even when protection is enabled. Use with caution.")
    AddBool(protectionCat, "onlyEquippable", "Only Equippable Items",
        "Limit quality-based filters (white/green/blue/epic) to armor and weapons only.")
    AddBool(protectionCat, "buybackWarning", "Buyback Warning",
        "Warn when selling more than 12 items (buyback limit).")
    AddBool(protectionCat, "epicConfirm", "Confirm Epic Sales",
        "Show a confirmation dialog when selling epic items.")
    AddBool(protectionCat, "highValueConfirm", "Confirm High-Value Sales",
        "Show a confirmation dialog for items above the gold threshold.")

    AddSlider(protectionCat, "highValueThreshold", "High-Value Threshold (gold)",
        "Items above this gold value trigger a confirmation dialog.",
        0, 100, 1, goldProxy, math.floor((ns.globalDefaults.highValueThreshold or 50000) / 10000),
        function(val) return val .. "g" end)

    AddBool(protectionCat, "excludeCurrentExpansion", "Exclude Current Expansion",
        "Hide all items from the current expansion in the sell popup.")

    -- ══════════════════════════════════════════
    -- Marking
    -- ══════════════════════════════════════════

    local markingCat = Settings.RegisterVerticalLayoutSubcategory(category, "Marking")

    AddBool(markingCat, "autoMarkGrayLoot", "Auto-Mark Gray Loot",
        "Automatically mark looted gray items as junk.")

    AddSlider(markingCat, "autoMarkBelowIlvl", "Auto-Mark Below Item Level",
        "Automatically mark looted equippable items below this ilvl as junk. Set 0 to disable.",
        0, 700, 5)

    AddDropdown(markingCat, "overlayMode", "Overlay Visual Mode",
        "Visual style for marked item overlays in bags.",
        { {"border", "Border Only"}, {"tint", "Tint Only"}, {"full", "Border + Tint"} })

    AddBool(markingCat, "showBagGoldDisplay", "Show Bag Gold Display",
        "Show total vendor value on the bag bar.")

    -- ══════════════════════════════════════════
    -- Display
    -- ══════════════════════════════════════════

    local displayCat = Settings.RegisterVerticalLayoutSubcategory(category, "Display")

    AddBool(displayCat, "showUndoToast", "Show Undo Toast",
        "Show an undo notification after selling.")
    AddBool(displayCat, "showMinimapButton", "Show Minimap Button",
        "Show the AutoSellPlus minimap button.")

    -- ══════════════════════════════════════════
    -- Bag Maintenance
    -- ══════════════════════════════════════════

    local bagCat = Settings.RegisterVerticalLayoutSubcategory(category, "Bag Maintenance")

    AddSlider(bagCat, "freeSlotThreshold", "Free Slot Alert Threshold",
        "Alert when free bag slots drop below this number. Set 0 to disable.",
        0, 50, 1)

    AddDropdown(bagCat, "freeSlotAlertMode", "Alert Mode",
        "How to notify when bag space is low.",
        { {"chat", "Chat Message"}, {"screen", "Screen Warning"} })

    AddBool(bagCat, "evictionEnabled", "Enable Value-Based Eviction",
        "When bags are full at a vendor, suggest selling cheapest items to free space.")

    -- ══════════════════════════════════════════
    -- Auto-Destroy
    -- ══════════════════════════════════════════

    local destroyCat = Settings.RegisterVerticalLayoutSubcategory(category, "Auto-Destroy")

    AddBool(destroyCat, "autoDestroyEnabled", "Enable Auto-Destroy",
        "Allow destroying junk items via /asp destroy. Must be enabled before use.")
    AddBool(destroyCat, "autoDestroyConfirm", "Require Confirmation",
        "Show a confirmation dialog before destroying items.")

    AddDropdown(destroyCat, "autoDestroyMaxQuality", "Max Destroy Quality",
        "Maximum item quality eligible for destruction.",
        { {0, "Poor (Gray)"}, {1, "Common (White)"}, {2, "Uncommon (Green)"}, {3, "Rare (Blue)"}, {4, "Epic (Purple)"} })

    AddSlider(destroyCat, "autoDestroyMaxValue", "Max Destroy Value (gold)",
        "Only destroy items worth less than this gold amount. Set 0 to destroy regardless of value.",
        0, 100, 1, goldProxy, math.floor((ns.globalDefaults.autoDestroyMaxValue or 0) / 10000),
        function(val) return val .. "g" end)

    -- ══════════════════════════════════════════
    -- Canvas sub-categories
    -- ══════════════════════════════════════════

    local profilesCanvas = CreateProfilesCanvas()
    Settings.RegisterCanvasLayoutSubcategory(category, profilesCanvas, "Profiles & Templates")

    local listsCanvas = CreateListsCanvas()
    Settings.RegisterCanvasLayoutSubcategory(category, listsCanvas, "Lists")

    local actionsCanvas = CreateActionsCanvas()
    Settings.RegisterCanvasLayoutSubcategory(category, actionsCanvas, "Quick Actions")

    Settings.RegisterAddOnCategory(category)
end

-- ============================================================
-- Init
-- ============================================================

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    self:UnregisterEvent("PLAYER_LOGIN")
    RegisterSettingsPanel()

    ns.ShowExportFrame = function()
        CreateImportExportFrame("Export Lists", "export")
    end
    ns.ShowImportFrame = function()
        CreateImportExportFrame("Import Lists", "import")
    end
end)
