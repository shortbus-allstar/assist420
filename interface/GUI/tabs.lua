-- gui_refactor/tabs.lua

local tabs            = {}
local ImGui           = require('ImGui')
local mq              = require('mq')
local style     = require('interface.GUI.style')
local config_editors  = require('interface.GUI.config_editors')
local ability_lists   = require('interface.GUI.ability_lists')
local state           = require('utils.state')
local lib             = require('utils.lib')
local abils           = require('routines.abils')
local navigation      = require('routines.navigation')
local widgets         = require('interface.GUI.widgets')
local config = require('interface.config')
local events = require('routines.events')

-- icons, animations from original code
local icons     = require('mq.icons')
local anim      = mq.FindTextureAnimation('A_SpellIcons')
local classanim = mq.FindTextureAnimation('A_DragItem')

local newassist = ''
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

local table_flags = bit32.bor(
    ImGuiTableFlags.Hideable,
    ImGuiTableFlags.RowBg,
    ImGuiTableFlags.ScrollY,
    ImGuiTableFlags.BordersOuter,
    ImGuiTableFlags.Resizable
)

local function DrawAbilityHistory()
    local history = state.abilityhistory or {}
    local maxRows = 5
    local rowHeight = 20
    local tableHeight = math.min(#history, maxRows) * rowHeight + 26

    -- Main Table with Name and Target Only
    ImGui.BeginChild("AbilityHistory", ImVec2(0, tableHeight))
    if ImGui.BeginTable("AbilityHistoryTable", 2, ImGuiTableFlags.RowBg) then
        ImGui.TableSetupColumn("Name", ImGuiTableColumnFlags.WidthStretch)
        ImGui.TableSetupColumn("Target", ImGuiTableColumnFlags.WidthStretch)
        ImGui.TableHeadersRow()

        for i = 1, math.min(#history, maxRows) do
            local entry = history[i]
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            ImGui.Text(entry.name)
            ImGui.TableSetColumnIndex(1)
            ImGui.Text(mq.TLO.Spawn(entry.target).CleanName() or "Unknown")
        end

        ImGui.EndTable()
    end
    ImGui.EndChild()

    -- Expand Button

    -- Expanded View Popup
    if ImGui.BeginPopupModal("ExpandedAbilityHistory", nil, ImGuiWindowFlags.AlwaysAutoResize) then
        ImGui.Text("Full Ability History")
        ImGui.Separator()
        ImGui.BeginChild("ExpandedHistory", ImVec2(600, 400))

        -- Expanded Table with Name, Target, and Timestamp
        if ImGui.BeginTable("ExpandedHistoryTable", 3, ImGuiTableFlags.RowBg) then
            ImGui.TableSetupColumn("Name", ImGuiTableColumnFlags.WidthStretch)
            ImGui.TableSetupColumn("Target", ImGuiTableColumnFlags.WidthStretch)
            ImGui.TableSetupColumn("Timestamp", ImGuiTableColumnFlags.WidthStretch)
            ImGui.TableHeadersRow()

            for _, entry in ipairs(history) do
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0)
                ImGui.Text(entry.name)
                ImGui.TableSetColumnIndex(1)
                ImGui.Text(mq.TLO.Spawn(entry.target).CleanName() or "Unknown")
                ImGui.TableSetColumnIndex(2)
                ImGui.Text(lib.formatTimestamp(entry.timestamp))
            end

            ImGui.EndTable()
        end

        ImGui.EndChild()
        if ImGui.Button("Close", ImVec2(100, 30)) then
            ImGui.CloseCurrentPopup()
        end
        ImGui.EndPopup()
    end
end

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

----------------------------------------------------------------------------
-- Because the original code had many local “DrawXYZTab()” functions,
-- we replicate them here, calling out to whichever modules we need.
----------------------------------------------------------------------------

local function DrawTabEnd()
    local windowHeight = ImGui.GetWindowHeight()
    local buttonPosY = windowHeight - style.BUTTON_SIZE - 10  -- Adjust the spacing as needed

    ImGui.SetCursorPosY(buttonPosY)
    local buttonLabel1 = "Save\nConfig"

    if ImGui.Button(buttonLabel1, style.BUTTON_SIZE, style.BUTTON_SIZE) then
        config.saveConfig()
    end

    ImGui.SameLine()
            
    local buttonLabel2 = "Load\nConfig"
    if ImGui.Button(buttonLabel2, style.BUTTON_SIZE, style.BUTTON_SIZE) then
        config.loadConfig()
    end

    ImGui.SameLine()

    if ImGui.Button(string.format('Reload\n     ' .. icons.FA_REFRESH), style.BUTTON_SIZE, style.BUTTON_SIZE) then
        mq.cmd('/multiline ; /lua stop assist420 ; /timed 5 /lua run assist420')
    end
end

function tabs.DrawConsoleTab()
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
            if ImGui.Button(string.format('Resume\n     ' .. icons.FA_PLAY), style.BUTTON_SIZE, style.BUTTON_SIZE) then
                state.paused = false
            end
            ImGui.PopStyleColor()
        else
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(1, 0, 0, 1))
            if ImGui.Button(string.format('Pause\n    ' .. icons.FA_PAUSE), style.BUTTON_SIZE, style.BUTTON_SIZE) then
                state.paused = true
                mq.cmd('/stopcast')
            end
            ImGui.PopStyleColor()
        end
        ImGui.SameLine()

        ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(0, 1, 1, 1))

        if ImGui.Button(string.format('Update\n     ' .. icons.FA_DOWNLOAD), style.BUTTON_SIZE * 2, style.BUTTON_SIZE) then

            local githubver = string.sub(state.githubver, 2)              
            local mqNextDir = mq.luaDir
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

        if ImGui.Button("State\n   " .. icons.FA_FILE_CODE_O , style.BUTTON_SIZE, style.BUTTON_SIZE) then
            style.showTableGUI = not style.showTableGUI
        end

        if state.version ~= tostring(state.githubver) then
            local alpha = 0.5 * (1 + math.sin((style.style.frameCounter % style.flashInterval) / style.flashInterval * (2 * math.pi)))  -- Use a sine function for smooth fading

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
            if ImGui.Button(string.format('  Nav:\n Camp'), style.BUTTON_SIZE, style.BUTTON_SIZE) then
                navigation.clearCamp()
                state.config.returnToCamp = false
                state.config.chaseAssist = true
            end
            ImGui.PopStyleColor()
        elseif state.config.chaseAssist then
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(1, 1, 0, 1))
            if ImGui.Button(string.format('  Nav:\n Chase'), style.BUTTON_SIZE, style.BUTTON_SIZE) then
                navigation.clearCamp()
                state.config.chaseAssist = false
                state.config.returnToCamp = false
            end
            ImGui.PopStyleColor()
        else
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(1, 0, 0, 1))
            if ImGui.Button(string.format('  Nav:\n None'), style.BUTTON_SIZE, style.BUTTON_SIZE) then
                navigation.setCamp()
                state.config.chaseAssist = false
                state.config.returnToCamp = true
            end
            ImGui.PopStyleColor()
        end

        ImGui.SameLine()

        if state.config.movement == 'auto' then
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(0, 1, 0, 1))
            if ImGui.Button(string.format(' Mode:\n Auto'), style.BUTTON_SIZE, style.BUTTON_SIZE) then
                state.config.movement = 'manual'
            end
            ImGui.PopStyleColor()
        elseif state.config.movement == 'manual' then
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(1,0,0,1))
            if ImGui.Button(string.format(' Mode:\nManual'), style.BUTTON_SIZE, style.BUTTON_SIZE) then
                state.config.movement = 'auto'
            end
            ImGui.PopStyleColor()
        end

        ImGui.SameLine()

        if state.config.burn == 'auto' then
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(0, 1, 0, 1))
            if ImGui.Button(string.format(' Burns:\n Auto'), style.BUTTON_SIZE, style.BUTTON_SIZE) then
                state.config.burn = 'manual'
            end
            ImGui.PopStyleColor()
        elseif state.config.burn == 'manual' then
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(1,0,0,1))
            if ImGui.Button(string.format(' Burns:\nManual'), style.BUTTON_SIZE, style.BUTTON_SIZE) then
                state.config.burn = 'auto'
            end
            ImGui.PopStyleColor()
        end

        ImGui.SameLine()

        if not state.config.feignOverride then
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(0, 1, 0, 1))
            if ImGui.Button(string.format(' Feigns:\n Auto'), style.BUTTON_SIZE, style.BUTTON_SIZE) then
                state.config.feignOverride = true
            end
            ImGui.PopStyleColor()
        elseif state.config.feignOverride then
            ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(1,0,0,1))
            if ImGui.Button(string.format(' Feigns:\nManual'), style.BUTTON_SIZE, style.BUTTON_SIZE) then
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
        ImGui.DrawTextureAnimation(anim,style.BUTTON_SIZE,style.BUTTON_SIZE)

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

        ImGui.TextColored(ImVec4(1, 0.8, 0, 1),'# in Abil Queue:')
        ImGui.SameLine()
        ImGui.Text(tostring(#state.queuedabils))
        ImGui.SameLine()
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 2) 
        ImGui.PushStyleColor(ImGuiCol.Text,ImVec4(1,0,0,1))
        if ImGui.Button('Clear##2',ImVec2(40,20)) then
            state.queuedabils = {}
        end
        ImGui.PopStyleColor()

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
        if ImGui.Button('Clear##1',ImVec2(40,20)) then
            state.curequeue = {}
        end
        ImGui.PopStyleColor()

        ImGui.TextColored(ImVec4(1, 0.8, 0, 1),'Role:')
        ImGui.SameLine()
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 2) 

        local roles = { "assist", "puller", "tank", "pullertank"}

        if ImGui.BeginCombo("##role:", state.config.role, ImGuiComboFlags.None) then
            for i, option in ipairs(roles) do
                local isSelected = (i == style.selectedOptionIndex)
                ImGui.PushStyleColor(ImGuiCol.Text, isSelected and ImVec4(0, 1, 1, 1) or ImGui.GetStyleColorVec4(ImGuiCol.Text))
                if ImGui.Selectable(option, isSelected) then
                    style.selectedOptionIndex = i
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

        local options = { "trace", "debug", "info", "warn", "error", "fatal", "help"}

        if ImGui.BeginCombo("##loglevel:", state.config.loglevel, ImGuiComboFlags.None) then
            for i, option in ipairs(options) do
                local isSelected = (i == style.selectedOptionIndex2)
                ImGui.PushStyleColor(ImGuiCol.Text, isSelected and ImVec4(0, 1, 1, 1) or ImGui.GetStyleColorVec4(ImGuiCol.Text))
                if ImGui.Selectable(option, isSelected) then
                    style.selectedOptionIndex2 = i
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
                local isSelected = (i == style.selectedOptionIndextheme)
            
                ImGui.PushStyleColor(ImGuiCol.Text, isSelected and ImVec4(0, 1, 1, 1) or ImGui.GetStyleColorVec4(ImGuiCol.Text))
            
                if ImGui.Selectable(theme.name, isSelected) then
                    style.selectedOptionIndextheme = i
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

        ImGui.TextColored(ImVec4(1, 0.8, 0, 1),'Ability History:')
        ImGui.SameLine()
        if ImGui.Button(icons.FA_EXPAND,20,20) then
            ImGui.OpenPopup("ExpandedAbilityHistory")
        end
        DrawAbilityHistory()
        

        if ImGui.Button("Test", style.BUTTON_SIZE, style.BUTTON_SIZE) then
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

