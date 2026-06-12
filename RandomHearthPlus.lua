--[[

Random Hearthstone Plus
======================================================================================================================================================
Enhanced version of Random Hearthstone by JamienAU.
Adds teleport toy support, modifier key bindings (Shift/Ctrl/Alt + click combinations), and full 12.0.5 API compatibility.

If there's a new hearthstone or teleport toy but the addon isn't being updated, simply add it to the rhToys list below.
ItemID can be found from the URL of the item page on Wowhead.com

Weary Spirit Binding (ID: 163206) does not appear to be in-game. Adding it to the list below may cause errors!

GitHub: https://github.com/davidchangok/RandomHearthPlus

]]
----------------------------------------------------------------------------------------------------------------------
-- Toy Database
----------------------------------------------------------------------------------------------------------------------
local rhToys = {
    -- Hearthstone Toys (original)
    184353, -- Kyrian Hearthstone
    183716, -- Venthyr Sinstone
    180290, -- Night Fae Hearthstone
    182773, -- Necrolord Hearthstone
    54452,  -- Ethereal Portal
    64488,  -- The Innkeeper's Daughter
    93672,  -- Dark Portal
    142542, -- Tome of Town Portal
    162973, -- Greatfather Winter's Hearthstone
    163045, -- Headless Horseman's Hearthstone
    165669, -- Lunar Elder's Hearthstone
    165670, -- Peddlefeet's Lovely Hearthstone
    165802, -- Noble Gardener's Hearthstone
    166746, -- Fire Eater's Hearthstone
    166747, -- Brewfest Reveler's Hearthstone
    168907, -- Holographic Digitalization Hearthstone
    172179, -- Eternal Traveler's Hearthstone
    193588, -- Timewalker's Hearthstone
    188952, -- Dominated Hearthstone
    200630, -- Ohn'ir Windsage's Hearthstone
    190237, -- Broker Translocation Matrix
    190196, -- Enlightened Hearthstone
    209035, -- Hearthstone of the Flame
    208704, -- Deepdweller's Earthen Hearthstone
    206195, -- Path of the Naaru
    212337, -- Stone of the Hearth
    210455, -- Draenic Hologem
    228940, -- Notorious Thread's Hearthstone
    235016, -- Redeployment Module
    236687, -- Explosive Hearthstone
    245970, -- P.O.S.T Master's Express Hearthstone
    246565, -- Cosmic Hearthstone
    263489, -- Naaru's Enfold
    257736, -- Lightcalled Hearthstone
    265100, -- Corewarden's Hearthstone
    263933, -- Preyseeker's Hearthstone
    -- Teleport Toys (new)
    253629, -- Private Key of the Arcanum
    243056, -- Delver's Ethreal Warp Gate
    230850, -- Delver's Robot 7001
}

----------------------------------------------------------------------------------------------------------------------
-- DO NOT EDIT BELOW HERE
-- Unless you want to, I'm not your supervisor.
----------------------------------------------------------------------------------------------------------------------

local rhpList, macroIcon, macroToyName, macroTimer, waitTimer, pendingMacroUpdate
local rhpCheckButtons, wait, lastRnd, loginMsg = {}, false, 0, "rhp1.0.0"
local playerClass = select(3, UnitClass("player"))
local addon, RHP = ...
local L = RHP.Localisation

-- Modifier key constants for attribute naming
local MOD_KEYS = { "SHIFT", "CTRL", "ALT" }
local MOD_ATTRS = { SHIFT = "shift", CTRL = "ctrl", ALT = "alt" }
local BTN_KEYS = { "1", "2", "3" }

-- Dropdown option identifiers (stored in dropdown:GetParent().optionValue or similar)
local DROPDOWN_RANDOM    = "RANDOM"
local DROPDOWN_HEARTH    = "HEARTHSTONE"
local DROPDOWN_DALARAN   = "DALARAN"
local DROPDOWN_GARRISON  = "GARRISON"

-- Resolve value-to-display mapping for modifier dropdowns
local function getModBindDisplayName(value)
    if value == nil then
        return L["RANDOM"]
    elseif value == "item:6948" then
        return L["HEARTHSTONE"]
    elseif value == "item:140192" then
        return L["DALARAN_HEARTH"]
    elseif value == "item:110560" then
        return L["GARRISON_HEARTH"]
    elseif type(value) == "number" and rhpDB and rhpDB.L and rhpDB.L.tList[value] then
        return rhpDB.L.tList[value]["name"]
    else
        return L["RANDOM"]
    end
end

