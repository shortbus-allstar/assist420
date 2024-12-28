-- gui_refactor/style.lua
-- Contains ImGui style pushing/popping and some global variables that were originally local.

local style = {}

local mq     = require('mq')
local ImGui  = require('ImGui')

-----------------------------------------------------------------------------
-- Variables that were originally top-level locals in the big file
-----------------------------------------------------------------------------

style.BUTTON_SIZE = 55

style.editIndex                = 1
style.selectedOptionIndextheme = 1
style.debuffOverrideIndex      = 1
style.buffOverrideIndex        = 1
style.buffTargetIndex          = 1

style.frameCounter = 0
style.flashInterval = 250 

style.showTableGUI  = false
style.openGUI       = true
style.shouldDrawGUI = true
style.isEditing     = false

-----------------------------------------------------------------------------
-- pushStyleColor / pushStyleVar / popStyles
-----------------------------------------------------------------------------

style.pushedStyleCount    = 0
style.pushedStyleVarCount = 0

function style.pushStyleColor(...)
    ImGui.PushStyleColor(...)
    style.pushedStyleCount = style.pushedStyleCount + 1
end

function style.pushStyleVar(...)
    ImGui.PushStyleVar(...)
    style.pushedStyleVarCount = style.pushedStyleVarCount + 1
end

-- Apply entire theme (same as original pushStyle function)
function style.pushStyle(t)
    -- The original code sets .w = 0.75 on windowbg/bg
    t.windowbg.w = 1 * (75/100)
    t.bg.w       = 1 * (75/100)

    style.pushStyleColor(ImGuiCol.WindowBg,       t.windowbg)
    style.pushStyleColor(ImGuiCol.TitleBg,        t.bg)
    style.pushStyleColor(ImGuiCol.TitleBgActive,  t.active)
    style.pushStyleColor(ImGuiCol.FrameBg,        t.bg)
    style.pushStyleColor(ImGuiCol.FrameBgHovered, t.hovered)
    style.pushStyleColor(ImGuiCol.FrameBgActive,  t.active)
    style.pushStyleColor(ImGuiCol.Button,         t.button)
    style.pushStyleColor(ImGuiCol.ButtonHovered,  t.hovered)
    style.pushStyleColor(ImGuiCol.ButtonActive,   t.active)
    style.pushStyleColor(ImGuiCol.PopupBg,        t.bg)
    style.pushStyleColor(ImGuiCol.Tab,            0,0,0,0)
    style.pushStyleColor(ImGuiCol.TabActive,      t.active)
    style.pushStyleColor(ImGuiCol.TabHovered,     t.hovered)
    style.pushStyleColor(ImGuiCol.TabUnfocused,   t.bg)
    style.pushStyleColor(ImGuiCol.TabUnfocusedActive, t.hovered)
    style.pushStyleColor(ImGuiCol.HeaderActive,   t.active)
    style.pushStyleColor(ImGuiCol.Header,         t.bg)
    style.pushStyleColor(ImGuiCol.HeaderHovered,  t.hovered)
    style.pushStyleColor(ImGuiCol.TextDisabled,   t.text)
    style.pushStyleColor(ImGuiCol.Text,           t.text)
    style.pushStyleColor(ImGuiCol.CheckMark,      t.text)
    style.pushStyleColor(ImGuiCol.Separator,      t.hovered)

    style.pushStyleVar(ImGuiStyleVar.WindowRounding, 10)
end

function style.popStyles()
    ImGui.PopStyleColor(style.pushedStyleCount)
    ImGui.PopStyleVar(style.pushedStyleVarCount)
    style.pushedStyleCount    = 0
    style.pushedStyleVarCount = 0
end

return style
