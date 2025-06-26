-- gui_refactor/config_editors.lua

local config_editors = {}

local ImGui           = require('ImGui')
local style     = require('interface.GUI.style')
local widgets = require('interface.GUI.widgets')

local state           = require('utils.state')
local lib             = require('utils.lib')
local abils           = require('routines.abils')
local mq              = require('mq')

-- Because the original code references icons, anim, etc.:
local icons     = require('mq.icons')
local isNameInputActive = false

local ImGuiTableFlags = ImGuiTableFlags
local table_flags = bit32.bor(
    ImGuiTableFlags.Hideable,
    ImGuiTableFlags.RowBg,
    ImGuiTableFlags.ScrollY,
    ImGuiTableFlags.BordersOuter,
    ImGuiTableFlags.Resizable
)

-----------------------------------------------------------------------------
-- The config_editors.dynamicWindowTitles and bools that were originally local
-----------------------------------------------------------------------------

config_editors.dynamicWindowTitle         = ''
config_editors.dynamicAggroWindowTitle    = ''
config_editors.dynamicHealWindowTitle     = ''
config_editors.dynamicDebuffWindowTitle   = ''
config_editors.dynamicBuffWindowTitle     = ''

config_editors.isEditing            = false
config_editors.isEditingAggro       = false
config_editors.isEditingHeal        = false
config_editors.isEditingDebuff      = false
config_editors.isEditingBuff        = false

local shouldDrawEditor     = true
local shouldDrawAggroEditor= true
local shouldDrawHealEditor = true
local shouldDrawDebuffEditor = true
local shouldDrawBuffEditor = true

-- For the popup window indexes
config_editors.debuffOverrideIndex  = 1
config_editors.buffOverrideIndex    = 1
config_editors.buffTargetIndex      = 1
config_editors.showDebuffOverwriteWindow = false
config_editors.showBuffTargetWindow      = false
config_editors.showBuffOverrideWindow    = false

config_editors.pickerAbilIndex = 0
config_editors.pickerlist      = state.config.abilities
config_editors.showCustTar     = false

-----------------------------------------------------------------------------
-- config_editors.DrawTable used by many editors
-----------------------------------------------------------------------------

local function contains(table, val)
    for _, value in ipairs(table) do
        if value == val then
            return true
        end
    end
    return false
end


function config_editors.DrawTable(name, rows, columns, columnLabels, checkWidth, nameWidth, editWidth, ...)
    local columnData = {...}
    assert(#columnLabels == columns, "Number of column labels must match the number of columns")

    for i = 1, columns do
        assert(#columnData[i] == rows, "Each column data must have the same number of rows")
    end

    if ImGui.BeginTable(name, columns, table_flags) then
        for i = 1, columns do
            if checkWidth and i == 1 then
                ImGui.TableSetupColumn(columnLabels[i], ImGuiTableColumnFlags.WidthFixed, checkWidth)
            elseif nameWidth and i == 2 then
                ImGui.TableSetupColumn(columnLabels[i], ImGuiTableColumnFlags.WidthFixed, nameWidth)
            elseif editWidth and i == 3 then
                ImGui.TableSetupColumn(columnLabels[i], ImGuiTableColumnFlags.WidthFixed, editWidth)
            else
                ImGui.TableSetupColumn(columnLabels[i])
            end
        end
        ImGui.TableHeadersRow()

        local alternatingColor = true
        for row = 1, rows do
            ImGui.TableNextRow(0, 27)
            if alternatingColor then
                ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, ImVec4(0, 0, 0, 1.0))
            else
                ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, ImVec4(0.1, 0.1, 0.1, 1.0))
            end
            alternatingColor = not alternatingColor

            for col = 1, columns do
                ImGui.TableSetColumnIndex(col - 1)
                local cellData = columnData[col][row]
                if type(cellData) == "function" then
                    cellData()
                else
                    ImGui.Text(tostring(cellData))
                end
            end
        end
        ImGui.EndTable()
    end
end

-----------------------------------------------------------------------------
-- Full-screen editor windows: DrawEditorWindow, DrawAggroEditorWindow, etc.
-- We preserve them exactly as from the original large file.
-----------------------------------------------------------------------------

-- Example “DrawAggroEditorWindow”:
function config_editors.DrawAggroEditorWindow()
    local flags = bit32.bor(ImGuiWindowFlags.NoSavedSettings)
    if config_editors.isEditingAggro then
        config_editors.isEditingAggro, shouldDrawAggroEditor = ImGui.Begin(config_editors.dynamicAggroWindowTitle, config_editors.isEditingAggro, flags)
        if shouldDrawAggroEditor then
            ImGui.SetWindowSize(600, 167, ImGuiCond.FirstUseEver)
            local abil = state.config.aggroabils[state.class][style.editIndex]
            local dropdownOptions = {"AA", "Spell", "Item", "Skill", "Disc", "Cmd"}  -- Dropdown options

            ImGui.Columns(2, "AggroColumns", false)  -- Split into 2 columns

            -- First table
            config_editors.DrawTable("AggroEditWin", 4, 2, {"##1", "##2"}, 65, 200, nil,
                {
                    "Name:", 
                    "Type:", 
                    function()
                        ImGui.Text("Cond:")
                        ImGui.SameLine()
                        if ImGui.Button(icons.FA_EXPAND, ImVec2(20, 20)) then
                            ImGui.OpenPopup("FullTextPopup")
                        end

                        ImGui.SetNextWindowSize(1000, 600)
                        ImGui.PushStyleColor(ImGuiCol.PopupBg, ImVec4(0, 0, 0, 1.0))
                        if ImGui.BeginPopup("FullTextPopup", bit32.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.AlwaysHorizontalScrollbar)) then
                            if ImGui.BeginChild("FullTextInput", 1000, 600) then
                                -- InputTextMultiline inside child window
                                local buffer = abil.cond or ""
                                abil.cond, _ = ImGui.InputTextMultiline("##InputText", buffer, 1000, 600)
                                ImGui.EndChild()
                            end
                            ImGui.EndPopup()
                        end
                        ImGui.PopStyleColor()
                    end,
                    "Active:"
                }, 
                {
                    function() abil.name = DrawTextInput(abil.name, "##Name", 200) end,
                    function() abil.type = DrawDropdown(abil.type, "##type", dropdownOptions, 200) end,
                    function() abil.cond = DrawTextInput(abil.cond, "##Condition", 200) end,
                    function() abil.active = ImGui.Checkbox("##Active", abil.active) end
                })

            ImGui.NextColumn()  -- Move to the next column

            -- Second table
            config_editors.DrawTable("AggroEditWin2", 4, 2, {"##3", "##4"}, 75, 200, nil,
                {
                    "Retry CD:", 
                    "Loop Delay:", 
                    "Priority:",
                    "AE:"
                }, 
                {
                    function() abil.abilcd = DrawNumberInput(abil.abilcd, "##abilcd") end,
                    function() abil.loopdel = DrawNumberInput(abil.loopdel, "##loopdel") end,
                    function() abil.priority = DrawNumberInput(abil.priority, "##priority") end,
                    function() 
                        abil.ae = ImGui.Checkbox("##AE", abil.ae) 
                        if abil.ae then
                            ImGui.SameLine()
                            abil.mobcount = DrawNumberInput(abil.mobcount, "##mobcount")
                        end
                    end
                })

            ImGui.Columns(1)  -- Reset columns to single column layout

            ImGui.End()
        end
        ImGui.End()
    end