----------------------------------------------------------------------------------------------------------------------
-- Frames
----------------------------------------------------------------------------------------------------------------------
local rhpOptionsPanel = CreateFrame("Frame")
rhpOptionsPanel.name = "Random Hearthstone Plus"
rhpOptionsPanel.OnCommit = function() rhpOptionsOkay(); end
rhpOptionsPanel.OnDefault = function() rhpResetDefaults(); end
rhpOptionsPanel.OnRefresh = function() end
local rhpCategory = Settings.RegisterCanvasLayoutCategory(rhpOptionsPanel, rhpOptionsPanel.name)
rhpCategory.ID = rhpOptionsPanel.name
Settings.RegisterAddOnCategory(rhpCategory)
local rhpTitle = CreateFrame("Frame", nil, rhpOptionsPanel)
local rhpDesc = CreateFrame("Frame", nil, rhpOptionsPanel)
local rhpOptionsScroll = CreateFrame("ScrollFrame", nil, rhpOptionsPanel, "UIPanelScrollFrameTemplate")
local rhpDivider = rhpOptionsScroll:CreateLine()
local rhpScrollChild = CreateFrame("Frame")
local rhpSelectAll = CreateFrame("Button", nil, rhpOptionsScroll, "UIPanelButtonTemplate")
local rhpDeselectAll = CreateFrame("Button", nil, rhpOptionsScroll, "UIPanelButtonTemplate")
local rhpOverride = CreateFrame("CheckButton", nil, rhpOptionsScroll, "UICheckButtonTemplate")
local rhpListener = CreateFrame("Frame")
local rhpBtn = CreateFrame("Button", "rhpB", nil, "SecureActionButtonTemplate")
local rhpDropdown = CreateFrame("DropdownButton", nil, rhpOptionsPanel, "WowStyle1DropdownTemplate")
local rhpDalHearth = CreateFrame("CheckButton", nil, rhpOptionsPanel, "UICheckButtonTemplate")
local rhpGarHearth = CreateFrame("CheckButton", nil, rhpOptionsPanel, "UICheckButtonTemplate")
local rhpMacroName = CreateFrame("EditBox", nil, rhpOptionsPanel, "InputBoxTemplate")

-- Modifier binding dropdowns (3x3 grid)
local rhpModDropdowns = {}
local rhpModSectionLabel = CreateFrame("Frame", nil, rhpOptionsPanel)
local rhpModHeaders = {}
local rhpModRowLabels = {}

----------------------------------------------------------------------------------------------------------------------
-- Functions
----------------------------------------------------------------------------------------------------------------------
-- Combat Check
local function combatCheck()
    if (InCombatLockdown() or UnitAffectingCombat("player") or UnitAffectingCombat("pet")) then
        return true
    end
end

-- Defer macro update until out of combat
local function deferMacroUpdate()
    if not pendingMacroUpdate then
        pendingMacroUpdate = true
        rhpListener:RegisterEvent("PLAYER_REGEN_ENABLED")
    end
end

-- Update all SecureActionButton attributes including modifier bindings
local function updateButtonAttributes()
    if combatCheck() then return end

    -- Main left-click action (random hearthstone toy)
    rhpBtn:SetAttribute("type", "toy")
    rhpBtn:SetAttribute("toy", macroToyName)

    -- Right click without modifiers → Dalaran Hearthstone
    if rhpDB.settings.dalOpt then
        rhpBtn:SetAttribute("type2", "item")
        rhpBtn:SetAttribute("item2", "item:140192")
    else
        rhpBtn:SetAttribute("type2", nil)
        rhpBtn:SetAttribute("item2", nil)
    end

    -- Middle click without modifiers → Garrison Hearthstone
    if rhpDB.settings.garOpt then
        rhpBtn:SetAttribute("type3", "item")
        rhpBtn:SetAttribute("item3", "item:110560")
    else
        rhpBtn:SetAttribute("type3", nil)
        rhpBtn:SetAttribute("item3", nil)
    end

    -- Modifier key bindings (Shift/Ctrl/Alt × Left/Right/Middle)
    for _, mod in ipairs(MOD_KEYS) do
        local modLower = MOD_ATTRS[mod]
        for _, btn in ipairs(BTN_KEYS) do
            local v = rhpDB.settings.modBinds[mod][btn]
            if v then
                if type(v) == "number" then
                    -- Toy item ID (e.g., shift-type1 = "toy", shift-toy1 = 253629)
                    rhpBtn:SetAttribute(modLower .. "-type" .. btn, "toy")
                    rhpBtn:SetAttribute(modLower .. "-toy" .. btn, v)
                    -- Clear other action attributes for this mod+btn
                    rhpBtn:SetAttribute(modLower .. "-item" .. btn, nil)
                    rhpBtn:SetAttribute(modLower .. "-spell" .. btn, nil)
                    rhpBtn:SetAttribute(modLower .. "-macro" .. btn, nil)
                elseif type(v) == "string" then
                    -- Item string like "item:6948" (e.g., shift-type1 = "item", shift-item1 = "item:6948")
                    rhpBtn:SetAttribute(modLower .. "-type" .. btn, "item")
                    rhpBtn:SetAttribute(modLower .. "-item" .. btn, v)
                    -- Clear other action attributes
                    rhpBtn:SetAttribute(modLower .. "-toy" .. btn, nil)
                    rhpBtn:SetAttribute(modLower .. "-spell" .. btn, nil)
                    rhpBtn:SetAttribute(modLower .. "-macro" .. btn, nil)
                end
            else
                -- Clear disabled binding so it falls through to base behavior
                rhpBtn:SetAttribute(modLower .. "-type" .. btn, nil)
                rhpBtn:SetAttribute(modLower .. "-toy" .. btn, nil)
                rhpBtn:SetAttribute(modLower .. "-item" .. btn, nil)
            end
        end
    end
end

