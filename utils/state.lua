local mq = require('mq')
local write = require('utils.Write')
local conf = require('interface.config')
local https = require("ssl.https")
local ltn12 = require("ltn12")

-- Function to retrieve the latest GitHub version
local function getGitHubVersion()
    local url = "https://api.github.com/repos/shortbus-allstar/assist420/releases"
    local response = {}

    local _, status = https.request{
        url = url,
        method = "GET",
        sink = ltn12.sink.table(response),
    }

    if status == 200 then
        local responseBody = table.concat(response)

        local json = require("cjson")
        local releases = json.decode(responseBody)

        -- Check if there are releases
        if #releases > 0 then
            -- Retrieve the tag name of the latest release
            return releases[1].tag_name
        else
            write.Trace('No releases found')
            return 'No releases found'
        end
    else
        write.Trace('Request failed')
        return 'Request failed'
    end
end


local state = {
    abilityhistory = {},
    assistSpawn = nil,
    backoff = false,
    buffqueue = {},
    campxloc = nil,
    campyloc = nil,
    campzloc = nil,
    casting = false,
    class = mq.TLO.Me.Class.ShortName(),
    canmem = true,
    charmbreak = false,
    chaseSpawn = nil,
    config = conf.getConfig(),
    cooldowns = {},
    corpsetimers = {},
    curequeue = {},
    currentpet = nil,
    dead = false,
    debufftimer = 0,
    facetimer = 0,
    githubver = getGitHubVersion(),
    hotTimers = {},
    maname = nil,
    medding = false,
    needInitAggro = true,
    nextAbil = {
        [1] = nil,
        [2] = nil
    },
    outAssistTarTimer = 0,
    paused = false,
    pulling = false,
    pullIgnores = {},
    queueCombat = {},
    queuedabils = {},
    queueOOC = {},
    scriptStartTime = os.time(), -- System time when the script started
    scriptStartMilliseconds = mq.gettime(), -- Millisecond time when the script started
    version = 'v1.0.3-beta',
}

local function doConditions()
    write.Trace('\arDo Conditions')
    local lib = require('utils.lib')
    local abils = require('routines.abils')
    local abiltable = nil
    local routine = nil
    if lib.combatStatus() ~= 'out' then
        abiltable, routine = abils.doQueue(state.queueCombat,'Combat')
    else
        abiltable, routine = abils.doQueue(state.queueOOC,'Out Of Combat')
    end
    if abiltable and routine then return abiltable, routine end
    return nil, nil
end

local function getRoutineOrder()
    local routines = {
    }
    for k, v in pairs(state.config.routines) do
        routines[v] = k
    end
    if #routines ~= 5 then write.Fatal('Number of routines was declared incorrectly, make sure the routines are defined in your config file and try again.') end
    return routines
end

local function processConditionRoutine()
    local abiltable = nil
    local routine = nil
    local queue = nil
    local abils = require('routines.abils')
    local lib = require('utils.lib')
    if lib.combatStatus() == 'out' then queue = state.queueOOC else queue = state.queueCombat end
    for i, v in pairs(queue) do
        if v then
            abiltable, routine = abils.processAbility(v)
            if abiltable and routine then
                if abiltable.type == 'Skill' or abiltable.type == 'Cmd' then abils.activateAbility(abiltable) end
                if abiltable.type == 'Disc' and mq.TLO.Spell(mq.TLO.Spell(abiltable.name).RankName() or 'nil').MyCastTime() == 0 then abils.activateAbility(abiltable) end
                if abiltable.type == 'AA' and mq.TLO.Spell(abiltable.name).MyCastTime() == 0 then abils.activateAbility(abiltable) end
                if abiltable.type == 'Item' and mq.TLO.FindItem(abiltable.name).CastTime() == 0 then abils.activateAbility(abiltable) end
            end
        end
    end
    state.nextAbil[1], state.nextAbil[2] = doConditions()
    if state.nextAbil[1] and state.nextAbil[2] then
        return true
    else
        return false
    end
end

local function processHealRoutine()
    write.Trace('ProcessHealRoutine function')
    if not state.config.doHealing then return end
    local heals = require('routines.heal')
    state.nextAbil[1], state.nextAbil[2] = heals.doHeals()
    if state.nextAbil[1] and state.nextAbil[2] then
        return true
    else
        return false
    end
end

local function processDebuffRoutine()
    if not state.config.doDebuffs then return end
    local debuffs = require('routines.debuff')
    write.Trace('processDebuff routine')
    state.nextAbil[1], state.nextAbil[2] = debuffs.doDebuffs()
    if state.nextAbil[1] and state.nextAbil[2] then
        return true
    else
        return false
    end
end

