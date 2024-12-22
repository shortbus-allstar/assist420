local mq = require('mq')
local config= require('interface.config')

local write = require('utils.Write')
local state = require('utils.state')
local lib = require('utils.lib')

local navigation = require('routines.navigation')
local abils = require('routines.abils')

local anim = mq.FindTextureAnimation('A_SpellIcons')
local classanim = mq.FindTextureAnimation('A_DragItem')
local icons = require('mq.icons')

local BUTTON_SIZE = 55
local editIndex = 1
local selectedOptionIndextheme = 1
local debuffOverrideIndex = 1
local buffOverrideIndex = 1
local buffTargetIndex = 1
local frameCounter = 0
local flashInterval = 250 

local showTableGUI = false
local openGUI = true
local shouldDrawGUI = true
local isEditing = false
local isEditingAggro = false
local isEditingHeal = false
local isEditingDebuff = false
local isEditingBuff = false
local shouldDrawEditor = true
local shouldDrawAggroEditor = true
local shouldDrawHealEditor = true
local shouldDrawDebuffEditor = true
local shouldDrawBuffEditor = true
local showDebuffOverwriteWindow = false
local showBuffTargetWindow = false
local showBuffOverrideWindow = false
local pickerAbilIndex = 0
local pickerlist = state.config.abilities
local showCustTar = false

local table_flags = bit32.bor(ImGuiTableFlags.Hideable, ImGuiTableFlags.RowBg, ImGuiTableFlags.ScrollY, ImGuiTableFlags.BordersOuter, ImGuiTableFlags.Resizable)

local newIgnoreValue = ""
local newassist = ""

local pushedStyleVarCount = 0
local pushedStyleCount = 0

local mod ={}

state.config.cureAvoids = state.config.cureAvoids or {}
state.config.otherTankList = state.config.otherTankList or {}
state.config.hotTargets = state.config.hotTargets or {}

local themes = {
    {
        windowbg = ImVec4(0.137, 0.224, 0.137, 1),  
        bg = ImVec4(0.118, 0.376, 0.118, 1),       
        hovered = ImVec4(0.078, 0.306, 0.078, 1),   
        active = ImVec4(0.059, 0.267, 0.059, 1),    
        button = ImVec4(0.118, 0.376, 0.118, 1),   
        text = ImVec4(0.949, 0.949, 0.2, 1),     
        name = 'Dank Marijuana Cat Piss Ganja',
        index = 1
    },
    {
        windowbg = ImVec4(.2, .2, .2, .8),
        bg = ImVec4(0.5, 0, 0.7, 1),
        hovered = ImVec4(0.6, 0, 0.8, 1),
        active = ImVec4(0.7, 0, 0.9, 1),
        button = ImVec4(0.4, 0, 0.6, 1),
        text = ImVec4(1, 1, 1, 1),
        name = "Purple Transformer",
        index = 2
    },
    {
        windowbg = ImVec4(0.2, 0, 0.2, 0.9),
        bg = ImVec4(0.3, 0, 0.3, 1),
        hovered = ImVec4(1, 0, 1, 1),
        active = ImVec4(0.8, 0, 0.8, 1),
        button = ImVec4(0.6, 0, 0.6, 1),
        text = ImVec4(1, 1, 1, 1),
        name = "Double Cup Sizzurp",
        index = 3
    },
    {
        windowbg = ImVec4(.2, .2, .2, .8),
        bg = ImVec4(0.3, 0.3, 0.6, 1),
        hovered = ImVec4(0.4, 0.4, 0.7, 1),
        active = ImVec4(0.5, 0.5, 0.8, 1),
        button = ImVec4(0.2, 0.2, 0.5, 1),
        text = ImVec4(1, 1, 1, 1),                
        name = "Necrohiss Baby Blue",
        index = 4
    },
    {
        windowbg = ImVec4(.1, .1, .1, .9),
        bg = ImVec4(0.7, 0.2, 0, 1),
        hovered = ImVec4(0.8, 0.3, 0, 1),
        active = ImVec4(0.9, 0.4, 0, 1),
        button = ImVec4(0.6, 0.1, 0, 1),
        text = ImVec4(1, 1, 1, 1),
        name = "Very Cool Lava " .. icons.FA_THUMBS_UP,
        index = 5
    },
    {
        windowbg = ImVec4(.1, .1, .1, .9),
        bg = ImVec4(0.5, 0.3, 0, 1),
        hovered = ImVec4(0.6, 0.4, 0, 1),
        active = ImVec4(0.7, 0.5, 0, 1),
        button = ImVec4(0.4, 0.2, 0, 1),
        text = ImVec4(1, 1, 1, 1),
        name = "Toasted Nuts",
        index = 6
    },
    {
        windowbg = ImVec4(.3, .3, .3, .8),
        bg = ImVec4(0, 0.5, 0.5, 1),
        hovered = ImVec4(0, 0.6, 0.6, 1),
        active = ImVec4(0, 0.7, 0.7, 1),
        button = ImVec4(0, 0.4, 0.4, 1),
        text = ImVec4(1, 1, 1, 1),
        name = "Light Blue Transformer",
        index = 7
    },
    {
        windowbg = ImVec4(.3, .3, .3, .8),
        bg = ImVec4(0.7, 0.2, 0.5, 1),
        hovered = ImVec4(0.8, 0.3, 0.6, 1),
        active = ImVec4(0.9, 0.4, 0.7, 1),
        button = ImVec4(0.6, 0.1, 0.4, 1),
        text = ImVec4(1, 1, 1, 1),
        name = "Pink Sock",
        index = 8
    },
    {
        windowbg = ImVec4(.2, .2, .2, .8),
        bg = ImVec4(0.7, 0, 0.2, 1),
        hovered = ImVec4(0.8, 0, 0.3, 1),
        active = ImVec4(0.9, 0, 0.4, 1),
        button = ImVec4(0.6, 0, 0.1, 1),
        text = ImVec4(1, 1, 1, 1),
        name = "Bloody Pink Sock",
        index = 9
    },
    {
        windowbg = ImVec4(0.2, 0.05, 0.2, 0.8),
        bg = ImVec4(0.5, 0, 0.5, 1),
        hovered = ImVec4(0, 1, 0.5, 1),
        active = ImVec4(0.2, 0.8, 0.2, 1),
        button = ImVec4(0.3, 0, 0.3, 1),
        text = ImVec4(1, 1, 1, 1),
        name = "Hulk (Incredible)",
        index = 10
    },
    {
        windowbg = ImVec4(0.1, 0.05, 0.1, 0.9),
        bg = ImVec4(0, 0, 0, 1),
        hovered = ImVec4(1, 0, 1, 1),
        active = ImVec4(0.8, 0, 0.8, 1),
        button = ImVec4(0.6, 0, 0.6, 1),
        text = ImVec4(1, 1, 1, 1),
        name = "Cyberpunk",
        index = 11
    },
    {
        windowbg = ImVec4(0.4, 0.1, 0.1, 0.8),
        bg = ImVec4(0.5, 0, 0, 1),
        hovered = ImVec4(0, 0, 0.5, 1),
        active = ImVec4(0.2, 0.2, 0.8, 1),
        button = ImVec4(0.3, 0, 0, 1),
        text = ImVec4(1, 1, 1, 1),
        name = "Walmart Spiderman",
        index = 12
    },
    {
        windowbg = ImVec4(0.4, 0.2, 0, 0.9),
        bg = ImVec4(1, 0.5, 0, 1),
        hovered = ImVec4(0.5, 0, 0.5, 1),
        active = ImVec4(0.7, 0.2, 0.7, 1),
        button = ImVec4(0.3, 0.5, 0.3, 1),
        text = ImVec4(1, 1, 1, 1),
        name = "Weird Vomit",
        index = 13
    },
    {
        windowbg = ImVec4(0.4, 0.2, 0, 0.9),
        bg = ImVec4(1, 0.5, 0, 1),
        hovered = ImVec4(0, 1, 0.5, 1),
        active = ImVec4(0.2, 0.8, 0.2, 1),
        button = ImVec4(0.3, 0.5, 0.3, 1),
        text = ImVec4(1, 1, 1, 1),
        name = "Plastic Minecraft",
        index = 14
    },
    {
        windowbg = ImVec4(0, 0.1, 0.2, 0.9),
        bg = ImVec4(0, 0, 0.3, 1),
        hovered = ImVec4(0.5, 0, 1, 1),
        active = ImVec4(0.7, 0.2, 1, 1),
        button = ImVec4(0.3, 0, 0.7, 1),
        text = ImVec4(1, 1, 1, 1),
        name = "Nyquil",
        index = 15
    },
    {
        windowbg = ImVec4(0.4, 0.4, 0, 0.9),
        bg = ImVec4(1, 1, 0, 1),
        hovered = ImVec4(1, 0.5, 0, 1),
        active = ImVec4(1, 0.8, 0.2, 1),
        button = ImVec4(0.7, 0.7, 0, 1),
        text = ImVec4(0, 0, 0, 1),
        name = "Toxic Piss",
        index = 16
    },
    {
        windowbg = ImVec4(0, 0.1, 0.2, 0.9),
        bg = ImVec4(0, 0.3, 0.5, 1),
        hovered = ImVec4(1, 0.5, 0, 1),
        active = ImVec4(1, 0.7, 0.2, 1),
        button = ImVec4(0, 0.2, 0.5, 1),
        text = ImVec4(1, 1, 1, 1),
        name = "Goku",
        index = 17
    },

}

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

local function pushStyleColor(...)
    ImGui.PushStyleColor(...)
    pushedStyleCount = pushedStyleCount + 1
end
local function pushStyleVar(...)
    ImGui.PushStyleVar(...)
    pushedStyleVarCount = pushedStyleVarCount + 1
end

-- Function to pop all pushed style colors


local function pushStyle(t)
    t.windowbg.w = 1*(75/100)
    t.bg.w = 1*(75/100)
    pushStyleColor(ImGuiCol.WindowBg, t.windowbg)
    pushStyleColor(ImGuiCol.TitleBg, t.bg)
    pushStyleColor(ImGuiCol.TitleBgActive, t.active)
    pushStyleColor(ImGuiCol.FrameBg, t.bg)
    pushStyleColor(ImGuiCol.FrameBgHovered, t.hovered)
    pushStyleColor(ImGuiCol.FrameBgActive, t.active)
    pushStyleColor(ImGuiCol.Button, t.button)
    pushStyleColor(ImGuiCol.ButtonHovered, t.hovered)
    pushStyleColor(ImGuiCol.ButtonActive, t.active)
    pushStyleColor(ImGuiCol.PopupBg, t.bg)
    pushStyleColor(ImGuiCol.Tab, 0, 0, 0, 0)
    pushStyleColor(ImGuiCol.TabActive, t.active)
    pushStyleColor(ImGuiCol.TabHovered, t.hovered)
    pushStyleColor(ImGuiCol.TabUnfocused, t.bg)
    pushStyleColor(ImGuiCol.TabUnfocusedActive, t.hovered)
    pushStyleColor(ImGuiCol.HeaderActive, t.active)
    pushStyleColor(ImGuiCol.Header, t.bg)
    pushStyleColor(ImGuiCol.HeaderHovered, t.hovered)
    pushStyleColor(ImGuiCol.TextDisabled, t.text)
    pushStyleColor(ImGuiCol.Text, t.text)
    pushStyleColor(ImGuiCol.CheckMark, t.text)
    pushStyleColor(ImGuiCol.Separator, t.hovered)

    pushStyleVar(ImGuiStyleVar.WindowRounding, 10)
end

local dynamicWindowTitle = ''
local dynamicAggroWindowTitle = ''
local dynamicHealWindowTitle = ''
local dynamicDebuffWindowTitle = ''
local dynamicBuffWindowTitle = ''

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function arrangeAbils()
    table.sort(state.config.abilities[state.class], function(a, b) return a.priority < b.priority end)
    table.sort(state.config.aggroabils[state.class], function(a, b) return a.priority < b.priority end)
    table.sort(state.config.healabils[state.class], function(a, b) return a.priority < b.priority end)
    table.sort(state.config.debuffabils[state.class], function(a, b) return a.priority < b.priority end)
    table.sort(state.config.buffabils[state.class], function(a, b) return a.priority < b.priority end)
end

local isNameInputActive = false

local function DrawTabEnd()
    local windowHeight = ImGui.GetWindowHeight()
    local buttonPosY = windowHeight - BUTTON_SIZE - 10  -- Adjust the spacing as needed

    ImGui.SetCursorPosY(buttonPosY)
    local buttonLabel1 = "Save\nConfig"

    if ImGui.Button(buttonLabel1, BUTTON_SIZE, BUTTON_SIZE) then
        config.saveConfig()
    end

    ImGui.SameLine()
            
    local buttonLabel2 = "Load\nConfig"
    if ImGui.Button(buttonLabel2, BUTTON_SIZE, BUTTON_SIZE) then
        config.loadConfig()
    end

    ImGui.SameLine()

    if ImGui.Button(string.format('Reload\n     ' .. icons.FA_REFRESH), BUTTON_SIZE, BUTTON_SIZE) then
        mq.cmd('/multiline ; /lua stop assist420 ; /timed 5 /lua run assist420')
    end
end

local function updatePicker(list,abilIndex)
    if Picker and Picker.Selected then
        local selected = Picker.Selected or {}
        if selected.Type == 'Spell' then
            list[state.class][abilIndex].type = selected.Type
            list[state.class][abilIndex].name = selected.Name
            if list == state.config.buffabils then list[state.class][abilIndex].buffname = selected.Name end
            if list == state.config.debuffabils then list[state.class][abilIndex].debuffname = selected.Name end
            Picker:ClearSelection()
        elseif selected.Type == 'Disc' then
            list[state.class][abilIndex].type = selected.Type
            list[state.class][abilIndex].name = selected.Name
            if list == state.config.buffabils then list[state.class][abilIndex].buffname = selected.Name end
            if list == state.config.debuffabils then list[state.class][abilIndex].debuffname = selected.Name end
            Picker:ClearSelection()
        elseif selected.Type == 'AA' then
            list[state.class][abilIndex].type = selected.Type
            list[state.class][abilIndex].name = selected.Name
            if list == state.config.buffabils then list[state.class][abilIndex].buffname = selected.Name end
            if list == state.config.debuffabils then list[state.class][abilIndex].debuffname = selected.Name end
            Picker:ClearSelection()
        elseif selected.Type == 'Item' then
            list[state.class][abilIndex].type = selected.Type
            list[state.class][abilIndex].name = selected.Name
            if list == state.config.buffabils then list[state.class][abilIndex].buffname = selected.Name end
            if list == state.config.debuffabils then list[state.class][abilIndex].debuffname = selected.Name end
            Picker:ClearSelection()
        elseif selected.Type == 'Ability' then
            list[state.class][abilIndex].type = "Skill"
            list[state.class][abilIndex].name = selected.Name
            if list == state.config.buffabils then list[state.class][abilIndex].buffname = selected.Name end
            if list == state.config.debuffabils then list[state.class][abilIndex].debuffname = selected.Name end
            Picker:ClearSelection()
        end
    end
