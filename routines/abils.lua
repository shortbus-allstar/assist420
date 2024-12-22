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
    cond = 'mq.TLO.Me.Combat()',
    custtar = 'mq.TLO.Me.ID()',
    priority = 1,
    loopdel = 0,
    abilcd = 10,
    active = true,
    usecombat = true,
    useooc = false,
    burn = false,
    feign = false
}

mod.aggroAbilTemplate = {
    name = 'Enter Name Here',
    type = 'AA',
    cond = 'true',
    priority = 1,
    loopdel = 0,
    abilcd = 10,
    active = true,
    ae = false,
    mobcount = 2
}

mod.healAbilTemplate = {
    name = 'Enter Name Here',
    type = 'Spell',
    cond = 'true',
    healpct = 100,
    priority = 1,
    loopdel = 0,
    abilcd = 10,
    active = true,
    cure = false,
    curetype = {
        "Poison",
    },
    rez = false,
    usextar = true,
    usegrouptank = true,
    usegroupmember = true,
    useothertank = true,
    useself = true,
    usepets = true,
    aeheal = false,
    emergheal = false,
    hot = false,
}

mod.buffAbilTemplate = {
    name = 'Enter Name Here',
    buffname = "Buff Name Here",
    type = 'Spell',
    cond = 'true',
    priority = 1,
    loopdel = 0,
    abilcd = 10,
    active = true,
    usegrouptank = true,
    usegroup = true,
    useself = true,
    usepets = true,
    othertargets = {},
    overrides = {}
}

mod.debuffAbilTemplate = {
    name = 'Enter Name Here',
    debuffname = 'Debuff Name Here',
    type = 'Spell',
    cond = 'true',
    priority = 1,
    loopdel = 0,
    abilcd = 10,
    active = true,
    ae = false,
    aemin = 2,
    overrides = {}
}

function mod.loadAbilCond(cond)
    local func
    if cond:match("^%s*function") then
        -- If the string starts with "function", ensure it's wrapped with "return"
        local result, err = load("return " .. cond, nil, "t", { mq = mq, write = write, print = print })
        if not result then
            write.Error("Error during function load: " .. err)
            return false
        end
        func = result
    else
        -- Otherwise, assume it's an expression to return a value
        local result, err = load("return " .. cond, nil, "t", { mq = mq, write = write, print = print })
        if not result then
            write.Error("Error during expression load: " .. err)
            return false
        end
        func = result
    end

    -- Execute the loaded function safely
    local success, value = pcall(func)
    if not success then
        write.Error("Error during condition execution: " .. value)
        return false
    end

    return value
end



function mod.isAbilReady(name,type,abilcd,feign)
    if state.cooldowns[name] then
        if (mq.gettime() - state.cooldowns[name]) < abilcd then write.Debug('CD not ready') return false end
    end
    if not lib.inControl() then write.Debug('Not in control') return false end
    if mq.TLO.Me.Feigning() and (feign or type == "Disc" or type == 'Spell' or type == 'AA' or type == 'Item') then write.Debug('You are feigned') return false end
    if (mq.TLO.Me.Casting() or state.class == "BRD") and type ~= "Cmd" and type ~= "Skill" then write.Debug('Already casting') return false end
    if mq.TLO.Me.Moving() and type ~= "Cmd" and type ~= "Skill" then write.Debug('Moving') return false end

    if type == 'Cmd' then return true end

    if type == 'AA' then 
        return mq.TLO.Me.AltAbilityReady(name)()
    end

    if type == 'Spell' then 
        local rankname = mq.TLO.Spell(name).RankName() or name
        if rankname then 
            if mq.TLO.Spell(rankname).Mana() >= mq.TLO.Me.CurrentMana() then write.Info('Not enough mana') return false end
            if not mq.TLO.Me.Gem(rankname)() then
                return true
            end
            return mq.TLO.Me.GemTimer(rankname)() == 0
        else
            write.Error('Rankname was nil in readycheck. Spell name is likely incorrectly spelled. Spell name declared as ' .. name)
            return false
        end
        if (mq.TLO.Cast.Timing() ~= 0 or mq.TLO.Me.Moving()) and state.class ~= "BRD" then return false end
    end

    if type == 'Disc' then
        return mq.TLO.Me.CombatAbilityReady(mq.TLO.Spell(name).RankName() or name)()
    end

    if type == 'Skill' then 
        return mq.TLO.Me.AbilityReady(name)()
    end

    if type == 'Item' then
        return mq.TLO.FindItem(name).TimerReady() == 0
    end
