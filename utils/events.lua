local mq = require('mq')
local state = require('utils.state')
local write = require('utils.Write')
local navigation = require('routines.navigation')

local mod = {}

local function replaceArgs(inputString, ...)
    local args = {...}
    local resultString = inputString:gsub("#(%d)#", function(num)
        local argIndex = tonumber(num)
        if argIndex and args[argIndex] then
            return args[argIndex]
        else
            return "#" .. num .. "#"
        end
    end)
    return resultString
end

function mod.init()
    mq.event('interrupted', '#*#Your #1#spell is interrupted#*#', mod.interruptcallback)
    mq.event('fizzle', '#*#Your #1#spell fizzles#*#', mod.interruptcallback)
    mq.event('eventDead', 'You died.', mod.eventDead)
    mq.event('eventDeadSlain', 'You have been slain by#*#', mod.eventDead)
    mq.event('zoned', '#*#Returning to Bind Location#*#', mod.notDead)
    mq.event('zoned2', 'You have entered#*#.', mod.zoned)
    mq.event('rezzed', 'You regain some experience from resurrection.', mod.notDead)
    for i, _ in ipairs(state.config.events) do
        if state.config.events[i] ~= state.config.events.newevent then
            mod.addevents(state.config.events[i].trig,state.config.events[i].cmd,state.config.events[i].cmddelay,state.config.events[i].loopdelay)
        end
    end
end

function mod.addevents(trig,cmd,cmddel,loopdel)
    mq.event(cmd, trig, function(line,arg1,arg2,arg3,arg4)
        local newcmd = replaceArgs(cmd,arg1,arg2,arg3,arg4)
        if not state.eventtimers[trig] or ((mq.gettime() - tonumber(state.eventtimers[trig])) > tonumber(cmddel)) then
            mq.cmd(newcmd)
            state.eventtimers[trig] = mq.gettime()
            state.paused = true
            mq.delay(loopdel)
            state.paused = false
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
    state.campxloc, state.campyloc, state.campzloc = navigation.clearCamp()
    mq.flushevents()
end

function mod.zoned()
    state.campxloc, state.campyloc, state.campzloc = navigation.clearCamp()
end

mod.interruptcallback = function(line, arg1)
    write.Debug('Interrup Event')
    state.interrupted = true
end

return mod