function tabs.DrawCondsTab()
    if ImGui.BeginTabItem(icons.MD_CALL_TO_ACTION .. "   Conditions") then
        -- The original calls “DrawList()” and “DrawEditorWindow()”
        local availableWidth, _ = ImGui.GetContentRegionAvail()
        local columnWidth = availableWidth / 2
        local totalWidth = (45 + 5) * 4 + 290

        local configTabOpen = false
        local abilTabOpen = false
        if ImGui.CollapsingHeader(icons.FA_COG .. "   Config Options") then
            configTabOpen = true
        else
            configTabOpen = false
        end

        if configTabOpen then
            ImGui.Columns(2)
            state.config.doConditions = DrawCheckbox(state.config.doConditions,"Do Conditions")
            ImGui.Columns(1)
        end

        if ImGui.CollapsingHeader(icons.FA_BOOK .. "   Abilities") then
            abilTabOpen = true
        else
            abilTabOpen = false
        end

        if abilTabOpen then
            ability_lists.DrawList()
            config_editors.DrawEditorWindow()
        end
        ImGui.NewLine()

        local startX = (availableWidth - totalWidth) / 2
        if startX < 0 then startX = 0 end 
        ImGui.SetCursorPosX(startX)

        anim:SetTextureCell(51)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)

        ImGui.SameLine()

        anim:SetTextureCell(356)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)

        ImGui.SameLine()
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 11)

        ImGui.PushStyleColor(ImGuiCol.Text, state.activeTheme.hovered)
        ImGui.SetWindowFontScale(4)
        ImGui.Text('Conditions')
        ImGui.PopStyleColor()
        ImGui.SetWindowFontScale(1)

        ImGui.SameLine()

        anim:SetTextureCell(42)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)

        ImGui.SameLine()

        anim:SetTextureCell(38)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)

        DrawTabEnd()
        ImGui.EndTabItem()
    end
