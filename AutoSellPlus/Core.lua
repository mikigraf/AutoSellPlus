local addonName, ns = ...

local freeSlotAlertCooldown = 0

-- ============================================================
-- Auto-Repair
-- ============================================================

local function DoAutoRepair()
    if not ns.db.autoRepair then return end
    if not CanMerchantRepair() then return end

    local repairCost, canRepair = GetRepairAllCost()
    if not canRepair or repairCost == 0 then return end

    -- Try guild funds first
    if ns.db.autoRepairGuild and IsInGuild() then
        local guildOk = pcall(function()
            if CanGuildBankRepair() then
                RepairAllItems(true)
            end
        end)
        if guildOk then
            ns:Print(format("Auto-repaired for %s (guild funds)", ns:FormatMoney(repairCost)))
            return
        end
    end

    -- Personal funds
    if GetMoney() >= repairCost then
        RepairAllItems(false)
        ns:Print(format("Auto-repaired for %s", ns:FormatMoney(repairCost)))
    else
        ns:Print("Not enough gold to auto-repair.")
    end
end

-- ============================================================
-- Bag Space Monitoring
-- ============================================================

local function CheckBagSpace()
    local threshold = ns.db.freeSlotThreshold
    if threshold <= 0 then return end

    local now = GetServerTime()
    if now < freeSlotAlertCooldown then return end

    local freeSlots = ns:CountFreeSlots()
    if freeSlots < threshold then
        freeSlotAlertCooldown = now + 60
        local mode = ns.db.freeSlotAlertMode or "chat"
        local msg = format("Low bag space! %d free slot%s (threshold: %d)", freeSlots, freeSlots == 1 and "" or "s", threshold)
        if mode == "chat" then
            ns:Print(msg)
        elseif mode == "screen" then
            if UIErrorsFrame then
                UIErrorsFrame:AddMessage(msg, 1, 0.5, 0, 1)
            end
        end
    end
end

-- ============================================================
-- Conflict Detection
-- ============================================================

local function DetectConflicts()
    if LeaPlusDB and LeaPlusDB.AutoSellJunk and LeaPlusDB.AutoSellJunk == "On" then
        ns:Print("|cFFFF6600Warning:|r Leatrix Plus auto-sell junk is enabled. This may conflict with AutoSellPlus.")
    end

    if Postal then
        ns:DebugPrint("Postal detected. Auto-sell will be suppressed during mail processing.")
    end
end

-- ============================================================
-- Login Self-Test
-- ============================================================