local function processCharmRoutine()
    if not state.config.doCharm then return end
    if state.charmbreak ~= true then return end
    local abiltable = {
        name = state.config.charmSpell,
        type = state.config.charmType
    }
    state.nextAbil[1], state.nextAbil[2] = abiltable, "charm"
    if state.nextAbil[1] and state.nextAbil[2] then
        return true
    else
        return false
    end
end

local function processBuffRoutine()
    if not state.config.doBuffs then return end
    local buffs = require('routines.buff')
    write.Trace('processBuffRoutine')
    state.nextAbil[1], state.nextAbil[2] = buffs.doBuffs()
    if state.nextAbil[1] and state.nextAbil[2] then
        return true
    else
        return false
    end
end

local function processQueuedAbils()
    if #state.queuedabils == 0 then return end
    local abils = require('routines.abils')
    for i = 1, #state.queuedabils do
        if abils.processQueueAbil(state.queuedabils[i]) then
            state.nextAbil[1], state.nextAbil[2] = state.queuedabils[i], "queue"
            break -- Stop after finding the first valid ability
        else
            state.nextAbil[1], state.nextAbil[2] = nil, nil
        end
    end
    if state.nextAbil[1] and state.nextAbil[2] then
        return true
    else
        return false
    end
end

local function whatNext()
    local suc = processQueuedAbils()
    if suc then return end
    local routineList = getRoutineOrder()
    
    for _, routine in pairs(routineList) do
        if routine == 'heals' then
            local success = processHealRoutine()
            if success then return end
        elseif routine == 'debuffs' then
            local success = processDebuffRoutine()
            if success then return end
        elseif routine == 'buffs' then
            local success = processBuffRoutine()
            if success then return end
        elseif routine == 'charm' then
            local success = processCharmRoutine()
            if success then return end
        elseif routine == 'conditions' then
            local success = processConditionRoutine()
            if success then return end
        end
    end
end

local function checkAsynchronousRemovals()
    write.Trace("Checking asynchronous removals")

    -- Get the most recent ability
    local lastUsed = state.abilityhistory[1]
    if not lastUsed then return end

    -- Check Buff Queue
    if #state.buffqueue > 0 then
        local buffEntry = state.buffqueue[1]
        if lastUsed.name == buffEntry.ability.name and lastUsed.target == buffEntry.requesterID and (mq.gettime() - lastUsed.timestamp) < 2000 then
            table.remove(state.buffqueue, 1)
            write.Info("Processed buff: %s on target ID %d", lastUsed.name, lastUsed.target)
        end
    end

    -- Check Cure Queue
    if #state.curequeue > 0 then
        local cureEntry = state.curequeue[1]
        if lastUsed.name == cureEntry.ability.name and lastUsed.target == cureEntry.requesterID and (mq.gettime() - lastUsed.timestamp) < 2000 then
            table.remove(state.curequeue, 1)
            write.Info("Processed cure: %s on target ID %d", lastUsed.name, lastUsed.target)
        end
    end

    -- Check General Abilities Queue
    if #state.queuedabils > 0 then
        local abilEntry = state.queuedabils[1]
        if lastUsed.name == abilEntry.name and lastUsed.target == abilEntry.tarid and (mq.gettime() - lastUsed.timestamp) < 2000 then
            table.remove(state.queuedabils, 1)
            write.Info("Processed ability: %s on target ID %d", lastUsed.name, lastUsed.target)
        end
    end
end



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
    local lib = require('utils.lib')
    state.assistSpawn = lib.getAssistTarget()
    state.chaseSpawn = lib.getChaseTarget()
    checkAsynchronousRemovals()
    whatNext()
    state.charmbreak = lib.checkCharm()
    if state.charmbreak == true and state.nextAbil[2] ~= "charmBreak" then
        local abils = require("routines.abils")
        local abiltable = {
            name = state.config.charmBreakSpell,
            type = state.config.charmBreakType
        }
        if abils.isAbilReady(abiltable.name,abiltable.type,0,false) then
            state.nextAbil[1], state.nextAbil[2] = abiltable, "charmBreak"
        end
    end
    if not state.campxloc and state.config.returnToCamp then
        state.config.returnToCamp = false
        mq.cmd('/dgtell ' .. mq.TLO.Me.Name() .. ':: Setting return to camp false. No camp loc declared.')
    end
    write.loglevel = state.config.loglevel
    mq.doevents()
    if mq.TLO.Me.Feigning() and state.config.movement == 'auto' and not state.paused and not state.config.feignOverride then
        local result, err = load('return ' .. state.config.standcond, nil, 't', { mq = mq })
        if result then
            local success, value = pcall(result)
            if success then
                if value == true then
                    state.feigned = false
                    mq.cmd('/stand')
                    return
                elseif value == false then
                    return
                end
            else
                write.Error('Error during custtar pcall: ' .. value)
            end
        else
            write.Error('Error during custtar load: ' .. err)
        end
    end
end

return state