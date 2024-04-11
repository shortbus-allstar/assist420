local mq = require('mq')
local imgui = require('ImGui')

local write = require('utils.Write')
local state = require('utils.state')
local events = require('utils.events')
local binds = require('utils.binds')
local lib = require('utils.lib')

local combat = require('routines.combat')
local navigation = require('routines.navigation')
local abils = require('routines.abils')
local med   = require('routines.med')

local anim = mq.FindTextureAnimation('A_SpellIcons')
local classanim = mq.FindTextureAnimation('A_DragItem')
local icons = require('mq.icons')

local themes = {}
local openGUI = true
local shouldDrawGUI = true
local editIndex = 1
local isEditing = false
local shouldDrawEditor = true
local showCustTar = false
local table_flags = bit32.bor(ImGuiTableFlags.Hideable, ImGuiTableFlags.RowBg, ImGuiTableFlags.ScrollY, ImGuiTableFlags.BordersOuter, ImGuiTableFlags.Resizable)
local edit_flags = bit32.bor(ImGuiWindowFlags.None)


local mod ={}

themes.SHD = {
    windowbg = ImVec4(0, 0, 0, 0.9),  -- Black
    bg = ImVec4(0, 0.2, 0, 1),  -- Green
    hovered = ImVec4(0.1, 0.1, 0.1, 1),  -- Dark Grey
    active = ImVec4(0.2, 0.2, 0.2, 1),  -- Darker Grey
    button = ImVec4(0, 0.1, 0, 1),  -- Darker Green
    text = ImVec4(1, 0.8, 0.5, 1),  -- Light Orange
}

themes.MNK = {
    windowbg = ImVec4(0.2, 0.15, 0.1, 0.9),  -- Brown
    bg = ImVec4(0.2, 0.2, 0.2, 1),  -- Darker Silver
    hovered = ImVec4(0.3, 0.3, 0.3, 1),  -- Dark Silver
    active = ImVec4(0.4, 0.4, 0.4, 1),  -- Darker Silver
    button = ImVec4(0.4, 0.3, 0.2, 1),  -- Darker Brown
    text = ImVec4(0.9, 0.9, 0.9, 1),  -- Light Gray
}

themes.BER = {
    windowbg = ImVec4(0.4, 0.1, 0.1, 0.9),  -- Red
    bg = ImVec4(0.2, 0.2, 0.2, 1),  -- Darker Grey
    hovered = ImVec4(0.3, 0.3, 0.3, 1),  -- Dark Grey
    active = ImVec4(0.4, 0.4, 0.4, 1),  -- Darker Grey
    button = ImVec4(0.3, 0.2, 0.2, 1),  -- Darker Red
    text = ImVec4(0.9, 0.9, 0.9, 1),  -- Light Gray
}

themes.BST = {
    windowbg = ImVec4(0.2, 0.15, 0.1, 0.9),  -- Brown
    bg = ImVec4(0.2, 0.1, 0.2, 1),  -- Purple
    hovered = ImVec4(0.3, 0.3, 0.3, 1),  -- Dark Silver
    active = ImVec4(0.4, 0.4, 0.4, 1),  -- Darker Silver
    button = ImVec4(0.4, 0.3, 0.2, 1),  -- Darker Brown
    text = ImVec4(0.9, 0.9, 0.9, 1),  -- Light Gray
}

themes.BRD = {
    windowbg = ImVec4(0.2, 0.2, 0.2, 0.9),  -- Silver
    bg = ImVec4(0.3, 0.3, 0.3, 0.9),  -- Black
    hovered = ImVec4(0.1, 0.1, 0.1, 1),  -- Dark Grey
    active = ImVec4(0.2, 0.2, 0.2, 1),  -- Darker Grey
    button = ImVec4(0.1, 0.1, 0.1, 1),  -- Darker Black
    text = ImVec4(1, 1, 1, 1),  -- White
}

BLACK = {
    windowbg = ImVec4(.1, .1, .1, .9),
    bg = ImVec4(0, 0, 0, 1),
    hovered = ImVec4(.4, .4, .4, 1),
    active = ImVec4(.3, .3, .3, 1),
    button = ImVec4(.3, .3, .3, 1),
    text = ImVec4(1, 1, 1, 1),
}

