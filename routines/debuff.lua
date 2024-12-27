local mq = require('mq')
local state = require('utils.state')
local write = require('utils.Write')
local mod = {}

function mod.getValidDebuffTargets()
    local targets = {}

    local maxRange = state.config.maxDebuffRange or 100
    local zRadius = state.config.debuffZRadius or 50
    local debuffStartAt = state.config.debuffStartAt or 100
    local debuffStopAt = state.config.debuffStopAt or 5

    -- Get a list of nearby NPCs
    local spawnCount = mq.TLO.SpawnCount('npc radius '..maxRange..' zradius '..zRadius)()
    for i = 1, spawnCount do
        local target = mq.TLO.NearestSpawn(i, 'npc radius '..maxRange..' zradius '..zRadius)
        local function underwaterCheck()
            if mq.TLO.Me.Underwater() and target.Underwater() then return true end
            if not mq.TLO.Me.Underwater() and not target.Underwater() then return true end
            return false
        end    
        if target() and target.Type() == 'NPC' and not target.Dead() and target.Aggressive() and target.LineOfSight() and underwaterCheck() then
            local hp = target.PctHPs() or 100
            if hp <= debuffStartAt and hp >= debuffStopAt then
                table.insert(targets, target)
            end
        end
    end

    return targets
end

function mod.prioritizeDebuffTargets(targets)
    local prioritizedTargets = {}
    local assistSpawn = state.assistSpawn
    local assistSpawnID = assistSpawn and assistSpawn.ID()
    local addedTargets = {}

    for _, target in ipairs(targets) do
        local targetID = target.ID()
        if target.Named() then
            table.insert(prioritizedTargets, target)
            addedTargets[targetID] = true
        elseif assistSpawnID == targetID then
            if not addedTargets[targetID] then
                table.insert(prioritizedTargets, target)
                addedTargets[targetID] = true
            end
        end
    end

    -- Add remaining targets
    for _, target in ipairs(targets) do
        local targetID = target.ID()
        if not addedTargets[targetID] then
            table.insert(prioritizedTargets, target)
            addedTargets[targetID] = true
        end
    end

    return prioritizedTargets
end


function mod.processDebuff(abiltable)
    local abils = require('routines.abils')
    local tarDistance = mq.TLO.Spawn(abiltable.tarid).Distance3D() or 0 
    local spell = nil
    local spellInfo = mq.TLO.Spell(abiltable.name)
    local rankname = (spellInfo and spellInfo.RankName()) or abiltable.name
    if state.paused then return nil end
    if abiltable.name == "Enter Name Here" then return nil end
    if not abiltable.active then return nil end
    if not abils.isAbilReady(abiltable.name,abiltable.type,abiltable.abilcd,false) then return nil end
    if not abils.loadAbilCond(abiltable.cond) then return nil end
    if abiltable.type == "AA" then
        spell = mq.TLO.Me.AltAbility(rankname).Spell
    elseif abiltable.type == "Spell" or abiltable.type == "Disc" then 
        spell = mq.TLO.Spell(rankname)
    elseif abiltable.type == "Item" then 
        spell = mq.TLO.FindItem(rankname).Spell
    end

    local spellRange = 0

    if spell and spell.MyRange() then 
        spellRange = spell.AERange()
        if spellRange == 0 then spellRange = spell.MyRange() end
        
        write.Debug(tarDistance)
        write.Debug(spell.MyRange() or "nil")
        if tarDistance >= spellRange and spell.TargetType() ~= "Self" then write.Info('Target out of Range') return nil end
    end
    
    if mq.TLO.Target.ID() ~= abiltable.tarid then
        mq.cmdf('/squelch /mqt id %s',abiltable.tarid)
        mq.delay(350)
    end

    if mq.TLO.Target.Buff(abiltable.debuffname)() then return nil end

    return abiltable, 'debuffs'
end

