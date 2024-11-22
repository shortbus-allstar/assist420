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
    campxloc = nil,
    campyloc = nil,
    campzloc = nil,
    casting = false,
    class = mq.TLO.Me.Class.ShortName(),
    canmem = true,
    chaseSpawn = nil,
    config = conf.getConfig(),
    cooldowns = {},
    dead = false,
    facetimer = 0,
    githubver = getGitHubVersion(),
    loglevel = 'debug',
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
    version = 'v2.0.0-alpha',
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
        [1] = 'heals'
    }
    for k, v in pairs(state.config.routines) do
        if k ~= 'heals' then
            routines[v] = k
        end
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
end

local function whatNext()
    local routineList = getRoutineOrder()
    
    for _, routine in ipairs(routineList) do
        --[[
        if routine == 'heals' then
            processHeals()
        elseif routine == 'buffs' then
            processBuffs()
        elseif routine == 'debuffs' then
            processDebuffs()
        elseif routine == 'charm' then
            processCharm()
        else
            ]]--
        if routine == 'conditions' then
            processConditionRoutine()
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
    whatNext()
    if not state.campxloc and state.config.returnToCamp then
        state.config.returnToCamp = false
        mq.cmd('/dgtell ' .. mq.TLO.Me.Name() .. ':: Setting return to camp false. No camp loc declared.')
    end
    write.loglevel = state.loglevel
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