end

function DrawInfoIconWithTooltip(text)
    ImGui.SameLine()
    ImGui.Text(icons.FA_INFO_CIRCLE)
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.Text(text)
        ImGui.EndTooltip()
    end
end

function DrawTable(name,rows, columns, columnLabels, checkWidth, nameWidth, editWidth, ...)
    local columnData = {...}

    assert(#columnLabels == columns, "Number of column labels must match the number of columns")
    for i = 1, columns do
        assert(#columnData[i] == rows, "Each column data must have the same number of rows")
    end

    if ImGui.BeginTable(name, columns, table_flags) then
        -- Set up the column labels
        for i = 1, columns do

            if checkWidth and i == 1 then 
                ImGui.TableSetupColumn(columnLabels[i],ImGuiTableColumnFlags.WidthFixed,checkWidth)
            elseif nameWidth and i == 2 then
                ImGui.TableSetupColumn(columnLabels[i],ImGuiTableColumnFlags.WidthFixed,nameWidth)
            elseif editWidth and i == 3 then
                ImGui.TableSetupColumn(columnLabels[i],ImGuiTableColumnFlags.WidthFixed,editWidth)
            else
                ImGui.TableSetupColumn(columnLabels[i])
            end
        end
        ImGui.TableHeadersRow()

        -- Fill the table with data
        local alternatingColor = true
        for row = 1, rows do

            if name ~= "HealEditWin" or row ~= 4 or state.config.healabils[state.class][editIndex].cure then
                ImGui.TableNextRow(0,27)
                

                -- Set background color for the row
                if alternatingColor then
                    ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, ImVec4(0, 0, 0, 1.0))  -- Darker color
                else
                    ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, ImVec4(0.1, 0.1, 0.1, 1.0))  -- Slightly lighter color
                end
                alternatingColor = not alternatingColor

                -- Insert the data for each column in the current row
                for col = 1, columns do
                    ImGui.TableSetColumnIndex(col - 1)
                    local cellData = columnData[col][row]
                    if type(cellData) == "function" then
                        cellData()  -- Call the function to render ImGui element
                    else
                        ImGui.Text(tostring(cellData))
                    end
                end
            end
        end

        ImGui.EndTable()
    end
end

local function DrawDragDrop(ability,abilityList,nameWidth,i)
    if ImGui.Button(ability.name .. " - " .. ability.priority, ImVec2(nameWidth - 30, 0)) then
    end

    if ImGui.BeginDragDropSource() then
        ImGui.SetDragDropPayload("ABILITY_INDEX", ability.priority)
        ImGui.Text("Ability: %s", ability.name)
        ImGui.EndDragDropSource()
    end
    if ImGui.BeginDragDropTarget() then
        local payload = ImGui.AcceptDragDropPayload("ABILITY_INDEX")
        if payload then
            local targetPriority = payload.Data
            if targetPriority ~= ability.priority then
                write.Help("Target Current Name: %s",ability.name)
                write.Help("Target Current Priority: %s",ability.priority)
                write.Help("Dragitem Current Name: %s",abilityList[state.class][targetPriority].name)
                write.Help("Dragitem Current Priority: %s",abilityList[state.class][targetPriority].priority)
                write.Help("targetPriority Variable: %s",targetPriority)

                if state.copyMode then
                    local originalPriority = abilityList[state.class][ability.priority].priority
                    local copiedAbility = deepcopy(abilityList[state.class][targetPriority])
                    copiedAbility.priority = originalPriority
                    abilityList[state.class][ability.priority] = copiedAbility
                    arrangeAbils()
                    if isEditing and editIndex ~= ability.priority then editIndex = ability.priority dynamicWindowTitle = abilityList[state.class][ability.priority].name end
                else
                 -- Swap the priorities of the dragged item and the current item
                    abilityList[state.class][targetPriority].priority = ability.priority
                    ability.priority = targetPriority
                    arrangeAbils()
                    if isEditing and editIndex ~= ability.priority then editIndex = ability.priority dynamicWindowTitle = abilityList[state.class][ability.priority].name end
                end
            end
        end
        ImGui.EndDragDropTarget()
    end

    ImGui.SameLine()
    ImGui.SetCursorPosX(ImGui.GetCursorPosX() - 5)

    pickerlist = abilityList

    if ImGui.Button(icons.FA_BULLSEYE .. "##" .. i, ImVec2(25,0)) and Picker then 
        Picker:SetOpen()
        pickerAbilIndex = i
    end

    if Picker and i == 1 then 
        Picker:DrawAbilityPicker() 
    end

end

local function DrawDropdown(currentValue, name, optionList, itemWidth)
    local selectedOptionIndex = nil

    -- Find the currently selected index
    for i, option in ipairs(optionList) do
        if option == currentValue then
            selectedOptionIndex = i
            break
        end
    end

    if itemWidth then
        ImGui.SetNextItemWidth(itemWidth)
    end

    if ImGui.BeginCombo(name, currentValue, ImGuiComboFlags.None) then
        -- Set the width of each item in the dropdown, if specified

        for i, option in ipairs(optionList) do
            local isSelected = (i == selectedOptionIndex)
            ImGui.PushStyleColor(ImGuiCol.Text, isSelected and ImVec4(0, 1, 1, 1) or ImGui.GetStyleColorVec4(ImGuiCol.Text))
            if ImGui.Selectable(option, isSelected) then
                selectedOptionIndex = i
                currentValue = option -- Update the currentValue based on the selected option
            end
            
            ImGui.PopStyleColor()
            
            -- Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
            if isSelected then
                ImGui.SetItemDefaultFocus()
            end
        end
        
        ImGui.EndCombo()
    end
    
    return currentValue
end

local function DrawEditDeleteAggro(ability,abilList)
    if ImGui.Button("Edit##Aggro" .. ability.priority) then
        isEditingAggro = true
        editIndex = ability.priority
        if ability then
            if not ability.name then
                ability.name = 'Blank'
            end
            dynamicAggroWindowTitle = "Edit Aggro Ability - " .. ability.name
            -- Rest of your code using ability.name
        else
           abilList[state.class][editIndex] = {}
           abilList[state.class][editIndex].name = 'Blank'
           dynamicAggroWindowTitle = "Edit Aggro Ability - " .. abilList[state.class][editIndex].name
        end
    end

    ImGui.SameLine()

    if ImGui.Button("Delete##" .. ability.priority) then
        table.remove(abilList[state.class], ability.priority)
        
        for i = 1, #state.config.aggroabils[state.class] do
            state.config.aggroabils[state.class][i].priority = i
        end
    end

end

local function DrawEditDeleteHeal(ability,abilList)
    if ImGui.Button("Edit##Heal" .. ability.priority) then
        isEditingHeal = true
        editIndex = ability.priority
        if ability then
            if not ability.name then
                ability.name = 'Blank'
            end
            dynamicHealWindowTitle = "Edit Heal Ability - " .. ability.name
            -- Rest of your code using ability.name
        else
           abilList[state.class][editIndex] = {}
           abilList[state.class][editIndex].name = 'Blank'
           dynamicHealWindowTitle = "Edit Heal Ability - " .. abilList[state.class][editIndex].name
        end
    end

    ImGui.SameLine()

    if ImGui.Button("Delete##" .. ability.priority) then
        table.remove(abilList[state.class], ability.priority)
        
        for i = 1, #state.config.healabils[state.class] do
            state.config.healabils[state.class][i].priority = i
        end
    end

end

local function DrawEditDeleteDebuff(ability,abilList)
    if ImGui.Button("Edit##Debuff" .. ability.priority) then
        isEditingDebuff = true
        editIndex = ability.priority
        if ability then
            if not ability.name then
                ability.name = 'Blank'
            end
            dynamicDebuffWindowTitle = "Edit Debuff Ability - " .. ability.name
            -- Rest of your code using ability.name
        else
           abilList[state.class][editIndex] = {}
           abilList[state.class][editIndex].name = 'Blank'
           dynamicDebuffWindowTitle = "Edit Debuff Ability - " .. abilList[state.class][editIndex].name
        end
    end

    ImGui.SameLine()

    if ImGui.Button("Delete##" .. ability.priority) then
        table.remove(abilList[state.class], ability.priority)
        
        for i = 1, #state.config.debuffabils[state.class] do
            state.config.debuffabils[state.class][i].priority = i
        end
    end

end

local function DrawEditDeleteBuff(ability,abilList)
    if ImGui.Button("Edit##Buff" .. ability.priority) then
        isEditingBuff = true
        editIndex = ability.priority
        if ability then
            if not ability.name then
                ability.name = 'Blank'
            end
            dynamicBuffWindowTitle = "Edit Buff Ability - " .. ability.name
            -- Rest of your code using ability.name
        else
           abilList[state.class][editIndex] = {}
           abilList[state.class][editIndex].name = 'Blank'
           dynamicBuffWindowTitle = "Edit Buff Ability - " .. abilList[state.class][editIndex].name
        end
    end

    ImGui.SameLine()

    if ImGui.Button("Delete##" .. ability.priority) then
        table.remove(abilList[state.class], ability.priority)
        
        for i = 1, #state.config.buffabils[state.class] do
            state.config.buffabils[state.class][i].priority = i
        end
    end

end