themes.ROG = {
    windowbg = ImVec4(.2, .2, .2, .6),
    bg = ImVec4(0, .3, .3, 1),
    hovered = ImVec4(0, .4, .4, 1),
    active = ImVec4(0, .5, .5, 1),
    button = ImVec4(0, .3, .3, 1),
    text = ImVec4(1, 1, 1, 1),
}

PINK = {
    windowbg = ImVec4(.2, .2, .2, .6),
    bg = ImVec4(1, 0, .5, 1),
    hovered = ImVec4(1, 0, .5, 1),
    active = ImVec4(1, 0, .7, 1),
    button = ImVec4(1, 0, .4, 1),
    text = ImVec4(1, 1, 1, 1),
}

GOLD = {
    windowbg = ImVec4(.2, .2, .2, .6),
    bg = ImVec4(.4, .2, 0, 1),
    hovered = ImVec4(.6, .4, 0, 1),
    active = ImVec4(.7, .5, 0, 1),
    button = ImVec4(.5, .3, 0, 1),
    text = ImVec4(1, 1, 1, 1),
}

local function pushStyle(t)
    t.windowbg.w = 1*(75/100)
    t.bg.w = 1*(75/100)
    ImGui.PushStyleColor(ImGuiCol.WindowBg, t.windowbg)
    ImGui.PushStyleColor(ImGuiCol.TitleBg, t.bg)
    ImGui.PushStyleColor(ImGuiCol.TitleBgActive, t.active)
    ImGui.PushStyleColor(ImGuiCol.FrameBg, t.bg)
    ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, t.hovered)
    ImGui.PushStyleColor(ImGuiCol.FrameBgActive, t.active)
    ImGui.PushStyleColor(ImGuiCol.Button, t.button)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, t.hovered)
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, t.active)
    ImGui.PushStyleColor(ImGuiCol.PopupBg, t.bg)
    ImGui.PushStyleColor(ImGuiCol.Tab, 0, 0, 0, 0)
    ImGui.PushStyleColor(ImGuiCol.TabActive, t.active)
    ImGui.PushStyleColor(ImGuiCol.TabHovered, t.hovered)
    ImGui.PushStyleColor(ImGuiCol.TabUnfocused, t.bg)
    ImGui.PushStyleColor(ImGuiCol.TabUnfocusedActive, t.hovered)
    ImGui.PushStyleColor(ImGuiCol.HeaderActive, t.active)
    ImGui.PushStyleColor(ImGuiCol.Header, t.bg)
    ImGui.PushStyleColor(ImGuiCol.HeaderHovered, t.hovered)
    ImGui.PushStyleColor(ImGuiCol.TextDisabled, t.text)
    ImGui.PushStyleColor(ImGuiCol.Text, t.text)
    ImGui.PushStyleColor(ImGuiCol.CheckMark, t.text)
    ImGui.PushStyleColor(ImGuiCol.Separator, t.hovered)

    ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 10)
end

local dynamicWindowTitle = ''

local ability = state.config.abilities[state.class][editIndex]
if ability then
    if not ability.name then
        ability.name = 'Blank'
    end
    dynamicWindowTitle = "Edit Ability - " .. ability.name
    -- Rest of your code using ability.name
else
   state.config.abilities[state.class][editIndex] = {}
   state.config.abilities[state.class][editIndex].name = 'Blank'
   dynamicWindowTitle = "Edit Ability - " .. state.config.abilities[state.class][editIndex].name
end

local isNameInputActive = false