end

-- Similarly: DrawEditorWindow (the generic one for normal abilities)
function config_editors.DrawEditorWindow()
    local flags = bit32.bor(ImGuiWindowFlags.NoSavedSettings)
    if config_editors.isEditing then
        config_editors.isEditing, shouldDrawEditor = ImGui.Begin(config_editors.dynamicWindowTitle, config_editors.isEditing, flags)
        if shouldDrawEditor then
            -- Add controls for editing ability properties
            ImGui.SetWindowSize(600,227,ImGuiCond.FirstUseEver)
            local contentWidthx, _ = ImGui.GetContentRegionAvail()
            ImGui.Columns(2, "AbilityColumns", false)

            -- Left column for the top-left section
            local leftColumnWidth = contentWidthx * 0.5  -- Adjust the proportion as needed
            ImGui.SetColumnWidth(0, leftColumnWidth)
            ImGui.BeginChild("LeftColumn", ImVec2(leftColumnWidth, -1))

            -- Top-left section
            if ImGui.BeginTable("TopLeftTable", 2, table_flags) then
                ImGui.TableSetupColumn("Variable", ImGuiTableColumnFlags.WidthFixed, 80)
                ImGui.TableSetupColumn("Value", ImGuiTableColumnFlags.WidthStretch)

                local alternatingColor = true

            -- Labels and Input fields
                local labels = {"Name:", "Type:", "Target:", "Cond:", "Burn:", "Feign:", "Passive Zone:"}
                for _, label in ipairs(labels) do
                    ImGui.TableNextColumn()

                -- Set up alternating label row colors
                    if alternatingColor then
                        ImGui.TableSetBgColor(ImGuiTableBgTarget.CellBg, ImVec4(0.1, 0.1, 0.1, 1.0)) -- Background color
                    else
                        ImGui.TableSetBgColor(ImGuiTableBgTarget.CellBg, ImVec4(0, 0, 0, 1)) -- Background color
                    end

                    ImGui.Text(label)
                    if label == "Cond:" then
                        ImGui.SameLine()
                        if ImGui.Button(icons.FA_EXPAND, ImVec2(20, 20)) then
                            ImGui.OpenPopup("FullTextPopup")
                        end
                    end
                    

                    ImGui.SetNextWindowSize(1000,600)
                    ImGui.PushStyleColor(ImGuiCol.PopupBg, ImVec4(0, 0, 0, 1.0))
                    if ImGui.BeginPopup("FullTextPopup", ImGuiWindowFlags.AlwaysAutoResize and ImGuiWindowFlags.AlwaysHorizontalScrollbar) then
                        if label == 'Cond:' then
                            if ImGui.BeginChild("FullTextInput", 1000, 600) then
                                -- Use InputTextMultiline inside the child window
                                local buffer = state.config.abilities[state.class][style.editIndex].cond or ""
                                state.config.abilities[state.class][style.editIndex].cond, _ = ImGui.InputTextMultiline("##InputText", buffer, 1000, 600)
                        
                                ImGui.EndChild()
                            end
                        end
                        ImGui.EndPopup()
                    end
                    ImGui.PopStyleColor()

                    ImGui.TableNextColumn()
                    local contentRegionPosX = ImGui.GetCursorPosX() - ImGui.GetScrollX()
                    ImGui.SetNextItemWidth(((contentWidthx * .5) - contentRegionPosX) - 10)
                    if label == "Name:" then
                        local inputTextSubmitted = false
                        state.config.abilities[state.class][style.editIndex].name, inputTextSubmitted = ImGui.InputText("##AbilityName", state.config.abilities[state.class][style.editIndex].name)
                        if inputTextSubmitted then
                            isNameInputActive = false
                        elseif ImGui.IsItemActive() then
                            isNameInputActive = true
                        end
                        if ImGui.IsItemDeactivatedAfterEdit() and isNameInputActive then
                            config_editors.dynamicWindowTitle = "Edit Ability - " .. state.config.abilities[state.class][style.editIndex].name
                            isNameInputActive = false
                        end
                    elseif label == "Type:" then
                        local types = {"AA", "Spell", "Item", "Skill", "Disc", "Cmd"}
                        local typeIndex = lib.findIndex(types, state.config.abilities[state.class][style.editIndex].type) or 1
                        local newTypeIndex, changed = ImGui.Combo("##Type", typeIndex, types)
                        if changed then
                            state.config.abilities[state.class][style.editIndex].type = types[newTypeIndex]
                        end
                
                    elseif label == "Target:" then
                        local targets = {"None", "Tank", "Self", "MA", "MA Target", "Custom Lua ID"}
                        local targetIndex = lib.findIndex(targets, state.config.abilities[state.class][style.editIndex].target) or 1
                        local newTargetIndex, changed = ImGui.Combo("##Tar", targetIndex, targets)
                        if changed then
                            state.config.abilities[state.class][style.editIndex].target = targets[newTargetIndex]
                
                            if state.config.abilities[state.class][style.editIndex].target == "Custom Lua ID" then
                                config_editors.showCustTar = true
                            else
                                config_editors.showCustTar = false
                            end
                        end

                        if config_editors.showCustTar == true then 
                            local contentRegionPosX = ImGui.GetCursorPosX() - ImGui.GetScrollX()
                            ImGui.SetNextItemWidth(((contentWidthx * .5) - contentRegionPosX) - 10)
                            state.config.abilities[state.class][style.editIndex].custtar, _ = ImGui.InputText("##CustTar", state.config.abilities[state.class][style.editIndex].custtar)
                        end

                    elseif label == "Cond:" then
                        state.config.abilities[state.class][style.editIndex].cond, _ = ImGui.InputText("##cond", state.config.abilities[state.class][style.editIndex].cond)
                    elseif label == "Burn:" then
                        state.config.abilities[state.class][style.editIndex].burn, _ = ImGui.Checkbox("##Burn", state.config.abilities[state.class][style.editIndex].burn)
                    elseif label == "Feign:" then
                        state.config.abilities[state.class][style.editIndex].feign, _ = ImGui.Checkbox("##Feign", state.config.abilities[state.class][style.editIndex].feign)
                    elseif label == "Passive Zone:" then
                        state.config.abilities[state.class][style.editIndex].passiveZone = ImGui.Checkbox("##PassiveZone", state.config.abilities[state.class][style.editIndex].passiveZone) 
                    end
                    

                -- Set up alternating row colors
                    if alternatingColor then
                        ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg1, ImVec4(0.1, 0.1, 0.1, 1.0)) -- Background color
                    else
                        ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg1, ImVec4(0, 0, 0, 1)) -- Background color
                    end
                    alternatingColor = not alternatingColor
                end

                ImGui.EndTable()
            end
            ImGui.EndChild()

            ImGui.NextColumn()

            local rightColumnWidth = contentWidthx * 0.5  -- Adjust the proportion as needed
            ImGui.SetColumnWidth(1, rightColumnWidth)
            ImGui.BeginChild("RightColumn", ImVec2(rightColumnWidth, -1))
            
            -- Top-right section
            if ImGui.BeginTable("TopRightTable", 2, table_flags) then
                ImGui.TableSetupColumn("Variable", ImGuiTableColumnFlags.WidthFixed, 130)
                ImGui.TableSetupColumn("Value", ImGuiTableColumnFlags.WidthStretch)
            
                local alternatingColor = true
            
                -- Labels and Input fields for the top-right section
                local labelsRight = {"Retry CD:", "Loop Delay:", "Priority:", "Active:", "Use In Combat:", "Use Outside Combat:"}
                for _, label in ipairs(labelsRight) do
                    ImGui.TableNextColumn()
            
                    -- Set up alternating label row colors
                    if alternatingColor then
                        ImGui.TableSetBgColor(ImGuiTableBgTarget.CellBg, ImVec4(0.1, 0.1, 0.1, 1.0)) -- Background color
                    else
                        ImGui.TableSetBgColor(ImGuiTableBgTarget.CellBg, ImVec4(0, 0, 0, 1)) -- Background color
                    end
            
                    ImGui.Text(label)
            
                    ImGui.TableNextColumn()
                    local contentRegionPosXRight = ImGui.GetCursorPosX() - ImGui.GetScrollX()
                    ImGui.SetNextItemWidth(((contentWidthx * .5) - contentRegionPosXRight) - 10)
                    if label == "Retry CD:" then
                        state.config.abilities[state.class][style.editIndex].abilcd, _ = ImGui.InputInt("##RetryCD", state.config.abilities[state.class][style.editIndex].abilcd)
                    elseif label == "Loop Delay:" then
                        state.config.abilities[state.class][style.editIndex].loopdel, _ = ImGui.InputInt("##LoopDelay", state.config.abilities[state.class][style.editIndex].loopdel)
                    elseif label == "Priority:" then
                        local newPriority, _ = ImGui.InputInt("##Priority", state.config.abilities[state.class][style.editIndex].priority)
                        -- Check if the entered priority already exists
                        local isDuplicate = false
                        for _, ability in ipairs(state.config.abilities[state.class]) do
                            if ability.priority == newPriority and ability ~= state.config.abilities[state.class][style.editIndex] then
                                isDuplicate = true
                                break
                            end
                        end
                        if isDuplicate then
                            ImGui.TextColored(1, 0, 0, 1, "Priority already exists")
                        else
                            state.config.abilities[state.class][style.editIndex].priority = newPriority
                        end                    
                    elseif label == "Active:" then
                        state.config.abilities[state.class][style.editIndex].active, _ = ImGui.Checkbox("##Active", state.config.abilities[state.class][style.editIndex].active)
                    elseif label == "Use In Combat:" then
                        local changed = nil
                        state.config.abilities[state.class][style.editIndex].usecombat, changed = ImGui.Checkbox("##UseCom", state.config.abilities[state.class][style.editIndex].usecombat)
                        if changed then
                            if not state.config.abilities[state.class][style.editIndex].usecombat then
                                abils.removeAbilFromQueue(state.config.abilities[state.class][style.editIndex],state.queueCombat)
                            else
                                abils.addAbilToQueue(state.config.abilities[state.class][style.editIndex],state.queueCombat)
                            end
                        end
                    elseif label == "Use Outside Combat:" then
                        local changed = nil
                        state.config.abilities[state.class][style.editIndex].useooc, changed = ImGui.Checkbox("##UseOOC", state.config.abilities[state.class][style.editIndex].useooc)
                        if changed then
                            if not state.config.abilities[state.class][style.editIndex].useooc then
                                abils.removeAbilFromQueue(state.config.abilities[state.class][style.editIndex],state.queueOOC)
                            else
                                abils.addAbilToQueue(state.config.abilities[state.class][style.editIndex],state.queueOOC)
                            end
                        end
                    end

                    -- Set up alternating row colors
                    if alternatingColor then
                        ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg1, ImVec4(0.1, 0.1, 0.1, 1.0)) -- Background color
                    else
                        ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg1, ImVec4(0, 0, 0, 1)) -- Background color
                    end
                    alternatingColor = not alternatingColor
                end
            
                ImGui.EndTable()
            end
            ImGui.EndChild()

            ImGui.Columns(1)  -- Reset columns
        else
            config_editors.showCustTar = false
        end
        ImGui.End()
    end