local function DrawAggroEditorWindow()
    local flags = bit32.bor(ImGuiWindowFlags.NoSavedSettings)
    if isEditingAggro then
        isEditingAggro, shouldDrawAggroEditor = ImGui.Begin(dynamicAggroWindowTitle, isEditingAggro, flags)
        if shouldDrawAggroEditor then
            ImGui.SetWindowSize(600, 167, ImGuiCond.FirstUseEver)  -- Adjust window size as needed
            
            local abil = state.config.aggroabils[state.class][editIndex]
            local dropdownOptions = {"AA", "Spell", "Item", "Skill", "Disc", "Cmd"}  -- Dropdown options

            ImGui.Columns(2, "AggroColumns", false)  -- Split into 2 columns

            -- First table
            DrawTable("AggroEditWin", 4, 2, {"##1", "##2"}, 65, 200, nil,
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
            DrawTable("AggroEditWin2", 4, 2, {"##3", "##4"}, 75, 200, nil,
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
    end
end

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
                    

                    ImGui.SetNextWindowSize(1000,600)
                    ImGui.PushStyleColor(ImGuiCol.PopupBg, ImVec4(0, 0, 0, 1.0))
                    if ImGui.BeginPopup("FullTextPopup", ImGuiWindowFlags.AlwaysAutoResize and ImGuiWindowFlags.AlwaysHorizontalScrollbar) then
                        if label == 'Cond:' then
                            if ImGui.BeginChild("FullTextInput", 1000, 600) then
                                -- Use InputTextMultiline inside the child window
                                local buffer = state.config.abilities[state.class][editIndex].cond or ""
                                state.config.abilities[state.class][editIndex].cond, _ = ImGui.InputTextMultiline("##InputText", buffer, 1000, 600)
                        
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
                        local newPriority, _ = ImGui.InputInt("##Priority", state.config.abilities[state.class][editIndex].priority)
                        -- Check if the entered priority already exists
                        local isDuplicate = false
                        for _, ability in ipairs(state.config.abilities[state.class]) do
                            if ability.priority == newPriority and ability ~= state.config.abilities[state.class][editIndex] then
                                isDuplicate = true
                                break
                            end
                        end
                        if isDuplicate then
                            ImGui.TextColored(1, 0, 0, 1, "Priority already exists")
                        else
                            state.config.abilities[state.class][editIndex].priority = newPriority
                        end                    
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
                        state.config.abilities[state.class][editIndex].useooc, changed = ImGui.Checkbox("##UseOOC", state.config.abilities[state.class][editIndex].useooc)
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

local function contains(table, val)
    for _, value in ipairs(table) do
        if value == val then
            return true
        end
    end
    return false
end

local function DrawDebuffEditorWindow()
    local flags = bit32.bor(ImGuiWindowFlags.NoSavedSettings)
    if isEditingDebuff then
        isEditingDebuff, shouldDrawDebuffEditor = ImGui.Begin(dynamicDebuffWindowTitle, isEditingDebuff, flags)
        if shouldDrawDebuffEditor then
            ImGui.SetWindowSize(600, 230, ImGuiCond.FirstUseEver) -- Adjust window size as needed

            -- Access the debuff ability being edited
            local abil = state.config.debuffabils[state.class][editIndex]
            local dropdownOptions = {"AA", "Spell", "Item", "Skill", "Disc", "Cmd"} -- Dropdown options

            ImGui.Columns(2, "DebuffColumns", false) -- Split into 2 columns

            -- First table
            DrawTable("DebuffEditWin", 6, 2, {"##1", "##2"}, 115, 150, nil,
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
                        if ImGui.Button(icons.FA_EXPAND, ImVec2(20, 20)) then
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
            DrawTable("DebuffEditWin2", 5, 2, {"##3", "##4"}, 75, 200, nil,
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
                            showDebuffOverwriteWindow = true
                            debuffOverrideIndex = abil.priority
                        end
                    end
                })

            ImGui.Columns(1) -- Reset columns to single column layout

            ImGui.End()
        end
    end
end

local function DrawBuffEditorWindow()
    local flags = bit32.bor(ImGuiWindowFlags.NoSavedSettings)
    if isEditingBuff then
        isEditingBuff, shouldDrawBuffEditor = ImGui.Begin(dynamicBuffWindowTitle, isEditingBuff, flags)
        if shouldDrawBuffEditor then
            ImGui.SetWindowSize(600, 250, ImGuiCond.FirstUseEver) -- Adjust window size as needed

            -- Access the Buff ability being edited
            local abil = state.config.buffabils[state.class][editIndex]
            local dropdownOptions = {"AA", "Spell", "Item", "Skill", "Disc", "Cmd"} -- Dropdown options

            ImGui.Columns(2, "BuffColumns", false) -- Split into 2 columns

            -- First table
            DrawTable("BuffEditWin", 7, 2, {"##1", "##2"}, 100, 200, nil,
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
                        if ImGui.Button(icons.FA_EXPAND, ImVec2(20, 20)) then
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
                    function()  
                        if ImGui.Button("Open Buff Targets",165,20) then
                            showBuffTargetWindow = true
                            buffTargetIndex = abil.priority
                        end
                    end,
                    function()  
                        if ImGui.Button("Open Buff Overrides",165,20) then
                            showBuffOverrideWindow = true
                            buffOverrideIndex = abil.priority
                        end
                    end
                })


            ImGui.NextColumn() -- Move to the next column

            -- Second table (Add any additional fields if needed)
            -- For example, you might have settings like 'Max Targets' or 'Buff Mode'

            -- Example:
            DrawTable("BuffEditWin2", 7, 2, {"##3", "##4"}, 120, 200, nil,
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

            ImGui.End()
        end
    end
end


local function DrawHealEditorWindow()
    local flags = bit32.bor(ImGuiWindowFlags.NoSavedSettings)
    if isEditingHeal then
        isEditingHeal, shouldDrawHealEditor = ImGui.Begin(dynamicHealWindowTitle, isEditingHeal, flags)
        if shouldDrawHealEditor then
            ImGui.SetWindowSize(600, 350, ImGuiCond.FirstUseEver) -- Adjust window size as needed

            local abil = state.config.healabils[state.class][editIndex]
            local dropdownOptions = {"AA", "Spell", "Item", "Skill", "Disc", "Cmd"} -- Dropdown options
            local cureOptions = {
                "Poison", "Disease", "Curse", "Corruption", "Detrimental"
            }-- Cure type options

            ImGui.Columns(2, "HealColumns", false) -- Split into 2 columns

            -- First table
            DrawTable("HealEditWin", 10, 2, {"##1", "##2"}, 150, 110, nil,
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
                    function()
                        if abil.cure then 
                            ImGui.Text("Cure Type:")
                        else
                            ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 25)
                        end
                    end,
                    "Cure:",
                    "Rez:",
                    "Active:",
                    "AE Heal:",
                    "Emergency Heal:",
                    "HoT:"
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
                    function() abil.hot = ImGui.Checkbox("##hot", abil.hot) end
                })

            ImGui.NextColumn() -- Move to the next column

            -- Second table
            DrawTable("HealEditWin2", 10, 2, {"##3", "##4"}, 150, 120, nil,
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

            ImGui.End()
        end
    end
end



local function DrawAggroList()
    local function calculateTableHeight()
        local totalHeight = (#state.config.aggroabils[state.class] * 27) + 20
        if totalHeight < 317 then 
            return totalHeight
        else 
            return 317
        end 
    end

    local tableHeight = calculateTableHeight()
    ImGui.BeginChild("AggroBorder", ImVec2(0, tableHeight))

    local totalWidth = ImGui.GetWindowWidth()
    local checkboxWidth = totalWidth * 0.15
    local nameWidth = totalWidth * 0.65
    local editButtonWidth = totalWidth * 0.20

    local activedata = {}
    local buttondata = {}
    local editdata = {}

    for i = #state.config.aggroabils[state.class], 1, -1 do
        local v = state.config.aggroabils[state.class][i]
        if v.priority ~= i then v.priority = i end
        if not v then 
            write.Error('Ability at index', i, 'is nil')
        else
            table.insert(activedata, 1, function() v.active = DrawCheckbox(v.active, "##aggro" .. i) end)
            table.insert(buttondata, 1, function() DrawDragDrop(v, state.config.aggroabils, nameWidth, i) end)
            table.insert(editdata, 1, function() DrawEditDeleteAggro(v, state.config.aggroabils) end)
        end
    end


    
    DrawTable("AggroListTable",#state.config.aggroabils[state.class],3,{"Active","Aggro Ability","Edit / Delete"},checkboxWidth,nameWidth,editButtonWidth,activedata,buttondata,editdata)

    ImGui.EndChild()
    

end

local function DrawHealList()
    local function calculateTableHeight()
        local totalHeight = (#state.config.healabils[state.class] * 27) + 20
        if totalHeight < 317 then
            return totalHeight
        else
            return 317
        end
    end

    local tableHeight = calculateTableHeight()
    ImGui.BeginChild("HealListBorder", ImVec2(0, tableHeight))

    local totalWidth = ImGui.GetWindowWidth()
    local checkboxWidth = totalWidth * 0.15
    local nameWidth = totalWidth * 0.65
    local editButtonWidth = totalWidth * 0.20

    local activedata = {}
    local buttondata = {}
    local editdata = {}

    for i = #state.config.healabils[state.class], 1, -1 do
        local v = state.config.healabils[state.class][i]
        if v.priority ~= i then v.priority = i end
        if not v then
            write.Error('Healing ability at index', i, 'is nil')
        else
            table.insert(activedata, 1, function() v.active = DrawCheckbox(v.active, "##heal" .. i) end)
            table.insert(buttondata, 1, function() DrawDragDrop(v, state.config.healabils, nameWidth, i) end)
            table.insert(editdata, 1, function() DrawEditDeleteHeal(v, state.config.healabils) end)
        end
    end

    DrawTable(
        "HealListTable",
        #state.config.healabils[state.class],
        3,
        {"Active", "Heal Ability", "Edit / Delete"},
        checkboxWidth,
        nameWidth,
        editButtonWidth,
        activedata,
        buttondata,
        editdata
    )

    ImGui.EndChild()
end

local function DrawDebuffList()
    local function calculateTableHeight()
        local totalHeight = (#state.config.debuffabils[state.class] * 27) + 20
        if totalHeight < 317 then
            return totalHeight
        else
            return 317
        end
    end

    local tableHeight = calculateTableHeight()
    ImGui.BeginChild("HealListBorder", ImVec2(0, tableHeight))

    local totalWidth = ImGui.GetWindowWidth()
    local checkboxWidth = totalWidth * 0.15
    local nameWidth = totalWidth * 0.65
    local editButtonWidth = totalWidth * 0.20

    local activedata = {}
    local buttondata = {}
    local editdata = {}

    for i = #state.config.debuffabils[state.class], 1, -1 do
        local v = state.config.debuffabils[state.class][i]
        if v.priority ~= i then v.priority = i end
        if not v then
            write.Error('Debuff ability at index', i, 'is nil')
        else
            table.insert(activedata, 1, function() v.active = DrawCheckbox(v.active, "##debuff" .. i) end)
            table.insert(buttondata, 1, function() DrawDragDrop(v, state.config.debuffabils, nameWidth, i) end)
            table.insert(editdata, 1, function() DrawEditDeleteDebuff(v, state.config.debuffabils) end)
        end
    end

    DrawTable(
        "DebuffListTable",
        #state.config.debuffabils[state.class],
        3,
        {"Active", "Debuff Ability", "Edit / Delete"},
        checkboxWidth,
        nameWidth,
        editButtonWidth,
        activedata,
        buttondata,
        editdata
    )

    ImGui.EndChild()
end

local function DrawBuffList()
    local function calculateTableHeight()
        local totalHeight = (#state.config.buffabils[state.class] * 27) + 20
        if totalHeight < 452 then
            return totalHeight
        else
            return 452
        end
    end

    local tableHeight = calculateTableHeight()
    ImGui.BeginChild("BuffListBorder", ImVec2(0, tableHeight))

    local totalWidth = ImGui.GetWindowWidth()
    local checkboxWidth = totalWidth * 0.15
    local nameWidth = totalWidth * 0.65
    local editButtonWidth = totalWidth * 0.20

    local activedata = {}
    local buttondata = {}
    local editdata = {}

    for i = #state.config.buffabils[state.class], 1, -1 do
        local v = state.config.buffabils[state.class][i]
        if v.priority ~= i then v.priority = i end
        if not v then
            write.Error('buff ability at index', i, 'is nil')
        else
            table.insert(activedata, 1, function() v.active = DrawCheckbox(v.active, "##buff" .. i) end)
            table.insert(buttondata, 1, function() DrawDragDrop(v, state.config.buffabils, nameWidth, i) end)
            table.insert(editdata, 1, function() DrawEditDeleteBuff(v, state.config.buffabils) end)
        end
    end

    DrawTable(
        "BuffListTable",
        #state.config.buffabils[state.class],
        3,
        {"Active", "Buff Ability", "Edit / Delete"},
        checkboxWidth,
        nameWidth,
        editButtonWidth,
        activedata,
        buttondata,
        editdata
    )

    ImGui.EndChild()
end




local function DrawList()

    local function calculateTableHeight()
        local totalHeight = (#state.config.abilities[state.class] * 26) + 20
        if totalHeight < 435 then 
            return totalHeight
        else 
            return 435
        end 
    end

    local tableHeight = calculateTableHeight()
    ImGui.BeginChild("ListBorder", ImVec2(0, tableHeight))

    local totalWidth = ImGui.GetWindowWidth()
    local checkboxWidth = totalWidth * 0.15
    local nameWidth = totalWidth * 0.65
    local editButtonWidth = totalWidth * 0.20

    local abilities = state.config.abilities[state.class]

    -- Sort abilities based on priority

    if ImGui.BeginTable("ListTable", 3, table_flags) then
        ImGui.TableSetupColumn("Active", ImGuiTableColumnFlags.WidthFixed, checkboxWidth)
        ImGui.TableSetupColumn("Name", ImGuiTableColumnFlags.WidthFixed, nameWidth)
        ImGui.TableSetupColumn("Edit / Delete", ImGuiTableColumnFlags.WidthFixed, editButtonWidth)
        ImGui.TableHeadersRow()


        local alternatingColor = true

        for i = 1, #abilities do
            arrangeAbils()
            local ability = abilities[i]
            if ability.priority ~= i then ability.priority = i end
            ImGui.TableNextRow()

            if alternatingColor then
                ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, ImVec4(0, 0, 0, 1.0))  -- Darker color
            else
                ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, ImVec4(0.1, 0.1, 0.1, 1.0))  -- Slightly lighter color
            end

            ImGui.TableSetColumnIndex(0)
            ability.active, _ = ImGui.Checkbox("##Check" .. ability.priority, ability.active)

            ImGui.TableSetColumnIndex(1)
            if ImGui.Button(ability.name .. " - " .. ability.priority, ImVec2(nameWidth - 30, 0)) then
            end

            if ImGui.BeginDragDropSource() then
                ImGui.SetDragDropPayload("ABILITY_INDEX", ability.priority)
                ImGui.Text("Ability: %s", ability.name)
                ImGui.EndDragDropSource()
            end
            if ImGui.BeginDragDropTarget() then
                local payload = ImGui.AcceptDragDropPayload("ABILITY_INDEX")
                if payload then
                    local targetPriority = payload.Data
                    if targetPriority ~= ability.priority then
                        write.Trace("Target Current Name: %s",ability.name)
                        write.Trace("Target Current Priority: %s",ability.priority)
                        write.Trace("Dragitem Current Name: %s",state.config.abilities[state.class][targetPriority].name)
                        write.Trace("Dragitem Current Priority: %s",state.config.abilities[state.class][targetPriority].priority)
                        write.Trace("targetPriority Variable: %s",targetPriority)

                        if state.copyMode then
                            local originalPriority = state.config.abilities[state.class][ability.priority].priority
                            local copiedAbility = deepcopy(state.config.abilities[state.class][targetPriority])
                            copiedAbility.priority = originalPriority
                            state.config.abilities[state.class][ability.priority] = copiedAbility
                            arrangeAbils()
                            if isEditing and editIndex ~= ability.priority then editIndex = ability.priority dynamicWindowTitle = state.config.abilities[state.class][ability.priority].name end
                        else
                         -- Swap the priorities of the dragged item and the current item
                            state.config.abilities[state.class][targetPriority].priority = ability.priority
                            ability.priority = targetPriority
                            arrangeAbils()
                            if isEditing and editIndex ~= ability.priority then editIndex = ability.priority dynamicWindowTitle = state.config.abilities[state.class][ability.priority].name end
                        end
                    end
                end
                ImGui.EndDragDropTarget()
            end

            ImGui.SameLine()
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() - 5)

            pickerlist = state.config.abilities

            if ImGui.Button(icons.FA_BULLSEYE .. "##" .. i, ImVec2(25,0)) and Picker then 
                Picker:SetOpen()
                pickerAbilIndex = i
            end

            if Picker and i == 1 then 
                Picker:DrawAbilityPicker() 
            end

            ImGui.TableSetColumnIndex(2)
            if ImGui.Button("Edit##" .. ability.priority) then
                isEditing = true
                editIndex = ability.priority
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
            end

            ImGui.SameLine()
            
            if ImGui.Button("Delete##" .. ability.priority) then
                table.remove(state.config.abilities[state.class], ability.priority)
                -- After removing an ability, you may need to break the loop or update your indices accordingly
                break
            end
            alternatingColor = not alternatingColor


        end

        ImGui.EndTable()
    
    end

    ImGui.EndChild()

    ImGui.NewLine()

    if ImGui.Button("Add Ability", 100, 55) then
        local newTemplate = abils.abilTemplate
        local newAbility = deepcopy(newTemplate)
        newAbility.priority = #state.config.abilities[state.class] + 1
        table.insert(state.config.abilities[state.class], newAbility)
    end
    ImGui.SameLine()

    state.copyMode, _ = ImGui.Checkbox("Copy Mode", state.copyMode)

    if state.copyMode then
        ImGui.SameLine()
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() - 103)
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() + 30)
        local alpha = 0.5 * (1 + math.sin((frameCounter % flashInterval) / flashInterval * (2 * math.pi)))
        ImGui.TextColored(ImVec4(1,0,0,alpha),"Copy Mode is on!")
    end

    ImGui.SameLine()
    if state.copyMode then
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 119)
    else
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 130)
    end

    ImGui.PopStyleColor()
    ImGui.PushStyleColor(ImGuiCol.Text, state.activeTheme.hovered)
    ImGui.SetWindowFontScale(3)
    ImGui.Text('Conditions')
    ImGui.PopStyleColor()
    ImGui.SetWindowFontScale(1)

    ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 345)

    anim:SetTextureCell(51)
    ImGui.DrawTextureAnimation(anim,45,45)
    ImGui.SameLine()
    anim:SetTextureCell(356)
    ImGui.DrawTextureAnimation(anim,45,45)
    ImGui.SameLine()
    anim:SetTextureCell(42)
    ImGui.DrawTextureAnimation(anim,45,45)
    ImGui.SameLine()
    anim:SetTextureCell(38)
    ImGui.DrawTextureAnimation(anim,45,45)
    ImGui.PushStyleColor(ImGuiCol.Text, state.activeTheme.text)