end

function tabs.DrawGenTab()
    if ImGui.BeginTabItem(icons.MD_SETTINGS .. "   General") then
        local totalWidth, _ = ImGui.GetContentRegionAvail()
        local columnWidth = totalWidth / 2
    
        ImGui.Columns(2)

        state.config.doAttacking = DrawCheckbox(state.config.doAttacking, "Attacking Enabled")
        state.config.doMedding = DrawCheckbox(state.config.doMedding, "Medding Enabled")
        state.config.combatMed = DrawCheckbox(state.config.combatMed, "Med in Combat")
        state.config.memSpellSetAtStart = DrawCheckbox(state.config.memSpellSetAtStart, "Mem Spell Set At Start")
        state.config.useMQ2Melee = DrawCheckbox(state.config.useMQ2Melee, "Use MQ2Melee")
        state.config.watchdog.enabled = DrawCheckbox(state.config.watchdog.enabled, "Watchdog Enabled")
        ImGui.SameLine()
        DrawInfoIconWithTooltip('Watchdog will detect any non-GUI crash in the script. It will log the error and attempt to restart the script if configured to do so.')
        state.config.watchdog.restart = DrawCheckbox(state.config.watchdog.restart, "Watchdog Restart Toggle")

        state.config.spellSetName = DrawTextInput(state.config.spellSetName, "Spell Set Name", 100)
        ImGui.NewLine()
        ImGui.Text('Assist Type:')
        local asstypes = { "Group MA", "Raid MA", "Custom Name", "Custom ID"}

        if ImGui.BeginCombo("##assisttype", state.config.assistType, ImGuiComboFlags.None) then
            for i, option in ipairs(asstypes) do
                local isSelected = (i == style.selectedOptionIndex3)
                ImGui.PushStyleColor(ImGuiCol.Text, isSelected and ImVec4(0, 1, 1, 1) or ImGui.GetStyleColorVec4(ImGuiCol.Text))
                if ImGui.Selectable(option, isSelected) then
                    style.selectedOptionIndex3 = i
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
                local isSelected = (i == style.selectedOptionIndex4)
                ImGui.PushStyleColor(ImGuiCol.Text, isSelected and ImVec4(0, 1, 1, 1) or ImGui.GetStyleColorVec4(ImGuiCol.Text))
                if ImGui.Selectable(option, isSelected) then
                    style.selectedOptionIndex4 = i
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
        state.config.maxTrackedAbils = DrawNumberInput(state.config.maxTrackedAbils,"Ability History Max # Tracked",{0,math.huge})
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
        state.config.watchdog.restartLimit = DrawNumberInput(state.config.watchdog.restartLimit, "Watchdog Restart Limit",{0,100})
        state.config.watchdog.pulse = DrawNumberInput(state.config.watchdog.pulse, "Watchdog Restart Recover Time", {0, math.huge})

        
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