end

-- Debuff Editor Window
function config_editors.DrawDebuffEditorWindow()
    local flags = bit32.bor(ImGuiWindowFlags.NoSavedSettings)
    if config_editors.isEditingDebuff then
        config_editors.isEditingDebuff, shouldDrawDebuffEditor = ImGui.Begin(config_editors.dynamicDebuffWindowTitle, config_editors.isEditingDebuff, flags)
        if shouldDrawDebuffEditor then
            ImGui.SetWindowSize(600, 230, ImGuiCond.FirstUseEver) -- Adjust window size as needed

            -- Access the debuff ability being edited
            local abil = state.config.debuffabils[state.class][style.editIndex]
            local dropdownOptions = {"AA", "Spell", "Item", "Skill", "Disc", "Cmd"} -- Dropdown options

            ImGui.Columns(2, "DebuffColumns", false) -- Split into 2 columns

            -- First table
            config_editors.DrawTable("DebuffEditWin", 6, 2, {"##1", "##2"}, 115, 150, nil,
                {
                    -- Column 1 Labels
                    function()
                        ImGui.Text("Name:")
                        ImGui.SameLine()
                        if ImGui.Button(icons.FA_EXPAND, ImVec2(20, 20)) then
                            ImGui.OpenPopup("FullTextPopup1")
                        end

                        ImGui.SetNextWindowSize(1000, 600)
                        ImGui.PushStyleColor(ImGuiCol.PopupBg, ImVec4(0, 0, 0, 1.0))
                        if ImGui.BeginPopup("FullTextPopup1", bit32.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.AlwaysHorizontalScrollbar)) then
                            if ImGui.BeginChild("FullTextInput1", 1000, 600) then
                                -- InputTextMultiline inside child window
                                local buffer = abil.name or ""
                                abil.name, _ = ImGui.InputTextMultiline("##InputText1", buffer, 1000, 600)
                                ImGui.EndChild()
                            end
                            ImGui.EndPopup()
                        end
                        ImGui.PopStyleColor()
                    end,
                    function()
                        ImGui.Text("Debuff Name:")
                        ImGui.SameLine()
                        if ImGui.Button(icons.FA_EXPAND.. "##2", ImVec2(20, 20)) then
                            ImGui.OpenPopup("FullTextPopup2")
                        end

                        ImGui.SetNextWindowSize(1000, 600)
                        ImGui.PushStyleColor(ImGuiCol.PopupBg, ImVec4(0, 0, 0, 1.0))
                        if ImGui.BeginPopup("FullTextPopup2", bit32.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.AlwaysHorizontalScrollbar)) then
                            if ImGui.BeginChild("FullTextInput2", 1000, 600) then
                                -- InputTextMultiline inside child window
                                local buffer = abil.debuffname or ""
                                abil.debuffname, _ = ImGui.InputTextMultiline("##InputText2", buffer, 1000, 600)
                                ImGui.EndChild()
                            end
                            ImGui.EndPopup()
                        end
                        ImGui.PopStyleColor()
                    end,
                    "Type:",
                    function()
                        ImGui.Text("Cond:")
                        ImGui.SameLine()
                        if ImGui.Button(icons.FA_EXPAND .. "##1", ImVec2(20, 20)) then
                            ImGui.OpenPopup("FullTextPopup")
                        end

                        ImGui.SetNextWindowSize(1000, 600)
                        ImGui.PushStyleColor(ImGuiCol.PopupBg, ImVec4(0, 0, 0, 1.0))
                        if ImGui.BeginPopup("FullTextPopup", bit32.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.AlwaysHorizontalScrollbar)) then
                            if ImGui.BeginChild("FullTextInput", 1000, 600) then
                                -- InputTextMultiline inside child window
                                local buffer = abil.cond or ""
                                abil.cond, _ = ImGui.InputTextMultiline("##InputText", buffer, 1000, 600)
                                ImGui.EndChild()
                            end
                            ImGui.EndPopup()
                        end
                        ImGui.PopStyleColor()
                    end,
                    "AE:",
                    "Active:"
                },
                {
                    -- Column 2 Inputs
                    function() abil.name = DrawTextInput(abil.name, "##Name", 150) end,
                    function() abil.debuffname = DrawTextInput(abil.debuffname, "##debuffName", 150) end,
                    function() abil.type = DrawDropdown(abil.type, "##type", dropdownOptions, 150) end,
                    function() abil.cond = DrawTextInput(abil.cond, "##Condition", 150) end,
                    function() abil.ae = DrawCheckbox(abil.ae,"##AE") end,
                    function() abil.active = ImGui.Checkbox("##Active", abil.active) end
                })


            ImGui.NextColumn() -- Move to the next column

            -- Second table (Add any additional fields if needed)
            -- For example, you might have settings like 'Max Targets' or 'Debuff Mode'

            -- Example:
            config_editors.DrawTable("DebuffEditWin2", 5, 2, {"##3", "##4"}, 75, 200, nil,
                {
                    "Priority:",
                    "Loop Delay:",
                    "Ability CD:",
                    "AE Tar Min:",
                    function() DrawInfoIconWithTooltip("Debuff Overrides are debuffs that this specific ability will not attempt to overwrite. The Debuff Name is checked by default.") end
                },
                {
                    function() abil.priority = DrawNumberInput(abil.priority or 1, "##priority") end,
                    function() abil.loopdel = DrawNumberInput(abil.loopdel or 0, "##loopdel") end,
                    function() abil.abilcd = DrawNumberInput(abil.abilcd or 10, "##abilcd") end,
                    function() abil.aemin = DrawNumberInput(abil.aemin or 2, "##aemin") end,
                    function()  
                        if ImGui.Button("Open Debuff Overrides",200,20) then
                            config_editors.showDebuffOverwriteWindow = true
                            config_editors.debuffOverrideIndex = abil.priority
                        end
                    end
                })

            ImGui.Columns(1) -- Reset columns to single column layout


        end
        ImGui.End()
    end
