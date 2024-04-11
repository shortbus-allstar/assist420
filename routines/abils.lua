local mq = require('mq')
local write = require('utils.Write')
local state = require('utils.state')
local lib = require('utils.lib')
local combat = require('routines.combat')

local mod = {}

mod.abilTemplate = {
    name = 'Enter Name Here',
    type = 'AA',
    target = 'None',
    cond = 'mq.TLO.Me.PctHPs() > 100',
    custtar = 'mq.TLO.Me.ID()',
    priority = 1,
    loopdel = 0,
    abilcd = 10,
    active = true,
    usecombat = true,
    useooc = true,
    burn = false,
    feign = false
}

function mod.loadAbilCond(cond)
    local result, err = load('return ' .. cond, nil, 't', { mq = mq })
    if result then
        local success, value = pcall(result)
        if success then
            return value
        else
            write.Error('Error during condition pcall: ' .. value)
            return false
        end
    else
        write.Error('Error during condition load: ' .. err)
        return false
    end
end

function mod.isAbilReady(name,type,abilcd)
    write.Trace('isAbilReady function')

    if state.cooldowns[name] and (mq.gettime() - state.cooldowns[name]) < abilcd then return false end
    if type == 'Cmd' then return true end

    if type == 'AA' then 
        return mq.TLO.Me.AltAbilityReady(name)()
    end

    if type == 'Spell' then 
        local rankname = mq.TLO.Spell(name).RankName()
        if rankname then 
            return mq.TLO.Me.GemTimer(rankname)() == 0
        else
            write.Error('Rankname was nil in readycheck. Spell name is likely incorrectly spelled. Spell name declared as ' .. name)
            return false
        end
    end

    if type == 'Disc' then
        return mq.TLO.Me.CombatAbilityReady(name)()
    end

    if type == 'Skill' then 
        return mq.TLO.Me.AbilityReady(name)()
    end

    if type == 'Item' then
        return mq.TLO.FindItem(name).TimerReady() == 0
    end
end

function mod.doAbility(name,type,tartype)
    write.Trace('doAbility function')
    local delay = 0
    local cmd = nil

    if type == 'AA' then 
        cmd = '/aa act ' .. name
        delay = mq.TLO.Me.AltAbility(name).Spell.MyCastTime()
    end

    if type == 'Spell' then
        cmd = string.format('/casting "%s" gem%s',mq.TLO.Spell(name).RankName(),state.config.miscGem)
        delay = mq.TLO.Spell(name).MyCastTime() + 1250
    end

    if type == 'Disc' then 
        cmd = '/disc ' .. name
        delay = mq.TLO.Spell(name).MyCastTime()
    end

    if type == 'Skill' then 
        cmd = '/do ' .. name
        delay = 0
    end

    if type == 'Item' then 
        cmd = '/useitem ' .. name
        delay = mq.TLO.FindItem(name).CastTime()
    end

    if type == 'Cmd' then 
        cmd = name
        delay = 0
    end

    if not cmd then write.Error('Error: cmd variable never declared. Ability type likely invalid. Type was passed to function as ' .. type) return false end
    write.Info('Using ' .. type .. ' ' .. name)

    local starttime = mq.gettime()

    if delay == 0 then
        mq.cmd(cmd)
        state.cooldowns[name] = mq.gettime()
        return true
    end

    while (mq.gettime() - starttime) < delay do
        write.Trace('New doAbility loop')
        mq.delay(10)
        state.updateLoopState()
        if state.interrupted then write.Info('Cast Interrupted') return false end
        if tartype ~= 'None' and (mq.TLO.Target.Type() == 'Corpse' or mq.TLO.Target.ID() == 0) then write.Info('Target is dead or no valid target') return false end
        combat.checkPet()
    end
    return true
end

function mod.targetHandling(tartype,custtar)
    write.Trace('targetHandling function')
    local id = 0

    if tartype == 'None' then id = mq.TLO.Target.ID() end
    if tartype == 'Tank' then id = mq.TLO.Group.MainTank.ID() end
    if tartype == 'Self' then id = mq.TLO.Me.ID() end
    if tartype == 'MA' then id = mq.TLO.Group.MainAssist.ID() end
    if tartype == 'MA Target' then id = mq.TLO.Me.GroupAssistTarget.ID() end
    if tartype == 'Custom Lua ID' then
        local result, err = load('return ' .. custtar, nil, 't', { mq = mq })
        if result then
            local success, value = pcall(result)
            if success then
                id = value
            else
                write.Error('Error during custtar pcall: ' .. value)
            end
        else
            write.Error('Error during custtar load: ' .. err)
        end
    end
    return id
end

function mod.feignedLoop()
    write.Trace('feignedLoop function')
    while mq.TLO.Me.Feigning() do
        write.Trace('feinedLoop new loop')
        mq.delay(100)
        state.updateLoopState()
        if not mq.TLO.Me.Feigning() then
            if state.config.feignOverride then state.feignOverride = true end
            state.feigned = false
            return
        end
        local result, err = load('return ' .. state.standcond, nil, 't', { mq = mq })
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

function mod.processAbility(abiltable)
    write.Trace('processAbility function')
    if state.paused then return end
    if not abiltable.active then return end
    if abiltable.burn == true and state.config.burn ~= 'auto' then return end
    if not mod.isAbilReady(abiltable.name,abiltable.type,abiltable.abilcd) then return end
    if not mod.loadAbilCond(abiltable.cond) then return end
    local tarid = mod.targetHandling(abiltable.target,abiltable.custtar)
    if mq.TLO.Target.ID() ~= tarid then
        mq.cmdf('/squelch /mqt id %s',tarid)
        write.Info('Targeting: %s',mq.TLO.Spawn(tarid).CleanName())
        mq.delay(300)
    end
    local success = mod.doAbility(abiltable.name,abiltable.type,abiltable.target)
    if success then
        if abiltable.feign == true and not state.feignOverride then state.feigned = true end
        mq.delay(abiltable.loopdel)
        if state.feigned == true and not state.feignOverride then mod.feignedLoop() return end
    end
end

function mod.customCount(tbl)
    local count = 0
    for _, _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

function mod.doQueue(queue)
    write.Trace('\apCHECKING ABILS')
    for i, v in pairs(queue) do
        if v then
            mod.processAbility(v)
        end
        if v == nil then
        end
    end
end

function mod.initQueues(cfgtbl)
    for _, v in ipairs(cfgtbl) do
        if v.usecombat then
            state.queueCombat[v.priority] = v
        end
        if v.useooc then 
            state.queueOOC[v.priority] = v
        end
    end
end

function mod.addAbilToQueue(abiltable,queue)
    write.Trace('addAbilToQueue function')
    queue[abiltable.priority] = abiltable
    print(queue[abiltable.priority].name)
end

function mod.removeAbilFromQueue(abiltable, queue)
    write.Trace('removeAbilFromQueue function')
    local index = lib.findIndex(queue,abiltable)
    print(index)
    if index then 
        queue[index] = nil 
    else write.Error('Index not declared correctly') end
end



return mod