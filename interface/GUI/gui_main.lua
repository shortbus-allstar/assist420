-- mod_main.lua
-- This file will tie everything together and return `mod`.

local mq    = require('mq')
local state = require('utils.state')

-- Require our newly split modules
local style      = require('interface.GUI.style')
local config_editors   = require('interface.GUI.config_editors')
local tabs             = require('interface.GUI.tabs')
local mod_utils        = require('interface.GUI.gui_utils')

-- Our module table
local mod = {}

-- Because parseImVec4() and loadTheme() were attached to `mod` in the original,
-- we attach them for backward compatibility (if needed).
mod.parseImVec4 = mod_utils.parseImVec4
mod.loadTheme   = mod_utils.loadTheme

-- If you need to load the theme data right away:
mod.loadTheme()

-- Main ImGui draw function
function mod.main()
    -- This mirrors the final lines of the original single-file code
    if not style.openGUI then return end

    style.pushStyle(state.activeTheme)
    style.openGUI, style.shouldDrawGUI = ImGui.Begin(state.class .. '420', style.openGUI, ImGuiWindowFlags.None)
    if style.shouldDrawGUI then
        style.frameCounter = style.frameCounter + 1
        ImGui.SetWindowSize(600, 800, ImGuiCond.FirstUseEver)

        if ImGui.BeginTabBar("Tabs") then
            tabs.DrawConsoleTab()
            tabs.DrawGenTab()
            tabs.DrawPullTab()
            tabs.DrawCondsTab()
            tabs.DrawHealTab()
            tabs.DrawBuffsTab()
            tabs.DrawDebuffsTab()
            tabs.DrawTankTab()
            tabs.DrawEventsTab()
            ImGui.EndTabBar()
        end

        -- These windows pop up if toggled in the code
        config_editors.DrawDebuffOverwriteWindow(config_editors.debuffOverrideIndex)
        config_editors.DrawBuffOverrideWindow(config_editors.buffOverrideIndex)
        config_editors.DrawBuffTargetWindow(config_editors.buffTargetIndex)
    end

    -- If user wants to see the 'state' table
    if style.showTableGUI then
        config_editors.displayTableGUI(state)
    end

    -- Ability Picker Update (e.g. for the “Bullseye” button)
    config_editors.updatePicker(config_editors.pickerlist, config_editors.pickerAbilIndex)

    style.popStyles()
    ImGui.End()
end

return mod