end

function mod.doAbility(name,type,tartype,memdelay,data)
    if state.paused then return false, 0 end
    if mq.TLO.Me.Casting() and state.class ~= "BRD" then return false, 0 end
    write.Trace('doAbility function')
    local delay = 0
    local cmd = nil
    local rankname = mq.TLO.Spell(name).RankName() or name
    state.interrupted = false

    if type == 'AA' then 
        cmd = '/aa act ' .. name
        delay = mq.TLO.Me.AltAbility(name).Spell.MyCastTime()
        rankname = mq.TLO.Me.AltAbility(name).Spell.RankName()
    end

    if type == 'Spell' and mq.TLO.Spell(rankname).Mana() and mq.TLO.Me.CurrentMana() >= mq.TLO.Spell(rankname).Mana() then
        cmd = string.format('/casting "%s" gem%s',mq.TLO.Spell(rankname).RankName(),state.config.miscGem)
        delay = mq.TLO.Spell(rankname).MyCastTime() + 1250
        if tartype ~= 'None' and mq.TLO.Target() and mq.TLO.Spell(rankname).TargetType() ~= "Self" then
            local spellRange = mq.TLO.Spell(rankname).AERange()
            if spellRange == 0 then spellRange = mq.TLO.Spell(rankname).MyRange() end
            if mq.TLO.Target.Distance3D() >= spellRange then 
                write.Info('Target out of range')
                return false, 0
            end
        end
        if not mq.TLO.Me.Gem(rankname)() then
            if not state.canmem or data == "Heal" then return false end
            delay = mq.TLO.Spell(rankname).RecastTime() + 500
            write.Info('Memming ' .. type .. ' ' .. name)
            mq.cmd(cmd)
            local tarid = mq.TLO.Target.ID()
            mq.delay(10)
            repeat
                mq.delay(10)
            until mq.TLO.Window('SpellBookWnd')() == "FALSE"
            mq.cmd('/interrupt')
            local start = mq.gettime()
            if delay < 1600 then
                delay = mq.TLO.Spell(rankname).RecastTime() + mq.TLO.Spell(rankname).MyCastTime()
                mq.delay(delay)
                return true
            else
                state.canmem = false
                while (mq.gettime() - start) < delay do
                    state.updateLoopState()
                    if state.paused then return false end
                    state.activeQueue(delay)
                end
                if mq.TLO.Target.ID() ~= tarid then
                    mq.cmdf('/squelch /mqt id %s',tarid)
                    mq.delay(350)
                end
                write.Info('Using ' .. type .. ' ' .. name)
                mq.cmd(cmd)
                mq.delay(1000)
                state.canmem = true
            end
            return true, math.huge
        end
    elseif type == 'Spell' and mq.TLO.Spell(rankname).Mana() and mq.TLO.Me.CurrentMana() <= mq.TLO.Spell(rankname).Mana() then
        write.Info('Not enough mana, skipping...')
        return false, 0
    end

    if type == 'Disc' and mq.TLO.Spell(rankname).EnduranceCost() and mq.TLO.Me.CurrentEndurance() >= mq.TLO.Spell(rankname).EnduranceCost() and mq.TLO.Spell(rankname).TargetType() ~= "Spell" then 
        if tartype ~= 'None' and mq.TLO.Target() then
            if (mq.TLO.Target.Distance3D() or math.huge) >= mq.TLO.Spell(rankname).MyRange() then 
                write.Info('Target out of range')
                return false, 0
            end
        end
        cmd = '/disc ' .. rankname
        delay = mq.TLO.Spell(rankname).MyCastTime()
    elseif type == 'Disc' and mq.TLO.Spell(rankname).EnduranceCost() and mq.TLO.Me.CurrentEndurance() <= mq.TLO.Spell(rankname).EnduranceCost() then
        write.Info('Not enough endurance, skipping...')
        return false, 0
    end

    if type == 'Skill' then 
        cmd = '/do ' .. name
        delay = 0
    end

    if type == 'Item' then 
        cmd = '/useitem ' .. name
        delay = mq.TLO.FindItem(name).CastTime()
        rankname = mq.TLO.FindItem(name).Clicky.Spell.RankName()
    end

    if type == 'Cmd' then 
        cmd = name
        delay = 0
    end

    if not cmd then write.Error('Error: cmd variable never declared. Ability type likely invalid. Type was passed to function as ' .. type) return false, 0 end
    if memdelay then
        if delay > memdelay then write.Debug('Cast will take too long for memmed spell, skipping..') return false, 0 end
    end
    write.Info('Using ' .. type .. ' ' .. name)

    if data == "Rez" and mq.TLO.Target.Distance3D() >= 10 then
        mq.cmd('/squelch /corpse')
        mq.delay(100)
    end
    if data == "Rez" and mq.TLO.Target.Type() == "Corpse" then
        state.corpsetimers[mq.TLO.Target.ID()] = mq.gettime()
    end
    if data == "HoT" then
        state.hotTimers[mq.TLO.Target.ID()] = mq.gettime()
    end
    if data == "AE HoT" then
        state.hotTimers[0] = mq.gettime()
    end
    mq.cmd(cmd)

    local starttime = mq.gettime()
    state.cooldowns[name] = mq.gettime()

    if delay == 0 then
        return true, 0
    end

    state.casting = true
    while (mq.gettime() - starttime) < delay do
        local heals = require('routines.heal')
        write.Trace('New doAbility loop')
        mq.delay(10)
        state.updateLoopState()
        combat.doFacing()
        if state.config.role == 'puller' and state.campxloc and not ((state.campxloc - state.config.campRadius < mq.TLO.Me.X() and mq.TLO.Me.X() < state.campxloc + state.config.campRadius) and (state.campyloc - state.config.campRadius < mq.TLO.Me.Y() and mq.TLO.Me.Y() < state.campyloc + state.config.campRadius) and (state.campzloc - 5 < mq.TLO.Me.Z() and mq.TLO.Me.Z() < state.campzloc + 5)) and not mq.TLO.Navigation.Active() and mq.TLO.Navigation.PathExists('locxyz '.. state.campxloc .. ' ' .. state.campyloc .. ' ' .. state.campzloc)() and mq.TLO.Me.CombatState() == 'COMBAT' and mq.TLO.Cast.Timing() == 0 and (mq.TLO.Target.PctAggro() or 0) == 100 then
            write.Info('Returning to camp')
            mq.cmdf('/squelch /nav locxyz %s %s %s',state.campxloc,state.campyloc,state.campzloc)
        end
        if not mq.TLO.Me.Casting then state.interrupted = true end
        if state.interrupted then write.Info('Cast Interrupted') return false, math.huge end
        if tartype ~= 'None' and data ~= "Rez" and (mq.TLO.Target.Type() == 'Corpse' or mq.TLO.Target.ID() == 0) then write.Info('Target is dead or no valid target') return false, math.huge end
        if data == "Rez" and mq.TLO.Target.ID() == 0 then write.Info('No valid target rez routine') return false, math.huge end
        if tartype ~= 'None' and mq.TLO.Target() and mq.TLO.Spell(rankname).TargetType() ~= "Self" then
            local spellRange = mq.TLO.Spell(rankname).AERange()
            if spellRange == 0 then spellRange = mq.TLO.Spell(rankname).MyRange() end
            if mq.TLO.Target.Distance3D() >= spellRange then 
                write.Info('Target out of range')
                return false, math.huge
            end
        end
        local healabil, routine = heals.doHeals()
        if healabil and healabil.emergheal and data ~= "Rez" and data ~= "Heal" then
            state.nextAbil[1], state.nextAbil[2] = healabil, routine
            write.Info('Interrupting to Heal')
            mq.cmd('/stopcast')
            return false, math.huge
        end
        if data == "Heal" and (mq.TLO.Target.PctHPs() or 0) > state.config.cancelHealsAt then
            write.Info('Cancelling Heal')
            mq.cmd('/stopcast')
            return false, math.huge
        end
        combat.checkPet()
    end
    if data ~= "charm" then
        state.charmbreak = lib.checkCharm()
        if state.charmbreak then
            write.Info('Interrupting for charm break')
            mq.cmd('/stopcast')
            return false, math.huge 
        end
    end
    if data == "Rez" then
        mq.delay(100)
        mq.doevents('eventCannotRez')
        mq.doevents('eventCannotRez2')
    end
    state.casting = false
    return true, math.huge
