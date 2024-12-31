--------------------------------------------------------------------------------
--  assist420.lua
--  Single-script approach that restarts on runtime errors.
--------------------------------------------------------------------------------
local mq = require('mq')
local PackageMan = require('mq/PackageMan')

StartTime = mq.gettime()

PackageMan.Require('lua-cjson','cjson')
PackageMan.Require('luasec','ssl')
PackageMan.Require('luasocket','ltn12')
PackageMan.Require('luafilesystem','lfs')

local write = require('utils.Write')
local state = require('utils.state')
local lib = require('utils.lib')

local events = require('routines.events')
local combat = require('routines.combat')
local navigation = require('routines.navigation')
local abils = require('routines.abils')
local heals = require('routines.heal')
local debuffs = require('routines.debuff')
local buffs = require('routines.buff')
local med   = require('routines.med')
local tank = require('routines.tank')

local conf = require('interface.config')
local binds = require('interface.binds')
local tlo = require('interface.tlo')
local ui = require('interface.GUI.gui_main')

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

--------------------------------------------------------------------------------
-- Require needed MQ plugins
--------------------------------------------------------------------------------
local function requirePlugins()
    for i, v in ipairs(reqplugins) do
        if not mq.TLO.Plugin(v).IsLoaded() then
            mq.cmdf('/plugin %s load', v)
            mq.delay(100)
            if not mq.TLO.Plugin(v).IsLoaded() then
                write.Fatal('Error loading plugin: %s', v)
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Set up your "watchdog" if state.config.watchdog.enabled is true
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- doSetup() function: plugin checks, event bindings, etc.
--------------------------------------------------------------------------------
local function doSetup()
    requirePlugins()
    -- Set the camp (if configured)
    if state.config.returnToCamp then
        navigation.setCamp()
    end

    -- Initialize your UI
    mq.imgui.init(state.class .. '420', ui.main)

    AbilityPicker = require('interface.GUI.AbilityPicker')
    Picker = AbilityPicker.new()
    Picker:InitializeAbilities()

    -- Reload DanNet plugin quietly
    mq.cmd('/squelch /plugin dannet unload')
    mq.delay(100)
    mq.cmd('/squelch /plugin dannet load')

    -- MQ2Melee plugin logic
    if not state.config.useMQ2Melee then 
        mq.cmd('/squelch /melee plugin=0')
    else
        mq.cmd('/squelch /melee plugin=1')
        mq.cmd('/squelch /melee stickmode=2')
    end

    -- Default MQ2 /assist off
    mq.cmd('/squelch /assist off')

    -- Your various slash-bind commands
    mq.bind('/state', binds.var)
    mq.bind('/backoff', binds.backoff)
    mq.bind('/pull', binds.pullCmd)
    mq.bind('/config', binds.configcmd)
    mq.bind(string.format('/%s', state.class), binds.bindcallback)
    mq.bind('/420off', function() mq.cmd('/lua stop assist420') end)

    -- /queue command
    mq.bind('/queue', function(abilityName, ...)
        local target = table.concat({...}, " ")
        if not abilityName or abilityName == "" or not target or target == "" then
            write.Warn("Usage: /queue [ability name] [target]")
            return
        end
        abils.queueAbility(abilityName, target)
    end)

    -- /burn command
    mq.bind('/burn', function()
        for _, v in ipairs(state.config.abilities[state.class]) do
            if v.burn then
                mq.cmdf('/queue "%s" "%s"', v.name, mq.TLO.Target.ID())
            end
        end
    end)

    -- Feign death event
    mq.event("failfeign", '#1# has fallen to the ground.', function(_, arg1)
        if arg1 == mq.TLO.Me.Name() then 
            write.Warn('Feign Failed, standing up...')
            mq.cmd('/stand')
        end
    end)

    -- Add your custom TLO
    mq.AddTopLevelObject('State', tlo.stateTLO)

    -- Initialize your sub-systems
    lib.initObservers()
    events.init()
    abils.initQueues(state.config.abilities[state.class])

    -- Load a spell set if configured
    if state.config.memSpellSetAtStart == true then
        mq.cmdf('/memspellset %s', state.config.spellSetName)
        mq.delay(100)
        repeat
            mq.delay(10)
        until mq.TLO.Window('SpellBookWnd')() == "FALSE"
    end
end

