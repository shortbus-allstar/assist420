local mq = require('mq')
local state = require('utils.state')
local write = require('utils.Write')
local lib = require('utils.lib')

local navigation = require('routines.navigation')

local mod = {}

function mod.init()
    mq.event('interrupted', '#*#Your #1#spell is interrupted#*#', mod.interruptcallback)
    mq.event('fizzle', '#*#Your #1#spell fizzles#*#', mod.interruptcallback)
    mq.event('newgroupmem', '#1# has joined the group.', mod.newgroupmem)
    mq.event('eventDead', 'You died.', mod.eventDead)
    mq.event('eventCannotRez', '#*#This corpse cannot be resurrected#*#', mod.cannotRez)
    mq.event('eventCannotRez2', '#*#You were unable to restore the corpse to life, but you may have success with a later attempt.#*#', mod.cannotRez)
    mq.event('eventDeadSlain', 'You have been slain by#*#', mod.eventDead)
    mq.event('rezzed2', '#*#Returning to Bind Location#*#', mod.notDead)
    mq.event('zoned2', 'You have entered #1#.', mod.finishZoning)
    mq.event('zoned', 'LOADING, PLEASE WAIT...', mod.zoning)
    mq.event('rezzed', 'You regain some experience from resurrection.', mod.notDead)
    mq.event('KeywordBuffRequest', '#1# tells you, \'#2#\'', mod.handleKeywordRequest)
    for _, v in pairs(state.config.customEvents) do
        if v.name == "" or v.trigger == '' or not v.active then goto next end
        mq.event(v.name, v.trigger, function(_, ...)
            local args = { ... }
    
            ------------------------------------------------------------------------
            -- Determine the target ID (if needed for abilities)
            ------------------------------------------------------------------------
            local targetID = nil
            if v.targetType == "Self" then
                targetID = mq.TLO.Me.ID()
            elseif v.targetType == "None" then 
                targetID = mq.TLO.Target.ID()
            elseif v.targetType == "Group Tank" then
                targetID = mq.TLO.Group.MainTank.ID()
            elseif v.targetType == "Group Assist" then
                targetID = mq.TLO.Group.MainAssist.ID()
            elseif v.targetType == "MA Target" then
                targetID = mq.TLO.Me.GroupAssistTarget.ID()
            elseif v.targetType:match("#%d#") then
                -- If the user typed something like "#1#", interpret that as the first arg
                local argIndex = tonumber(v.targetType:match("#(%d+)#"))
                local argValue = args[argIndex]
                if argValue then
                    local spawn = mq.TLO.Spawn(argValue)
                    if spawn then
                        targetID = spawn.ID()
                    end
                end
            elseif v.targetType == "Custom Lua ID" then
                -- Evaluate whatever the user put in v.luaID as a chunk of code returning a targetID
                local func, err = load("return " .. v.luaID, nil, "t", { mq = mq })
                if func then
                    local success, result = pcall(func)
                    if success then
                        targetID = result
                    end
                end
            end
    
            ------------------------------------------------------------------------
            -- 1) If abilityName != "None", queue the ability
            ------------------------------------------------------------------------
            if v.abilityName and v.abilityName ~= "" and v.abilityName ~= "None" then
                if targetID then
                    local abils = require('routines.abils')
                    abils.queueAbility(v.abilityName, _, targetID)
                end
            end

    
            ------------------------------------------------------------------------
            -- 2) If cmd is set, run mq.cmd(...) after replacing #1#, #2#, etc.
            ------------------------------------------------------------------------
            if v.cmd and v.cmd ~= "" then
                local outputCmd = v.cmd
                for i, argVal in ipairs(args) do
                    -- Replace e.g. "#1#" with the first argVal, "#2#" with the second, etc.
                    local pattern = "#" .. i .. "#"
                    outputCmd = outputCmd:gsub(pattern, argVal)
                end
                mq.cmd(outputCmd)
            end
        end)
        ::next::
    end
    
end

function mod.unregisterSingleEvent(key)
    local v = state.config.customEvents[key]
    if not v then return end
    if v.name and v.name ~= "" then
        mq.unevent(v.name)
    end
end

