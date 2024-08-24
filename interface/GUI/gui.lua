local mq = require('mq')
local imgui = require('ImGui')
local config= require('interface.config')

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

local BUTTON_SIZE = 55
local editIndex = 1
local selectedOptionIndextheme = 1
local frameCounter = 0
local flashInterval = 250 

local showTableGUI = false
local openGUI = true
local shouldDrawGUI = true
local isEditing = false
local isEditingAggro = false
local shouldDrawEditor = true
local shouldDrawAggroEditor = true
local pickerAbilIndex = 0
local pickerlist = state.config.abilities
local showCustTar = false

local table_flags = bit32.bor(ImGuiTableFlags.Hideable, ImGuiTableFlags.RowBg, ImGuiTableFlags.ScrollY, ImGuiTableFlags.BordersOuter, ImGuiTableFlags.Resizable)
local edit_flags = bit32.bor(ImGuiWindowFlags.None)

local newIgnoreValue = ""
local newassist = ""

local pushedStyleVarCount = 0
local pushedStyleCount = 0

local mod ={}

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
            Picker:ClearSelection()
        elseif selected.Type == 'Disc' then
            list[state.class][abilIndex].type = selected.Type
            list[state.class][abilIndex].name = selected.Name
            Picker:ClearSelection()
        elseif selected.Type == 'AA' then
            list[state.class][abilIndex].type = selected.Type
            list[state.class][abilIndex].name = selected.Name
            Picker:ClearSelection()
        elseif selected.Type == 'Item' then
            list[state.class][abilIndex].type = selected.Type
            list[state.class][abilIndex].name = selected.Name
            Picker:ClearSelection()
        elseif selected.Type == 'Ability' then
            list[state.class][abilIndex].type = "Skill"
            list[state.class][abilIndex].name = selected.Name
            Picker:ClearSelection()
        end
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

local function DrawHealEditWindow()
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
                    state.config.role = option -- Update state.loglevel based on the selected option
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

        if ImGui.BeginCombo("##loglevel:", state.loglevel, ImGuiComboFlags.None) then
            for i, option in ipairs(options) do
                local isSelected = (i == selectedOptionIndex2)
                ImGui.PushStyleColor(ImGuiCol.Text, isSelected and ImVec4(0, 1, 1, 1) or ImGui.GetStyleColorVec4(ImGuiCol.Text))
                if ImGui.Selectable(option, isSelected) then
                    selectedOptionIndex2 = i
                    state.loglevel = option -- Update state.loglevel based on the selected option
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
                    state.activeTheme = theme -- Update state.loglevel based on the selected option
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

            -- Only allow drag and drop if it's not the "heals" routine
            if routineName ~= "heals" then
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
        ImGui.NewLine()
        ImGui.Text('Assist Type:')
        local asstypes = { "Group MA", "Raid MA", "Custom Name", "Custom ID"}

        if ImGui.BeginCombo("##assisttype", state.config.assistType, ImGuiComboFlags.None) then
            for i, option in ipairs(asstypes) do
                local isSelected = (i == selectedOptionIndex3)
                ImGui.PushStyleColor(ImGuiCol.Text, isSelected and ImVec4(0, 1, 1, 1) or ImGui.GetStyleColorVec4(ImGuiCol.Text))
                if ImGui.Selectable(option, isSelected) then
                    selectedOptionIndex3 = i
                    state.config.assistType = option -- Update state.loglevel based on the selected option
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
                    state.config.chaseType = option -- Update state.loglevel based on the selected option
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

local function DrawHealTab()
    if ImGui.BeginTabItem(icons.FA_HEART .. "   Heals") then
        local totalWidth, _ = ImGui.GetContentRegionAvail()
        local columnWidth = totalWidth / 2
    
        ImGui.Columns(2)
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
        ImGui.Columns(1)
        DrawTabEnd()
        ImGui.EndTabItem()
    end
end

local function DrawDebuffsTab()
    if ImGui.BeginTabItem(icons.FA_FIRE .. "   Debuffs") then
        local totalWidth, _ = ImGui.GetContentRegionAvail()
        local columnWidth = totalWidth / 2
    
        ImGui.Columns(2)
        ImGui.Columns(1)
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

local function DrawEventsTab()
    if ImGui.BeginTabItem(icons.FA_FILE_TEXT_O.. "   Events") then
        local totalWidth, _ = ImGui.GetContentRegionAvail()
        local columnWidth = totalWidth / 2
    
        ImGui.Columns(2)
        ImGui.Columns(1)
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