end

-- Buff Editor Window
function config_editors.DrawBuffEditorWindow()
    local flags = bit32.bor(ImGuiWindowFlags.NoSavedSettings)
    if config_editors.isEditingBuff then
        config_editors.isEditingBuff, shouldDrawBuffEditor = ImGui.Begin(config_editors.dynamicBuffWindowTitle, config_editors.isEditingBuff, flags)
        if shouldDrawBuffEditor then
            ImGui.SetWindowSize(600, 275, ImGuiCond.FirstUseEver) -- Adjust window size as needed

            -- Access the Buff ability being edited
            local abil = state.config.buffabils[state.class][style.editIndex]
            local dropdownOptions = {"AA", "Spell", "Item", "Skill", "Disc", "Cmd"} -- Dropdown options

            ImGui.Columns(2, "BuffColumns", false) -- Split into 2 columns

            -- First table
            config_editors.DrawTable("BuffEditWin", 8, 2, {"##1", "##2"}, 100, 200, nil,
                {
                    -- Column 1 Labels
                    function()
                        ImGui.Text("Name:")
                        ImGui.SameLine()
                        if ImGui.Button(icons.FA_EXPAND, ImVec2(20, 20)) then
                            ImGui.OpenPopup("FullTextPopup1")
                        end

                        ImGui.SetNextWindowSize(1000, 600)
                        ImGui.PushStyleColor(ImGuiCol.PopupBg, ImVec4(0, 0, 0, 1.0))
                        if ImGui.BeginPopup("FullTextPopup1", bit32.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.AlwaysHorizontalScrollbar)) then
                            if ImGui.BeginChild("FullTextInput1", 1000, 600) then
                                -- InputTextMultiline inside child window
                                local buffer = abil.name or ""
                                abil.name, _ = ImGui.InputTextMultiline("##InputText1", buffer, 1000, 600)
                                ImGui.EndChild()
                            end
                            ImGui.EndPopup()
                        end
                        ImGui.PopStyleColor()
                    end,
                    function()
                        ImGui.Text("Buff Name:")
                        ImGui.SameLine()
                        if ImGui.Button(icons.FA_EXPAND .. "##2", ImVec2(20, 20)) then
                            ImGui.OpenPopup("FullTextPopup2")
                        end

                        ImGui.SetNextWindowSize(1000, 600)
                        ImGui.PushStyleColor(ImGuiCol.PopupBg, ImVec4(0, 0, 0, 1.0))
                        if ImGui.BeginPopup("FullTextPopup2", bit32.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.AlwaysHorizontalScrollbar)) then
                            if ImGui.BeginChild("FullTextInput2", 1000, 600) then
                                -- InputTextMultiline inside child window
                                local buffer = abil.buffname or ""
                                abil.buffname, _ = ImGui.InputTextMultiline("##InputText2", buffer, 1000, 600)
                                ImGui.EndChild()
                            end
                            ImGui.EndPopup()
                        end
                        ImGui.PopStyleColor()
                    end,
                    "Type:",
                    function()
                        ImGui.Text("Cond:")
                        ImGui.SameLine()
                        if ImGui.Button(icons.FA_EXPAND .. "##1", ImVec2(20, 20)) then
                            ImGui.OpenPopup("FullTextPopup")
                        end

                        ImGui.SetNextWindowSize(1000, 600)
                        ImGui.PushStyleColor(ImGuiCol.PopupBg, ImVec4(0, 0, 0, 1.0))
                        if ImGui.BeginPopup("FullTextPopup", bit32.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.AlwaysHorizontalScrollbar)) then
                            if ImGui.BeginChild("FullTextInput", 1000, 600) then
                                -- InputTextMultiline inside child window
                                local buffer = abil.cond or ""
                                abil.cond, _ = ImGui.InputTextMultiline("##InputText", buffer, 1000, 600)
                                ImGui.EndChild()
                            end
                            ImGui.EndPopup()
                        end
                        ImGui.PopStyleColor()
                    end,
                    "Active:",
                    "Passive Zone:",
                    function() DrawInfoIconWithTooltip("Other targets outside of the default options that we will check for this buff.") end,
                    function() DrawInfoIconWithTooltip("Targets that have any of the buffs in the override list will be skipped for this buff ability.") end
                    
                },
                {
                    -- Column 2 Inputs
                    function() abil.name = DrawTextInput(abil.name, "##Name", 165) end,
                    function() abil.buffname = DrawTextInput(abil.buffname, "##BuffName", 165) end,
                    function() abil.type = DrawDropdown(abil.type, "##type", dropdownOptions, 165) end,
                    function() abil.cond = DrawTextInput(abil.cond, "##Condition", 165) end,
                    function() abil.active = ImGui.Checkbox("##Active", abil.active) end,
                    function() abil.passiveZone = ImGui.Checkbox("##PassiveZone", abil.passiveZone) end,
                    
                    function()  
                        if ImGui.Button("Open Buff Targets",165,20) then
                            config_editors.showBuffTargetWindow = true
                            config_editors.buffTargetIndex = abil.priority
                        end
                    end,
                    function()  
                        if ImGui.Button("Open Buff Overrides",165,20) then
                            config_editors.showBuffOverrideWindow = true
                            config_editors.buffOverrideIndex = abil.priority
                        end
                    end
                })


            ImGui.NextColumn() -- Move to the next column

            -- Second table (Add any additional fields if needed)
            -- For example, you might have settings like 'Max Targets' or 'Buff Mode'

            -- Example:
            config_editors.DrawTable("BuffEditWin2", 7, 2, {"##3", "##4"}, 120, 200, nil,
                {
                    "Priority:",
                    "Loop Delay:",
                    "Ability CD:",
                    "Use Group Tank:",
                    "Use Group:",
                    "Use Self:",
                    "Use Pets:"
                },
                {
                    function() abil.priority = DrawNumberInput(abil.priority or 1, "##priority") end,
                    function() abil.loopdel = DrawNumberInput(abil.loopdel or 0, "##loopdel") end,
                    function() abil.abilcd = DrawNumberInput(abil.abilcd or 10, "##abilcd") end,
                    function() abil.usegrouptank = DrawCheckbox(abil.usegrouptank,"##usegrouptank") end,
                    function() abil.usegroup = DrawCheckbox(abil.usegroup,"##usegroup") end,
                    function() abil.useself = DrawCheckbox(abil.useself,"##useself") end,
                    function() abil.usepets = DrawCheckbox(abil.usepets,"##usepets") end

                })

            ImGui.Columns(1) -- Reset columns to single column layout


        end
        ImGui.End()
    end