end

function DrawCheckbox(value, name)
    local isChecked = value
    isChecked, _ = ImGui.Checkbox(name, isChecked)
    return isChecked
end

function DrawNumberInput(value, name, range)
    local inputValue = value
    if range then
        inputValue = math.max(math.min(inputValue, range[2]), range[1])
    end
    ImGui.SetNextItemWidth(100)
    inputValue, _ = ImGui.InputInt(name, inputValue)
    return inputValue
end

function DrawTextInput(value, name,width)
    local inputValue = value
    local inputTextSubmitted = false
    ImGui.SetNextItemWidth(width)
    
    inputValue, inputTextSubmitted = ImGui.InputText(name, inputValue)
    
    -- Handle text input submission
    if inputTextSubmitted then
        -- Perform any action needed upon text input submission
    end
    
    -- Handle text input focus
    local isInputActive = ImGui.IsItemActive()
    
    -- Handle text input deactivation after edit
    if ImGui.IsItemDeactivatedAfterEdit() and isInputActive then
        
    end
    return inputValue
end

local function popStyles()
    ImGui.PopStyleColor(pushedStyleCount)
    ImGui.PopStyleVar(pushedStyleVarCount)
    pushedStyleCount = 0
    pushedStyleVarCount = 0
end

local function displayTableGUI(inputTable, parentKey)
    ImGui.Begin("State", showTableGUI)
    ImGui.Separator()

    local nodeName = parentKey or "state" -- Default node name if no parent key provided
    local nodeOpened = ImGui.TreeNode(nodeName)

    if nodeOpened then
        -- Sort keys alphabetically
        local sortedKeys = {}
        for key, _ in pairs(inputTable) do
            table.insert(sortedKeys, key)
        end
        table.sort(sortedKeys)

        -- Iterate over sorted keys
        for _, key in ipairs(sortedKeys) do
            local value = inputTable[key]
            local fullKey = parentKey and parentKey .. "/" .. key or key -- Combine parent key and current key
            local displayKey = type(key) == "number" and "[" .. key .. "]" or tostring(key) -- Display numeric keys with brackets

            if type(value) == "table" then
                displayTableGUI(value, fullKey)
            else
                ImGui.Text(displayKey .. ": " .. tostring(value))
            end
        end

        ImGui.TreePop()
    end

    ImGui.End()
end




local function DrawConsoleTab()
    if ImGui.BeginTabItem(icons.MD_CODE..'   Console') then
        local totalWidth, _ = ImGui.GetContentRegionAvail()
        local columnWidth = totalWidth / 2

        ImGui.Columns(2)
        ImGui.SetColumnWidth(1,columnWidth)
        ImGui.SetColumnWidth(2,columnWidth)

        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 15) 

        ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(0.8, 0.2, 0.8, 1.0))
        ImGui.SetWindowFontScale(1.7)
        ImGui.Text(mq.TLO.Me.Class.ShortName())
        ImGui.PopStyleColor()
        ImGui.SameLine()
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() - 8)
        ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(0, 1, 0, 1.0)) 
        ImGui.Text('420')
        ImGui.PopStyleColor()
        ImGui.SameLine()
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 15)
        ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(1.0, 0.5, 0.0, 1.0)) 
        ImGui.Text(state.version)
        ImGui.SetWindowFontScale(1)
        ImGui.PopStyleColor()


        ImGui.NewLine()
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 90) 

        if ImGui.Button('Patch Notes',85,25) then
            os.execute('start https://github.com/shortbus-allstar/assist420/blob/main/README.md')
        end

        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 30) 

        classanim:SetTextureCell(702)
        ImGui.DrawTextureAnimation(classanim,200,200)

        ImGui.SameLine()
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() - 105) 
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() + 80)
        classanim:SetTextureCell(lib.getclassicon())
        ImGui.DrawTextureAnimation(classanim,115,115)

        ImGui.NewLine()
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 75) 

        if ImGui.Button('Report a Bug',110,25) then
            os.execute('start https://github.com/shortbus-allstar/assist420/issues/new')
        end

        ImGui.NewLine()

        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 12) 

        if state.paused then
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(0, 1, 0, 1))
            if ImGui.Button(string.format('Resume\n     ' .. icons.FA_PLAY), BUTTON_SIZE, BUTTON_SIZE) then
                state.paused = false
            end
            ImGui.PopStyleColor()
        else
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(1, 0, 0, 1))
            if ImGui.Button(string.format('Pause\n    ' .. icons.FA_PAUSE), BUTTON_SIZE, BUTTON_SIZE) then
                state.paused = true
                mq.cmd('/stopcast')
            end
            ImGui.PopStyleColor()
        end
        ImGui.SameLine()

        ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(0, 1, 1, 1))

        if ImGui.Button(string.format('Update\n     ' .. icons.FA_DOWNLOAD), BUTTON_SIZE * 2, BUTTON_SIZE) then

            local githubver = string.sub(state.githubver, 2)              local mqNextDir = mq.luaDir
            local zipFilePath = mqNextDir .. "\\assist420.zip"
            
            -- Download the zip file
            local downloadCommand = 'powershell.exe -ExecutionPolicy Bypass -Command "& {Invoke-WebRequest -Uri \'https://github.com/shortbus-allstar/assist420/archive/' .. state.githubver .. '.zip\' -OutFile \'' .. zipFilePath .. '\'}"'
            local downloadSuccess = os.execute(downloadCommand)
            
            -- Check if download was successful
            if downloadSuccess then
                print("Download successful.")
            else
                print("Download failed.")
                return  -- Exit script if download failed
            end
            
            -- Extract contents of the zip file
            local extractCommand = 'powershell.exe -Command "Expand-Archive -Path \'' .. zipFilePath .. '\' -DestinationPath \'' .. mqNextDir .. '\' -Force"'
            local extractSuccess = os.execute(extractCommand)
            
            
            -- Define the path to the extracted directory
            local extractedDir = mqNextDir .. "\\assist420-" .. githubver
            print(extractedDir)
            local targetDir = mq.luaDir .. "\\assist420"
            
            -- Print the contents of the extracted directory before copying
            print("Contents of extracted directory before copying:")
            os.execute('dir "' .. extractedDir .. '"')
            
            -- Copy contents of the extracted directory to the target directory
            local copyCommand = 'xcopy /s /e /q /y "' .. extractedDir .. '" "' .. targetDir .. '"'
            local copySuccess = os.execute(copyCommand)
            
            -- Print the contents of the target directory after copying
            os.execute('dir "' .. targetDir .. '"')
            
            -- Clean up: Delete the extracted directory and zip file
            local cleanupCommand1 = 'rmdir /s /q "' .. extractedDir .. '"'
            local cleanupCommand2 = 'del /q "' .. zipFilePath .. '"'
            os.execute(cleanupCommand1)
            os.execute(cleanupCommand2)
            
        end
            
        ImGui.PopStyleColor()

        if ImGui.IsItemHovered() and state.version ~= state.githubver and ImGui.IsItemHovered() then
            ImGui.SetTooltip("This update includes a config change. Saving a preset as a backup is recommended")
        end

        

        ImGui.SameLine()

        if ImGui.Button("State\n   " .. icons.FA_FILE_CODE_O , BUTTON_SIZE, BUTTON_SIZE) then
            showTableGUI = not showTableGUI
        end

        if state.version ~= tostring(state.githubver) then
            local alpha = 0.5 * (1 + math.sin((frameCounter % flashInterval) / flashInterval * (2 * math.pi)))  -- Use a sine function for smooth fading

            ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 75) 
            ImGui.TextColored(ImVec4(1, 0, 0, alpha), "Update Available!")
        else
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 70)
            ImGui.TextColored(ImVec4(0, 1, 0, 1), "Using Latest Version")
        end
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 40) 

        ImGui.Text('GitHub Version:') 
        ImGui.SameLine()
        ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(1.0, 0.5, 0.0, 1.0))
        ImGui.Text(tostring(state.githubver)) 
        ImGui.PopStyleColor()

        ImGui.SetCursorPosY(ImGui.GetCursorPosY() +10) 
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() +10) 

        if state.config.returnToCamp then
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(0, 1, 0, 1))
            if ImGui.Button(string.format('  Nav:\n Camp'), BUTTON_SIZE, BUTTON_SIZE) then
                navigation.clearCamp()
                state.config.returnToCamp = false
                state.config.chaseAssist = true
            end
            ImGui.PopStyleColor()
        elseif state.config.chaseAssist then
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(1, 1, 0, 1))
            if ImGui.Button(string.format('  Nav:\n Chase'), BUTTON_SIZE, BUTTON_SIZE) then
                navigation.clearCamp()
                state.config.chaseAssist = false
                state.config.returnToCamp = false
            end
            ImGui.PopStyleColor()
        else
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(1, 0, 0, 1))
            if ImGui.Button(string.format('  Nav:\n None'), BUTTON_SIZE, BUTTON_SIZE) then
                navigation.setCamp()
                state.config.chaseAssist = false
                state.config.returnToCamp = true
            end
            ImGui.PopStyleColor()
        end

        ImGui.SameLine()

        if state.config.movement == 'auto' then
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(0, 1, 0, 1))
            if ImGui.Button(string.format(' Mode:\n Auto'), BUTTON_SIZE, BUTTON_SIZE) then
                state.config.movement = 'manual'
            end
            ImGui.PopStyleColor()
        elseif state.config.movement == 'manual' then
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(1,0,0,1))
            if ImGui.Button(string.format(' Mode:\nManual'), BUTTON_SIZE, BUTTON_SIZE) then
                state.config.movement = 'auto'
            end
            ImGui.PopStyleColor()
        end

        ImGui.SameLine()

        if state.config.burn == 'auto' then
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(0, 1, 0, 1))
            if ImGui.Button(string.format(' Burns:\n Auto'), BUTTON_SIZE, BUTTON_SIZE) then
                state.config.burn = 'manual'
            end
            ImGui.PopStyleColor()
        elseif state.config.burn == 'manual' then
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(1,0,0,1))
            if ImGui.Button(string.format(' Burns:\nManual'), BUTTON_SIZE, BUTTON_SIZE) then
                state.config.burn = 'auto'
            end
            ImGui.PopStyleColor()
        end

        ImGui.SameLine()

        if not state.config.feignOverride then
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(0, 1, 0, 1))
            if ImGui.Button(string.format(' Feigns:\n Auto'), BUTTON_SIZE, BUTTON_SIZE) then
                state.config.feignOverride = true
            end
            ImGui.PopStyleColor()
        elseif state.config.feignOverride then
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(1,0,0,1))
            if ImGui.Button(string.format(' Feigns:\nManual'), BUTTON_SIZE, BUTTON_SIZE) then
                state.config.feignOverride = false
            end
            ImGui.PopStyleColor()
        end

        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 8) 

        ImGui.NextColumn()


        local function hpcolor()
            if mq.TLO.Me.PctHPs() and tonumber(mq.TLO.Me.PctHPs()) > 75 then return ImVec4(0,1,0,1) end
            if mq.TLO.Me.PctHPs() and tonumber(mq.TLO.Me.PctHPs()) <= 75 and mq.TLO.Me.PctHPs() > 35 then return ImVec4(1,1,0,1) end
            if mq.TLO.Me.PctHPs() and tonumber(mq.TLO.Me.PctHPs()) <= 35 then return ImVec4(1,0,0,1) end
        end

        local function manacolor()
            if mq.TLO.Me.PctMana() > 75 then return ImVec4(0,1,0,1) end
            if mq.TLO.Me.PctMana() <= 75 and mq.TLO.Me.PctMana() > 35 then return ImVec4(1,1,0,1) end
            if mq.TLO.Me.PctMana() <= 35 then return ImVec4(1,0,0,1) end
        end

        ImGui.Text(mq.TLO.Me.Name())
        ImGui.TextColored(ImVec4(1, 0.8, 0, 1),'Level')
        ImGui.SameLine()
        ImGui.Text(tostring(mq.TLO.Me.Level()))
        ImGui.SameLine()
        ImGui.TextColored(ImVec4(1, 0.8, 0, 1),mq.TLO.Me.Class.Name())

        ImGui.SameLine()
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 10) 
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 15) 
        anim:SetTextureCell(867)
        ImGui.DrawTextureAnimation(anim,BUTTON_SIZE,BUTTON_SIZE)

        ImGui.NewLine()
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 45) 

        ImGui.TextColored(ImVec4(1, 0.8, 0, 1),'Hitpoints %:')
        ImGui.SameLine()
        ImGui.TextColored(hpcolor(),tostring(mq.TLO.Me.PctHPs()))

        ImGui.TextColored(ImVec4(1, 0.8, 0, 1),'Mana %:')
        ImGui.SameLine()
        ImGui.TextColored(manacolor(),tostring(mq.TLO.Me.PctMana()))

        ImGui.TextColored(ImVec4(1, 0.8, 0, 1),'Current Zone:')
        ImGui.SameLine()
        ImGui.Text(tostring(mq.TLO.Zone.Name()))

        ImGui.TextColored(ImVec4(1, 0.8, 0, 1),'Group Main Tank:')
        ImGui.SameLine()
        ImGui.Text(tostring(mq.TLO.Group.MainTank.Name()))

        ImGui.TextColored(ImVec4(1, 0.8, 0, 1),'Players in Zone:')
        ImGui.SameLine()
        ImGui.Text(tostring(mq.TLO.SpawnCount('pc')()))

        ImGui.TextColored(ImVec4(1, 0.8, 0, 1),'Currently Casting:')
        ImGui.SameLine()
        ImGui.Text(tostring(mq.TLO.Me.Casting.Name()))

        ImGui.TextColored(ImVec4(1, 0.8, 0, 1),'Current Target:')
        ImGui.SameLine()
        ImGui.Text(tostring(mq.TLO.Target.CleanName()))

        ImGui.TextColored(ImVec4(1, 0.8, 0, 1),string.format("Memory Usage:"))
        ImGui.SameLine()
        ImGui.Text("%.2f MB", collectgarbage("count") / 1024)

        ImGui.TextColored(ImVec4(1, 0.8, 0, 1),'# in Buff Queue:')
        ImGui.SameLine()
        ImGui.Text(tostring(#state.buffqueue))
        ImGui.SameLine()
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 2) 
        ImGui.PushStyleColor(ImGuiCol.Text,ImVec4(1,0,0,1))
        if ImGui.Button('Clear',ImVec2(40,20)) then
            state.buffqueue = {}
        end
        ImGui.PopStyleColor()

        ImGui.TextColored(ImVec4(1, 0.8, 0, 1),'# in Cure Queue:')
        ImGui.SameLine()
        ImGui.Text(tostring(#state.curequeue))
        ImGui.SameLine()
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 2) 
        ImGui.PushStyleColor(ImGuiCol.Text,ImVec4(1,0,0,1))
        if ImGui.Button('Clear1',ImVec2(40,20)) then
            state.curequeue = {}
        end
        ImGui.PopStyleColor()

        ImGui.TextColored(ImVec4(1, 0.8, 0, 1),'Role:')
        ImGui.SameLine()
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 2) 

        local roles = { "assist", "puller", "tank", "pullertank"}

        if ImGui.BeginCombo("##role:", state.config.role, ImGuiComboFlags.None) then
            for i, option in ipairs(roles) do
                local isSelected = (i == selectedOptionIndex)
                ImGui.PushStyleColor(ImGuiCol.Text, isSelected and ImVec4(0, 1, 1, 1) or ImGui.GetStyleColorVec4(ImGuiCol.Text))
                if ImGui.Selectable(option, isSelected) then
                    selectedOptionIndex = i
                    state.config.role = option -- Update state.config.loglevel based on the selected option
                end
            
                ImGui.PopStyleColor()
            
                    -- Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
                if isSelected then
                    ImGui.SetItemDefaultFocus()
                end
            end
            
            ImGui.EndCombo()
        end

        ImGui.TextColored(ImVec4(1, 0.8, 0, 1),'Log Level:')
        ImGui.SameLine()
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 2) 

        local options = { "trace", "debug", "info", "warn", "error", "fatal", "help" }

        if ImGui.BeginCombo("##loglevel:", state.config.loglevel, ImGuiComboFlags.None) then
            for i, option in ipairs(options) do
                local isSelected = (i == selectedOptionIndex2)
                ImGui.PushStyleColor(ImGuiCol.Text, isSelected and ImVec4(0, 1, 1, 1) or ImGui.GetStyleColorVec4(ImGuiCol.Text))
                if ImGui.Selectable(option, isSelected) then
                    selectedOptionIndex2 = i
                    state.config.loglevel = option -- Update state.config.loglevel based on the selected option
                end
            
                ImGui.PopStyleColor()
            
                    -- Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
                if isSelected then
                    ImGui.SetItemDefaultFocus()
                end
            end
            
            ImGui.EndCombo()
        end

        ImGui.TextColored(ImVec4(1, 0.8, 0, 1),'Theme:')
        ImGui.SameLine()
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 2) 

        if ImGui.BeginCombo("##theme:", state.activeTheme.name, ImGuiComboFlags.None) then
            for i, theme in ipairs(themes) do
                local isSelected = (i == selectedOptionIndextheme)
            
                ImGui.PushStyleColor(ImGuiCol.Text, isSelected and ImVec4(0, 1, 1, 1) or ImGui.GetStyleColorVec4(ImGuiCol.Text))
            
                if ImGui.Selectable(theme.name, isSelected) then
                    selectedOptionIndextheme = i
                    state.activeTheme = theme -- Update state.config.loglevel based on the selected option
                end
            
                ImGui.PopStyleColor()
            
                    -- Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
                if isSelected then
                    ImGui.SetItemDefaultFocus()
                end
            end
            
            ImGui.EndCombo()
        end

        if ImGui.Button("Test", BUTTON_SIZE, BUTTON_SIZE) then
            local tank = require('routines.tank')
            local function centerPoint() print('centerpoint') return {mq.TLO.Me.X(), mq.TLO.Me.Y(), mq.TLO.Me.Z()} end
            local function points() return {
                {mq.TLO.Group.Member(1).X(), mq.TLO.Group.Member(1).Y(), mq.TLO.Group.Member(1).Z()},
                {mq.TLO.Group.Member(2).X(), mq.TLO.Group.Member(1).Y(), mq.TLO.Group.Member(2).Z()},
                {mq.TLO.Group.Member(3).X(), mq.TLO.Group.Member(1).Y(), mq.TLO.Group.Member(3).Z()},
                {mq.TLO.Group.Member(4).X(), mq.TLO.Group.Member(1).Y(), mq.TLO.Group.Member(4).Z()}
            }
            end
            local optimal = tank.findOptimalFacingPoint(centerPoint(), points())
            print(optimal[1])
            print(optimal[2])
            print(optimal[3])
            if type(optimal) ~= "string" then mq.cmdf('/face fast loc %s,%s,%s',optimal[2],optimal[1],optimal[3]) else print('no optimal') end
        end

        ImGui.Columns(1)
        DrawTabEnd()
        ImGui.EndTabItem()
    end