function tabs.DrawHealTab()
    if ImGui.BeginTabItem(icons.FA_HEART .. "   Heals") then
        local availableWidth, _ = ImGui.GetContentRegionAvail()
        local columnWidth = availableWidth / 2
        local totalWidth = (45 + 5) * 4 + 200


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
            ImGui.NewLine()
            DrawOtherTankListTable()

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
            ImGui.NewLine()
            ImGui.NewLine()
            DrawHotTargetsTable()
            

            ImGui.Columns(1)
        end

        if ImGui.CollapsingHeader(icons.FA_BOOK .. "   Abilities") then
            abilTabOpen = true
        else
            abilTabOpen = false
        end

        if abilTabOpen then
            ability_lists.DrawHealList()
            config_editors.DrawHealEditorWindow()

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
                local alpha = 0.5 * (1 + math.sin((style.frameCounter % style.flashInterval) / style.flashInterval * (2 * math.pi)))
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

        local startX = (availableWidth - totalWidth) / 2
        if startX < 0 then startX = 0 end 
        ImGui.SetCursorPosX(startX)

        -- Draw the section
        anim:SetTextureCell(99)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)

        ImGui.SameLine()

        anim:SetTextureCell(118)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)

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
        ImGui.DrawTextureAnimation(anim, 45, 45)

        ImGui.SameLine()

        anim:SetTextureCell(156)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)
    
        DrawTabEnd()
        ImGui.EndTabItem()
    end