end

-- Heal Editor Window
function config_editors.DrawHealEditorWindow()
    local flags = bit32.bor(ImGuiWindowFlags.NoSavedSettings)
    if config_editors.isEditingHeal then
        config_editors.isEditingHeal, shouldDrawHealEditor = ImGui.Begin(config_editors.dynamicHealWindowTitle, config_editors.isEditingHeal, flags)
        if shouldDrawHealEditor then
            ImGui.SetWindowSize(600, 365, ImGuiCond.FirstUseEver) -- Adjust window size as needed

            local abil = state.config.healabils[state.class][style.editIndex]
            local dropdownOptions = {"AA", "Spell", "Item", "Skill", "Disc", "Cmd"} -- Dropdown options
            local cureOptions = {
                "Poison", "Disease", "Curse", "Corruption", "Detrimental"
            }-- Cure type options

            ImGui.Columns(2, "HealColumns", false) -- Split into 2 columns

            -- First table
            config_editors.DrawTable("HealEditWin", 11, 2, {"##1", "##2"}, 150, 110, nil,
                {
                    function()
                        ImGui.Text("Name:")
                        ImGui.SameLine()
                        if ImGui.Button(icons.FA_EXPAND, ImVec2(20, 20)) then
                            ImGui.OpenPopup("FullTextPopup1")
                        end

                        ImGui.SetNextWindowSize(1000, 600)
                        ImGui.PushStyleColor(ImGuiCol.PopupBg, ImVec4(0, 0, 0, 1.0))
                        if ImGui.BeginPopup("FullTextPopup1", bit32.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.AlwaysHorizontalScrollbar)) then
                            if ImGui.BeginChild("FullTextInput1", 1000, 600) then
                                -- InputTextMultiline inside child window
                                local buffer = abil.name or ""
                                abil.name, _ = ImGui.InputTextMultiline("##InputText1", buffer, 1000, 600)
                                ImGui.EndChild()
                            end
                            ImGui.EndPopup()
                        end
                        ImGui.PopStyleColor()
                    end,
                    "Type:",
                    function()
                        ImGui.Text("Cond:")
                        ImGui.SameLine()
                        if ImGui.Button(icons.FA_EXPAND .. "##1", ImVec2(20, 20)) then
                            ImGui.OpenPopup("FullTextPopup")
                        end

                        ImGui.SetNextWindowSize(1000, 600)
                        ImGui.PushStyleColor(ImGuiCol.PopupBg, ImVec4(0, 0, 0, 1.0))
                        if ImGui.BeginPopup("FullTextPopup", bit32.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.AlwaysHorizontalScrollbar)) then
                            if ImGui.BeginChild("FullTextInput", 1000, 600) then
                                -- InputTextMultiline inside child window
                                local buffer = abil.cond or ""
                                abil.cond, _ = ImGui.InputTextMultiline("##InputText", buffer, 1000, 600)
                                ImGui.EndChild()
                            end
                            ImGui.EndPopup()
                        end
                        ImGui.PopStyleColor()
                    end,
                    "Cure Type:",
                    "Cure:",
                    "Rez:",
                    "Active:",
                    "AE Heal:",
                    "Emergency Heal:",
                    "HoT:",
                    "Use Passive Zone:"
                },
                {
                    function() abil.name = DrawTextInput(abil.name, "##Name", 200) end,
                    function() abil.type = DrawDropdown(abil.type, "##type", dropdownOptions, 200) end,
                    function() abil.cond = DrawTextInput(abil.cond, "##Condition", 200) end,
                    function()
                        if abil.cure then
                            if type(abil.curetype) ~= "table" then abil.curetype = {} end
                            local selectionLabels = {"Poison", "Disease", "Corruption", "Curse", "Detrimental"}
                            
                            for _, label in ipairs(selectionLabels) do
                                -- Check if the label is currently selected
                                local isSelected = contains(abil.curetype, label)
                                
                                -- Display the selectable item
                                local _, isClicked = ImGui.Selectable(label, isSelected)
                                if isSelected and isClicked then
                                    -- If it was selected and clicked, deselect it
                                    for i, v in ipairs(abil.curetype) do
                                        if v == label then
                                            table.remove(abil.curetype, i)
                                            break
                                        end
                                    end
                                elseif isClicked then
                                    table.insert(abil.curetype, label)
                                end
                            end
                        end
                    end,
                    function() abil.cure = ImGui.Checkbox("##Cure", abil.cure) end,
                    function() abil.rez = ImGui.Checkbox("##Rez", abil.rez) end,
                    function() abil.active = ImGui.Checkbox("##Active", abil.active) end,
                    function() abil.aeheal = ImGui.Checkbox("##aeheal", abil.aeheal) end,
                    function() abil.emergheal = ImGui.Checkbox("##emergheal", abil.emergheal) end,
                    function() abil.hot = ImGui.Checkbox("##hot", abil.hot) end,
                    function() abil.passiveZone = ImGui.Checkbox("##PassiveZone", abil.passiveZone) end
                })

            ImGui.NextColumn() -- Move to the next column

            -- Second table
            config_editors.DrawTable("HealEditWin2", 10, 2, {"##3", "##4"}, 150, 120, nil,
                {
                    "Retry CD:",
                    "Loop Delay:",
                    "Priority:",
                    function()
                        ImGui.Text("Override Heal Pct:")
                        DrawInfoIconWithTooltip("Ability will not activate on targets greater than this HP %. If the heal config setting 'Heal At' (different Emergency settings if emergency ability, 'HoT At' if hot) is lower than this number, than that setting will take precedent.")
                    end,
                    "Use XTar:",
                    "Use Group Tank:",
                    "Use Group Members:",
                    "Use Other Tanks:",
                    "Use Self:",
                    "Use Pets:"
                },
                {
                    function() abil.abilcd = DrawNumberInput(abil.abilcd, "##abilcd") end,
                    function() abil.loopdel = DrawNumberInput(abil.loopdel, "##loopdel") end,
                    function() abil.priority = DrawNumberInput(abil.priority, "##priority") end,
                    function() abil.healpct = DrawNumberInput(abil.healpct, "##healpct") end,
                    function() abil.usextar = ImGui.Checkbox("##UseXtar", abil.usextar) end,
                    function() abil.usegrouptank = ImGui.Checkbox("##UseGroupTank", abil.usegrouptank) end,
                    function() abil.usegroupmember = ImGui.Checkbox("##UseGroupMember", abil.usegroupmember) end,
                    function() abil.useothertank = ImGui.Checkbox("##UseOtherTank", abil.useothertank) end,
                    function() abil.useself = ImGui.Checkbox("##UseSelf", abil.useself) end,
                    function() abil.usepets = ImGui.Checkbox("##UsePets", abil.usepets) end,
                    
                })
            ImGui.Columns(1) -- Reset columns to single column layout


        end
        ImGui.End()
    end