end

local function DrawRoutineTable()
    local routines = state.config.routines

    -- Sort routines based on their values
    local sortedRoutines = {}
    for name, value in pairs(routines) do
        table.insert(sortedRoutines, { name = name, value = value })
    end
    table.sort(sortedRoutines, function(a, b) return a.value < b.value end)

    if ImGui.BeginTable("RoutineTable", 1, table_flags, ImGui.GetContentRegionAvail(), 154) then
        ImGui.TableSetupColumn("Routine Order:", ImGuiTableColumnFlags.WidthFixed, ImGui.GetContentRegionAvail())
        ImGui.TableHeadersRow()

        local index = 1
        for _, routine in ipairs(sortedRoutines) do
            local routineName = routine.name
            local routineValue = routine.value

            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)

            -- Draw button with routine name
            if ImGui.Button(routineName, ImVec2(ImGui.GetContentRegionAvail(), 0)) then
            end


            -- Drag and drop source
            if ImGui.BeginDragDropSource() then
                ImGui.SetDragDropPayload("ROUTINE_INDEX", index)
                ImGui.Text("Routine: %s", routineName)
                ImGui.EndDragDropSource()
            end

            -- Drag and drop target
            if ImGui.BeginDragDropTarget() then
                local payload = ImGui.AcceptDragDropPayload("ROUTINE_INDEX")
                if payload then
                    local targetIndex = payload.Data
                    if targetIndex ~= index then
                        -- Swap the routines
                        state.config.routines[routineName], state.config.routines[sortedRoutines[targetIndex].name] = state.config.routines[sortedRoutines[targetIndex].name], state.config.routines[routineName]
                    end
                end
                ImGui.EndDragDropTarget()
            end


            index = index + 1
        end

        ImGui.EndTable()
    end
end

local function DrawCondsTab()
    if ImGui.BeginTabItem(icons.MD_CALL_TO_ACTION .. "   Abilities") then
        DrawList()
        DrawEditorWindow()
        DrawTabEnd()
        ImGui.EndTabItem()
    end
end

local function DrawGenTab()
    if ImGui.BeginTabItem(icons.MD_SETTINGS .. "   General") then
        local totalWidth, _ = ImGui.GetContentRegionAvail()
        local columnWidth = totalWidth / 2
    
        ImGui.Columns(2)

        state.config.doMedding = DrawCheckbox(state.config.doMedding, "Medding Enabled")
        state.config.combatMed = DrawCheckbox(state.config.combatMed, "Med in Combat")
        state.config.useMQ2Melee = DrawCheckbox(state.config.useMQ2Melee, "Use MQ2Melee")
        state.config.memSpellSetAtStart = DrawCheckbox(state.config.memSpellSetAtStart, "Mem Spell Set At Start")
        state.config.spellSetName = DrawTextInput(state.config.spellSetName, "Spell Set Name", 100)
        ImGui.NewLine()
        ImGui.Text('Assist Type:')
        local asstypes = { "Group MA", "Raid MA", "Custom Name", "Custom ID"}

        if ImGui.BeginCombo("##assisttype", state.config.assistType, ImGuiComboFlags.None) then
            for i, option in ipairs(asstypes) do
                local isSelected = (i == selectedOptionIndex3)
                ImGui.PushStyleColor(ImGuiCol.Text, isSelected and ImVec4(0, 1, 1, 1) or ImGui.GetStyleColorVec4(ImGuiCol.Text))
                if ImGui.Selectable(option, isSelected) then
                    selectedOptionIndex3 = i
                    state.config.assistType = option -- Update state.config.loglevel based on the selected option
                end
            
                ImGui.PopStyleColor()
            
                    -- Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
                if isSelected then
                    ImGui.SetItemDefaultFocus()
                end
            end
            
            ImGui.EndCombo()
        end
        if state.config.assistType == "Custom Name" then
            ImGui.Text("Custom Name: " .. state.config.assistTypeCustName)
            if ImGui.Button("Change Name",55,20) then
                ImGui.OpenPopup("ChangeAssistName")
            end
        end
        if state.config.assistType == "Custom ID" then
            ImGui.Text("Custom ID: " .. state.config.assistTypeCustID)
            if ImGui.Button("Change ID",55,20) then
                ImGui.OpenPopup("ChangeAssistID")
            end
        end

        if ImGui.BeginPopup("ChangeAssistName") then
            ImGui.Text("Enter new main assist name:")
            -- Make sure newIgnoreValue is updated with input text
            newassist = ImGui.InputText("##NewIgnoreValue", newassist)
            
            if ImGui.Button("OK", ImVec2(120, 0)) then
                -- Add the new ignore value to the table if it's not empty
                if newassist ~= "" then
                    state.config.assistTypeCustName = newassist
                end
                
                -- Reset the input field
                newassist = ""
                ImGui.CloseCurrentPopup()
            end
            
            ImGui.SameLine()
            
            if ImGui.Button("Cancel", ImVec2(120, 0)) then
                -- Close the pop-up window without adding the value
                newassist = ""
                ImGui.CloseCurrentPopup()
            end
            
            ImGui.EndPopup()
        end

        if ImGui.BeginPopup("ChangeAssistID") then
            ImGui.Text("Enter new main assist ID:")
            -- Make sure newIgnoreValue is updated with input text
            newassist = ImGui.InputText("##NewIgnoreValue", newassist)
            
            if ImGui.Button("OK", ImVec2(120, 0)) then
                -- Add the new ignore value to the table if it's not empty
                if newassist ~= "" then
                    state.config.assistTypeCustID = newassist
                end
                
                -- Reset the input field
                newassist = ""
                ImGui.CloseCurrentPopup()
            end
            
            ImGui.SameLine()
            
            if ImGui.Button("Cancel", ImVec2(120, 0)) then
                -- Close the pop-up window without adding the value
                newassist = ""
                ImGui.CloseCurrentPopup()
            end
            
            ImGui.EndPopup()
        end

        ImGui.Text('Chase Type:')
        local chasetypes = { "Group MA", "Group Tank", "Custom Name", "Custom ID"}

        if ImGui.BeginCombo("##chasetype", state.config.chaseType, ImGuiComboFlags.None) then
            for i, option in ipairs(chasetypes) do
                local isSelected = (i == selectedOptionIndex4)
                ImGui.PushStyleColor(ImGuiCol.Text, isSelected and ImVec4(0, 1, 1, 1) or ImGui.GetStyleColorVec4(ImGuiCol.Text))
                if ImGui.Selectable(option, isSelected) then
                    selectedOptionIndex4 = i
                    state.config.chaseType = option -- Update state.config.loglevel based on the selected option
                end
            
                ImGui.PopStyleColor()
            
                    -- Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
                if isSelected then
                    ImGui.SetItemDefaultFocus()
                end
            end
            
            ImGui.EndCombo()
        end
        if state.config.chaseType == "Custom Name" then
            ImGui.Text("Custom Name: " .. state.config.chaseTypeCustName)
            if ImGui.Button("Change Name",55,20) then
                ImGui.OpenPopup("ChangeChaseName")
            end
        end
        if state.config.chaseType == "Custom ID" then
            ImGui.Text("Custom ID: " .. state.config.chaseTypeCustID)
            if ImGui.Button("Change ID",55,20) then
                ImGui.OpenPopup("ChangeChaseID")
            end
        end

        if ImGui.BeginPopup("ChangeChaseName") then
            ImGui.Text("Enter new chase target name:")
            -- Make sure newIgnoreValue is updated with input text
            newassist = ImGui.InputText("##NewIgnoreValue", newassist)
            
            if ImGui.Button("OK", ImVec2(120, 0)) then
                -- Add the new ignore value to the table if it's not empty
                if newassist ~= "" then
                    state.config.chaseTypeCustName = newassist
                end
                
                -- Reset the input field
                newassist = ""
                ImGui.CloseCurrentPopup()
            end
            
            ImGui.SameLine()
            
            if ImGui.Button("Cancel", ImVec2(120, 0)) then
                -- Close the pop-up window without adding the value
                newassist = ""
                ImGui.CloseCurrentPopup()
            end
            
            ImGui.EndPopup()
        end

        if ImGui.BeginPopup("ChangeChaseID") then
            ImGui.Text("Enter new chase target ID:")
            -- Make sure newIgnoreValue is updated with input text
            newassist = ImGui.InputText("##NewIgnoreValue", newassist)
            
            if ImGui.Button("OK", ImVec2(120, 0)) then
                -- Add the new ignore value to the table if it's not empty
                if newassist ~= "" then
                    state.config.chaseTypeCustID = newassist
                end
                
                -- Reset the input field
                newassist = ""
                ImGui.CloseCurrentPopup()
            end
            
            ImGui.SameLine()
            
            if ImGui.Button("Cancel", ImVec2(120, 0)) then
                -- Close the pop-up window without adding the value
                newassist = ""
                ImGui.CloseCurrentPopup()
            end
            
            ImGui.EndPopup()
        end

        ImGui.NewLine()
        ImGui.Text('Stand Condition (FD):')
        ImGui.SameLine()
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() - 4)
        if ImGui.Button(icons.FA_EXPAND .. "##standcond", ImVec2(20, 20)) then
            ImGui.OpenPopup("standcond")
        end
        
        
        ImGui.SetNextWindowSize(1000,600)
        ImGui.PushStyleColor(ImGuiCol.PopupBg, ImVec4(0, 0, 0, 1.0))
        if ImGui.BeginPopup("standcond", ImGuiWindowFlags.AlwaysAutoResize and ImGuiWindowFlags.AlwaysHorizontalScrollbar) then
            if ImGui.BeginChild("FullTextInput", 1000, 600) then
                    -- Use InputTextMultiline inside the child window
                local buffer = state.config.standcond or ""
                state.config.standcond, _ = ImGui.InputTextMultiline("##InputText", buffer, 1000, 600)
            
                ImGui.EndChild()
            end
            ImGui.EndPopup()
        end
        state.config.standcond = DrawTextInput(state.config.standcond, "##Stand Condition", ImGui.GetContentRegionAvail() - 10)

        ImGui.PopStyleColor()
        ImGui.PushStyleColor(ImGuiCol.Text, state.activeTheme.hovered)
        ImGui.SetWindowFontScale(3)
        ImGui.Text('General')
        ImGui.PopStyleColor()
        ImGui.SetWindowFontScale(1)
        DrawRoutineTable()
        ImGui.NextColumn()
        state.config.attackAt = DrawNumberInput(state.config.attackAt, "Attack At", {0, 100})
        state.config.attackRange = DrawNumberInput(state.config.attackRange, "Attack Range")
        state.config.campRadius = DrawNumberInput(state.config.campRadius, "Camp Radius")
        state.config.chaseDistance = DrawNumberInput(state.config.chaseDistance, "Chase Distance")
        state.config.chaseMaxDistance = DrawNumberInput(state.config.chaseMaxDistance, "Chase Max Distance")
        state.config.medEndAt = DrawNumberInput(state.config.medEndAt, "Med End At", {0, 100})
        state.config.medManaAt = DrawNumberInput(state.config.medManaAt, "Med Mana At", {0, 100})
        state.config.medStop = DrawNumberInput(state.config.medStop, "Med Stop", {0, 100})
        state.config.miscGem = DrawNumberInput(state.config.miscGem, "Misc Gem", {1, 13})
        state.config.petAttackAt = DrawNumberInput(state.config.petAttackAt, "Pet Attack At", {0, 100})
        state.config.petRange = DrawNumberInput(state.config.petRange, "Pet Range")

        
        ImGui.NewLine()
        anim:SetTextureCell(808)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 20)
        ImGui.DrawTextureAnimation(anim,220,220)
        ImGui.Columns(1)
        DrawTabEnd()
        ImGui.EndTabItem()
    end