local function DrawEditorWindow()
    local flags = bit32.bor(ImGuiWindowFlags.NoSavedSettings)
    if isEditing then
        isEditing, shouldDrawEditor = ImGui.Begin(dynamicWindowTitle, isEditing, flags)
        if shouldDrawEditor then
            -- Add controls for editing ability properties
            ImGui.SetWindowSize(600,200,ImGuiCond.FirstUseEver)
            local contentWidthx, _ = ImGui.GetContentRegionAvail()
            ImGui.Columns(2, "AbilityColumns", false)

            -- Left column for the top-left section
            local leftColumnWidth = contentWidthx * 0.5  -- Adjust the proportion as needed
            ImGui.SetColumnWidth(0, leftColumnWidth)
            ImGui.BeginChild("LeftColumn", ImVec2(leftColumnWidth, -1))

            -- Top-left section
            if ImGui.BeginTable("TopLeftTable", 2, table_flags) then
                ImGui.TableSetupColumn("Variable", ImGuiTableColumnFlags.WidthFixed, 70)
                ImGui.TableSetupColumn("Value", ImGuiTableColumnFlags.WidthStretch)

                local alternatingColor = true

            -- Labels and Input fields
                local labels = {"Name:", "Type:", "Target:", "Cond:", "Burn:", "Feign:"}
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

                    ImGui.SetNextWindowSize(400,400)
                    ImGui.PushStyleColor(ImGuiCol.PopupBg, ImVec4(0, 0, 0, 1.0))
                    if ImGui.BeginPopup("FullTextPopup", ImGuiWindowFlags.AlwaysAutoResize) then
                        if label == 'Cond:' then
                            if ImGui.BeginChild("FullTextInput", 380, 380) then
                                -- Use InputTextMultiline inside the child window
                                local buffer = state.config.abilities[state.class][editIndex].cond or ""
                                state.config.abilities[state.class][editIndex].cond, _ = ImGui.InputTextMultiline("##InputText", buffer, 400, 400)
                        
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
                        state.config.abilities[state.class][editIndex].name, inputTextSubmitted = ImGui.InputText("##AbilityName", state.config.abilities[state.class][editIndex].name)
                        if inputTextSubmitted then
                            isNameInputActive = false
                        elseif ImGui.IsItemActive() then
                            isNameInputActive = true
                        end
                        if ImGui.IsItemDeactivatedAfterEdit() and isNameInputActive then
                            dynamicWindowTitle = "Edit Ability - " .. state.config.abilities[state.class][editIndex].name
                            isNameInputActive = false
                        end
                    elseif label == "Type:" then
                        local types = {"AA", "Spell", "Item", "Skill", "Disc", "Cmd"}
                        local typeIndex = lib.findIndex(types, state.config.abilities[state.class][editIndex].type) or 1
                        local newTypeIndex, changed = ImGui.Combo("##Type", typeIndex, types)
                        if changed then
                            state.config.abilities[state.class][editIndex].type = types[newTypeIndex]
                        end
                
                    elseif label == "Target:" then
                        local targets = {"None", "Tank", "Self", "MA", "MA Target", "Custom Lua ID"}
                        local targetIndex = lib.findIndex(targets, state.config.abilities[state.class][editIndex].target) or 1
                        local newTargetIndex, changed = ImGui.Combo("##Tar", targetIndex, targets)
                        if changed then
                            state.config.abilities[state.class][editIndex].target = targets[newTargetIndex]
                
                            if state.config.abilities[state.class][editIndex].target == "Custom Lua ID" then
                                showCustTar = true
                            else
                                showCustTar = false
                            end
                        end

                        if showCustTar == true then 
                            local contentRegionPosX = ImGui.GetCursorPosX() - ImGui.GetScrollX()
                            ImGui.SetNextItemWidth(((contentWidthx * .5) - contentRegionPosX) - 10)
                            state.config.abilities[state.class][editIndex].custtar, _ = ImGui.InputText("##CustTar", state.config.abilities[state.class][editIndex].custtar)
                        end

                    elseif label == "Cond:" then
                        state.config.abilities[state.class][editIndex].cond, _ = ImGui.InputText("##cond", state.config.abilities[state.class][editIndex].cond)
                    elseif label == "Burn:" then
                        state.config.abilities[state.class][editIndex].burn, _ = ImGui.Checkbox("##Burn", state.config.abilities[state.class][editIndex].burn)
                    elseif label == "Feign:" then
                        state.config.abilities[state.class][editIndex].feign, _ = ImGui.Checkbox("##Feign", state.config.abilities[state.class][editIndex].feign)
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
                        state.config.abilities[state.class][editIndex].abilcd, _ = ImGui.InputInt("##RetryCD", state.config.abilities[state.class][editIndex].abilcd)
                    elseif label == "Loop Delay:" then
                        state.config.abilities[state.class][editIndex].loopdel, _ = ImGui.InputInt("##LoopDelay", state.config.abilities[state.class][editIndex].loopdel)
                    elseif label == "Priority:" then
                        state.config.abilities[state.class][editIndex].priority, _ = ImGui.InputInt("##Priority", state.config.abilities[state.class][editIndex].priority)
                    elseif label == "Active:" then
                        state.config.abilities[state.class][editIndex].active, _ = ImGui.Checkbox("##Active", state.config.abilities[state.class][editIndex].active)
                    elseif label == "Use In Combat:" then
                        local changed = nil
                        state.config.abilities[state.class][editIndex].usecombat, changed = ImGui.Checkbox("##UseCom", state.config.abilities[state.class][editIndex].usecombat)
                        if changed then
                            if not state.config.abilities[state.class][editIndex].usecombat then
                                abils.removeAbilFromQueue(state.config.abilities[state.class][editIndex],state.queueCombat)
                            else
                                abils.addAbilToQueue(state.config.abilities[state.class][editIndex],state.queueCombat)
                            end
                        end
                    elseif label == "Use Outside Combat:" then
                        local changed = nil
                        state.config.abilities[state.class][editIndex].useooc, _ = ImGui.Checkbox("##UseOOC", state.config.abilities[state.class][editIndex].useooc)
                        if changed then
                            if not state.config.abilities[state.class][editIndex].useooc then
                                abils.removeAbilFromQueue(state.config.abilities[state.class][editIndex],state.queueOOC)
                            else
                                abils.addAbilToQueue(state.config.abilities[state.class][editIndex],state.queueOOC)
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
            showCustTar = false
        end
        ImGui.End()
    end