-- Put this somewhere in your script so it’s accessible (e.g. top-level function)
function mod.registerSingleEvent(key)
    local v = state.config.customEvents[key]
    if not v then return end

    if not v.active then
        return
    end

    -- Optional: remove old event if you want to avoid duplicate registrations
    mq.unevent(v.name)

    mq.event(v.name, v.trigger, function(_, ...)
        local args = { ... }
        local targetID = nil

        -- 1) Figure out the target
        if v.targetType == "Self" then
            targetID = mq.TLO.Me.ID()
        elseif v.targetType == "None" then 
            targetID = mq.TLO.Target.ID()
        elseif v.targetType == "Group Tank" then
            targetID = mq.TLO.Group.MainTank.ID()
        elseif v.targetType == "Group Assist" then
            targetID = mq.TLO.Group.MainAssist.ID()
        elseif v.targetType == "MA Target" then
            targetID = mq.TLO.Me.GroupAssistTarget.ID()
        elseif v.targetType:match("#%d#") then
            local argIndex = tonumber(v.targetType:match("#(%d+)#"))
            local argValue = args[argIndex]
            if argValue then
                local spawn = mq.TLO.Spawn(argValue)
                if spawn then
                    targetID = spawn.ID()
                end
            end
        elseif v.targetType == "Custom Lua ID" then
            local func, err = load("return " .. v.luaID, nil, "t", { mq=mq })
            if func then
                local success, result = pcall(func)
                if success then
                    targetID = result
                end
            end
        end

        -- 2) Queue ability if not "None"
        if v.abilityName and v.abilityName ~= "" and v.abilityName ~= "None" then
            if targetID then
                local abils = require('routines.abils')
                abils.queueAbility(v.abilityName, _, targetID)
            end
        end

        -- 3) Run command if specified, replacing #1#, #2# placeholders
        if v.cmd and v.cmd ~= "" then
            local outputCmd = v.cmd
            for i, argVal in ipairs(args) do
                outputCmd = outputCmd:gsub("#"..i.."#", argVal or "")
            end
            mq.cmd(outputCmd)
        end
    end)
end


function mod.notDead()
    state.dead = false
    mq.delay(500)
    state.paused = false
    mq.flushevents()
    write.Info('Unpausing')
end

function mod.eventDead()
    state.dead = true
    write.Info('You greened out dawg. Pausing your shit')
    mq.flushevents()
end

function mod.finishZoning(line, arg1)
    write.Info('Zoned Event')
    if arg1 == "the Drunken Monkey stance adequately" then 
        return 
    else
        state.pullIgnores = lib.unZipIgnores()
    end
end

function mod.newgroupmem(line, arg1)
    lib.initToon(mq.TLO.Spawn(arg1))
end

function mod.zoning()
    state.campxloc, state.campyloc, state.campzloc = navigation.clearCamp()
end

function mod.cannotRez()
    write.Info('Cannot rez corpse')
    state.corpsetimers[mq.TLO.Target.ID()] = mq.gettime() + 50000
end

mod.interruptcallback = function(line, arg1)
    write.Trace('Interrup Event')
    state.interrupted = true
end

function mod.handleKeywordRequest(line, senderName, message)
    local lowerMessage = message:lower()
    local matchedKeyword = nil

    -- Find the first keyword that occurs in the message
    for keyword, v in pairs(state.config.keywords) do
        if lowerMessage:find(keyword, 1, true) and v.active then
            matchedKeyword = keyword
            break
        end
    end

    if not matchedKeyword then
        write.Debug(("No matching keyword found in message: %s"):format(message))
        return
    end

    local entry = state.config.keywords[matchedKeyword]
    if not entry then
        write.Debug(("No configuration entry for found keyword: %s"):format(matchedKeyword))
        return
    end

    -- Determine sender ID
    local senderSpawn = mq.TLO.Spawn(senderName)
    local senderID = senderSpawn() and senderSpawn.ID() or 0
    if senderID == 0 then
        write.Warn("Unable to find sender ID for "..senderName..", cannot queue buffs/cures.")
        return
    end

    local buffsToQueue = {}
    for _, buffName in ipairs(entry.buffs or {}) do
        local abilIndex = lib.findBuffAbility(buffName)
        if abilIndex then
            table.insert(buffsToQueue, state.config.buffabils[state.class][abilIndex])
        else
            write.Debug("No buff ability found for: "..buffName)
        end
    end

    local curesToQueue = {}
    for _, cureName in ipairs(entry.cures or {}) do
        local abilIndex = lib.findCureAbility(cureName)
        if abilIndex then
            table.insert(curesToQueue, state.config.healabils[state.class][abilIndex])
        else
            write.Debug("No cure ability found for: "..cureName)
        end
    end

    if #buffsToQueue == 0 and #curesToQueue == 0 then
        write.Info("No abilities found for keyword: "..matchedKeyword)
        return
    end

    state.buffqueue = state.buffqueue or {}
    state.curequeue = state.curequeue or {}

    -- Instead of inserting all buffs/cures as arrays, insert each ability individually
    for _, buffAbil in ipairs(buffsToQueue) do
        table.insert(state.buffqueue, {requesterID=senderID, ability=buffAbil})
    end

    for _, cureAbil in ipairs(curesToQueue) do
        table.insert(state.curequeue, {requesterID=senderID, ability=cureAbil})
    end

    write.Info(("Queued %d buffs and %d cures for keyword '%s' requested by %s"):format(#buffsToQueue, #curesToQueue, matchedKeyword, senderName))
end


return mod