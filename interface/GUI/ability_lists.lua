-- gui_refactor/ability_lists.lua
-- Contains code for listing abilities (Aggro, Heal, Buff, Debuff, normal "Abilities").
local mq = require('mq')
local ability_lists   = {}
local ImGui           = require('ImGui')
local style     = require('interface.GUI.style')
local widgets = require('interface.GUI.widgets')
local config_editors = require('interface.GUI.config_editors')
local write           = require('utils.Write')
local state           = require('utils.state')
local lib             = require('utils.lib')
local abils           = require('routines.abils')

local anim      = mq.FindTextureAnimation('A_SpellIcons')
local icons     = require('mq.icons')
local classanim = mq.FindTextureAnimation('A_DragItem')

-- Because the original code used these table flags in many places:
local ImGuiTableFlags = ImGuiTableFlags
local table_flags = bit32.bor(
    ImGuiTableFlags.Hideable,
    ImGuiTableFlags.RowBg,
    ImGuiTableFlags.ScrollY,
    ImGuiTableFlags.BordersOuter,
    ImGuiTableFlags.Resizable
)

-----------------------------------------------------------------------------
-- arrangeAbils: Sort each ability list by priority
-----------------------------------------------------------------------------

local function arrangeAbils()
    table.sort(state.config.abilities[state.class],   function(a, b) return a.priority < b.priority end)
    table.sort(state.config.aggroabils[state.class],  function(a, b) return a.priority < b.priority end)
    table.sort(state.config.healabils[state.class],   function(a, b) return a.priority < b.priority end)
    table.sort(state.config.debuffabils[state.class], function(a, b) return a.priority < b.priority end)
    table.sort(state.config.buffabils[state.class],   function(a, b) return a.priority < b.priority end)
end

-----------------------------------------------------------------------------
-- deepcopy, used for copying abilities
-----------------------------------------------------------------------------

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-----------------------------------------------------------------------------
-- DrawDragDrop: used by each of the lists for reordering
-----------------------------------------------------------------------------

function ability_lists.DrawDragDrop(ability, abilityList, nameWidth, i)
    if ImGui.Button(ability.name .. " - " .. ability.priority, ImVec2(nameWidth - 30, 0)) then
        -- no-op
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
                write.Help("Target Current Name: %s", ability.name)
                write.Help("Target Current Priority: %s", ability.priority)
                write.Help("Dragitem Current Name: %s", abilityList[state.class][targetPriority].name)
                write.Help("Dragitem Current Priority: %s", abilityList[state.class][targetPriority].priority)
                write.Help("targetPriority Variable: %s", targetPriority)

                if state.copyMode then
                    local originalPriority = abilityList[state.class][ability.priority].priority
                    local copiedAbility    = deepcopy(abilityList[state.class][targetPriority])
                    copiedAbility.priority = originalPriority
                    abilityList[state.class][ability.priority] = copiedAbility
                    arrangeAbils()
                else
                    -- Swap
                    abilityList[state.class][targetPriority].priority = ability.priority
                    ability.priority = targetPriority
                    arrangeAbils()
                end
            end
        end
        ImGui.EndDragDropTarget()
    end

    ImGui.SameLine()
    ImGui.SetCursorPosX(ImGui.GetCursorPosX() - 5)

    -- If user clicks the "Bullseye" icon to open the ability picker
    config_editors.pickerlist = abilityList -- hooking into the global variable from original code
    if ImGui.Button(icons.FA_BULLSEYE .. "##" .. i, ImVec2(25,0)) and Picker then 
        Picker:SetOpen()
        config_editors.pickerAbilIndex = i
    end

    if Picker and i == 1 then
        Picker:DrawAbilityPicker()
    end
end

-----------------------------------------------------------------------------
-- Utility “DrawEditDeleteX” functions from original code
-- Each list uses a slightly different editing window, so we keep them in the Editor, 
-- but the “draw list” wants to call the "Edit / Delete" logic. 
-- We'll replicate the tiny "DrawEditDelete*" references:
-----------------------------------------------------------------------------