end

function mod.targetHandling(tartype,custtar)
    write.Trace('targetHandling function')
    local id = 0

    if tartype == 'None' then id = mq.TLO.Target.ID() end
    if tartype == 'Tank' then id = mq.TLO.Group.MainTank.ID() end
    if tartype == 'Self' then id = mq.TLO.Me.ID() end
    if tartype == 'MA' then id = mq.TLO.Spawn(state.maname).ID() end
    if tartype == 'MA Target' then id = state.assistSpawn.ID() end
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

function mod.processCharm(abiltable)
    if state.paused then return false end
    if not mod.isAbilReady(abiltable.name,abiltable.type,0,false) then return false end
    return abiltable, 'charm'
end

function mod.processAbility(abiltable)
    if state.paused then return false end
    if not abiltable.active then return false end
    if abiltable.burn == true and state.config.burn ~= 'auto' then return false end
    if not mod.isAbilReady(abiltable.name,abiltable.type,abiltable.abilcd,abiltable.feign) then return false end
    if not mod.loadAbilCond(abiltable.cond) then return false end
    if state.config.feignOverride and abiltable.feign then return false end
    return abiltable, 'conditions'
end

function mod.activateCharm(abiltable)
    local tarid = mod.targetHandling("Custom Lua ID",state.currentpet)
    if mq.TLO.Target.ID() ~= tarid then
        mq.cmdf('/squelch /mqt id %s',tarid)
        write.Info('Targeting: %s',mq.TLO.Spawn(tarid).CleanName())
        mq.delay(300)
    end
    local success = mod.doAbility(abiltable.name,abiltable.type,"Custom Lua ID",math.huge,"charm")
    if success then
        state.charmbreak = false
    end
