local mq = require('mq')
local PackageMan = require('mq/PackageMan')


PackageMan.Require('lua-cjson','cjson')
PackageMan.Require('luasec','ssl')
PackageMan.Require('luasocket','ltn12')
PackageMan.Require('luafilesystem','lfs')

local write = require('utils.Write')
local state = require('utils.state')
local events = require('utils.events')
local binds = require('utils.binds')
local lib = require('utils.lib')
local combat = require('routines.combat')
local navigation = require('routines.navigation')
local abils = require('routines.abils')
local med   = require('routines.med')
local tank = require('routines.tank')
local ui = require('interface.GUI.gui')

local reqplugins = {
    "MQ2DanNet",
    "MQ2Cast",
    "MQ2Melee",
    "MQ2Nav",
    "MQ2Debuffs",
    "MQ2MoveUtils",
    "MQ2Rez"
}

Picker = nil

local function requirePlugins()
    for i, v in ipairs(reqplugins) do
        if not mq.TLO.Plugin(v).IsLoaded() then
            mq.cmdf('/plugin %s load',v)
            mq.delay(100)
            if not mq.TLO.Plugin(v).IsLoaded() then write.Fatal('Error loading plugin: %s',v) end
        end
    end
end


local function doSetup()
    requirePlugins()
    if state.config.returnToCamp then navigation.setCamp() end
    mq.imgui.init(state.class .. '420', ui.main)

    AbilityPicker = require('interface.GUI.AbilityPicker')
    Picker = AbilityPicker.new()
    Picker:InitializeAbilities()

    mq.cmd('/squelch /plugin dannet unload')
    mq.delay(100)
    mq.cmd('/squelch /plugin dannet load')
    mq.cmd('/squelch /melee plugin=0')

    mq.bind('/state',binds.var)
    mq.bind('/pull',binds.pullCmd)
    mq.bind('/config',binds.configcmd)
    mq.bind(string.format('/%s',state.class),binds.bindcallback)
    mq.bind('/420off',function() mq.cmd('/lua stop assist420') end)

    mq.event("failfeign", '#1# has fallen to the ground.', function(_,arg1) 
        if arg1 == mq.TLO.Me.Name() then 
            write.Warn('Feign Failed, standing up...')
            mq.cmd('/stand')
        end 
    end)
    events.init()
    abils.initQueues(state.config.abilities[state.class])
    state.pullIgnores = lib.unZipIgnores()
end

local function doNextAbility(delay)
    local ability, routine = state.nextAbil[1], state.nextAbil[2]
    if ability and routine then
        if routine == 'conditions' then
            local prevabildelay = nil
            prevabildelay = abils.activateAbility(ability,delay)

            if prevabildelay == 0 then
                local queue = nil
                if lib.combatStatus() == 'out' then queue = state.queueOOC else queue = state.queueCombat end
                for i, v in pairs(queue) do
                    if v then
                        local abiltable, _ = abils.processAbility(v)
                        if abiltable then
                            prevabildelay = abils.activateAbility(abiltable)
                            if prevabildelay ~= 0 then return end
                        end
                    end
                end
            end
            
        end
    end
end

local function getCorrectQueue(role)
    if role == 'assist' then
        return function(delay)
            if lib.meleeready() then
                state.updateLoopState()
                navigation.checkNav()
                med.doMed()
                if lib.combatStatus() ~= 'out' then
                    combat.checkCombat()
                end
                doNextAbility(delay)
            end
        end
    end
    if role == 'tank' then
        return function(delay) 
            if lib.meleeready() then
                state.updateLoopState()
                navigation.checkNav()
                med.doMed()
                if lib.combatStatus() ~= 'out' then
                    tank.doTanking()
                end
                doNextAbility(delay)
            end
        end
    end
    if role == 'puller' then
        return function(delay) 
            if lib.meleeready() then
                state.updateLoopState()
                navigation.checkNav()
                navigation.doPulls()
                med.doMed()
                if lib.combatStatus() ~= 'out' then
                    combat.checkCombat()
                end
                doNextAbility(delay)
            end
        end
    end
    if role == 'pullertank' then
        return function(delay) 
            if lib.meleeready() then
                navigation.doPulls()
                state.updateLoopState()
                navigation.checkNav()
                med.doMed()
                if lib.combatStatus() ~= 'out' then
                    combat.checkCombat()
                    abils.doQueue(state.queueCombat,'Combat')
                else
                    abils.doQueue(state.queueOOC,'Out Of Combat')
                end
            end
        end
    end
end

local function main()
    doSetup()
    while true do
        state.activeQueue = getCorrectQueue(state.config.role)
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
                state.activeQueue()
            elseif mq.TLO.Me.Invis() then
                lib.checkFD()
                navigation.checkNav()
                mq.delay(500)
                med.doMed()
                mq.delay(500)
            end
        end
        if Picker then Picker:Reload() end
    end
end

main()