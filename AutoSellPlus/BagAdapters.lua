local addonName, ns = ...

-- Bag addon adapters for compatibility
local BAG_ADDON_ADAPTERS = {
    default = {
        getFrame = function(bag, slot)
            -- Combined bags view (modern WoW)
            local combined = _G["ContainerFrameCombinedBags"]
            if combined and combined:IsShown() and combined.Items then
                for _, btn in pairs(combined.Items) do
                    if btn.GetBagID and btn:GetBagID() == bag and btn:GetID() == slot then
                        return btn
                    end
                end
            end
            -- Individual container frames (search by bag ID, not index)
            for i = 1, 13 do
                local frame = _G["ContainerFrame" .. i]
                if frame and frame:IsShown() and frame.GetBagID and frame:GetBagID() == bag then
                    if frame.Items then
                        for _, btn in pairs(frame.Items) do
                            if btn:GetID() == slot then
                                return btn
                            end
                        end
                    end
                    -- Classic fallback: global name
                    local name = frame:GetName()
                    if name then
                        local f = _G[name .. "Item" .. slot]
                        if f then return f end
                    end
                end
            end
            return nil
        end,
    },
    bagnon = {
        getFrame = function(bag, slot)
            -- Bagnon: use ItemGroup.byBag lookup table
            local inv = _G["BagnonInventory1"]
            if inv and inv.ItemGroup and inv.ItemGroup.byBag then
                local bagSlots = inv.ItemGroup.byBag[bag]
                if bagSlots and bagSlots[slot] then
                    return bagSlots[slot]
                end
            end
            -- Fallback: iterate serial-numbered frames
            local i = 1
            while i <= 500 do
                local btn = _G["BagnonContainerItem" .. i]
                if not btn then break end
                if btn:IsVisible() then
                    local btnBag = btn.GetBag and btn:GetBag() or btn.bag
                    if btnBag == bag and btn:GetID() == slot then
                        return btn
                    end
                end
                i = i + 1
            end
            return nil
        end,
    },
    adibags = {
        getFrame = function(bag, slot)
            -- AdiBags: serial-numbered buttons with .bag/.slot properties
            local i = 1
            while i <= 500 do
                local btn = _G["AdiBagsItemButton" .. i]
                if not btn then break end
                if btn:IsVisible() and btn.bag == bag and btn.slot == slot then
                    return btn
                end
                i = i + 1
            end
            return nil
        end,
    },
    arkinventory = {
        getFrame = function(bag, slot)
            -- ArkInventory: bag index is 1-based (bag + 1)
            return _G["ARKINV_Frame1ScrollContainerBag" .. (bag + 1) .. "Item" .. slot]
        end,
    },
    baganator = {
        getFrame = function(bag, slot)
            -- Baganator Classic: try named frames
            local i = 1
            while i <= 500 do
                local btn = _G["BGRLiveItemButton" .. i]
                if not btn then break end
                if btn:IsVisible() and btn.GetBagID and btn:GetBagID() == bag and btn:GetID() == slot then
                    return btn
                end
                i = i + 1
            end
            -- Baganator Retail: frames are unnamed pools, handled by corner widget
            return nil
        end,
    },
}

function ns:GetBagAdapterName()
    if Baganator then return "baganator" end
    if Bagnon then return "bagnon" end
    if AdiBags then return "adibags" end
    if ArkInventory then return "arkinventory" end
    return "default"
end

function ns:GetBagItemFrame(bag, slot)
    local adapterName = self:GetBagAdapterName()
    local adapter = BAG_ADDON_ADAPTERS[adapterName] or BAG_ADDON_ADAPTERS.default
    return adapter.getFrame(bag, slot)
end