end

local configTabOpen = false
local abilTabOpen = false

local newCureAvoid = ""  -- Temporary variable for input
local showAddPopup = false  -- Track whether the popup is active

function DrawCureAvoidsTable()
    -- Begin table
    if ImGui.BeginTable("Cure Avoids Table", 2, ImGuiTableFlags.Borders) then
        -- Table headers
        ImGui.TableSetupColumn("Cure Avoids")
        ImGui.TableSetupColumn("Delete")
        ImGui.TableHeadersRow()

        -- Populate rows
        for index, cureAvoid in ipairs(state.config.cureAvoids) do
            ImGui.TableNextRow()
            ImGui.TableNextColumn()
            ImGui.Text(cureAvoid)  -- Display the Cure Avoid entry

            ImGui.TableNextColumn()
            if ImGui.Button("Delete##" .. index) then
                table.remove(state.config.cureAvoids, index)  -- Remove entry on delete button click
            end
        end

        ImGui.EndTable()
    end

    -- Button to show the add popup
    if ImGui.Button("Add Cure Avoid") then
        showAddPopup = true  -- Activate popup
    end

    -- Draw popup for adding new cure avoids
    if showAddPopup then
        ImGui.OpenPopup("Add Cure Avoid")
        if ImGui.BeginPopupModal("Add Cure Avoid", nil, ImGuiWindowFlags.AlwaysAutoResize) then
            ImGui.Text("Enter a new Cure Avoid:")
            newCureAvoid = ImGui.InputText("##newCureAvoid", newCureAvoid)

            if ImGui.Button("Add") then
                if newCureAvoid ~= "" then
                    print(newCureAvoid)
                    -- Safeguard: Directly insert the string (no processing needed as apostrophes are valid in Lua)
                    table.insert(state.config.cureAvoids, newCureAvoid)
                end
                newCureAvoid = ""  -- Clear the input
                showAddPopup = false  -- Close popup
                ImGui.CloseCurrentPopup()
            end

            ImGui.SameLine()

            if ImGui.Button("Cancel") then
                newCureAvoid = ""  -- Clear the input
                showAddPopup = false  -- Close popup
                ImGui.CloseCurrentPopup()
            end

            ImGui.EndPopup()
        end
    end
end

local newOtherTank = ""  -- Temporary variable for input for otherTankList
local newHotTarget = "" 
local newOverrideTarget = ""
local newBuffTarget = ""
local newBuffOverride = ""


local showAddOverridePopup = false 
local showAddOtherTankPopup = false  -- Track whether the popup for otherTankList is active
local showAddHotTargetPopup = false
local showAddBuffTargetPopup = false
local showAddBuffOverridePopup = false  -- Track whether the popup for hotTargets is active

function DrawOtherTankListTable()
    -- Begin table
    if ImGui.BeginTable("Other Tank List Table", 2, ImGuiTableFlags.Borders) then
        -- Table headers
        ImGui.TableSetupColumn("Other Tank List")
        ImGui.TableSetupColumn("Delete")
        ImGui.TableHeadersRow()

        -- Populate rows
        for index, otherTank in ipairs(state.config.otherTankList) do
            ImGui.TableNextRow()
            ImGui.TableNextColumn()
            ImGui.Text(otherTank)  -- Display the entry

            ImGui.TableNextColumn()
            if ImGui.Button("Delete##OtherTank" .. index) then
                table.remove(state.config.otherTankList, index)  -- Remove entry
            end
        end

        ImGui.EndTable()
    end

    -- Button to show the add popup
    if ImGui.Button("Add Other Tank") then
        showAddOtherTankPopup = true
    end

    -- Draw popup for adding new tanks
    if showAddOtherTankPopup then
        ImGui.OpenPopup("Add Other Tank")
        if ImGui.BeginPopupModal("Add Other Tank", nil, ImGuiWindowFlags.AlwaysAutoResize) then
            ImGui.Text("Enter a new Other Tank:")
            newOtherTank = ImGui.InputText("##newOtherTank", newOtherTank)

            if ImGui.Button("Add") then
                if newOtherTank ~= "" then
                    table.insert(state.config.otherTankList, newOtherTank)
                end
                newOtherTank = ""  -- Clear the input
                showAddOtherTankPopup = false  -- Close popup
                ImGui.CloseCurrentPopup()
            end

            ImGui.SameLine()

            if ImGui.Button("Cancel") then
                newOtherTank = ""  -- Clear the input
                showAddOtherTankPopup = false  -- Close popup
                ImGui.CloseCurrentPopup()
            end

            ImGui.EndPopup()
        end
    end
end




function DrawDebuffOverwriteWindow(abilindex)
    if showDebuffOverwriteWindow then
        showDebuffOverwriteWindow = ImGui.Begin("Debuff Overwrite Table", showDebuffOverwriteWindow, ImGuiWindowFlags.None)
        if showDebuffOverwriteWindow then
            ImGui.SetWindowSize(600, 350, ImGuiCond.FirstUseEver)
            DrawDebuffOverwriteTable(abilindex)
        end
        ImGui.End()
    end
end

function DrawBuffTargetWindow(abilindex)
    if showBuffTargetWindow then
        showBuffTargetWindow = ImGui.Begin("Buff Target Table", showBuffTargetWindow, ImGuiWindowFlags.None)
        if showBuffTargetWindow then
            ImGui.SetWindowSize(600, 350, ImGuiCond.FirstUseEver)
            DrawBuffTargetTable(abilindex)
        end
        ImGui.End()
    end
end

function DrawBuffOverrideWindow(abilindex)
    if showBuffOverrideWindow then
        showBuffOverrideWindow = ImGui.Begin("Buff Override Table", showBuffOverrideWindow, ImGuiWindowFlags.None)
        if showBuffOverrideWindow then
            ImGui.SetWindowSize(600, 350, ImGuiCond.FirstUseEver)
            DrawBuffOverrideTable(abilindex)
        end
        ImGui.End()
    end
end

function DrawBuffTargetTable(abilindex)
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
        showAddBuffTargetPopup = true
    end

    -- Draw popup for adding new Buff targets
    if showAddBuffTargetPopup then
        ImGui.OpenPopup("Add Target")
        if ImGui.BeginPopupModal("Add Target", nil, ImGuiWindowFlags.AlwaysAutoResize) then
            ImGui.Text("Enter a new Target:")
            newBuffTarget = ImGui.InputText("##newBuffTarget", newBuffTarget)

            if ImGui.Button("Add") then
                if newBuffTarget ~= "" then
                    table.insert(state.config.buffabils[state.class][abilindex].othertargets, newBuffTarget)
                end
                newBuffTarget = ""  -- Clear the input
                showAddBuffTargetPopup = false  -- Close popup
                ImGui.CloseCurrentPopup()
            end

            ImGui.SameLine()

            if ImGui.Button("Cancel") then
                newBuffTarget = ""  -- Clear the input
                showAddBuffTargetPopup = false  -- Close popup
                ImGui.CloseCurrentPopup()
            end

            ImGui.EndPopup()
        end
    end
end

function DrawBuffOverrideTable(abilindex)
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
        showAddBuffOverridePopup = true
    end

    -- Draw popup for adding new Buff overrides
    if showAddBuffOverridePopup then
        ImGui.OpenPopup("Add Override")
        if ImGui.BeginPopupModal("Add Override", nil, ImGuiWindowFlags.AlwaysAutoResize) then
            ImGui.Text("Enter a new Override:")
            newBuffOverride = ImGui.InputText("##newBuffOverride", newBuffOverride)

            if ImGui.Button("Add") then
                if newBuffOverride ~= "" then
                    table.insert(state.config.buffabils[state.class][abilindex].overrides, newBuffOverride)
                end
                newBuffOverride = ""  -- Clear the input
                showAddBuffOverridePopup = false  -- Close popup
                ImGui.CloseCurrentPopup()
            end

            ImGui.SameLine()

            if ImGui.Button("Cancel") then
                newBuffTarget = ""  -- Clear the input
                showAddBuffTargetPopup = false  -- Close popup
                ImGui.CloseCurrentPopup()
            end

            ImGui.EndPopup()
        end
    end
end

function DrawDebuffOverwriteTable(abilindex)
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
        showAddOverridePopup = true
    end

    -- Draw popup for adding new Override targets
    if showAddOverridePopup then
        ImGui.OpenPopup("Add Override")
        if ImGui.BeginPopupModal("Add Override", nil, ImGuiWindowFlags.AlwaysAutoResize) then
            ImGui.Text("Enter a new Override:")
            newOverrideTarget = ImGui.InputText("##newOverrideTarget", newOverrideTarget)

            if ImGui.Button("Add") then
                if newOverrideTarget ~= "" then
                    table.insert(state.config.debuffabils[state.class][abilindex].overrides, newOverrideTarget)
                end
                newOverrideTarget = ""  -- Clear the input
                showAddOverridePopup = false  -- Close popup
                ImGui.CloseCurrentPopup()
            end

            ImGui.SameLine()

            if ImGui.Button("Cancel") then
                newOverrideTarget = ""  -- Clear the input
                showAddOverridePopup = false  -- Close popup
                ImGui.CloseCurrentPopup()
            end

            ImGui.EndPopup()
        end
    end
end

function DrawHotTargetsTable()
    -- Begin table
    if ImGui.BeginTable("HoT Targets Table", 2, ImGuiTableFlags.Borders) then
        -- Table headers
        ImGui.TableSetupColumn("HoT Targets")
        ImGui.TableSetupColumn("Delete")
        ImGui.TableHeadersRow()

        -- Populate rows
        for index, hotTarget in ipairs(state.config.hotTargets) do
            ImGui.TableNextRow()
            ImGui.TableNextColumn()
            ImGui.Text(hotTarget)  -- Display the entry

            ImGui.TableNextColumn()
            if ImGui.Button("Delete##HotTarget" .. index) then
                table.remove(state.config.hotTargets, index)  -- Remove entry
            end
        end

        ImGui.EndTable()
    end

    -- Button to show the add popup
    if ImGui.Button("Add HoT Target") then
        showAddHotTargetPopup = true
    end

    -- Draw popup for adding new HoT targets
    if showAddHotTargetPopup then
        ImGui.OpenPopup("Add HoT Target")
        if ImGui.BeginPopupModal("Add HoT Target", nil, ImGuiWindowFlags.AlwaysAutoResize) then
            ImGui.Text("Enter a new HoT Target:")
            newHotTarget = ImGui.InputText("##newHotTarget", newHotTarget)

            if ImGui.Button("Add") then
                if newHotTarget ~= "" then
                    table.insert(state.config.hotTargets, newHotTarget)
                end
                newHotTarget = ""  -- Clear the input
                showAddHotTargetPopup = false  -- Close popup
                ImGui.CloseCurrentPopup()
            end

            ImGui.SameLine()

            if ImGui.Button("Cancel") then
                newHotTarget = ""  -- Clear the input
                showAddHotTargetPopup = false  -- Close popup
                ImGui.CloseCurrentPopup()
            end

            ImGui.EndPopup()
        end
    end
end

