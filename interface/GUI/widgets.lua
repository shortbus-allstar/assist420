-- gui_refactor/widgets.lua
-- Contains the smaller “draw” helper functions (checkbox, text input, number input).

local widgets = {}
local ImGui = require('ImGui')
local icons     = require('mq.icons')

function DrawInfoIconWithTooltip(text)
    ImGui.SameLine()
    ImGui.Text(icons.FA_INFO_CIRCLE)
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.Text(text)
        ImGui.EndTooltip()
    end
end


function DrawCheckbox(value, name)
    local isChecked = value
    isChecked, _ = ImGui.Checkbox(name, isChecked)
    return isChecked
end

function DrawNumberInput(value, name, range)
    local inputValue = value
    if not inputValue then inputValue = 0 end
    if range then
        -- Force into range
        if inputValue < range[1] then inputValue = range[1] end
        if inputValue > range[2] then inputValue = range[2] end
    end
    ImGui.SetNextItemWidth(100)
    inputValue, _ = ImGui.InputInt(name, inputValue)
    return inputValue
end

function DrawTextInput(value, name, width)
    local inputValue = value or ""
    if width then
        ImGui.SetNextItemWidth(width)
    end
    inputValue, _ = ImGui.InputText(name, inputValue)
    return inputValue
end

function DrawDropdown(currentValue, name, optionList, itemWidth)
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

return widgets