end

function tabs.DrawBuffsTab()
    if ImGui.BeginTabItem(icons.FA_BOOK .. "   Buffs") then

        local availableWidth, _ = ImGui.GetContentRegionAvail()
        local columnWidth = availableWidth / 2
        local totalWidth = (45 + 5) * 4 + 155

        if ImGui.CollapsingHeader(icons.FA_COG .. "   Config Options") then
            configTabOpen = true
        else
            configTabOpen = false
        end

        if configTabOpen then
            local totalWidth, _ = ImGui.GetContentRegionAvail()
            local columnWidth = totalWidth / 2
            ImGui.Columns(2)
            state.config.doBuffs = DrawCheckbox(state.config.doBuffs,"Do Buffs")
            ImGui.NextColumn()
            state.config.buffCheckInterval = DrawNumberInput(state.config.buffCheckInterval,"Buff Check Interval",{0,math.huge})

            ImGui.Columns(1)
        end

        if ImGui.CollapsingHeader(icons.FA_BOOK .. "   Abilities") then
            abilTabOpen = true
        else
            abilTabOpen = false
        end

        if abilTabOpen then

            ability_lists.DrawBuffList()
            config_editors.DrawBuffEditorWindow()

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
                local alpha = 0.5 * (1 + math.sin((style.frameCounter % style.flashInterval) / style.flashInterval * (2 * math.pi)))
                ImGui.TextColored(ImVec4(1,0,0,alpha),"Copy Mode is on!")
            end
        end
    
        ImGui.NewLine()

        local startX = (availableWidth - totalWidth) / 2
        if startX < 0 then startX = 0 end 
        ImGui.SetCursorPosX(startX)

        -- Draw the section
        anim:SetTextureCell(132)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)

        ImGui.SameLine()

        anim:SetTextureCell(123)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)

        ImGui.SameLine()
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 11)

        ImGui.PushStyleColor(ImGuiCol.Text, state.activeTheme.hovered)
        ImGui.SetWindowFontScale(4)
        ImGui.Text('Buffs')
        ImGui.PopStyleColor()
        ImGui.SetWindowFontScale(1)

        ImGui.SameLine()

        anim:SetTextureCell(21)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)

        ImGui.SameLine()

        anim:SetTextureCell(130)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)
        ImGui.NewLine()
        DrawTabEnd()
        ImGui.EndTabItem()
    end
