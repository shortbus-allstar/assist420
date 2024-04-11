local mq = require('mq')
local write = require('utils.Write')
local state = require('utils.state')
local nav = require('routines.navigation')
local navigation = require('routines.navigation')

local mod = {}

function mod.bindcallback(arg1,arg2)
    if arg1 == 'camp' then 
        if not arg2 then
            if state.config.returnToCamp == false then
                write.Help('Camphere: On')
                state.config.returnToCamp = true
                state.config.chaseAssist = false
                nav.setCamp()
            elseif state.config.returnToCamp == true then 
                write.Help('Camphere: Off')
                state.config.returnToCamp = false
            end
        elseif arg2 == 'On' or arg2 == 'on' then
            write.Help('Camphere: On')
            state.config.returnToCamp = true
            state.config.chaseAssist = false
            nav.setCamp()
        elseif arg2 == 'Off' or arg2 == 'off' then
            write.Help('Camphere: Off')
            state.config.returnToCamp = false
        end
    end

    if arg1 == 'chase' then 
        if not arg2 then
            if state.config.chaseAssist == false then
                write.Help('Chase: On')
                state.config.chaseAssist = true
                state.config.returnToCamp = false
            elseif state.config.chaseAssist == true then 
                write.Help('Chase: Off')
                state.config.chaseAssist = false
            end
        elseif arg2 == 'On' or arg2 == 'on' then
            write.Help('Chase: On')
            state.config.returnToCamp = false
            state.config.chaseAssist = true
        elseif arg2 == 'Off' or arg2 == 'off' then
            write.Help('Chase: Off')
            state.config.chaseAssist = false
        end
    end

    if arg1 == 'movement' then 
        if not arg2 then
            if state.config.movement == 'auto' then
                write.Help('Movement: Manual')
                state.config.movement = 'manual'
            elseif state.config.movement == 'manual' then 
                write.Help('Movement: Auto')
                state.config.movement = 'auto'
            end
        elseif arg2 == 'Auto' or arg2 == 'auto' then
            write.Help('Movement: Auto')
            state.config.movement = 'auto'
        elseif arg2 == 'Manual' or arg2 == 'manual' then
            write.Help('Movement: Manual')
            state.config.movement = 'manual'
        end
    end

    if arg1 == 'burn' then 
        if not arg2 then
            if state.config.burn == 'auto' then
                write.Help('Burn: Manual')
                state.config.burn = 'manual'
            elseif state.config.burn == 'manual' then 
                write.Help('Burn: Auto')
                state.config.burn = 'auto'
            end
        elseif arg2 == 'Auto' or arg2 == 'auto' then
            write.Help('Burn: Auto')
            state.config.burn = 'auto'
        elseif arg2 == 'Manual' or arg2 == 'manual' then
            write.Help('Burn: Manual')
            state.config.burn = 'manual'
        end
    end

    if arg1 == 'pause' then 
        if not arg2 then
            if state.paused == true then
                write.Help('Unpausing')
                state.paused = false
            elseif state.paused == false then 
                write.Help('Pausing')
                state.paused = true
            end
        elseif arg2 == 'On' or arg2 == 'on' then
            write.Help('Pausing')
            state.paused = true
        elseif arg2 == 'Off' or arg2 == 'off' then
            write.Help('Unpausing')
            state.paused = false
        end
    end

    if arg1 == 'addignore' then
        navigation.addToIgnore(mq.TLO.Target.ID())
    end
end

function mod.var(key, newValue)
    local parts = {}
    for part in key:gmatch("[^.]+") do
        table.insert(parts, part)
    end

    local currentTable = state
    for i, part in ipairs(parts) do
        if currentTable[part] == nil then
            print("\atError: Invalid key or nested structure.")
            return
        end

        if i == #parts then
            -- Print current value
            print("\atCurrent value: \ar", currentTable[part])

            -- Update the value if a new value is provided
            if newValue then
                -- Convert newValue based on the original value's type
                local originalType = type(currentTable[part])

                if originalType == "boolean" then
                    currentTable[part] = newValue == "true"
                elseif originalType == "number" then
                    currentTable[part] = tonumber(newValue) or currentTable[part]
                else
                    currentTable[part] = newValue
                end

                print("\atValue updated to: \ar", currentTable[part])
            end
        else
            currentTable = currentTable[part]
        end
    end
end

return mod