function ability_lists.DrawEditDeleteAggro(ability, abilList)
    if ImGui.Button("Edit##Aggro" .. ability.priority) then
        config_editors.isEditingAggro = true
        style.editIndex = ability.priority
        if ability then
            if not ability.name then
                ability.name = 'Blank'
            end
            config_editors.dynamicAggroWindowTitle = "Edit Aggro Ability - " .. ability.name
        else
            abilList[state.class][style.editIndex] = {}
            abilList[state.class][style.editIndex].name = 'Blank'
            config_editors.dynamicAggroWindowTitle = "Edit Aggro Ability - " .. abilList[state.class][style.editIndex].name
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

function ability_lists.DrawEditDeleteHeal(ability, abilList)
    if ImGui.Button("Edit##Heal" .. ability.priority) then
        config_editors.isEditingHeal = true
        style.editIndex = ability.priority
        if ability then
            if not ability.name then
                ability.name = 'Blank'
            end
            config_editors.dynamicHealWindowTitle = "Edit Heal Ability - " .. ability.name
        else
           abilList[state.class][style.editIndex] = {}
           abilList[state.class][style.editIndex].name = 'Blank'
           config_editors.dynamicHealWindowTitle = "Edit Heal Ability - " .. abilList[state.class][style.editIndex].name
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

function ability_lists.DrawEditDeleteDebuff(ability, abilList)
    if ImGui.Button("Edit##Debuff" .. ability.priority) then
        config_editors.isEditingDebuff = true
        style.editIndex = ability.priority
        if ability then
            if not ability.name then
                ability.name = 'Blank'
            end
            config_editors.dynamicDebuffWindowTitle = "Edit Debuff Ability - " .. ability.name
        else
            abilList[state.class][style.editIndex] = {}
            abilList[state.class][style.editIndex].name = 'Blank'
            config_editors.dynamicDebuffWindowTitle = "Edit Debuff Ability - " .. abilList[state.class][style.editIndex].name
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

function ability_lists.DrawEditDeleteBuff(ability, abilList)
    if ImGui.Button("Edit##Buff" .. ability.priority) then
        config_editors.isEditingBuff = true
        style.editIndex = ability.priority
        if ability then
            if not ability.name then
                ability.name = 'Blank'
            end
            config_editors.dynamicBuffWindowTitle = "Edit Buff Ability - " .. ability.name
        else
            abilList[state.class][style.editIndex] = {}
            abilList[state.class][style.editIndex].name = 'Blank'
            config_editors.dynamicBuffWindowTitle = "Edit Buff Ability - " .. abilList[state.class][style.editIndex].name
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

-----------------------------------------------------------------------------
-- Now the “DrawXList” functions (DrawAggroList, DrawHealList, DrawDebuffList, DrawBuffList, DrawList).
-- We’ll preserve them exactly, except we’ll call the smaller “DrawDragDrop” or “DrawEditDeleteX” from above.
-----------------------------------------------------------------------------

function ability_lists.DrawAggroList()
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

    local totalWidth    = ImGui.GetWindowWidth()
    local checkboxWidth = totalWidth * 0.15
    local nameWidth     = totalWidth * 0.65
    local editButtonWidth = totalWidth * 0.20

    local activedata = {}
    local buttondata = {}
    local editdata   = {}

    for i = #state.config.aggroabils[state.class], 1, -1 do
        local v = state.config.aggroabils[state.class][i]
        if v.priority ~= i then v.priority = i end
        if not v then 
            write.Error('Ability at index', i, 'is nil')
        else
            table.insert(activedata, 1, function() 
                v.active = DrawCheckbox(v.active, "##aggro" .. i) 
            end)
            table.insert(buttondata, 1, function() 
                ability_lists.DrawDragDrop(v, state.config.aggroabils, nameWidth, i)
            end)
            table.insert(editdata, 1, function() 
                ability_lists.DrawEditDeleteAggro(v, state.config.aggroabils) 
            end)
        end
    end

    config_editors.DrawTable("AggroListTable",
        #state.config.aggroabils[state.class],
        3,
        {"Active","Aggro Ability","Edit / Delete"},
        checkboxWidth,
        nameWidth,
        editButtonWidth,
        activedata, 
        buttondata, 
        editdata
    )

    ImGui.EndChild()