end

-----------------------------------------------------------------------------
-- Additional smaller utilities: DrawCheckbox, DrawNumberInput, DrawTextInput, etc.
-- Already moved to widgets, so we do not re-duplicate them here.

-- Next, the “displayTableGUI” to see `state` in a tree:
-----------------------------------------------------------------------------

function config_editors.displayTableGUI(inputTable, parentKey)
    ImGui.Begin("State", style.showTableGUI)
    ImGui.Separator()

    local nodeName  = parentKey or "state"
    local nodeOpened = ImGui.TreeNode(nodeName)
    if nodeOpened then
        local sortedKeys = {}
        for key, _ in pairs(inputTable) do
            table.insert(sortedKeys, key)
        end
        table.sort(sortedKeys)

        for _, key in ipairs(sortedKeys) do
            local value   = inputTable[key]
            local fullKey = parentKey and parentKey .. "/" .. key or key
            if type(value) == "table" then
                config_editors.displayTableGUI(value, fullKey)
            else
                ImGui.Text(tostring(key) .. ": " .. tostring(value))
            end
        end

        ImGui.TreePop()
    end

    ImGui.End()
end

-----------------------------------------------------------------------------
-- The “updatePicker” function
-----------------------------------------------------------------------------

function config_editors.updatePicker(list, abilIndex)
    if Picker and Picker.Selected then
        local selected = Picker.Selected or {}
        if selected.Type == 'Spell'
           or selected.Type == 'Disc'
           or selected.Type == 'AA'
           or selected.Type == 'Item'
        then
            list[state.class][abilIndex].type = selected.Type
            list[state.class][abilIndex].name = selected.Name
            if list == state.config.buffabils then
                list[state.class][abilIndex].buffname = selected.Name
            elseif list == state.config.debuffabils then
                list[state.class][abilIndex].debuffname = selected.Name
            end
            Picker:ClearSelection()

        elseif selected.Type == 'Ability' then
            list[state.class][abilIndex].type = "Skill"
            list[state.class][abilIndex].name = selected.Name
            if list == state.config.buffabils then
                list[state.class][abilIndex].buffname = selected.Name
            elseif list == state.config.debuffabils then
                list[state.class][abilIndex].debuffname = selected.Name
            end
            Picker:ClearSelection()
        end
    end
