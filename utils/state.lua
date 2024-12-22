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
    assistSpawn = nil,
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
    queueOOC = {},
    version = 'v1.0.1-beta',
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

local function whatNext()
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
    -- Check Buff Queue
    for i = #state.buffqueue, 1, -1 do
        local entry = state.buffqueue[i]
        local abil = entry.ability
        -- Conditions:
        -- 1. mq.TLO.Target.ID() == entry.requesterID
        -- 2. mq.TLO.Me.Casting.Name() == abil.name
        if mq.TLO.Target.ID() == entry.requesterID and mq.TLO.Me.Casting.Name() == abil.name then
            -- Remove this ability from the buff queue
            table.remove(state.buffqueue, i)
            write.Debug(("Removed buff ability %s from queue based on async conditions."):format(abil.name))
        end
    end

    -- Check Cure Queue
    for i = #state.curequeue, 1, -1 do
        local entry = state.curequeue[i]
        local abil = entry.ability
        if mq.TLO.Target.ID() == entry.requesterID and mq.TLO.Me.Casting.Name() == abil.name then
            -- Remove this cure ability from the cure queue
            table.remove(state.curequeue, i)
            write.Debug(("Removed cure ability %s from queue based on async conditions."):format(abil.name))
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