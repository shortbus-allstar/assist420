local mq = require('mq')
local write = require('utils.Write')
local conf = require('interface.config')

local state = {
    campxloc = nil,
    campyloc = nil,
    campzloc = nil,
    class = mq.TLO.Me.Class.ShortName(),
    config = conf.getConfig(),
    cooldowns = {},
    dead = false,
    facetimer = 0,
    feigned = false,
    feignOverride = false,
    loglevel = 'debug',
    medding = false,
    paused = false,
    pulling = false,
    pullIgnores = {},
    queueCombat = {},
    queueOOC = {}
}

function state.updateLoopState()
    write.Trace('Update Loop State Function')
    if mq.TLO.MacroQuest.GameState() ~= 'INGAME' then
        write.Help('Not in game, putting the lighter down...')
        mq.exit()
    end
    state.dead = mq.TLO.Me.Dead()
    if state.dead == true then 
        state.paused = true
        return
    end
    write.loglevel = state.loglevel
    mq.doevents()
end

return state