end

-----------------------------------------------------------------------------
-- The windows that show debuff/buff overrides:
-----------------------------------------------------------------------------

function config_editors.DrawDebuffOverwriteWindow(abilindex)
    if config_editors.showDebuffOverwriteWindow then
        config_editors.showDebuffOverwriteWindow = ImGui.Begin("Debuff Overwrite Table", config_editors.showDebuffOverwriteWindow, ImGuiWindowFlags.None)
        if config_editors.showDebuffOverwriteWindow then
            ImGui.SetWindowSize(600, 350, ImGuiCond.FirstUseEver)
            config_editors.DrawDebuffOverwriteTable(abilindex)
        end
        ImGui.End()
    end
end

function config_editors.DrawBuffOverrideWindow(abilindex)
    if config_editors.showBuffOverrideWindow then
        config_editors.showBuffOverrideWindow = ImGui.Begin("Buff Override Table", config_editors.showBuffOverrideWindow, ImGuiWindowFlags.None)
        if config_editors.showBuffOverrideWindow then
            ImGui.SetWindowSize(600, 350, ImGuiCond.FirstUseEver)
            config_editors.DrawBuffOverrideTable(abilindex)
        end
        ImGui.End()
    end
end

function config_editors.DrawBuffTargetWindow(abilindex)
    if config_editors.showBuffTargetWindow then
        config_editors.showBuffTargetWindow = ImGui.Begin("Buff Target Table", config_editors.showBuffTargetWindow, ImGuiWindowFlags.None)
        if config_editors.showBuffTargetWindow then
            ImGui.SetWindowSize(600, 350, ImGuiCond.FirstUseEver)
            config_editors.DrawBuffTargetTable(abilindex)
        end
        ImGui.End()
    end
end

-----------------------------------------------------------------------------
-- The actual table-drawing for each (overrides, buff targets, etc.)
-----------------------------------------------------------------------------