end

function tabs.DrawDebuffsTab()
    if ImGui.BeginTabItem(icons.FA_FIRE .. "   Debuffs") then
        local availableWidth, _ = ImGui.GetContentRegionAvail()
        local columnWidth = availableWidth / 2
        local totalWidth = (45 + 5) * 4 + 225

        if ImGui.CollapsingHeader(icons.FA_COG .. "   Config Options") then
            configTabOpen = true
        else
            configTabOpen = false
        end

        if configTabOpen then
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
        end

        if ImGui.CollapsingHeader(icons.FA_BOOK .. "   Abilities") then
            abilTabOpen = true
        else
            abilTabOpen = false
        end

        if abilTabOpen then
            ability_lists.DrawDebuffList()
            config_editors.DrawDebuffEditorWindow()
    
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
                local alpha = 0.5 * (1 + math.sin((style.frameCounter % style.flashInterval) / style.flashInterval * (2 * math.pi)))
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

        local startX = (availableWidth - totalWidth) / 2
        if startX < 0 then startX = 0 end 
        ImGui.SetCursorPosX(startX)

        -- Draw the section
        anim:SetTextureCell(17)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)

        ImGui.SameLine()

        anim:SetTextureCell(55)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)

        ImGui.SameLine()
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 11)

        ImGui.PushStyleColor(ImGuiCol.Text, state.activeTheme.hovered)
        ImGui.SetWindowFontScale(4)
        ImGui.Text('Debuffs')
        ImGui.PopStyleColor()
        ImGui.SetWindowFontScale(1)

        ImGui.SameLine()

        anim:SetTextureCell(5)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)

        ImGui.SameLine()

        anim:SetTextureCell(72)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)
        ImGui.NewLine()




        DrawTabEnd()
        ImGui.EndTabItem()
    end
end

local newIgnoreValue = ''

function tabs.DrawPullTab()
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

function tabs.DrawTankTab()
    if ImGui.BeginTabItem(icons.FA_SHIELD.. "   Tanking") then
        local availableWidth, _ = ImGui.GetContentRegionAvail()
        local columnWidth = availableWidth / 2
        local totalWidth = (45 + 5) * 4 + 225

        if ImGui.CollapsingHeader(icons.FA_COG .. "   Config Options") then
            configTabOpen = true
        else
            configTabOpen = false
        end

        if configTabOpen then

            ImGui.Columns(2)
            
            state.config.doTanking = DrawCheckbox(state.config.doTanking,"Tanking Enabled")
            state.config.tankTaunting = DrawCheckbox(state.config.tankTaunting,"Taunting Enabled")
            state.config.petTank = DrawCheckbox(state.config.petTank,"Pet Tank Toggle")
            state.config.tankAttackWhilePetTanking = DrawCheckbox(state.config.tankAttackWhilePetTanking,"Attack While Pet Tanking Toggle")

            ImGui.NextColumn()

            state.config.tankEngageRadius = DrawNumberInput(state.config.tankEngageRadius,"Tank Engage Radius")
            state.config.tankPetAttackPct = DrawNumberInput(state.config.tankPetAttackPct,"Attack While Pet Tanking At",{0,100})

            ImGui.Columns(1)
        end

        if ImGui.CollapsingHeader(icons.FA_BOOK .. "   Abilities") then
            abilTabOpen = true
        else
            abilTabOpen = false
        end

        if abilTabOpen then

            ability_lists.DrawAggroList()
            config_editors.DrawAggroEditorWindow()

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
                local alpha = 0.5 * (1 + math.sin((style.frameCounter % style.flashInterval) / style.flashInterval * (2 * math.pi)))
                ImGui.TextColored(ImVec4(1,0,0,alpha),"Copy Mode is on!")
            end
        end

        ImGui.NewLine()

        local startX = (availableWidth - totalWidth) / 2
        if startX < 0 then startX = 0 end 
        ImGui.SetCursorPosX(startX)

        -- Draw the section
        anim:SetTextureCell(1722)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)

        ImGui.SameLine()

        anim:SetTextureCell(1660)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)

        ImGui.SameLine()
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 11)

        ImGui.PushStyleColor(ImGuiCol.Text, state.activeTheme.hovered)
        ImGui.SetWindowFontScale(4)
        ImGui.Text('Tanking')
        ImGui.PopStyleColor()
        ImGui.SetWindowFontScale(1)

        ImGui.SameLine()

        anim:SetTextureCell(1736)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)

        ImGui.SameLine()

        anim:SetTextureCell(90)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)
        ImGui.NewLine()
    
        DrawTabEnd()
        ImGui.EndTabItem()
    end