local function DrawHealTab()
    if ImGui.BeginTabItem(icons.FA_HEART .. "   Heals") then
        local totalWidth, _ = ImGui.GetContentRegionAvail()
        local columnWidth = totalWidth / 2

        
        if ImGui.CollapsingHeader(icons.FA_COG .. "   Config Options") then
            configTabOpen = true
        else
            configTabOpen = false
        end

        if configTabOpen then
            ImGui.Columns(2)
            state.config.doCuring = DrawCheckbox(state.config.doCuring, "Do Curing")
            state.config.doHealing = DrawCheckbox(state.config.doHealing, "Do Healing")
            state.config.doRezzing = DrawCheckbox(state.config.doRezzing, "Do Rezzing")
            state.config.interruptToEmergHeal = DrawCheckbox(state.config.interruptToEmergHeal, "Interrupt to Emergency Heal")
            state.config.petHeals = DrawCheckbox(state.config.petHeals, "Pet Heals")
            state.config.rezFellowship = DrawCheckbox(state.config.rezFellowship, "Rez Fellowship")
            state.config.rezGuild = DrawCheckbox(state.config.rezGuild, "Rez Guild")

            DrawCureAvoidsTable()

            ImGui.NextColumn()

            state.config.cancelHealsAt = DrawNumberInput(state.config.cancelHealsAt, "Cancel Heals At", {0, 100})
            state.config.groupEmergencyMemberCount = DrawNumberInput(state.config.groupEmergencyMemberCount, "Group Emergency Member Count", {1, 6})
            state.config.groupHealMemberCount = DrawNumberInput(state.config.groupHealMemberCount, "Group Heal Member Count", {1, 6})
            state.config.groupHoTMemberCount = DrawNumberInput(state.config.groupHoTMemberCount, "Group HoT Member Count", {1, 6})
            state.config.groupEmergencyPct = DrawNumberInput(state.config.groupEmergencyPct, "Group Emergency Pct", {0, 100})
            state.config.groupMemberEmergencyPct = DrawNumberInput(state.config.groupMemberEmergencyPct, "Group Member Emergency Pct", {0, 100})
            state.config.groupTankEmergencyPct = DrawNumberInput(state.config.groupTankEmergencyPct, "Group Tank Emergency Pct", {0, 100})
            state.config.otherTankEmergencyPct = DrawNumberInput(state.config.otherTankEmergencyPct, "Other Tank Emergency Pct", {0, 100})
            state.config.selfEmergencyPct = DrawNumberInput(state.config.selfEmergencyPct, "Self Emergency Pct", {0, 100})
            state.config.healAt = DrawNumberInput(state.config.healAt, "Heal At", {0, 100})
            state.config.hotAt = DrawNumberInput(state.config.hotAt, "HoT At", {0, 100})
            state.config.hotRecastTime = DrawNumberInput(state.config.hotRecastTime, "HoT Recast Time", {0, math.huge}) -- Positive only
            state.config.rezCheckInterval = DrawNumberInput(state.config.rezCheckInterval, "Rez Check Interval", {0, math.huge}) -- Positive only
            state.config.xTarHealList = DrawNumberInput(state.config.xTarHealList, "X Target Heal List", {0, 20})
            ImGui.Columns(1)
        end

        if ImGui.CollapsingHeader(icons.FA_BOOK .. "   Abilities") then
            abilTabOpen = true
        else
            abilTabOpen = false
        end

        if abilTabOpen then
            DrawHealList()
            DrawHealEditorWindow()

            ImGui.NewLine()

            if ImGui.Button("Add Heal Abil", 100, 55) then
                local newTemplate = abils.healAbilTemplate
                local newAbility = deepcopy(newTemplate)
                newAbility.priority = #state.config.healabils[state.class] + 1
                table.insert(state.config.healabils[state.class], newAbility)
            end
            ImGui.SameLine()
        
            state.copyMode, _ = ImGui.Checkbox("Copy Mode", state.copyMode)
        
            if state.copyMode then
                ImGui.SameLine()
                ImGui.SetCursorPosX(ImGui.GetCursorPosX() - 103)
                ImGui.SetCursorPosY(ImGui.GetCursorPosY() + 30)
                local alpha = 0.5 * (1 + math.sin((frameCounter % flashInterval) / flashInterval * (2 * math.pi)))
                ImGui.TextColored(ImVec4(1,0,0,alpha),"Copy Mode is on!")
            end
        
            ImGui.SameLine()
            if state.copyMode then
                ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 119)
            else
                ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 130)
            end
            ImGui.NewLine()
        end

        ImGui.NewLine()

        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 80)
        anim:SetTextureCell(99)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim,45,45)

        ImGui.SameLine()

        anim:SetTextureCell(118)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim,45,45)

        ImGui.SameLine()
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 11)

        ImGui.PushStyleColor(ImGuiCol.Text, state.activeTheme.hovered)
        ImGui.SetWindowFontScale(4)
        ImGui.Text('Healing')
        ImGui.PopStyleColor()
        ImGui.SetWindowFontScale(1)

        ImGui.SameLine()

        anim:SetTextureCell(101)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim,45,45)

        ImGui.SameLine()

        anim:SetTextureCell(156)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim,45,45)

    
        ImGui.Columns(2)

        DrawOtherTankListTable()
        ImGui.NextColumn()
        DrawHotTargetsTable()

        ImGui.Columns(1)
        DrawTabEnd()
        ImGui.EndTabItem()
    end
end

local function DrawBuffsTab()
    if ImGui.BeginTabItem(icons.FA_BOOK .. "   Buffs") then
        local totalWidth, _ = ImGui.GetContentRegionAvail()
        local columnWidth = totalWidth / 2
        ImGui.Columns(2)
        state.config.doBuffs = DrawCheckbox(state.config.doBuffs,"Do Buffs")
        ImGui.NextColumn()
        state.config.buffCheckInterval = DrawNumberInput(state.config.buffCheckInterval,"Buff Check Interval",{0,math.huge})

        ImGui.Columns(1)

        DrawBuffList()
        DrawBuffEditorWindow()

        ImGui.NewLine()

        if ImGui.Button("Add Buff", 100, 55) then
            local newTemplate = abils.buffAbilTemplate
            local newAbility = deepcopy(newTemplate)
            newAbility.priority = #state.config.buffabils[state.class] + 1
            table.insert(state.config.buffabils[state.class], newAbility)
        end
        ImGui.SameLine()
    
        state.copyMode, _ = ImGui.Checkbox("Copy Mode", state.copyMode)
    
        if state.copyMode then
            ImGui.SameLine()
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() - 103)
            ImGui.SetCursorPosY(ImGui.GetCursorPosY() + 30)
            local alpha = 0.5 * (1 + math.sin((frameCounter % flashInterval) / flashInterval * (2 * math.pi)))
            ImGui.TextColored(ImVec4(1,0,0,alpha),"Copy Mode is on!")
        end
    
        ImGui.SameLine()
        if state.copyMode then
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 119)
        else
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 130)
        end
        ImGui.NewLine()
        DrawTabEnd()
        ImGui.EndTabItem()
    end
end

local function DrawDebuffsTab()
    if ImGui.BeginTabItem(icons.FA_FIRE .. "   Debuffs") then
        local totalWidth, _ = ImGui.GetContentRegionAvail()
        local columnWidth = totalWidth / 2
    
        ImGui.Columns(2)

        state.config.doDebuffs = DrawCheckbox(state.config.doDebuffs,"Do Debuffs")
        state.config.doCharm = DrawCheckbox(state.config.doCharm,"Do Charm")
        state.config.debuffMode = DrawDropdown(state.config.debuffMode,"Debuff Mode",{"Cycle Targets", "Cycle Debuffs"},150)
        state.config.charmSpell = DrawTextInput(state.config.charmSpell,"Charm Abil",150)
        state.config.charmType = DrawDropdown(state.config.charmType,"Charm Abil Type",{"AA","Spell","Cmd","Disc","Item","Skill"},150)
        state.config.charmBreakSpell = DrawTextInput(state.config.charmBreakSpell,"Charm Break Abil",150)
        ImGui.SameLine()
        DrawInfoIconWithTooltip("This is the ability that will activate immediately on a charm break. Default target is your charm pet.")
        state.config.charmBreakType = DrawDropdown(state.config.charmBreakType,"Charm Break Abil Type",{"AA","Spell","Cmd","Disc","Item","Skill"},150)

        ImGui.NextColumn()

        state.config.maxDebuffRange = DrawNumberInput(state.config.maxDebuffRange,"Max Debuff Range",{0,math.huge})
        state.config.debuffStartAt = DrawNumberInput(state.config.debuffStartAt,"Debuff Start At",{0,100})
        state.config.debuffStopAt = DrawNumberInput(state.config.debuffStopAt,"Debuff Stop At",{0,100})
        state.config.debuffZRadius = DrawNumberInput(state.config.debuffZRadius,"Debuff Z Radius",{0,math.huge})
        state.config.debuffAETargetMin = DrawNumberInput(state.config.debuffAETargetMin,"AE Target Min",{0,math.huge})
        if ImGui.Button("Set Pet",55,20) then
            state.currentpet = mq.TLO.Target.ID()
        end
        ImGui.SameLine()
        ImGui.Text(string.format("Current Pet: %s",mq.TLO.Spawn(state.currentpet).CleanName()))

        ImGui.Columns(1)

        anim:SetTextureCell(17)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim,90,90)
        ImGui.SameLine()

        anim:SetTextureCell(55)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim,90,90)
        ImGui.SameLine()

        anim:SetTextureCell(5)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim,90,90)
        ImGui.SameLine()

        ImGui.SetCursorPosY(ImGui.GetCursorPosY() + 10)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 25)

        ImGui.PushStyleColor(ImGuiCol.Text, state.activeTheme.hovered)
        ImGui.SetWindowFontScale(5)
        ImGui.Text('Debuffs')
        ImGui.PopStyleColor()
        ImGui.SetWindowFontScale(1)



        DrawDebuffList()
        DrawDebuffEditorWindow()

        ImGui.NewLine()

        if ImGui.Button("Add Debuff", 100, 55) then
            local newTemplate = abils.debuffAbilTemplate
            local newAbility = deepcopy(newTemplate)
            newAbility.priority = #state.config.debuffabils[state.class] + 1
            table.insert(state.config.debuffabils[state.class], newAbility)
        end
        ImGui.SameLine()
    
        state.copyMode, _ = ImGui.Checkbox("Copy Mode", state.copyMode)
    
        if state.copyMode then
            ImGui.SameLine()
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() - 103)
            ImGui.SetCursorPosY(ImGui.GetCursorPosY() + 30)
            local alpha = 0.5 * (1 + math.sin((frameCounter % flashInterval) / flashInterval * (2 * math.pi)))
            ImGui.TextColored(ImVec4(1,0,0,alpha),"Copy Mode is on!")
        end
    
        ImGui.SameLine()
        if state.copyMode then
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 119)
        else
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 130)
        end
        ImGui.NewLine()
        DrawTabEnd()
        ImGui.EndTabItem()
    end
end