function config_editors.DrawBuffTargetTable(abilindex)
    -- Begin table
    if ImGui.BeginTable("Buff Targets:", 2, ImGuiTableFlags.Borders) then
        -- Table headers
        ImGui.TableSetupColumn("Targets")
        ImGui.TableSetupColumn("Delete")
        ImGui.TableHeadersRow()

        -- Populate rows
        for index, target in ipairs(state.config.buffabils[state.class][abilindex].othertargets) do
            ImGui.TableNextRow()
            ImGui.TableNextColumn()
            ImGui.Text(target)  -- Display the entry

            ImGui.TableNextColumn()
            if ImGui.Button("Delete##buffTargets" .. index) then
                table.remove(state.config.buffabils[state.class][abilindex].othertargets, index)  -- Remove entry
            end
        end

        ImGui.EndTable()
    end

    -- Button to show the add popup
    if ImGui.Button("Add Target") then
        config_editors.showAddBuffTargetPopup = true
    end

    -- Draw popup for adding new Buff targets
    if config_editors.showAddBuffTargetPopup then
        ImGui.OpenPopup("Add Target")
        if ImGui.BeginPopupModal("Add Target", nil, ImGuiWindowFlags.AlwaysAutoResize) then
            ImGui.Text("Enter a new Target:")
            config_editors.newBuffTarget = ImGui.InputText("##newBuffTarget", config_editors.newBuffTarget)

            if ImGui.Button("Add") then
                if config_editors.newBuffTarget ~= "" then
                    table.insert(state.config.buffabils[state.class][abilindex].othertargets, config_editors.newBuffTarget)
                end
                config_editors.newBuffTarget = ""  -- Clear the input
                config_editors.showAddBuffTargetPopup = false  -- Close popup
                ImGui.CloseCurrentPopup()
            end

            ImGui.SameLine()

            if ImGui.Button("Cancel") then
                config_editors.newBuffTarget = ""  -- Clear the input
                config_editors.showAddBuffTargetPopup = false  -- Close popup
                ImGui.CloseCurrentPopup()
            end

            ImGui.EndPopup()
        end
    end
end

function config_editors.DrawBuffOverrideTable(abilindex)
    -- Begin table
    if ImGui.BeginTable("Buff Overrides:", 2, ImGuiTableFlags.Borders) then
        -- Table headers
        ImGui.TableSetupColumn("Overrides")
        ImGui.TableSetupColumn("Delete")
        ImGui.TableHeadersRow()

        -- Populate rows
        for index, override in ipairs(state.config.buffabils[state.class][abilindex].overrides) do
            ImGui.TableNextRow()
            ImGui.TableNextColumn()
            ImGui.Text(override)  -- Display the entry

            ImGui.TableNextColumn()
            if ImGui.Button("Delete##buffOverrides" .. index) then
                table.remove(state.config.buffabils[state.class][abilindex].overrides, index)  -- Remove entry
            end
        end

        ImGui.EndTable()
    end

    -- Button to show the add popup
    if ImGui.Button("Add Override") then
        config_editors.showAddBuffOverridePopup = true
    end

    -- Draw popup for adding new Buff overrides
    if config_editors.showAddBuffOverridePopup then
        ImGui.OpenPopup("Add Override")
        if ImGui.BeginPopupModal("Add Override", nil, ImGuiWindowFlags.AlwaysAutoResize) then
            ImGui.Text("Enter a new Override:")
            config_editors.newBuffOverride = ImGui.InputText("##newBuffOverride", config_editors.newBuffOverride)

            if ImGui.Button("Add") then
                if config_editors.newBuffOverride ~= "" then
                    table.insert(state.config.buffabils[state.class][abilindex].overrides, config_editors.newBuffOverride)
                end
                config_editors.newBuffOverride = ""  -- Clear the input
                config_editors.showAddBuffOverridePopup = false  -- Close popup
                ImGui.CloseCurrentPopup()
            end

            ImGui.SameLine()

            if ImGui.Button("Cancel") then
                config_editors.newBuffTarget = ""  -- Clear the input
                config_editors.showAddBuffTargetPopup = false  -- Close popup
                ImGui.CloseCurrentPopup()
            end

            ImGui.EndPopup()
        end
    end
end

function config_editors.DrawDebuffOverwriteTable(abilindex)
    -- Begin table
    if ImGui.BeginTable("Overwrite Overrides:", 2, ImGuiTableFlags.Borders) then
        -- Table headers
        DrawInfoIconWithTooltip("Overwrite Overrides is a list of debuffs that this ability will not attempt to overwrite")
        ImGui.TableSetupColumn("Overrides")
        ImGui.TableSetupColumn("Delete")
        ImGui.TableHeadersRow()

        -- Populate rows
        for index, override in ipairs(state.config.debuffabils[state.class][abilindex].overrides) do
            ImGui.TableNextRow()
            ImGui.TableNextColumn()
            ImGui.Text(override)  -- Display the entry

            ImGui.TableNextColumn()
            if ImGui.Button("Delete##debuffOverrides" .. index) then
                table.remove(state.config.debuffabils[state.class][abilindex].overrides, index)  -- Remove entry
            end
        end

        ImGui.EndTable()
    end

    -- Button to show the add popup
    if ImGui.Button("Add Override") then
        config_editors.showAddOverridePopup = true
    end

    -- Draw popup for adding new Override targets
    if config_editors.showAddOverridePopup then
        ImGui.OpenPopup("Add Override")
        if ImGui.BeginPopupModal("Add Override", nil, ImGuiWindowFlags.AlwaysAutoResize) then
            ImGui.Text("Enter a new Override:")
            config_editors.newOverrideTarget = ImGui.InputText("##newOverrideTarget", config_editors.newOverrideTarget)

            if ImGui.Button("Add") then
                if config_editors.newOverrideTarget ~= "" then
                    table.insert(state.config.debuffabils[state.class][abilindex].overrides, config_editors.newOverrideTarget)
                end
                config_editors.newOverrideTarget = ""  -- Clear the input
                config_editors.showAddOverridePopup = false  -- Close popup
                ImGui.CloseCurrentPopup()
            end

            ImGui.SameLine()

            if ImGui.Button("Cancel") then
                config_editors.newOverrideTarget = ""  -- Clear the input
                config_editors.showAddOverridePopup = false  -- Close popup
                ImGui.CloseCurrentPopup()
            end

            ImGui.EndPopup()
        end
    end
end

-----------------------------------------------------------------------------
-- Etc. for the “Cure Avoids” tables, “Hot Targets,” “Other Tanks,” etc.
-- All those popped up windows also go here if they are part of the “editor” logic.
-----------------------------------------------------------------------------

-- For example, the “DrawCureAvoidsTable”, “DrawOtherTankListTable”, “DrawHotTargetsTable” 
-- also belong here. Paste them from the original code, preserving everything.

return config_editors