end

local function DrawList()
    ImGui.BeginChild("ListBorder", ImVec2(0, 200))

    local totalWidth = ImGui.GetWindowWidth()
    local checkboxWidth = totalWidth * 0.15
    local nameWidth = totalWidth * 0.65
    local editButtonWidth = totalWidth * 0.20

    if ImGui.BeginTable("ListTable", 3, table_flags) then
        ImGui.TableSetupColumn("Active", ImGuiTableColumnFlags.WidthFixed, checkboxWidth)
        ImGui.TableSetupColumn("Name", ImGuiTableColumnFlags.WidthFixed, nameWidth)
        ImGui.TableSetupColumn("Edit", ImGuiTableColumnFlags.WidthFixed, editButtonWidth)
        ImGui.TableHeadersRow()

        local alternatingColor = true
        for i, ability in ipairs(state.config.abilities[state.class]) do
            ImGui.TableNextRow()

            if alternatingColor then
                ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, ImVec4(0, 0, 0, 1.0))  -- Darker color
            else
                ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, ImVec4(0.1, 0.1, 0.1, 1.0))  -- Slightly lighter color
            end

            ImGui.TableSetColumnIndex(0)
            ability.active, _ = ImGui.Checkbox("##Check" .. i, ability.active)

            ImGui.TableSetColumnIndex(1)
            ImGui.Text(ability.name)

            ImGui.TableSetColumnIndex(2)
            if ImGui.Button("Edit##" .. i) then
                isEditing = true
                editIndex = i
            end
            alternatingColor = not alternatingColor
        end

        ImGui.EndTable()
    end

    ImGui.EndChild()
end

local function popStyles()
    ImGui.PopStyleColor(22)

    ImGui.PopStyleVar(1)
end

function mod.main()
    if not openGUI then return end
    pushStyle(themes[state.class])
    openGUI, shouldDrawGUI = ImGui.Begin(state.class .. '420', openGUI, ImGuiWindowFlags.None)
    if shouldDrawGUI then
        ImGui.SetWindowSize(600,800,ImGuiCond.FirstUseEver)
        if ImGui.BeginTabBar("Tabs") then
            if ImGui.BeginTabItem("List Tab") then
                DrawList()
                DrawEditorWindow()
                ImGui.EndTabItem()
            end
    
            -- Add more tabs as needed
    
            ImGui.EndTabBar()
        end
    end

    -- Make sure to call popStyles() and ImGui.End() even if shouldDrawGUI is false
    popStyles()
    ImGui.End()
end



return mod





