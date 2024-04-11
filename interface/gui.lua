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
local frameCounter = 0
local flashInterval = 250 
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
        local windowHeight = ImGui.GetWindowHeight()
        local buttonPosY = windowHeight - 125  -- Adjust the spacing as needed
    
        ImGui.SetCursorPosY(buttonPosY)

        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 12) 

        if state.paused then
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(0, 1, 0, 1))
            if ImGui.Button(string.format('Resume\n     ' .. icons.FA_PLAY), 55, 55) then
                state.paused = false
            end
            ImGui.PopStyleColor()
        else
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(1, 0, 0, 1))
            if ImGui.Button(string.format('Pause\n    ' .. icons.FA_PAUSE), 55, 55) then
                state.paused = true
                mq.cmd('/stopcast')
            end
            ImGui.PopStyleColor()
        end
        ImGui.SameLine()

        ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(0, 1, 1, 1))

        if ImGui.Button(string.format('Update\n     ' .. icons.FA_DOWNLOAD), 55 * 2, 55) then

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


        if ImGui.Button(string.format('Reload\n     ' .. icons.FA_REFRESH), 55, 55) then
            mq.cmd('/multiline ; /lua stop assist420 ; /timed 5 /lua run assist420')
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

        ImGui.NewLine()

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
        ImGui.DrawTextureAnimation(anim,55,55)

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

        ImGui.Columns(1)
        ImGui.EndTabItem()
    end
end

local function DrawCondsTab()
    if ImGui.BeginTabItem("Conditions") then
        DrawList()
        DrawEditorWindow()
        ImGui.EndTabItem()
    end
end

function mod.main()
    if not openGUI then return end
    pushStyle(themes[state.class])
    openGUI, shouldDrawGUI = ImGui.Begin(state.class .. '420', openGUI, ImGuiWindowFlags.None)
    if shouldDrawGUI then
        frameCounter = frameCounter + 1
        ImGui.SetWindowSize(600,800,ImGuiCond.FirstUseEver)
        if ImGui.BeginTabBar("Tabs") then
            DrawConsoleTab()
            DrawCondsTab()
            ImGui.EndTabBar()
        end
    end

    -- Make sure to call popStyles() and ImGui.End() even if shouldDrawGUI is false
    popStyles()
    ImGui.End()
end



return mod