-- Create or update global macro
local function updateMacro()
    if not combatCheck() then
        local macroText
        if #rhpList == 0 then
            if rhpDB.settings.warnMsg ~= true then
                rhpDB.settings.warnMsg = true
                print(L["NO_VALID_CHOSEN"])
            end
            macroText = "#showtooltip " .. macroToyName .. "\n/use " .. macroToyName
        else
            -- Add cancelform to macro if player is a druid
            if playerClass == 11 then
                macroText = "#showtooltip " .. macroToyName
                    .. "\n/cancelform"
                    .. "\n/stopcasting"
                    .. "\n/click [mod:shift,btn:1]rhpB 1;[mod:shift,btn:2]rhpB 2;[mod:shift,btn:3]rhpB 3;[mod:ctrl,btn:1]rhpB 1;[mod:ctrl,btn:2]rhpB 2;[mod:ctrl,btn:3]rhpB 3;[mod:alt,btn:1]rhpB 1;[mod:alt,btn:2]rhpB 2;[mod:alt,btn:3]rhpB 3;[btn:2]rhpB 2;[btn:3]rhpB 3;rhpB"
            else
                macroText = "#showtooltip " .. macroToyName
                    .. "\n/stopcasting"
                    .. "\n/click [mod:shift,btn:1]rhpB 1;[mod:shift,btn:2]rhpB 2;[mod:shift,btn:3]rhpB 3;[mod:ctrl,btn:1]rhpB 1;[mod:ctrl,btn:2]rhpB 2;[mod:ctrl,btn:3]rhpB 3;[mod:alt,btn:1]rhpB 1;[mod:alt,btn:2]rhpB 2;[mod:alt,btn:3]rhpB 3;[btn:2]rhpB 2;[btn:3]rhpB 3;rhpB"
            end
        end
        if macroTimer ~= true then
            macroTimer = true
            C_Timer.After(0.1, function()
                if combatCheck() then
                    macroTimer = false
                    deferMacroUpdate()
                    return
                end
                local macroIndex = GetMacroIndexByName(rhpDB.settings.macroName)
                if macroIndex == 0 then
                    print(L["MACRO_NOT_FOUND"], rhpDB.settings.macroName, "'")
                    CreateMacro(rhpDB.settings.macroName, macroIcon, macroText, nil)
                    rhpMacroName:SetText(rhpDB.settings.macroName)
                else
                    EditMacro(macroIndex, nil, macroIcon, macroText)
                end
                macroTimer = false
            end)
        end
    end
end

local function updateMacroName()
    if not combatCheck() then
        local name = rhpMacroName:GetText()
        local macroIndex = GetMacroIndexByName(rhpDB.settings.macroName)
        if macroIndex == 0 then
            updateMacro()
        else
            EditMacro(macroIndex, name)
            rhpDB.settings.macroName = name
            print(L["UPDATE_MACRO_NAME"], name, "'")
        end
    end
end

local function checkMacroName()
    if not combatCheck() then
        local name = rhpMacroName:GetText()
        if name == rhpDB.settings.macroName or string.len(name) == 0 then return end
        if GetMacroIndexByName(name) == 0 then
            rhpMacroName.Icon:Hide()
            updateMacroName()
        end
    end
end