--------------------------------------------------------------------------------
-- doNextAbility(): handle queued abilities, conditions, debuffs, etc.
--------------------------------------------------------------------------------
local function doNextAbility(delay)
    local ability, routine = state.nextAbil[1], state.nextAbil[2]
    if not ability or not routine then return end

    if routine == 'queue' then
        -- First, process all instant-cast abilities
        for i = #state.queuedabils, 1, -1 do
            local abil = state.queuedabils[i]
            local targetID = abil.tarid
            local type = abil.type

            if abils.processQueueAbil(abil) and mq.TLO.Target.ID() == targetID then
                local isInstant = false
                if type == "Cmd" or type == "Skill" then
                    isInstant = true
                elseif type == "Spell"
                  and mq.TLO.Me.Gem(mq.TLO.Spell(abil.name).RankName() or "")()
                  and mq.TLO.Spell(mq.TLO.Spell(abil.name).RankName() or "").MyCastTime() == 0 then
                    isInstant = true
                elseif type == "Disc"
                  and mq.TLO.Spell(mq.TLO.Spell(abil.name).RankName() or "").MyCastTime() == 0 then
                    isInstant = true
                elseif type == "AA"
                  and mq.TLO.Me.AltAbility(abil.name).Spell.MyCastTime() == 0 then
                    isInstant = true
                elseif type == "Item"
                  and mq.TLO.FindItem(abil.name).CastTime() == 0 then
                    isInstant = true
                end

                if isInstant then
                    abils.activateQueuedAbility(abil)
                    table.remove(state.queuedabils, i)
                end
            end
        end

        -- Then, process the main queued ability
        if abils.processQueueAbil(ability) then
            abils.activateQueuedAbility(ability)
        end
    end

    if routine == 'conditions' then
        local prevabildelay = abils.activateAbility(ability, delay)
        if prevabildelay == 0 then
            local queue = (lib.combatStatus() == 'out') and state.queueOOC or state.queueCombat
            for _, v in pairs(queue) do
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

    if routine == 'heals' then
        heals.activateHeal(ability, delay, ability.cure, ability.rez, ability.hot)
    end

    if routine == 'charm' or routine == 'charmBreak' then
        local abiltable, _ = abils.processCharm(ability)
        if abiltable then
            abils.activateCharm(ability)
        end
    end

    if routine == 'buffs' then
        buffs.activateBuff(ability)
    end

    if routine == 'debuffs' then
        debuffs.activateDebuff(ability)
    end
end

--------------------------------------------------------------------------------
-- getCorrectQueue(): returns the function that runs your logic based on role
--------------------------------------------------------------------------------
local function getCorrectQueue(role)
    if role == 'assist' then
        return function(delay)
            if lib.meleeready() then
                state.updateLoopState()
                navigation.checkNav()
                med.doMed()
                if not lib.passiveZone(mq.TLO.Zone.ID()) then
                    if lib.combatStatus() ~= 'out' then
                        combat.checkCombat()
                    end
                    doNextAbility(delay)
                end
            end
        end
    elseif role == 'tank' then
        return function(delay)
            if lib.meleeready() then
                state.updateLoopState()
                navigation.checkNav()
                med.doMed()
                if not lib.passiveZone(mq.TLO.Zone.ID()) then
                    if lib.combatStatus() ~= 'out' then
                        tank.doTanking()
                    end
                    doNextAbility(delay)
                end
            end
        end
    elseif role == 'puller' then
        return function(delay)
            if lib.meleeready() then
                state.updateLoopState()
                navigation.checkNav()
                med.doMed()
                if not lib.passiveZone(mq.TLO.Zone.ID()) then
                    navigation.doPulls()
                    if lib.combatStatus() ~= 'out' then
                        combat.checkCombat()
                    end
                    doNextAbility(delay)
                end
            end
        end
    elseif role == 'pullertank' then
        return function(delay)
            if lib.meleeready() then
                state.updateLoopState()
                navigation.checkNav()
                med.doMed()
                if not lib.passiveZone(mq.TLO.Zone.ID()) then
                    navigation.doPulls()
                    if lib.combatStatus() ~= 'out' then
                        tank.doTanking()
                    end
                    doNextAbility(delay)
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- assist420Main(): Your original "main()" logic, renamed for clarity
--                  Wrap it in a pcall so runtime errors don't kill the script.
--------------------------------------------------------------------------------
local function assist420Loop()
    -- 2) Enter the main loop. This loop never ends unless you zone or break it.
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

        if Picker then
            Picker:Reload()
        end
    end
end


--------------------------------------------------------------------------------
-- runScriptWithWatchdog(): pcall loop to catch any errors in assist420Main().
--                          If a runtime error occurs, log it and restart.
--------------------------------------------------------------------------------
local function runScriptWithWatchdog()
    while true do
        local ok, errMsg = pcall(assist420Loop)
        if not ok then
            -- We *caught* an unhandled error
            write.Watchdog('assist420 crashed with error: %s', errMsg)

            -- Decide if we restart or stop
            state.watchdog.restartCount = state.watchdog.restartCount + 1
            if state.watchdog.restartCount <= state.config.watchdog.restartLimit and state.config.watchdog.restart then
                write.Watchdog('Restart attempt %d of %d. Waiting %dms...', state.watchdog.restartCount, state.config.watchdog.restartLimit, state.config.watchdog.pulse)
                mq.delay(state.config.watchdog.pulse)
                abils.initQueues(state.config.abilities[state.class])
            else
                write.Watchdog('Reached the restart limit (%d). Not restarting.', state.config.watchdog.restartLimit)
                break
            end
        else
            -- If assist420Main() returns normally (unlikely in an infinite loop),
            -- we exit the loop.
            write.Info('assist420 exited cleanly.')
            break
        end
    end
end

--------------------------------------------------------------------------------
-- Finally, start the script by calling runScriptWithWatchdog().
-------------------------------------------------------------------------------
doSetup()
if state.config.watchdog.enabled then 
    runScriptWithWatchdog() 
else
    assist420Loop()
end
