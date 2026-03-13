local addonName, ns = ...

local FLAT_BACKDROP = ns.FLAT_BACKDROP

-- ============================================================
-- Toast Notification System
-- ============================================================

local TOAST_WIDTH = 300
local TOAST_HEIGHT = 36
local TOAST_SLIDE_OFFSET = 310
local TOAST_SLIDE_DURATION = 0.3
local TOAST_FADE_DURATION = 0.3
local TOAST_DEFAULT_DURATION = 5
local TOAST_MAX_VISIBLE = 5
local TOAST_PADDING = 4
local TOAST_RIGHT_MARGIN = 20
local TOAST_TOP_MARGIN = 200
local ACCENT_WIDTH = 4

local TOAST_COLORS = {
    success = { 0.1, 0.8, 0.1 },
    info    = { 0.3, 0.6, 1.0 },
    warning = { 1.0, 0.8, 0.1 },
    danger  = { 0.8, 0.1, 0.1 },
}

-- Active toasts (ordered oldest to newest)
local activeToasts = {}

-- Frame pool for recycling
local framePool = {}

-- ============================================================
-- Internal Helpers
-- ============================================================

local function RepositionToasts()
    for i, toast in ipairs(activeToasts) do
        local targetY = -(i - 1) * (TOAST_HEIGHT + TOAST_PADDING)
        toast.targetY = targetY
        -- Snap position if not currently animating slide-in
        if not toast.isSliding then
            toast:ClearAllPoints()
            toast:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT",
                -TOAST_RIGHT_MARGIN, -TOAST_TOP_MARGIN + targetY)
        end
    end
end

local function RemoveFromActive(toast)
    for i, t in ipairs(activeToasts) do
        if t == toast then
            table.remove(activeToasts, i)
            break
        end
    end
end

local function RecycleToast(toast)
    toast:Hide()
    toast:SetAlpha(1)
    toast:ClearAllPoints()
    toast.isSliding = false
    toast.isFading = false
    toast.slideElapsed = 0
    toast.fadeElapsed = 0
    toast.dismissTimer = nil
    toast.targetY = 0
    framePool[#framePool + 1] = toast
end

local function CreateToastFrame()
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(TOAST_WIDTH, TOAST_HEIGHT)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop(FLAT_BACKDROP)
    frame:SetBackdropColor(0.06, 0.06, 0.06, 0.96)
    frame:SetBackdropBorderColor(0, 0, 0, 1)

    -- Colored left accent bar
    local accent = frame:CreateTexture(nil, "OVERLAY")
    accent:SetPoint("TOPLEFT", 1, -1)
    accent:SetPoint("BOTTOMLEFT", 1, 1)
    accent:SetWidth(ACCENT_WIDTH)
    accent:SetColorTexture(1, 1, 1, 1)
    frame.accent = accent

    -- Message text
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", accent, "RIGHT", 8, 0)
    text:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    frame.text = text

    -- Animation state
    frame.isSliding = false
    frame.isFading = false
    frame.slideElapsed = 0
    frame.fadeElapsed = 0
    frame.targetY = 0

    -- OnUpdate handler for animations
    frame:SetScript("OnUpdate", function(self, elapsed)
        -- Slide-in animation
        if self.isSliding then
            self.slideElapsed = self.slideElapsed + elapsed
            local progress = self.slideElapsed / TOAST_SLIDE_DURATION
            if progress >= 1 then
                progress = 1
                self.isSliding = false
            end
            -- Ease-out: decelerate
            local eased = 1 - (1 - progress) * (1 - progress)
            local offsetX = TOAST_SLIDE_OFFSET * (1 - eased)
            self:ClearAllPoints()
            self:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT",
                -TOAST_RIGHT_MARGIN + offsetX,
                -TOAST_TOP_MARGIN + self.targetY)
        end

        -- Fade-out animation
        if self.isFading then
            self.fadeElapsed = self.fadeElapsed + elapsed
            local progress = self.fadeElapsed / TOAST_FADE_DURATION
            if progress >= 1 then
                self.isFading = false
                RemoveFromActive(self)
                RecycleToast(self)
                RepositionToasts()
                return
            end
            self:SetAlpha(1 - progress)
        end
    end)

    return frame
end

local function AcquireToast()
    if #framePool > 0 then
        local toast = framePool[#framePool]
        framePool[#framePool] = nil
        return toast
    end
    return CreateToastFrame()
end

-- ============================================================
-- Public API
-- ============================================================

function ns:DismissToast(toast)
    if not toast or toast.isFading then return end
    -- Cancel auto-dismiss timer
    if toast.dismissTimer then
        toast.dismissTimer:Cancel()
        toast.dismissTimer = nil
    end
    toast.isFading = true
    toast.fadeElapsed = 0
end

function ns:DismissAllToasts()
    -- Copy the list since dismissing modifies activeToasts
    local toasts = {}
    for i, t in ipairs(activeToasts) do
        toasts[i] = t
    end
    for _, toast in ipairs(toasts) do
        ns:DismissToast(toast)
    end
end

function ns:ShowToast(message, toastType, duration)
    toastType = toastType or "info"
    duration = duration or TOAST_DEFAULT_DURATION

    local colors = TOAST_COLORS[toastType] or TOAST_COLORS.info

    -- Enforce max visible: dismiss oldest if at capacity
    while #activeToasts >= TOAST_MAX_VISIBLE do
        ns:DismissToast(activeToasts[1])
    end

    local toast = AcquireToast()

    -- Configure appearance
    toast.accent:SetColorTexture(colors[1], colors[2], colors[3], 1)
    toast.text:SetText(message)

    -- Add to active list (newest at end)
    activeToasts[#activeToasts + 1] = toast

    -- Calculate target position (index-based, newest at bottom)
    local index = #activeToasts
    local targetY = -(index - 1) * (TOAST_HEIGHT + TOAST_PADDING)
    toast.targetY = targetY

    -- Start off-screen to the right
    toast:ClearAllPoints()
    toast:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT",
        -TOAST_RIGHT_MARGIN + TOAST_SLIDE_OFFSET,
        -TOAST_TOP_MARGIN + targetY)
    toast:SetAlpha(1)
    toast:Show()

    -- Begin slide-in
    toast.isSliding = true
    toast.slideElapsed = 0
    toast.isFading = false
    toast.fadeElapsed = 0

    -- Schedule auto-dismiss
    toast.dismissTimer = C_Timer.NewTimer(duration, function()
        toast.dismissTimer = nil
        ns:DismissToast(toast)
    end)

    return toast
end
