local mq = require('mq')
local write = require('utils.Write')
local state = require('utils.state')
local events = require('utils.events')
local binds = require('utils.binds')
local lib = require('utils.lib')
local combat = require('routines.combat')
local navigation = require('routines.navigation')
local abils = require('routines.abils')
local med   = require('routines.med')
local ui = require('interface.gui')

if state.config.returnToCamp then navigation.setCamp() end

mq.imgui.init(state.class .. '420', ui.main)

mq.bind('/state',binds.var)
mq.bind(string.format('/%s',state.class),binds.bindcallback)
mq.bind('/420off',function() mq.cmd('/lua stop assist420') end)

local function main()
    events.init()
    abils.initQueues(state.config.abilities[state.class])
    if tostring(state.config.returnToCamp) == 'On' then state.campxloc, state.campyloc, state.campzloc = navigation.setCamp() end

    while true do
        state.updateLoopState()
        write.Trace('Main Loop')
        if state.dead == true then 
            mq.doevents('zoned')
            mq.delay(100)
            mq.doevents('rezzed')
            mq.delay(100)
        end

        if not state.paused and lib.inControl() and not mq.TLO.Me.Shrouded() then
            if not mq.TLO.Me.Invis() and not lib.isBlockingWindowOpen() then
                lib.checkFD()
                if lib.meleeready() then
                    navigation.doPulls()
                    state.updateLoopState()
                    navigation.checkNav()
                    med.doMed()
                    if lib.combatStatus ~= 'out' then
                        combat.checkCombat()
                        abils.doQueue(state.queueCombat)
                    else
                        abils.doQueue(state.queueOOC)
                    end
                end
            elseif mq.TLO.Me.Invis() then
                lib.checkFD()
                navigation.checkNav()
                mq.delay(500)
                med.doMed()
                mq.delay(500)
            end
        end
    end
end

main()