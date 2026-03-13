local addonName, ns = ...

local FLAT_BACKDROP = ns.FLAT_BACKDROP

-- ============================================================
-- Shared Styled Widget Library
-- ============================================================

function ns.CreateStyledCheck(parent, size)
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

function ns.CreateStyledSlider(parent, minVal, maxVal, step)
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

function ns.CreateStyledEditBox(parent, width)
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

function ns.CreateFlatButton(parent, text, width, height)
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

function ns.CreateCloseButton(parent)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(22, 22)
    btn:SetPoint("TOPRIGHT", -4, -4)
    btn:SetBackdrop(FLAT_BACKDROP)
    btn:SetBackdropColor(0.12, 0.12, 0.12, 1)
    btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lbl:SetPoint("CENTER")
    lbl:SetText("x")
    lbl:SetTextColor(0.60, 0.60, 0.60)
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.7, 0.15, 0.15, 1)
        lbl:SetTextColor(1, 0.3, 0.3)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        lbl:SetTextColor(0.60, 0.60, 0.60)
    end)
    return btn
end