end

function mod.activateAbility(abiltable,delay)
    local tarid = mod.targetHandling(abiltable.target,abiltable.custtar)
    if mq.TLO.Target.ID() ~= tarid then
        if delay then
            if delay < 300 then return end
        end
        mq.cmdf('/squelch /mqt id %s',tarid)
        write.Info('Targeting: %s',mq.TLO.Spawn(tarid).CleanName())
        mq.delay(300)
    end
    local success, abildelay = mod.doAbility(abiltable.name,abiltable.type,abiltable.target,delay)
    if success then
        if abiltable.feign then 
            write.Info('Feign Death')
            mq.delay(1000)
            mq.doevents("failfeign")
        end
        if abiltable.loopdel == 0 then return abildelay 
        else
            mq.delay(abiltable.loopdel)
            abildelay = math.huge
        end
    end
    return abildelay
end

function mod.customCount(tbl)
    local count = 0
    for _, _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

function mod.doQueue(queue,name)
    write.Trace('\apCHECKING ABILS')
    write.Trace(name)
    write.Trace(#queue)
    local abiltable = nil
    local routine = nil
    for i, v in pairs(queue) do
        if v then
            abiltable, routine = mod.processAbility(v)
            if abiltable and routine then
                return abiltable, routine
            end
        end
    end
    return nil, nil
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