end

local newKeywordBuffer = ""

function tabs.DrawEventsTab()
    if ImGui.BeginTabItem(icons.FA_FILE_TEXT_O.. "   Events") then
        local availableWidth, _ = ImGui.GetContentRegionAvail()
        local columnWidth = availableWidth / 2
        local totalWidth = (45 + 5) * 4 + 180

        if ImGui.CollapsingHeader(icons.FA_BOOK .. "   Keywords", ImGuiTreeNodeFlags.DefaultOpen) then
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

                    if state.config.keywords[keyword].active == nil then state.config.keywords[keyword].active = true end
                    state.config.keywords[keyword].active = DrawCheckbox(state.config.keywords[keyword].active,"##active")
                    ImGui.SameLine()
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
            ImGui.NewLine()
        end

        if ImGui.CollapsingHeader(icons.FA_BOOK .. "   Custom Events") then
            abilTabOpen = true
        else
            abilTabOpen = false
        end

        if abilTabOpen then

            local eventKeys = {}
            for key in pairs(state.config.customEvents) do
                table.insert(eventKeys, key)
            end
            table.sort(eventKeys)
            --------------------------------------------------------------------------------
            -- Step A: Build the dropdown labels
            --------------------------------------------------------------------------------
            local dropdownLabels = {}
            local keyToLabel = {}
            for _, key in ipairs(eventKeys) do
                local ev = state.config.customEvents[key]
                local displayName = (ev.name and ev.name ~= "") and ev.name or key
                table.insert(dropdownLabels, displayName)
                keyToLabel[key] = displayName
            end

            --------------------------------------------------------------------------------
            -- Begin Two-Column Layout
            --------------------------------------------------------------------------------
            ImGui.Columns(2)  -- 2 columns, no ID, no border

            --------------------------------------------------------------------------------
            -- Column 1
            --------------------------------------------------------------------------------

            ------------------------------------------------------------------------------
            -- Step B: Determine which event is currently selected; show that in the combo
            ------------------------------------------------------------------------------
            local currentLabel = keyToLabel[state.selectedEventKey] or "Select Event"

            currentLabel = DrawDropdown(currentLabel, "Select Event", dropdownLabels, 200)

            -- Convert the chosen display label back to the real key
            local newKey = nil
            for k, label in pairs(keyToLabel) do
                if label == currentLabel then
                    newKey = k
                    break
                end
            end

            if newKey then
                state.selectedEventKey = newKey
            end

            local selectedEvent = state.config.customEvents[state.selectedEventKey]

            ------------------------------------------------------------------------------
            -- If an event is selected, show Delete/Re-init in Column 1
            ------------------------------------------------------------------------------
            if selectedEvent then
                if ImGui.Button("Delete Event") then
                    mq.unevent(state.config.customEvents[state.selectedEventKey].name)
                    state.config.customEvents[state.selectedEventKey] = nil
                    state.selectedEventKey = nil
                end

                ImGui.SameLine()
                if ImGui.Button("Reload Event") then
                    -- Call our helper to re-register just this event
                    events.registerSingleEvent(state.selectedEventKey)
                end

                if selectedEvent.active == nil then
                    selectedEvent.active = true
                end
                local newActive, changedActive = ImGui.Checkbox("Active", selectedEvent.active)
                if changedActive then
                    selectedEvent.active = newActive
                    if newActive then
                        events.registerSingleEvent(state.selectedEventKey)
                    else
                        events.unregisterSingleEvent(state.selectedEventKey)
                    end
                end
            end

            ------------------------------------------------------------------------------
            -- Step D: Create a brand-new event (also in Column 1)
            ------------------------------------------------------------------------------
            ImGui.Spacing()
            ImGui.Text("Create a new Event:")
            state.newEventName = state.newEventName or ""
            state.newEventName = DrawTextInput(state.newEventName, "New Event Name", 200)

            if ImGui.Button("Add New Event") then
                local newKey = "customEvent_" .. (#eventKeys + 1)
                state.config.customEvents[newKey] = {
                    name       = state.newEventName,
                    trigger    = "",
                    abilityName= "None",
                    targetType = "None",
                    cmd        = "",
                    luaID      = ""
                }
                state.selectedEventKey = newKey
                state.newEventName = ""
            end

            --------------------------------------------------------------------------------
            -- Move to Column 2
            --------------------------------------------------------------------------------
            ImGui.NextColumn()

            --------------------------------------------------------------------------------
            -- Column 2
            -- Step C: If there's a selected event, let the user edit it
            --------------------------------------------------------------------------------
            if selectedEvent then
                selectedEvent.name = DrawTextInput(selectedEvent.name or "", "Event Name", 200)
                selectedEvent.trigger = DrawTextInput(selectedEvent.trigger, "Trigger Phrase", 200)

                -- Build your ability list + "None" option
                local abilities = {}
                table.insert(abilities, "None") -- Place this at the top
                local abilityTables = {
                    state.config.abilities,
                    state.config.aggroabils,
                    state.config.healabils,
                    state.config.debuffabils,
                    state.config.buffabils,
                }
                for _, abilityTable in ipairs(abilityTables) do
                    for _, classAbilities in pairs(abilityTable) do
                        for _, ability in ipairs(classAbilities) do
                            table.insert(abilities, ability.name)
                        end
                    end
                end

                selectedEvent.abilityName = DrawDropdown(
                    (selectedEvent.abilityName ~= "" and selectedEvent.abilityName) or "None",
                    "Ability",
                    abilities,
                    200
                )

                -- Let the user specify a command to run
                selectedEvent.cmd = DrawTextInput(selectedEvent.cmd or "", "Command", 200)

                local targetOptions = { "None", "Self", "Group MA", "Group Tank", "MA Target", "Custom Lua ID" }
                selectedEvent.targetType = DrawDropdown(selectedEvent.targetType or "None", "Target Type", targetOptions, 200)

                if selectedEvent.targetType == "Custom Lua ID" then
                    selectedEvent.luaID = DrawTextInput(selectedEvent.luaID or "", "Lua Script", 200)
                end
            end

            --------------------------------------------------------------------------------
            -- End the columns
            --------------------------------------------------------------------------------
            ImGui.Columns(1)
        end

        ImGui.NewLine()

        local startX = (availableWidth - totalWidth) / 2
        if startX < 0 then startX = 0 end 
        ImGui.SetCursorPosX(startX)

        -- Draw the section
        anim:SetTextureCell(1333)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)

        ImGui.SameLine()

        anim:SetTextureCell(1353)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)

        ImGui.SameLine()
        ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 11)

        ImGui.PushStyleColor(ImGuiCol.Text, state.activeTheme.hovered)
        ImGui.SetWindowFontScale(4)
        ImGui.Text('Events')
        ImGui.PopStyleColor()
        ImGui.SetWindowFontScale(1)

        ImGui.SameLine()

        anim:SetTextureCell(807)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)

        ImGui.SameLine()

        anim:SetTextureCell(788)
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 5)
        ImGui.DrawTextureAnimation(anim, 45, 45)
    
        DrawTabEnd()
        ImGui.EndTabItem()
    end
end

return tabs