end

function ability_lists.DrawHealList()
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

    local totalWidth    = ImGui.GetWindowWidth()
    local checkboxWidth = totalWidth * 0.15
    local nameWidth     = totalWidth * 0.65
    local editButtonWidth = totalWidth * 0.20

    local activedata = {}
    local buttondata = {}
    local editdata   = {}

    for i = #state.config.healabils[state.class], 1, -1 do
        local v = state.config.healabils[state.class][i]
        if v.priority ~= i then v.priority = i end
        if not v then
            write.Error('Healing ability at index', i, 'is nil')
        else
            table.insert(activedata, 1, function() 
                v.active = DrawCheckbox(v.active, "##heal" .. i)
            end)
            table.insert(buttondata, 1, function() 
                ability_lists.DrawDragDrop(v, state.config.healabils, nameWidth, i)
            end)
            table.insert(editdata, 1, function() 
                ability_lists.DrawEditDeleteHeal(v, state.config.healabils)
            end)
        end
    end

    config_editors.DrawTable(
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

function ability_lists.DrawDebuffList()
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

    local totalWidth    = ImGui.GetWindowWidth()
    local checkboxWidth = totalWidth * 0.15
    local nameWidth     = totalWidth * 0.65
    local editButtonWidth = totalWidth * 0.20

    local activedata = {}
    local buttondata = {}
    local editdata   = {}

    for i = #state.config.debuffabils[state.class], 1, -1 do
        local v = state.config.debuffabils[state.class][i]
        if v.priority ~= i then v.priority = i end
        if not v then
            write.Error('Debuff ability at index', i, 'is nil')
        else
            table.insert(activedata, 1, function() 
                v.active = DrawCheckbox(v.active, "##debuff" .. i)
            end)
            table.insert(buttondata, 1, function() 
                ability_lists.DrawDragDrop(v, state.config.debuffabils, nameWidth, i)
            end)
            table.insert(editdata, 1, function() 
                ability_lists.DrawEditDeleteDebuff(v, state.config.debuffabils)
            end)
        end
    end

    config_editors.DrawTable(
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

function ability_lists.DrawBuffList()
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

    local totalWidth    = ImGui.GetWindowWidth()
    local checkboxWidth = totalWidth * 0.15
    local nameWidth     = totalWidth * 0.65
    local editButtonWidth = totalWidth * 0.20

    local activedata = {}
    local buttondata = {}
    local editdata   = {}

    for i = #state.config.buffabils[state.class], 1, -1 do
        local v = state.config.buffabils[state.class][i]
        if v.priority ~= i then v.priority = i end
        if not v then
            write.Error('buff ability at index', i, 'is nil')
        else
            table.insert(activedata, 1, function() 
                v.active = DrawCheckbox(v.active, "##buff" .. i)
            end)
            table.insert(buttondata, 1, function() 
                ability_lists.DrawDragDrop(v, state.config.buffabils, nameWidth, i)
            end)
            table.insert(editdata, 1, function() 
                ability_lists.DrawEditDeleteBuff(v, state.config.buffabils)
            end)
        end
    end

    config_editors.DrawTable(
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

function ability_lists.DrawList()
    -- This was the “general abilities” list from the original code
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

    local totalWidth    = ImGui.GetWindowWidth()
    local checkboxWidth = totalWidth * 0.15
    local nameWidth     = totalWidth * 0.65
    local editButtonWidth = totalWidth * 0.20

    local abilities = state.config.abilities[state.class]

    if ImGui.BeginTable("ListTable", 3, table_flags) then
        ImGui.TableSetupColumn("Active", ImGuiTableColumnFlags.WidthFixed, checkboxWidth)
        ImGui.TableSetupColumn("Name",   ImGuiTableColumnFlags.WidthFixed, nameWidth)
        ImGui.TableSetupColumn("Edit / Delete", ImGuiTableColumnFlags.WidthFixed, editButtonWidth)
        ImGui.TableHeadersRow()

        local alternatingColor = true

        for i = 1, #abilities do
            arrangeAbils()
            local ability = abilities[i]
            if ability.priority ~= i then ability.priority = i end
            ImGui.TableNextRow()

            if alternatingColor then
                ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, ImVec4(0, 0, 0, 1.0))
            else
                ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, ImVec4(0.1, 0.1, 0.1, 1.0))
            end

            ImGui.TableSetColumnIndex(0)
            ability.active, _ = ImGui.Checkbox("##Check" .. ability.priority, ability.active)

            ImGui.TableSetColumnIndex(1)
            if ImGui.Button(ability.name .. " - " .. ability.priority, ImVec2(nameWidth - 30, 0)) then
                -- no-op
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
                        write.Trace("Target Current Name: %s", ability.name)
                        write.Trace("Target Current Priority: %s", ability.priority)
                        write.Trace("Dragitem Current Name: %s", abilities[targetPriority].name)
                        write.Trace("Dragitem Current Priority: %s", abilities[targetPriority].priority)
                        write.Trace("targetPriority Variable: %s", targetPriority)

                        if state.copyMode then
                            local originalPriority = abilities[ability.priority].priority
                            local copiedAbility    = deepcopy(abilities[targetPriority])
                            copiedAbility.priority = originalPriority
                            abilities[ability.priority] = copiedAbility
                            arrangeAbils()
                        else
                            abilities[targetPriority].priority = ability.priority
                            ability.priority = targetPriority
                            arrangeAbils()
                        end
                    end
                end
                ImGui.EndDragDropTarget()
            end

            ImGui.SameLine()
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() - 5)

            config_editors.pickerlist = state.config.abilities
            if ImGui.Button(icons.FA_BULLSEYE .. "##" .. i, ImVec2(25,0)) and Picker then 
                Picker:SetOpen()
                config_editors.pickerAbilIndex = i
            end

            if Picker and i == 1 then 
                Picker:DrawAbilityPicker()
            end

            ImGui.TableSetColumnIndex(2)
            if ImGui.Button("Edit##" .. ability.priority) then
                config_editors.isEditing = true
                style.editIndex = ability.priority
                if ability then
                    if not ability.name then
                        ability.name = 'Blank'
                    end
                    config_editors.dynamicWindowTitle = "Edit Ability - " .. ability.name
                else
                    abilities[style.editIndex] = {}
                    abilities[style.editIndex].name = 'Blank'
                    config_editors.dynamicWindowTitle = "Edit Ability - " .. abilities[style.editIndex].name
                end
            end

            ImGui.SameLine()
            if ImGui.Button("Delete##" .. ability.priority) then
                table.remove(abilities, ability.priority)
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
        local newAbility  = deepcopy(newTemplate)
        newAbility.priority = #abilities + 1
        table.insert(abilities, newAbility)
    end
    ImGui.SameLine()

    state.copyMode, _ = ImGui.Checkbox("Copy Mode", state.copyMode)

    if state.copyMode then
        ImGui.SameLine()
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() - 103)
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() + 30)
        local alpha = 0.5 * (1 + math.sin((style.frameCounter % style.flashInterval) / style.flashInterval * (2 * math.pi)))
        ImGui.TextColored(ImVec4(1,0,0,alpha),"Copy Mode is on!")
    end

    -- The section that draws fancy icons, text, etc.
end

return ability_lists