-- Set random Hearthstone
local function setRandom()
    if not combatCheck() then
        if #rhpList > 0 then
            local rnd = rhpList[math.random(1, #rhpList)]
            if #rhpList > 1 then
                while rnd == lastRnd do
                    rnd = rhpList[math.random(1, #rhpList)]
                end
                lastRnd = rnd
            end
            macroToyName = rhpDB.L.tList[rnd]["name"]
            if rhpDB.iconOverride.name == L["RANDOM"] then
                macroIcon = rhpDB.L.tList[rnd]["icon"]
            else
                macroIcon = rhpDB.iconOverride.icon
            end
        else
            macroToyName = "item:6948"
            macroIcon = 134414
        end
        updateButtonAttributes()
        updateMacro()
    end
end

-- Generate a list of valid toys
local function listGenerate()
    rhpList = {}
    local allCovenant
    local covenantHearths = {
        -- { Criteria index, Covenant index, Covenant toy, Enabled }
        { 1, 1, 184353, false }, -- Kyrian
        { 4, 2, 183716, false }, -- Venthyr
        { 3, 3, 180290, false }, -- Night Fae
        { 2, 4, 182773, false }, -- Necrolord
    }
    for i, v in pairs(covenantHearths) do
        if select(3, GetAchievementCriteriaInfo(15646, v[1])) == true then
            covenantHearths[i][4] = true
        elseif C_Covenants.GetActiveCovenantID() ~= v[2] then
            if rhpDB.L.tList[v[3]] ~= nil and rhpCheckButtons[v[3]] then
                rhpCheckButtons[v[3]].Extratext = rhpCheckButtons[v[3]]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                rhpCheckButtons[v[3]].Extratext:SetText("|cff777777(" .. L["RENOWN_LOCKED"] .. ")|r")
                rhpCheckButtons[v[3]].Extratext:SetPoint("LEFT", rhpCheckButtons[v[3]].Text, "RIGHT", 10, 0)
            end
        end
    end

    if select(4, GetAchievementInfo(15241)) == true then
        if rhpDB.settings.covOverride == true then
            allCovenant = false
        else
            allCovenant = true
        end
    end

    for i, v in pairs(rhpDB.L.tList) do
        if v["status"] == true then
            if PlayerHasToy(i) then
                local addToy = true
                -- Check for Covenant
                for _, k in pairs(covenantHearths) do
                    if i == k[3] then
                        if k[4] == false and C_Covenants.GetActiveCovenantID() ~= k[2] then
                            addToy = false
                        elseif allCovenant == false and C_Covenants.GetActiveCovenantID() ~= k[2] then
                            addToy = false
                            break
                        end
                    end
                end
                -- Check Draenei
                if i == 210455 then
                    local _, _, raceID = UnitRace("player")
                    if not (raceID == 11 or raceID == 30) then
                        addToy = false
                    end
                end
                -- Create the list
                if addToy == true then
                    table.insert(rhpList, i)
                end
            end
        end
    end
    setRandom()
    -- Refresh modifier dropdowns to reflect updated toy names
    for _, mod in ipairs(MOD_KEYS) do
        for _, btn in ipairs(BTN_KEYS) do
            rhpModDropdowns[mod][btn]:SetText(getModBindDisplayName(rhpDB.settings.modBinds[mod][btn]))
        end
    end
end

-- Update Hearthstone selections when options panel closes
local function rhpOptionsOkay()
    for i, v in pairs(rhpDB.L.tList) do
        if rhpCheckButtons[i] then
            v["status"] = rhpCheckButtons[i]:GetChecked()
        end
    end
    rhpDB.settings.covOverride = rhpOverride:GetChecked()
    rhpDB.settings.dalOpt = rhpDalHearth:GetChecked()
    rhpDB.settings.garOpt = rhpGarHearth:GetChecked()
    rhpDB.settings.warnMsg = false
    listGenerate()
end

-- Macro icon selection
local function rhpSelectIcon(arg1)
    if arg1 == "Random" then
        rhpDB.iconOverride.name = L["RANDOM"]
        rhpDB.iconOverride.icon = 134400
        rhpDB.iconOverride.id = nil
    elseif arg1 == "Hearthstone" then
        rhpDB.iconOverride.name = L["HEARTHSTONE"]
        rhpDB.iconOverride.icon = 134414
        rhpDB.iconOverride.id = 6948
    else
        rhpDB.iconOverride.name = rhpDB.L.tList[arg1]["name"]
        rhpDB.iconOverride.icon = rhpDB.L.tList[arg1]["icon"]
        rhpDB.iconOverride.id = arg1
    end
    rhpDropdown:SetText(rhpDB.iconOverride.name)
    rhpDropdown.Texture:SetTexture(rhpDB.iconOverride.icon)
end

-- Dropdown menu generator for macro icon
local function rhpDropdownGenerator(dropdown, rootDescription)
    local function IsSelected(value)
        if value == "Random" then return rhpDB.iconOverride.name == L["RANDOM"] end
        if value == "Hearthstone" then return rhpDB.iconOverride.name == L["HEARTHSTONE"] end
        return rhpDB.iconOverride.id == value
    end

    rootDescription:CreateRadio(L["RANDOM"], IsSelected, function() rhpSelectIcon("Random") end, "Random")
    rootDescription:CreateRadio(L["HEARTHSTONE"], IsSelected, function() rhpSelectIcon("Hearthstone") end, "Hearthstone")

    for i = 1, #rhToys do
        if rhpDB.L.tList[rhToys[i]] ~= nil then
            rootDescription:CreateRadio(rhpDB.L.tList[rhToys[i]]["name"], IsSelected, function() rhpSelectIcon(rhToys[i]) end, rhToys[i])
        end
    end
end

-- Dropdown menu generator for modifier bindings
local function rhpModDropdownGenerator(dropdown, rootDescription)
    local mod = dropdown.modKey
    local btn = dropdown.btnKey

    local function IsSelected(value)
        local current = rhpDB.settings.modBinds[mod][btn]
        if value == DROPDOWN_RANDOM then
            return current == nil
        elseif value == DROPDOWN_HEARTH then
            return current == "item:6948"
        elseif value == DROPDOWN_DALARAN then
            return current == "item:140192"
        elseif value == DROPDOWN_GARRISON then
            return current == "item:110560"
        else
            return current == tonumber(value)
        end
    end

    local function OnSelect(value)
        if value == DROPDOWN_RANDOM then
            rhpDB.settings.modBinds[mod][btn] = nil
        elseif value == DROPDOWN_HEARTH then
            rhpDB.settings.modBinds[mod][btn] = "item:6948"
        elseif value == DROPDOWN_DALARAN then
            rhpDB.settings.modBinds[mod][btn] = "item:140192"
        elseif value == DROPDOWN_GARRISON then
            rhpDB.settings.modBinds[mod][btn] = "item:110560"
        else
            rhpDB.settings.modBinds[mod][btn] = tonumber(value)
        end
        dropdown:SetText(getModBindDisplayName(rhpDB.settings.modBinds[mod][btn]))
    end

    rootDescription:CreateRadio(L["RANDOM"], IsSelected, function() OnSelect(DROPDOWN_RANDOM) end, DROPDOWN_RANDOM)
    rootDescription:CreateRadio(L["HEARTHSTONE"], IsSelected, function() OnSelect(DROPDOWN_HEARTH) end, DROPDOWN_HEARTH)
    rootDescription:CreateRadio(L["DALARAN_HEARTH"], IsSelected, function() OnSelect(DROPDOWN_DALARAN) end, DROPDOWN_DALARAN)
    rootDescription:CreateRadio(L["GARRISON_HEARTH"], IsSelected, function() OnSelect(DROPDOWN_GARRISON) end, DROPDOWN_GARRISON)

    -- Add all toys from the list
    for i = 1, #rhToys do
        if rhpDB.L.tList[rhToys[i]] ~= nil then
            rootDescription:CreateRadio(rhpDB.L.tList[rhToys[i]]["name"], IsSelected, function() OnSelect(tostring(rhToys[i])) end, tostring(rhToys[i]))
        end
    end
end

-- Add items in savedvariable
local function rhpInitDB(table, item, value)
    local isTable = type(value) == "table"
    local exists = false
    -- Check if the item already exists in the table
    for k, v in pairs(table) do
        if k == item or (type(v) == "table" and isTable and v == value) then
            exists = true
            break
        end
    end
    -- If the item does not exist, add it
    if not exists then
        if value ~= nil then
            -- Add item with a value
            table[item] = value
        else
            -- Add item without a value
            table.insert(table, item)
        end
    end
end

-- Reset to default settings
local function rhpResetDefaults()
    -- Reset all toy checkboxes to checked
    for i, v in pairs(rhpCheckButtons) do
        v:SetChecked(true)
    end
    -- Reset settings checkboxes
    rhpOverride:SetChecked(false)
    rhpDalHearth:SetChecked(true)
    rhpGarHearth:SetChecked(true)
    -- Reset macro name
    rhpMacroName:SetText(L["MACRO_NAME"])
    -- Reset icon override
    rhpSelectIcon("Random")
    -- Reset all modifier bindings to Random
    for _, mod in ipairs(MOD_KEYS) do
        for _, btn in ipairs(BTN_KEYS) do
            rhpDB.settings.modBinds[mod][btn] = nil
            rhpModDropdowns[mod][btn]:SetText(L["RANDOM"])
        end
    end
    print(L["DEFAULT_RESTORED"])
end

----------------------------------------------------------------------------------------------------------------------
-- SecureActionButton (rhpB)
----------------------------------------------------------------------------------------------------------------------
rhpBtn:RegisterForClicks("AnyDown")
rhpBtn:SetAttribute("pressAndHoldAction", true)
rhpBtn:SetAttribute("type", "toy")
rhpBtn:SetAttribute("typerelease", "toy")
rhpBtn:SetScript("PostClick", function(self, button)
    if not combatCheck() then
        if button == "LeftButton" or button == "1" then
            -- Only reroll on left click (not on modifier-right/middle clicks)
            -- Check if no modifier was held
            if not IsShiftKeyDown() and not IsControlKeyDown() and not IsAltKeyDown() then
                setRandom()
            end
        end
    end
end)

----------------------------------------------------------------------------------------------------------------------
-- Options Panel Layout
----------------------------------------------------------------------------------------------------------------------

-- Title
rhpTitle:SetPoint("TOPLEFT", 10, -10)
rhpTitle:SetWidth(SettingsPanel.Container:GetWidth() - 35)
rhpTitle:SetHeight(1)
rhpTitle.Text = rhpTitle:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
rhpTitle.Text:SetPoint("TOPLEFT", rhpTitle, 0, 0)
rhpTitle.Text:SetText(L["ADDON_NAME"])

-- Thanks
rhpOptionsPanel.Thanks = rhpOptionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
rhpOptionsPanel.Thanks:SetPoint("TOPRIGHT", rhpOptionsPanel, "TOPRIGHT", -5, -5)
rhpOptionsPanel.Thanks:SetTextColor(1, 1, 1, 0.5)
rhpOptionsPanel.Thanks:SetText(L["THANKS"] .. " :)\nOriginal by JamienAU | Enhanced by David W Zhang")
rhpOptionsPanel.Thanks:SetJustifyH("RIGHT")

-- Description
rhpDesc:SetPoint("TOPLEFT", 20, -40)
rhpDesc:SetWidth(SettingsPanel.Container:GetWidth() - 35)
rhpDesc:SetHeight(1)
rhpDesc.Text = rhpDesc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rhpDesc.Text:SetPoint("TOPLEFT", rhpDesc, 0, 0)
rhpDesc.Text:SetText(L["DESCRIPTION"])

-- Scroll Frame
rhpOptionsScroll:SetPoint("TOPLEFT", 5, -60)
rhpOptionsScroll:SetPoint("BOTTOMRIGHT", -25, 150)

-- Divider
rhpDivider:SetStartPoint("BOTTOMLEFT", rhpDivider:GetParent(), 20, -10)
rhpDivider:SetEndPoint("BOTTOMRIGHT", rhpDivider:GetParent(), 0, -10)
rhpDivider:SetColorTexture(0.25, 0.25, 0.25, 1)
rhpDivider:SetThickness(1.2)

-- Scroll Frame child
rhpOptionsScroll:SetScrollChild(rhpScrollChild)
rhpScrollChild:SetWidth(SettingsPanel.Container:GetWidth() - 35)
rhpScrollChild:SetHeight(1)

-- Checkbox for each toy
local chkOffset = 0
for i = 1, #rhToys do
    if i > 1 then
        chkOffset = chkOffset + -26
    end
    rhpCheckButtons[rhToys[i]] = CreateFrame("CheckButton", nil, rhpScrollChild, "UICheckButtonTemplate")
    rhpCheckButtons[rhToys[i]]:SetPoint("TOPLEFT", 15, chkOffset)
    rhpCheckButtons[rhToys[i]]:SetSize(25, 25)
    rhpCheckButtons[rhToys[i]].Text = rhpCheckButtons[rhToys[i]]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local item = Item:CreateFromItemID(rhToys[i])
    item:ContinueOnItemLoad(function()
        if rhpCheckButtons[rhToys[i]] then
            rhpCheckButtons[rhToys[i]].Text:SetText(item:GetItemName())
        end
    end)
    rhpCheckButtons[rhToys[i]].Text:SetTextColor(1, 1, 1, 1)
    rhpCheckButtons[rhToys[i]].Text:SetPoint("LEFT", 28, 0)
end

-- Select All button
rhpSelectAll:SetPoint("TOPLEFT", rhpSelectAll:GetParent(), "BOTTOMLEFT", 20, -20)
rhpSelectAll:SetSize(100, 25)
rhpSelectAll:SetText(L["SELECT_ALL"])
rhpSelectAll:SetScript("OnClick", function(self)
    for i, v in pairs(rhpCheckButtons) do
        v:SetChecked(true)
    end
end)

-- Deselect All button
rhpDeselectAll:SetPoint("TOPLEFT", rhpDeselectAll:GetParent(), "BOTTOMLEFT", 135, -20)
rhpDeselectAll:SetSize(100, 25)
rhpDeselectAll:SetText(L["DESELECT_ALL"])
rhpDeselectAll:SetScript("OnClick", function(self)
    for i, v in pairs(rhpCheckButtons) do
        v:SetChecked(false)
    end
end)

-- Macro override dropdown
rhpDropdown:SetPoint("TOPRIGHT", rhpOverride:GetParent(), "BOTTOMRIGHT", -20, -35)
rhpDropdown:SetWidth(200)
rhpDropdown:SetDefaultText(L["RANDOM"])
rhpDropdown.Texture = rhpDropdown:CreateTexture(nil, "OVERLAY")
rhpDropdown.Texture:SetSize(24, 24)
rhpDropdown.Texture:SetPoint("LEFT", rhpDropdown, "RIGHT", 5, 0)
rhpDropdown.Extratext = rhpDropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rhpDropdown.Extratext:SetText(L["OPT_MACRO_ICON"])
rhpDropdown.Extratext:SetPoint("BOTTOMLEFT", rhpDropdown, "TOPLEFT", 0, 5)

-- Covenant override checkbox
rhpOverride:SetPoint("TOPLEFT", rhpOverride:GetParent(), "BOTTOMLEFT", 15, -50)
rhpOverride:SetSize(25, 25)
rhpOverride.Text:SetJustifyH("LEFT")
rhpOverride.Text:SetText(" " .. L["COV_ONLY"])
rhpOverride.Text:SetTextColor(1, 1, 1, 1)

-- Dalaran hearth checkbox
rhpDalHearth:SetPoint("TOPLEFT", rhpOverride, "BOTTOMLEFT", 0, 0)
rhpDalHearth:SetSize(25, 25)
rhpDalHearth.Text:SetJustifyH("LEFT")
rhpDalHearth.Text:SetText(" " .. L["DAL_R_CLICK"])
rhpDalHearth.Text:SetTextColor(1, 1, 1, 1)

-- Garrison hearth checkbox
rhpGarHearth:SetPoint("TOPLEFT", rhpDalHearth, "BOTTOMLEFT", 0, 0)
rhpGarHearth:SetSize(25, 25)
rhpGarHearth.Text:SetJustifyH("LEFT")
rhpGarHearth.Text:SetText(" " .. L["GAR_M_CLICK"])
rhpGarHearth.Text:SetTextColor(1, 1, 1, 1)

-- Custom macro name box
rhpMacroName:SetPoint("TOPLEFT", rhpDropdown, "BOTTOMLEFT", 25, -20)
rhpMacroName:SetAutoFocus(false)
rhpMacroName:SetSize(208, 20)
rhpMacroName:SetFontObject("GameFontNormal")
rhpMacroName:SetTextColor(1, 1, 1, 1)
rhpMacroName:SetMaxLetters(16)
rhpMacroName.Text = rhpMacroName:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rhpMacroName.Text:SetText(L["OPT_MACRO_NAME"])
rhpMacroName.Text:SetPoint("BOTTOMLEFT", rhpMacroName, "TOPLEFT", 0, 5)
rhpMacroName.Exist = rhpMacroName:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rhpMacroName.Exist:SetTextColor(1, 0, 0, 1)
rhpMacroName.Exist:SetJustifyH("LEFT")
rhpMacroName.Exist:SetPoint("TOPLEFT", rhpMacroName, "BOTTOMLEFT", 0, -5)
rhpMacroName.Exist:SetText(L["UNIQUE_NAME_ERROR"])
rhpMacroName.Exist:Hide()
rhpMacroName.Icon = rhpMacroName:CreateTexture(nil, "OVERLAY")
rhpMacroName.Icon:SetPoint("LEFT", rhpMacroName, "RIGHT", 5, 0)
rhpMacroName.Icon:SetTexture("Interface/COMMON/CommonIcons.PNG")
rhpMacroName.Icon:SetSize(24, 24)
rhpMacroName:SetScript("OnShow", function()
    rhpMacroName.Exist:Hide()
    rhpMacroName.Icon:Hide()
    rhpMacroName:SetText(rhpDB.settings.macroName)
end)
rhpMacroName:SetScript("OnTextChanged", function(self, userInput)
    if userInput == true then
        -- Checking if the macro exists. Adding in a timer so it doesn't spam check on every key press.
        if waitTimer ~= true then
            waitTimer = true
            C_Timer.After(0.5, function()
                local name = rhpMacroName:GetText()
                if name ~= rhpDB.settings.macroName and GetMacroIndexByName(name) ~= 0 then
                    rhpMacroName.Exist:Show()
                    rhpMacroName.Icon:SetTexCoord(0.25, 0.38, 0, 0.26)
                    rhpMacroName.Icon:Show()
                elseif string.len(name) == 0 then
                    rhpMacroName.Icon:Hide()
                else
                    rhpMacroName.Exist:Hide()
                    rhpMacroName.Icon:SetTexCoord(0, 0.13, 0.51, 0.75)
                    rhpMacroName.Icon:Show()
                end
                waitTimer = false
            end)
        end
    end
end)
rhpMacroName:SetScript("OnEditFocusLost", function() checkMacroName() end)
rhpMacroName:SetScript("OnEnterPressed", function() checkMacroName() end)

----------------------------------------------------------------------------------------------------------------------
-- Modifier Key Binding Section (3x3 dropdown grid)
----------------------------------------------------------------------------------------------------------------------
-- Section label
rhpModSectionLabel:SetPoint("TOPLEFT", rhpMacroName, "BOTTOMLEFT", -25, -40)
rhpModSectionLabel:SetWidth(SettingsPanel.Container:GetWidth() - 35)
rhpModSectionLabel:SetHeight(1)
rhpModSectionLabel.Text = rhpModSectionLabel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
rhpModSectionLabel.Text:SetPoint("TOPLEFT", rhpModSectionLabel, 0, 0)
rhpModSectionLabel.Text:SetText(L["MOD_BINDINGS"])

-- Column headers: Left Click | Right Click | Middle Click
local headerLabels = { L["MOD_LEFT_CLICK"], L["MOD_RIGHT_CLICK"], L["MOD_MIDDLE_CLICK"] }
local headerStartX = 125
local headerSpacing = 160
for i, label in ipairs(headerLabels) do
    local hdr = CreateFrame("Frame", nil, rhpOptionsPanel)
    hdr:SetPoint("TOPLEFT", rhpModSectionLabel, "TOPLEFT", headerStartX + (i - 1) * headerSpacing, -25)
    hdr:SetWidth(140)
    hdr:SetHeight(1)
    hdr.Text = hdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr.Text:SetPoint("TOPLEFT", hdr, 0, 0)
    hdr.Text:SetText(label)
    hdr.Text:SetTextColor(1, 0.82, 0, 1) -- gold color for headers
    rhpModHeaders[i] = hdr
end

-- Row labels and dropdowns
local rowLabels = { L["MOD_SHIFT"], L["MOD_CTRL"], L["MOD_ALT"] }
local rowStartY = -50
local rowSpacing = -30

for modIdx, mod in ipairs(MOD_KEYS) do
    rhpModDropdowns[mod] = {}
    -- Row label
    local rowLabel = CreateFrame("Frame", nil, rhpOptionsPanel)
    rowLabel:SetPoint("TOPLEFT", rhpModSectionLabel, "TOPLEFT", 5, rowStartY + (modIdx - 1) * rowSpacing)
    rowLabel:SetWidth(110)
    rowLabel:SetHeight(1)
    rowLabel.Text = rowLabel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rowLabel.Text:SetPoint("TOPLEFT", rowLabel, 0, -7)
    rowLabel.Text:SetText(rowLabels[modIdx])
    rowLabel.Text:SetTextColor(1, 1, 1, 1)
    rhpModRowLabels[mod] = rowLabel

    for btnIdx, btn in ipairs(BTN_KEYS) do
        local dd = CreateFrame("DropdownButton", nil, rhpOptionsPanel, "WowStyle1DropdownTemplate")
        dd:SetPoint("TOPLEFT", rhpModSectionLabel, "TOPLEFT", headerStartX + (btnIdx - 1) * headerSpacing, rowStartY + (modIdx - 1) * rowSpacing)
        dd:SetWidth(140)
        dd:SetDefaultText(L["RANDOM"])
        dd.modKey = mod
        dd.btnKey = btn
        dd:SetupMenu(rhpModDropdownGenerator)
        rhpModDropdowns[mod][btn] = dd
    end
end

----------------------------------------------------------------------------------------------------------------------
-- Listener for addon loaded
----------------------------------------------------------------------------------------------------------------------
rhpListener:RegisterEvent("ADDON_LOADED")
rhpListener:RegisterEvent("PLAYER_ENTERING_WORLD")
rhpListener:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_REGEN_ENABLED" and pendingMacroUpdate then
        pendingMacroUpdate = false
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        updateMacro()
        return
    end
    if event == "ADDON_LOADED" and arg1 == addon then
        -- Set savedvariable defaults if first load or compare and update savedvariables with toy list
        if rhpDB == nil then
            print(L["SETUP_1"])
            print(L["SETUP_2"])
            print(L["SETUP_3"])
            rhpDB = {}
        end
        rhpInitDB(rhpDB, "settings", {})
        rhpInitDB(rhpDB.settings, "covOverride", false)
        rhpInitDB(rhpDB.settings, "dalOpt", true)
        rhpInitDB(rhpDB.settings, "garOpt", true)
        rhpInitDB(rhpDB.settings, "macroName", L["MACRO_NAME"])
        rhpInitDB(rhpDB.settings, "loginMsg", "")
        rhpInitDB(rhpDB.settings, "warnMsg", false)
        rhpInitDB(rhpDB, "iconOverride", { name = "Random", icon = 134400 })
        rhpInitDB(rhpDB, "L", {})
        rhpInitDB(rhpDB.L, "locale", GetLocale())

        -- Initialize modifier bindings storage
        rhpInitDB(rhpDB.settings, "modBinds", {})
        for _, mod in ipairs(MOD_KEYS) do
            if rhpDB.settings.modBinds[mod] == nil then
                rhpDB.settings.modBinds[mod] = {}
            end
            for _, btn in ipairs(BTN_KEYS) do
                if rhpDB.settings.modBinds[mod][btn] == nil then
                    rhpDB.settings.modBinds[mod][btn] = nil -- explicit nil = random
                end
            end
        end

        if rhpDB.L.tList == nil then
            wait = true
            rhpDB.L.tList = {}
            for i = 1, #rhToys do
                local item = Item:CreateFromItemID(rhToys[i])
                item:ContinueOnItemLoad(function()
                    rhpDB.L.tList[rhToys[i]] = {
                        name = item:GetItemName(),
                        icon = item:GetItemIcon(),
                        status = true
                    }
                end)
            end
        end

        rhpDB.chkStatus = nil

        -- Remove IDs that no longer exist in rhToys list
        for i, v in pairs(rhpDB.L.tList) do
            local exists = 0
            for l = 1, #rhToys do
                if i == rhToys[l] then
                    exists = 1
                end
            end
            if exists == 0 then
                rhpDB.L.tList[i] = nil
            end
        end

        -- Add any new IDs to saved variables as enabled
        for i = 1, #rhToys do
            if not rhpDB.L.tList[rhToys[i]] then
                wait = true
                local item = Item:CreateFromItemID(rhToys[i])
                item:ContinueOnItemLoad(function()
                    rhpDB.L.tList[rhToys[i]] = {
                        name = item:GetItemName(),
                        icon = item:GetItemIcon(),
                        status = true
                    }
                    if rhpCheckButtons[rhToys[i]] then
                        rhpCheckButtons[rhToys[i]]:SetChecked(true)
                    end
                    if i == #rhToys then
                        listGenerate()
                    end
                end)
            end
        end

        -- Update rhpDB if locale has changed
        if rhpDB.L.locale ~= GetLocale() then
            -- Update main list
            for i, v in pairs(rhpDB.L.tList) do
                local item = Item:CreateFromItemID(i)
                item:ContinueOnItemLoad(function()
                    rhpDB.L.tList[i]["name"] = item:GetItemName()
                end)
            end

            -- Update iconOverride
            if rhpDB.iconOverride.id ~= nil then
                local item = Item:CreateFromItemID(rhpDB.iconOverride.id)
                item:ContinueOnItemLoad(function()
                    rhpDB.iconOverride.name = item:GetItemName()
                    rhpDropdown:SetText(rhpDB.iconOverride.name)
                end)
            end

            rhpDB.L.locale = GetLocale()
        end

        -- Loop through options and set checkbox state
        for i, v in pairs(rhpDB.L.tList) do
            if rhpCheckButtons[i] then
                rhpCheckButtons[i]:SetChecked(v["status"])
            end
        end

        -- Set localised name for Dalaran and Garrison hearths
        local tmp = { { "dalaran", 140192 }, { "garrison", 110560 } }
        for _, v in pairs(tmp) do
            local item = Item:CreateFromItemID(v[2])
            item:ContinueOnItemLoad(function()
                rhpDB.L[v[1]] = item:GetItemName()
            end)
        end

        rhpOverride:SetChecked(rhpDB.settings.covOverride)
        rhpDalHearth:SetChecked(rhpDB.settings.dalOpt)
        rhpGarHearth:SetChecked(rhpDB.settings.garOpt)
        rhpDropdown.Texture:SetTexture(rhpDB.iconOverride.icon)
        rhpDropdown:SetText(rhpDB.iconOverride.name)
        rhpDropdown:SetupMenu(rhpDropdownGenerator)

        -- Initialize modifier dropdown display text
        for _, mod in ipairs(MOD_KEYS) do
            for _, btn in ipairs(BTN_KEYS) do
                rhpModDropdowns[mod][btn]:SetText(getModBindDisplayName(rhpDB.settings.modBinds[mod][btn]))
            end
        end

        self:UnregisterEvent("ADDON_LOADED")
    end

    if rhpDB and rhpDB.settings.loginMsg ~= loginMsg then
        rhpDB.settings.loginMsg = loginMsg
        print(L["LOGIN_MESSAGE_1"])
        print(L["LOGIN_MESSAGE_2"])
    end

    if event == "PLAYER_ENTERING_WORLD" then
        if not wait then
            listGenerate()
        end
    end
end)

----------------------------------------------------------------------------------------------------------------------
-- Slash command
----------------------------------------------------------------------------------------------------------------------
SLASH_RandomHearthstonePlus1 = "/rhp"
function SlashCmdList.RandomHearthstonePlus(msg, editbox)
    Settings.OpenToCategory(rhpCategory:GetID())
end

--[[
    Ignore this, it's for future me when Blizz breaks things again:
    /Interface/SharedXML/Settings/Blizzard_Settings.lua
]]