function mod.activateDebuff(abiltable,delay)
    local targetSpawn = mq.TLO.Spawn(abiltable.tarid)
    if targetSpawn() then
        write.Info('Targeting: %s', targetSpawn.CleanName())
    else
        write.Error('Target with ID %s not found.', abiltable.tarid)
        return 0
    end
    local delayed = false
    if mq.TLO.Target.ID() ~= abiltable.tarid then
        if delay then
            if delay < 300 then return end
        end
        mq.cmdf('/squelch /mqt id %s',abiltable.tarid)
        write.Info('Targeting: %s',mq.TLO.Spawn(abiltable.tarid).CleanName())
        mq.delay(300)
        delayed = true
    end
    local abils = require('routines.abils')
    if abiltable.overrides then
        for _, v in ipairs(abiltable.overrides) do
            if mq.TLO.Target.Buff(v)() then 
                if delayed == true then 
                    return math.huge 
                else
                    return 0
                end
            end
        end
    end
    local success, abildelay = abils.doAbility(abiltable.name,abiltable.type,abiltable.target,delay,"Debuff")
    if success then
        if abiltable.loopdel == 0 then 
            if delayed == true then 
                return math.huge 
            else
                return abildelay
            end
        else
            mq.delay(abiltable.loopdel)
            abildelay = math.huge
        end
    end
    if delayed == true then 
        return math.huge 
    else
        return abildelay
    end
end

function mod.doDebuffs()
    write.Trace('Debuff routine started')
    if state.backoff then return end
    if state.paused then return end
    if (mq.gettime() - state.debufftimer) < 1000 then return end

    -- Get valid debuff targets
    local validTargets = mod.getValidDebuffTargets()
    if #validTargets == 0 then
        write.Trace('No valid targets found')
        return
    end

    write.Trace('Valid targets found')

    local doae = true
    local npccount = mq.TLO.SpawnCount('npc radius 50 zradius 10')()

    write.Debug('Valid Targets : %s, NPCCount: %s',#validTargets,npccount)

    if #validTargets <  npccount then write.Debug('No AE, will aggro others') doae = false end
    local targets = mod.prioritizeDebuffTargets(validTargets)
    local debuffMode = state.config.debuffMode -- 'cycleDebuffs' or 'cycleTargets'

    if #targets >= state.config.debuffAETargetMin and #targets and doae == true then  
        local aetargets = {}   
        for _, abil in ipairs(state.config.debuffabils[state.class]) do
            if abil.ae then
                for _, target in ipairs(targets) do
                    if mq.TLO.Spawn(target).Buff(abil.debuffname)() then return nil end
                    for _, override in ipairs(state.config.debuffabils[state.class][abil.priority].overrides) do
                        local spawn = mq.TLO.Spawn(target)
                        if spawn and spawn.Buff(override)() then
                            write.Debug(string.format('Target %s has debuff %s, skipping', spawn.CleanName(), override))
                        elseif spawn then
                            table.insert(aetargets,target)
                        end
                    end
                end
                if abil.aemin <= #aetargets then
                    write.Debug('AE Abil')
                    abil.tarid = aetargets[1]
                    local ability = mod.processDebuff(abil)
                    if ability then
                        return abil, 'debuffs'
                    end
                end
            end
        end
    end

    local function applyDebuff(target, abil)
        -- Check overrides
        if mq.TLO.Spawn(target).Buff(abil.debuffname)() then return nil end
        for _, override in ipairs(state.config.debuffabils[state.class][abil.priority].overrides) do
            local spawn = mq.TLO.Spawn(target)
            if spawn and spawn.Buff(override)() then
                write.Debug(string.format('Target %s has debuff %s, skipping', spawn.CleanName(), override))
                return nil
            end
        end

        -- Process the debuff
        abil.tarid = target.ID()
        local ability = mod.processDebuff(abil)
        if ability then
            return abil, 'debuffs'
        end

        return nil
    end
    if debuffMode == 'Cycle Debuffs' then
        -- Apply all debuffs to the highest-priority target
        for _, target in ipairs(targets) do
            for _, abil in ipairs(state.config.debuffabils[state.class]) do
                if abil and not abil.ae then
                    local result, result2 = applyDebuff(target, abil)
                    if result then
                        return result, result2
                    end
                end
            end
        end
    elseif debuffMode == 'Cycle Targets' then
        -- Apply the highest-priority debuff to all targets
        for _, abil in ipairs(state.config.debuffabils[state.class]) do
            if abil and not abil.ae then
                for _, target in ipairs(targets) do
                    local result, result2 = applyDebuff(target, abil)
                    if result then
                        return result, result2
                    end
                end
            end
        end
    end
end


return mod