local function DrawPullTab()
    if ImGui.BeginTabItem(icons.FA_BICYCLE.. "   Pulls") then
        local totalWidth, _ = ImGui.GetContentRegionAvail()
        local columnWidth = totalWidth / 2
    
        ImGui.Columns(2)
        state.config.doPulling = DrawCheckbox(state.config.doPulling, "Pulling Enabled")
        state.config.chainPullToggle = DrawCheckbox(state.config.chainPullToggle, "Chain Pulling Enabled")
        state.config.pullAbilName = DrawTextInput(state.config.pullAbilName,"Pull Ability Name", 175)
        local types = {"AA", "Spell", "Item", "Skill", "Disc", "Cmd", "Melee"}
        local typeIndex = lib.findIndex(types, state.config.pullAbilType) or 1
        ImGui.SetNextItemWidth(175)
        local newTypeIndex, changed = ImGui.Combo("##Type", typeIndex, types)
        if changed then
            state.config.pullAbilType = types[newTypeIndex]
        end

        ImGui.SameLine()
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() - 4)
        ImGui.Text('Pull Ability Type')

        ImGui.PushStyleColor(ImGuiCol.Text, state.activeTheme.hovered)
        ImGui.SetWindowFontScale(3)
        ImGui.Text('Pulling')
        ImGui.PopStyleColor()
        ImGui.SetWindowFontScale(1)

        local windowHeight = (28 * #state.config.pullPauseConds) + 22

        if #state.config.pullPauseConds >= 3 then
            windowHeight = 108
        end
        

        if ImGui.BeginTable("PullCondsTable", 3, table_flags, ImGui.GetContentRegionAvail(),windowHeight) then
            ImGui.TableSetupColumn("Expand", ImGuiTableColumnFlags.WidthFixed, 27)
            ImGui.TableSetupColumn("Pause Conditon:", ImGuiTableColumnFlags.WidthFixed, 175)
            ImGui.TableSetupColumn("Delete", ImGuiTableColumnFlags.WidthFixed, ImGui.GetContentRegionAvail())
            ImGui.TableHeadersRow()
    
            for i = 0, #state.config.pullPauseConds do

                if state.config.pullPauseConds[i] == nil then goto nextloop end
                local popupId = "FullTextPopup_" .. i
                
    
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0)

                if ImGui.Button(icons.FA_EXPAND .. "##Expand_" .. i, ImVec2(20, 20)) then
                    ImGui.OpenPopup(popupId)
                end
                
                
                ImGui.SetNextWindowSize(1000,600)
                ImGui.PushStyleColor(ImGuiCol.PopupBg, ImVec4(0, 0, 0, 1.0))
                if ImGui.BeginPopup(popupId, ImGuiWindowFlags.AlwaysAutoResize and ImGuiWindowFlags.AlwaysHorizontalScrollbar) then
                    if ImGui.BeginChild("FullTextInput", 1000, 600) then
                            -- Use InputTextMultiline inside the child window
                        local buffer = state.config.pullPauseConds[i] or ""
                        state.config.pullPauseConds[i], _ = ImGui.InputTextMultiline("##InputText", buffer, 1000, 600)
                    
                        ImGui.EndChild()
                    end
                    ImGui.EndPopup()
                end
                ImGui.PopStyleColor()

                ImGui.TableSetColumnIndex(1)

                state.config.pullPauseConds[i] = DrawTextInput(state.config.pullPauseConds[i],'##pullpausecond' .. i, 175)

                ImGui.TableSetColumnIndex(2)

                if ImGui.Button("Delete",50, 25) then
                    table.remove(state.config.pullPauseConds,i)
                end
                ::nextloop::
            end
            ImGui.EndTable()
        end

        ImGui.NewLine()

        if ImGui.Button("Add Pull Pause\nCondition", 100, 45) then
            table.insert(state.config.pullPauseConds,#state.config.pullPauseConds,"New Pause Cond")
        end

        ImGui.NewLine()

        local ignoreHeight = (28*#state.pullIgnores) + 24

        if #state.pullIgnores >=4 then
            ignoreHeight = 136
        end

        if ImGui.BeginTable("PullIgnores", 2, table_flags, ImGui.GetContentRegionAvail(),ignoreHeight) then
            ImGui.TableSetupColumn("Pull Ignores", ImGuiTableColumnFlags.NoSavedSettings, 245)
            ImGui.TableSetupColumn("Delete", ImGuiTableColumnFlags.WidthFixed, 55)
            ImGui.TableHeadersRow()
    
            for i = 1, #state.pullIgnores do

                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0)

                if state.pullIgnores[i] ~= mq.TLO.Zone.ShortName() then
                    ImGui.Text(mq.TLO.Spawn(state.pullIgnores[i]).Name())
                end

                ImGui.TableSetColumnIndex(1)

                if ImGui.Button("Delete##" .. i,50, 25) then
                    table.remove(state.pullIgnores,i)
                end
            end
            ImGui.EndTable()
        end

        ImGui.NewLine()
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 12)
    
        if ImGui.Button("Add Pull Ignore") then
            ImGui.OpenPopup("AddIgnorePopup")
        end
        
        
        if ImGui.BeginPopup("AddIgnorePopup") then
            ImGui.Text("Enter new pull ignore name:")
            -- Make sure newIgnoreValue is updated with input text
            newIgnoreValue = ImGui.InputText("##NewIgnoreValue", newIgnoreValue)
            
            if ImGui.Button("OK", ImVec2(120, 0)) then
                -- Add the new ignore value to the table if it's not empty
                if newIgnoreValue ~= "" then
                    table.insert(state.config.ignores[mq.TLO.Zone.ShortName()], #state.config.ignores[mq.TLO.Zone.ShortName()] + 1, newIgnoreValue)
                    table.insert(state.pullIgnores, #state.pullIgnores + 1, mq.TLO.Spawn(newIgnoreValue).ID())
                end
                
                -- Reset the input field
                newIgnoreValue = ""
                ImGui.CloseCurrentPopup()
            end
            
            ImGui.SameLine()
            
            if ImGui.Button("Cancel", ImVec2(120, 0)) then
                -- Close the pop-up window without adding the value
                newIgnoreValue = ""
                ImGui.CloseCurrentPopup()
            end
            
            ImGui.EndPopup()
        end
        
        
        
        

        ImGui.NextColumn()
        state.config.chainPullHP = DrawNumberInput(state.config.chainPullHP, "Chain Pull HP:", {0, 100})
        state.config.chainPullMax = DrawNumberInput(state.config.chainPullMax, "Chain Pull Max:")
        state.config.postPullAbilPause = DrawNumberInput(state.config.postPullAbilPause, "Post Pull Ability Pause:")
        state.config.pullAbilRange = DrawNumberInput(state.config.pullAbilRange, "Pull Ability Range:")
        state.config.pullPauseHealerMana = DrawNumberInput(state.config.pullPauseHealerMana, "Pull Pause Healer Mana:", {0,100})
        state.config.pullPauseTankMana = DrawNumberInput(state.config.pullPauseTankMana, "Pull Pause Tank Mana:", {0,100})
        state.config.pullPauseTankEnd = DrawNumberInput(state.config.pullPauseTankEnd, "Pull Pause Tank End:", {0,100})
        state.config.pullRadius = DrawNumberInput(state.config.pullRadius, "Pull Radius:")
        state.config.pullZRange = DrawNumberInput(state.config.pullZRange, "Pull Z Range:")

        ImGui.NewLine()

        anim:SetTextureCell(1083)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 20)
        ImGui.DrawTextureAnimation(anim,220,220)
        

        ImGui.Columns(1)
        DrawTabEnd()
        ImGui.EndTabItem()
    end
end

local function DrawTankTab()
    if ImGui.BeginTabItem(icons.FA_SHIELD.. "   Tanking") then
        local totalWidth, _ = ImGui.GetContentRegionAvail()
        local columnWidth = totalWidth / 2

        ImGui.Columns(2)
        
        state.config.doTanking = DrawCheckbox(state.config.doTanking,"Tanking Enabled")
        state.config.tankTaunting = DrawCheckbox(state.config.tankTaunting,"Taunting Enabled")
        state.config.petTank = DrawCheckbox(state.config.petTank,"Pet Tank Toggle")
        state.config.tankAttackWhilePetTanking = DrawCheckbox(state.config.tankAttackWhilePetTanking,"Attack While Pet Tanking Toggle")

        ImGui.NextColumn()

        state.config.tankEngageRadius = DrawNumberInput(state.config.tankEngageRadius,"Tank Engage Radius")

        ImGui.PushStyleColor(ImGuiCol.Text, state.activeTheme.hovered)
        ImGui.SetWindowFontScale(3)
        ImGui.Text('Tanking')
        ImGui.PopStyleColor()
        ImGui.SetWindowFontScale(1)

        state.config.tankPetAttackPct = DrawNumberInput(state.config.tankPetAttackPct,"Attack While Pet Tanking At",{0,100})

        ImGui.Columns(1)

        ImGui.NewLine()

        DrawAggroList()
        DrawAggroEditorWindow()

        ImGui.NewLine()

        if ImGui.Button("Add Aggro Abil", 100, 55) then
            local newTemplate = abils.aggroAbilTemplate
            local newAbility = deepcopy(newTemplate)
            newAbility.priority = #state.config.aggroabils[state.class] + 1
            table.insert(state.config.aggroabils[state.class], newAbility)
        end
        ImGui.SameLine()
    
        state.copyMode, _ = ImGui.Checkbox("Copy Mode", state.copyMode)
    
        if state.copyMode then
            ImGui.SameLine()
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() - 103)
            ImGui.SetCursorPosY(ImGui.GetCursorPosY() + 30)
            local alpha = 0.5 * (1 + math.sin((frameCounter % flashInterval) / flashInterval * (2 * math.pi)))
            ImGui.TextColored(ImVec4(1,0,0,alpha),"Copy Mode is on!")
        end
    
        ImGui.SameLine()
        if state.copyMode then
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 119)
        else
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 130)
        end

        ImGui.SameLine()
        anim:SetTextureCell(1722)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 20)
        ImGui.DrawTextureAnimation(anim,105,105)

        ImGui.SameLine()
        anim:SetTextureCell(1660)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 20)
        ImGui.DrawTextureAnimation(anim,105,105)

        ImGui.SameLine()
        anim:SetTextureCell(1736)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 20)
        ImGui.DrawTextureAnimation(anim,105,105)

        ImGui.NewLine()
    
        DrawTabEnd()
        ImGui.EndTabItem()
    end
end

local newKeywordBuffer = ""

local function DrawEventsTab()
    if ImGui.BeginTabItem(icons.FA_FILE_TEXT_O.. "   Events") then
        local totalWidth, _ = ImGui.GetContentRegionAvail()

        if ImGui.CollapsingHeader("Keywords   "..icons.FA_BOOK, ImGuiTreeNodeFlags.DefaultOpen) then
            -- Build combined ability list
            local allAbilities = {}
            local buffAbilities = state.config.buffabils[state.class] or {}
            local healAbilities = state.config.healabils[state.class] or {}
            
            for _, abil in ipairs(buffAbilities) do
                table.insert(allAbilities, {name=abil.name, cure=false})
            end
            for _, abil in ipairs(healAbilities) do
                if abil.cure then
                    table.insert(allAbilities, {name=abil.name, cure=true})
                end
            end

            -- Convert keywords to a list
            local keywordList = {}
            for k, v in pairs(state.config.keywords) do
                table.insert(keywordList, {keyword=k, data=v})
            end
            table.sort(keywordList, function(a,b) return a.keyword < b.keyword end)

            local rows = #keywordList
            local columns = 3
            local columnLabels = {"Keyword","Abilities","Delete"}

            local rowHeight = 27
            local tableHeight = (rows * rowHeight) + 20

            if ImGui.BeginTable("KeywordTable", columns, table_flags, ImVec2(0, tableHeight)) then
                ImGui.TableSetupColumn(columnLabels[1])
                ImGui.TableSetupColumn(columnLabels[2])
                ImGui.TableSetupColumn(columnLabels[3])
                ImGui.TableHeadersRow()

                local alternatingColor = true
                for i, entry in ipairs(keywordList) do
                    local keyword = entry.keyword
                    local kdata = entry.data
                    local buffs = kdata.buffs or {}
                    local cures = kdata.cures or {}

                    ImGui.TableNextRow(0,rowHeight)

                    -- Column 1: Keyword name
                    ImGui.TableSetColumnIndex(0)
                    ImGui.Text(keyword)

                    -- Column 2: Multi-select combo for abilities using Selectable and icons.FA_CHECK for selected state
                    ImGui.TableSetColumnIndex(1)
                    ImGui.PushID("keyword_abils_"..i)
                    ImGui.SetNextItemWidth(200)
                    if ImGui.BeginCombo("##abilities", "Select Abilities", ImGuiComboFlags.HeightLarge) then
                        for _, ability in ipairs(allAbilities) do
                            local isSelected = false
                            if ability.cure then
                                for _, c in ipairs(cures) do
                                    if c:lower() == ability.name:lower() then
                                        isSelected = true
                                        break
                                    end
                                end
                            else
                                for _, b in ipairs(buffs) do
                                    if b:lower() == ability.name:lower() then
                                        isSelected = true
                                        break
                                    end
                                end
                            end

                            -- Prefix ability name with a check icon if selected
                            local displayName = (isSelected and (icons.FA_CHECK.." "..ability.name) or ability.name)

                            local newSelected, pressed = ImGui.Selectable(displayName, false, ImGuiSelectableFlags.DontClosePopups)
                            if pressed then
                                -- Toggle logic
                                if isSelected then
                                    -- Was selected, remove it
                                    if ability.cure then
                                        for idx, c in ipairs(cures) do
                                            if c:lower() == ability.name:lower() then
                                                table.remove(cures, idx)
                                                break
                                            end
                                        end
                                    else
                                        for idx, b in ipairs(buffs) do
                                            if b:lower() == ability.name:lower() then
                                                table.remove(buffs, idx)
                                                break
                                            end
                                        end
                                    end
                                else
                                    -- Was not selected, add it
                                    if ability.cure then
                                        table.insert(cures, ability.name)
                                    else
                                        table.insert(buffs, ability.name)
                                    end
                                end
                                -- Update original tables
                                kdata.buffs = buffs
                                kdata.cures = cures
                            end
                        end
                        ImGui.EndCombo()
                    end
                    ImGui.PopID()

                    ImGui.TableSetColumnIndex(2)
                    ImGui.PushID("keyword_del_"..i)
                    if ImGui.Button("Delete") then
                        state.config.keywords[keyword] = nil
                    end
                    ImGui.PopID()

                end
                ImGui.EndTable()
            end

            -- Add new keyword section
            ImGui.NewLine()
            ImGui.Text("Add New Keyword:")
            ImGui.SetNextItemWidth(400)
            ImGui.SameLine()
            newKeywordBuffer = newKeywordBuffer or ""
            local newValue, changed = ImGui.InputText("##NewKeyword", newKeywordBuffer)
            if changed then
                newKeywordBuffer = newValue
            end
            ImGui.SameLine()
            if ImGui.Button("Add Keyword") then
                local nk = newKeywordBuffer:lower():match("%S+")
                if nk and nk ~= "" and not state.config.keywords[nk] then
                    state.config.keywords[nk] = {buffs={}, cures={}}
                    newKeywordBuffer = ""
                end
            end
        end

        DrawTabEnd()
        ImGui.EndTabItem()
    end
end




function mod.parseImVec4(str)
    local values = {}
    for val in str:gmatch("%d+%.?%d*") do
        table.insert(values, tonumber(val))
    end
    return ImVec4(values[1] or 0, values[2] or 0, values[3] or 0, values[4] or 0)
end

function mod.loadTheme()
    local tbl = {}
    tbl.windowbg = mod.parseImVec4(state.config.selectedTheme.windowbg)
    tbl.bg = mod.parseImVec4(state.config.selectedTheme.bg)
    tbl.hovered = mod.parseImVec4(state.config.selectedTheme.hovered)
    tbl.active = mod.parseImVec4(state.config.selectedTheme.active)
    tbl.button = mod.parseImVec4(state.config.selectedTheme.button)
    tbl.text = mod.parseImVec4(state.config.selectedTheme.text)
    tbl.name = state.config.selectedTheme.name
    tbl.index = state.config.selectedTheme.index
    state.activeTheme = tbl
    selectedOptionIndextheme = state.activeTheme.index
end

mod.loadTheme()



function mod.main()
    if not openGUI then return end
    pushStyle(state.activeTheme)
    openGUI, shouldDrawGUI = ImGui.Begin(state.class .. '420', openGUI, ImGuiWindowFlags.None)
    if shouldDrawGUI then
        frameCounter = frameCounter + 1
        ImGui.SetWindowSize(600,800,ImGuiCond.FirstUseEver)
        if ImGui.BeginTabBar("Tabs") then
            DrawConsoleTab()
            DrawCondsTab()
            DrawGenTab()
            DrawHealTab()
            DrawBuffsTab()
            DrawDebuffsTab()
            DrawPullTab()
            DrawTankTab()
            DrawEventsTab()
            ImGui.EndTabBar()
        end
        DrawDebuffOverwriteWindow(debuffOverrideIndex)
        DrawBuffOverrideWindow(buffOverrideIndex)
        DrawBuffTargetWindow(buffTargetIndex)
    end

    if showTableGUI then
        displayTableGUI(state)
    end

    updatePicker(pickerlist,pickerAbilIndex)

    -- Make sure to call popStyles() and ImGui.End() even if shouldDrawGUI is false
    popStyles()
    ImGui.End()
end

return mod