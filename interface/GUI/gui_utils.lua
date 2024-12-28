-- gui_refactor/mod_utils.lua
local mod_utils = {}

local state = require('utils.state')
local style = require('interface.GUI.style')

function mod_utils.parseImVec4(str)
    local values = {}
    for val in str:gmatch("%d+%.?%d*") do
        table.insert(values, tonumber(val))
    end
    return ImVec4(values[1] or 0, values[2] or 0, values[3] or 0, values[4] or 0)
end

function mod_utils.loadTheme()
    local tbl = {}
    tbl.windowbg = mod_utils.parseImVec4(state.config.selectedTheme.windowbg)
    tbl.bg       = mod_utils.parseImVec4(state.config.selectedTheme.bg)
    tbl.hovered  = mod_utils.parseImVec4(state.config.selectedTheme.hovered)
    tbl.active   = mod_utils.parseImVec4(state.config.selectedTheme.active)
    tbl.button   = mod_utils.parseImVec4(state.config.selectedTheme.button)
    tbl.text     = mod_utils.parseImVec4(state.config.selectedTheme.text)
    tbl.name     = state.config.selectedTheme.name
    tbl.index    = state.config.selectedTheme.index

    state.activeTheme = tbl
    style.selectedOptionIndextheme = state.activeTheme.index
end

return mod_utils