local function RunSelfTest()
    local disabled = {}

    if not C_Container or not C_Container.UseContainerItem then
        ns.features.selling = false
        disabled[#disabled + 1] = "selling"
    end
    if not C_Container or not C_Container.GetContainerNumSlots then
        ns.features.scanning = false
        disabled[#disabled + 1] = "scanning"
    end
    if not C_Item or not C_Item.GetItemInfo then
        ns.features.itemInfo = false
        disabled[#disabled + 1] = "itemInfo"
    end
    if not C_TransmogCollection or not C_TransmogCollection.PlayerHasTransmog then
        ns.features.transmog = false
        disabled[#disabled + 1] = "transmog"
    end
    if not C_EquipmentSet or not C_EquipmentSet.GetEquipmentSetIDs then
        ns.features.equipSets = false
        disabled[#disabled + 1] = "equipSets"
    end
    if not C_Container or not C_Container.PickupContainerItem then
        ns.features.destroying = false
        disabled[#disabled + 1] = "destroying"
    end

    if #disabled > 0 then
        ns:Print("|cFFFF0000Warning:|r Disabled features due to missing APIs: " .. table.concat(disabled, ", "))
    end
end

-- ============================================================
-- Slash Command Handler
-- ============================================================

local function HandleSlashCommand(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        args[#args + 1] = word:lower()
    end

    local cmd = args[1]

    if not cmd or cmd == "help" then
        ns:Print("v" .. ns.version .. " - Commands:")
        print("  /asp toggle - Enable/disable addon")
        print("  /asp dryrun - Toggle dry run mode")
        print("  /asp config - Open settings panel")
        print("  /asp sell - Sell immediately (at merchant)")
        print("  /asp preview - One-shot dry run")
        print("  /asp mark - Toggle bulk mark mode")
        print("  /asp debug - Toggle debug output")
        print("  /asp session - View session stats")
        print("  /asp session reset - Reset session")
        print("  /asp log - Show last 10 sales")
        print("  /asp log ui - Open sale history panel")
        print("  /asp log clear - Clear sale history")
        print("  /asp add <itemID> - Add to never-sell list")
        print("  /asp remove <itemID> - Remove from never-sell list")
        print("  /asp list - Show never-sell and always-sell lists")
        print("  /asp export - Export lists")
        print("  /asp import - Import lists")
        print("  /asp overlay - Cycle overlay visual mode")
        print("  /asp keep <itemID> <count> - Set stack limit")
        print("  /asp keep list - Show stack limits")
        print("  /asp keep clear [itemID] - Clear stack limit(s)")
        print("  /asp destroy - Destroy junk items")
        print("  /asp profile save|load|list|delete <name>")
        print("  /asp template [name|list] - Apply a preset template")
        print("  /asp wizard - Re-run setup wizard")
        print("  /asp reset - Reset all settings (with confirm)")
        print("  /asp reset lists - Clear all lists")
        return
    end

    if cmd == "config" or cmd == "options" then
        Settings.OpenToCategory(ns.settingsCategoryID)
        return
    end

    if cmd == "toggle" then
        ns.db.enabled = not ns.db.enabled
        ns:Print("Addon " .. (ns.db.enabled and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))
        return
    end

    if cmd == "dryrun" then
        ns.db.dryRun = not ns.db.dryRun
        ns:Print("Dry run " .. (ns.db.dryRun and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))
        return
    end

    if cmd == "debug" then
        ns.debugMode = not ns.debugMode
        ns:Print("Debug mode " .. (ns.debugMode and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))
        return
    end

    if cmd == "sell" then
        local queue = ns:BuildSellQueue()
        if #queue > 0 then
            ns:ConfirmAndSell(queue)
        else
            ns:Print("Nothing to sell.")
        end
        return
    end

    if cmd == "preview" then
        local origDryRun = ns.db.dryRun
        ns.db.dryRun = true
        local queue = ns:BuildSellQueue()
        if #queue > 0 then
            ns:StartSelling(queue)
        else
            ns:Print("Nothing would be sold.")
        end
        ns.db.dryRun = origDryRun
        return
    end

    if cmd == "mark" then
        ns:ToggleBulkMarkMode()
        return
    end

    if cmd == "session" then
        if args[2] == "reset" then
            ns:ResetSession()
        elseif args[2] == "export" then
            local r = ns:GetSessionReport()
            ns:Print(format("Session export: %d items, %s, %dg/hr", r.itemCount, ns:FormatMoney(r.totalCopper), r.goldPerHour))
        else
            ns:PrintSessionReport()
        end
        return
    end

    if cmd == "log" then
        if args[2] == "clear" then
            ns:ClearSaleHistory()
        elseif args[2] == "ui" then
            ns:ShowHistoryPanel()
        else
            ns:PrintSaleLog(tonumber(args[2]) or 10)
        end
        return
    end

    if cmd == "add" then
        local itemID = tonumber(args[2])
        if not itemID then
            ns:Print("Usage: /asp add <itemID>")
            return
        end
        ns.db.neverSellList[itemID] = true
        local itemName = C_Item.GetItemNameByID(itemID)
        ns:Print(format("Added %s (ID: %d) to never-sell list", itemName or "Unknown", itemID))
        return
    end

    if cmd == "remove" then
        local itemID = tonumber(args[2])
        if not itemID then
            ns:Print("Usage: /asp remove <itemID>")
            return
        end
        ns.db.neverSellList[itemID] = nil
        local itemName = C_Item.GetItemNameByID(itemID)
        ns:Print(format("Removed %s (ID: %d) from never-sell list", itemName or "Unknown", itemID))
        return
    end

    if cmd == "list" then
        ns:Print("Never-sell list (global):")
        local count = 0
        for itemID in pairs(ns.db.neverSellList) do
            local itemName = C_Item.GetItemNameByID(itemID)
            print(format("  [%d] %s", itemID, itemName or "Unknown"))
            count = count + 1
        end
        if count == 0 then print("  (empty)") end

        if AutoSellPlusCharDB and AutoSellPlusCharDB.charNeverSellList then
            ns:Print("Never-sell list (this char):")
            count = 0
            for itemID in pairs(AutoSellPlusCharDB.charNeverSellList) do
                local itemName = C_Item.GetItemNameByID(itemID)
                print(format("  [%d] %s", itemID, itemName or "Unknown"))
                count = count + 1
            end
            if count == 0 then print("  (empty)") end
        end

        ns:Print("Always-sell list (global):")
        count = 0
        for itemID in pairs(ns.db.alwaysSellList) do
            local itemName = C_Item.GetItemNameByID(itemID)
            print(format("  [%d] %s", itemID, itemName or "Unknown"))
            count = count + 1
        end
        if count == 0 then print("  (empty)") end

        if AutoSellPlusCharDB and AutoSellPlusCharDB.charAlwaysSellList then
            ns:Print("Always-sell list (this char):")
            count = 0
            for itemID in pairs(AutoSellPlusCharDB.charAlwaysSellList) do
                local itemName = C_Item.GetItemNameByID(itemID)
                print(format("  [%d] %s", itemID, itemName or "Unknown"))
                count = count + 1
            end
            if count == 0 then print("  (empty)") end
        end
        return
    end

    if cmd == "export" then
        if ns.ShowExportFrame then
            ns.ShowExportFrame()
        else
            local data = ns:SerializeList("all")
            ns:Print("Export data: " .. data)
        end
        return
    end

    if cmd == "import" then
        if ns.ShowImportFrame then
            ns.ShowImportFrame()
        else
            ns:Print("Usage: Paste import data after /asp import <data>")
            if args[2] then
                local data = table.concat(args, " ", 2)
                local ok, count = ns:DeserializeList(data)
                if ok then
                    ns:Print(format("Imported %d items.", count))
                else
                    ns:Print("Import failed.")
                end
            end
        end
        return
    end

    if cmd == "keep" then
        local sub = args[2]
        if sub == "list" then
            local limits = ns.db.stackLimits
            if not limits or not next(limits) then
                ns:Print("No stack limits set.")
            else
                ns:Print("Stack limits:")
                for itemID, limit in pairs(limits) do
                    local itemName = C_Item.GetItemNameByID(itemID)
                    print(format("  [%d] %s: keep %d", itemID, itemName or "Unknown", limit))
                end
            end
        elseif sub == "clear" then
            local itemID = tonumber(args[3])
            if itemID then
                ns.db.stackLimits[itemID] = nil
                local itemName = C_Item.GetItemNameByID(itemID)
                ns:Print(format("Cleared stack limit for %s", itemName or "item " .. itemID))
            else
                wipe(ns.db.stackLimits)
                ns:Print("All stack limits cleared.")
            end
        else
            local itemID = tonumber(sub)
            local count = tonumber(args[3])
            if not itemID or not count then
                ns:Print("Usage: /asp keep <itemID> <count>")
                return
            end
            ns.db.stackLimits[itemID] = count
            local itemName = C_Item.GetItemNameByID(itemID)
            ns:Print(format("Will keep up to %d of %s", count, itemName or "item " .. itemID))
        end
        return
    end

    if cmd == "destroy" then
        ns:DestroyJunk()
        return
    end

    if cmd == "profile" then
        local sub = args[2]
        local name = args[3]
        if sub == "save" and name then
            ns:SaveProfile(name)
        elseif sub == "load" and name then
            ns:LoadProfile(name)
        elseif sub == "delete" and name then
            ns:DeleteProfile(name)
        elseif sub == "list" then
            ns:ListProfiles()
        else
            ns:Print("Usage: /asp profile save|load|list|delete <name>")
        end
        return
    end

    if cmd == "template" then
        if not args[2] or args[2] == "list" then
            ns:ListTemplates()
        else
            local name = table.concat(args, " ", 2)
            ns:ApplyTemplate(name)
        end
        return
    end

    if cmd == "wizard" then
        ns:ShowWizard()
        return
    end

    if cmd == "reset" then
        if args[2] == "lists" then
            wipe(ns.db.neverSellList)
            wipe(ns.db.alwaysSellList)
            if AutoSellPlusCharDB then
                wipe(AutoSellPlusCharDB.charNeverSellList)
                wipe(AutoSellPlusCharDB.charAlwaysSellList)
            end
            ns:Print("All lists cleared.")
            return
        end

        StaticPopupDialogs["ASP_RESET_CONFIRM"] = {
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
        StaticPopup_Show("ASP_RESET_CONFIRM")
        return
    end

    if cmd == "overlay" then
        local modes = { "border", "tint", "full" }
        local current = ns.db.overlayMode or "border"
        local nextIdx = 1
        for i, m in ipairs(modes) do
            if m == current then
                nextIdx = (i % #modes) + 1
                break
            end
        end
        ns.db.overlayMode = modes[nextIdx]
        ns:Print(format("Overlay mode: |cFF00FF00%s|r", ns.db.overlayMode))
        ns:SafeCall(function() ns:RefreshOverlays() end)
        return
    end

    if cmd == "undo" then
        ns:UndoLastSale()
        return
    end

    ns:Print("Unknown command. Type /asp help for usage.")
end

SLASH_AUTOSELLPLUS1 = "/asp"
SLASH_AUTOSELLPLUS2 = "/autosell"
SlashCmdList["AUTOSELLPLUS"] = HandleSlashCommand

-- ============================================================
-- Event Frame
-- ============================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("MERCHANT_CLOSED")
eventFrame:RegisterEvent("EQUIPMENT_SETS_CHANGED")
eventFrame:RegisterEvent("UI_ERROR_MESSAGE")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        ns:RebuildEquipmentSetCache()

        -- Auto-load saved profile
        if AutoSellPlusCharDB.activeProfile ~= ""
            and AutoSellPlusDB.profiles[AutoSellPlusCharDB.activeProfile] then
            AutoSellPlusDB.global = ns.DeepCopy(AutoSellPlusDB.profiles[AutoSellPlusCharDB.activeProfile])
            ns.ValidateDB(AutoSellPlusDB.global, ns.globalDefaults)
            ns:DebugPrint("Auto-loaded profile: " .. AutoSellPlusCharDB.activeProfile)
        end

        ns:Print(format("v%s loaded. Type /asp for commands.", ns.version))

        -- Self-test
        ns:SafeCall(RunSelfTest)

        -- Initialize session
        ns:SafeCall(function() ns:InitSession() end)

        -- Initialize marking system
        ns:SafeCall(function() ns:InitMarking() end)

        -- Create minimap button
        ns:SafeCall(function() ns:CreateMinimapButton() end)

        -- Update junk value for alt tracking
        ns:SafeCall(function() ns:UpdateCharJunkValue() end)

        -- Conflict detection
        ns:SafeCall(DetectConflicts)

        -- First-run wizard (per-character)
        if not AutoSellPlusCharDB.charFirstRunComplete then
            C_Timer.After(2, function()
                ns:ShowWizard()
            end)
        end

        if ns._FireEvent then ns._FireEvent("LOADED") end

    elseif event == "MERCHANT_SHOW" then
        if ns.db.enabled then
            -- Auto-repair first
            ns:SafeCall(DoAutoRepair)

            -- Evict cheapest items if bags are full (before auto-sell)
            if ns.db.evictionEnabled and ns.db.freeSlotThreshold > 0 then
                ns:SafeCall(function() ns:EvictAtVendor() end)
            end

            -- Then handle sell mode
            ns:HandleAutoSell()
        end

    elseif event == "MERCHANT_CLOSED" then
        ns:HidePopup()
        ns:HideConfirmList()
        ns:StopSelling()
        ns:CancelAutoSell()
        StaticPopup_Hide("ASP_AUTOSELL_EPIC_CONFIRM")
        StaticPopup_Hide("ASP_AUTOSELL_HIGHVALUE_CONFIRM")
        StaticPopup_Hide("ASP_EVICT_CONFIRM")

    elseif event == "EQUIPMENT_SETS_CHANGED" then
        ns:RebuildEquipmentSetCache()

    elseif event == "UI_ERROR_MESSAGE" then
        if ns:IsSelling() then
            ns:StopSelling()
        end

    elseif event == "BAG_UPDATE_DELAYED" then
        ns:SafeCall(CheckBagSpace)
        ns:SafeCall(function() ns:UpdateCharJunkValue() end)
    end
end)
