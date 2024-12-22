local mq = require('mq')
local write = require('utils.Write')
local state = require('utils.state')
local lib = require('utils.lib')

local mod = {}

function mod.processBuff(abiltable)
    local abils = require('routines.abils')
    local tarDistance = mq.TLO.Spawn(abiltable.tarid).Distance3D() or 0 
    local spell = nil
    local spellInfo = mq.TLO.Spell(abiltable.name)
    local rankname = (spellInfo and spellInfo.RankName()) or abiltable.name
    if state.paused then return nil end
    if not abiltable.active then return nil end
    if abiltable.name == "Enter Name Here" then return nil end
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

    return abiltable, 'buffs'
end

function mod.activateBuff(abiltable,delay)
    if mq.TLO.Target.ID() ~= abiltable.tarid then
        if delay then
            if delay < 300 then return end
        end
        mq.cmdf('/squelch /mqt id %s',abiltable.tarid)
        write.Info('Targeting: %s',mq.TLO.Spawn(abiltable.tarid).CleanName())
        mq.delay(300)
    end
    local abils = require('routines.abils')
    local success, abildelay = abils.doAbility(abiltable.name,abiltable.type,abiltable.target,delay)
    if success then
        if abiltable.loopdel == 0 then return abildelay 
        else
            mq.delay(abiltable.loopdel)
            abildelay = math.huge
        end
    end
    return abildelay
end

function mod.getBuffTargetsForAbility(abil)
    local targets = {}

    if abil.useself and not abil.usegroup then
        table.insert(targets, {targetID=mq.TLO.Me.ID(), targetName=mq.TLO.Me.Name()})
    end

    if abil.usegrouptank and mq.TLO.Group.MainTank.ID() or 0 > 0 then
        table.insert(targets, {targetID=mq.TLO.Group.MainTank.ID(), targetName=mq.TLO.Group.MainTank.Name()})
    end

    if abil.usegroup then
        table.insert(targets, {targetID=mq.TLO.Me.ID(), targetName=mq.TLO.Me.Name()})
        local groupSize = mq.TLO.Group.GroupSize() or 0
        for i=1,groupSize do
            local memberName = mq.TLO.Group.Member(i).Name()
            if memberName and memberName ~= mq.TLO.Me.Name() then
                local memberSpawn = mq.TLO.Group.Member(i)
                if memberSpawn() then
                    table.insert(targets, {targetID=memberSpawn.ID(), targetName=memberName})
                end
            end
        end
    end

    if abil.usepets then
        local groupSize = mq.TLO.Group.GroupSize() or 0
        for i=1,groupSize do
            local memberName = mq.TLO.Group.Member(i).Name()
            if memberName then
                local memberSpawn = mq.TLO.Group.Member(i)
                if memberSpawn.Pet() and memberSpawn.Pet.ID() > 0 then
                    table.insert(targets, {targetID=memberSpawn.Pet.ID(), targetName=memberSpawn.Pet.CleanName()})
                end
            end
        end
        -- Also consider the player's own pet if applicable
        if mq.TLO.Me.Pet.ID() > 0 then
            table.insert(targets, {targetID=mq.TLO.Me.Pet.ID(), targetName=mq.TLO.Me.Pet.CleanName()})
        end
    end

    -- othertargets: additional targets user configured
    for _, t in pairs(abil.othertargets) do
        local targetString = t
        local targetValue = nil
    
        -- Try to treat t as a Lua expression
        local fn, err = load("return " .. targetString, nil, "t", {mq=mq})
        if fn then
            local ok, val = pcall(fn)
            if ok and val then
                targetValue = val
            end
        end
    
        -- If targetValue is still nil, try directly as a spawn name/ID
        if not targetValue then
            targetValue = t -- fallback, assuming t is a name or an ID string
        end
    
        -- Now targetValue should be a name or ID we can pass to mq.TLO.Spawn
        local s = mq.TLO.Spawn(targetValue)
        if s() then
            table.insert(targets, {targetID=s.ID(), targetName=s.CleanName()})
        end
    end

    return targets
end

function mod.checkBuffOverrides(abil, targetID)
    local overrides = abil.overrides
    if not overrides or #overrides == 0 then
        return false
    end

    local targetSpawn = mq.TLO.Spawn(targetID)
    if not targetSpawn() then
        -- No spawn found, can't confirm overrides, assume none
        return false
    end

    local targetName = targetSpawn.CleanName() or targetSpawn.Name()
    local isDannet = targetName and mq.TLO.DanNet(targetName)()

    for _, overrideBuffName in ipairs(overrides) do
        if isDannet then
            -- On Dannet, check if observer exists
            local overrideStatus = mq.TLO.DanNet(targetName).O('Me.Buff['..overrideBuffName..']')()
            if overrideStatus == nil then
                -- No observer, create one
                mq.cmdf('/dobserve %s -q "%s"', targetName, 'Me.Buff['..overrideBuffName..']')
                mq.delay(100) -- wait for observer init
                overrideStatus = mq.TLO.DanNet(targetName).O('Me.Buff['..overrideBuffName..']')()
            end

            -- Now overrideStatus is nil, "NULL", or value
            if overrideStatus and overrideStatus ~= "NULL" then
                -- Found an override buff
                return true
            end

            -- If overrideStatus is "NULL" or nil after retry, no override buff here, check next
        else
            -- Not on Dannet, do a direct spawn-based check
            if targetSpawn.Buff(overrideBuffName)() then
                -- Found an override buff
                return true
            end
            -- No override buff found for this one, continue checking others
        end
    end

    -- Checked all override buffs, none found
    return false
end


function mod.hasBuff(abil, targetID)
    local buffName = abil.buffname
    local targetName = mq.TLO.Spawn(targetID).CleanName()
    local isDannet = targetName and mq.TLO.DanNet(targetName)()

    if mod.checkBuffOverrides(abil,targetID) then
        return true
    end

    if isDannet then
        -- On Dannet
        -- Check if observer exists
        if not mq.TLO.DanNet(targetName).O("Me.Buff[" .. buffName .. "]")() then
            -- Create observer
            mq.cmdf('/dobserve %s -q "%s"', targetName, 'Me.Buff['..buffName..']')
            mq.delay(100) -- wait for observer to initialize
        end

        local buffStatus = mq.TLO.DanNet(targetName).O('Me.Buff['..buffName..']')()
        -- Observer returns something non-NULL if buff is present
        if buffStatus and buffStatus ~= 'NULL' then
            return true
        else
            return false
        end
    else
        -- Not on Dannet, use spawn-based check
        -- First, try without retargeting if we are already targeting them
        if mq.TLO.Target.ID() ~= targetID then
            -- Not currently targeting them, check TLO directly by spawn method:
            local s = mq.TLO.Spawn(targetID)
            if s() then
                if s.Buff(buffName)() then
                    -- Buff found without targeting them directly this time.
                    local nowMs = mq.gettime()
                    state.buffRetargetTime = state.buffRetargetTime or {}
                    local nextAllowedTime = state.buffRetargetTime[targetID] or 0
        
                    if nowMs > nextAllowedTime then
                        -- It's been longer than buffCheckInterval since last retarget or no retarget on record.
                        -- We want to target them anyway to update the spawn object.
                        mq.cmdf('/squelch /mqt id %s',targetID)
                        mq.delay(400)
                        local tar = mq.TLO.Target
                        -- After retargeting, set the next allowed retarget time to now + buffCheckInterval
                        state.buffRetargetTime[targetID] = nowMs + (state.config.buffCheckInterval or 5000)
        
                        -- Check buff again after update
                        if tar() and tar.Buff(buffName)() then
                            return true
                        else
                            -- If after retargeting we lose the buff somehow, treat as no buff.
                            return false
                        end
                    else
                        -- Within interval, no need to retarget, buff confirmed present
                        return true
                    end
                else
                    -- Buff not found. Let's possibly retarget them for a more accurate check
                    state.buffRetargetTime = state.buffRetargetTime or {}
                    local nowMs = mq.gettime()
                    local nextAllowedTime = state.buffRetargetTime[targetID] or 0
        
                    if nowMs < nextAllowedTime then
                        -- Not enough time has passed since last retarget attempt
                        -- Assume buff is present to avoid spamming target attempts
                        write.Debug(("Skipping retarget for target %s due to interval, assuming buff present"):format(targetID))
                        return true
                    else
                        -- Enough time passed, attempt retarget
                        mq.cmdf('/squelch /mqt id %s',targetID)
                        mq.delay(400) -- allow spawn object updates
                        local tar = mq.TLO.Target
                        -- Set the next allowed retarget time with a hard-coded 10s interval
                        state.buffRetargetTime[targetID] = nowMs + 10000
                        
                        if tar() and tar.Buff(buffName)() then
                            return true
                        else
                            return false
                        end
                    end
                end
            else
                -- Could not find spawn at all
                -- If we can't even find the spawn, we can't confirm no buff.
                -- The instructions don't specify, but let's be conservative and assume buff present.
                return true
            end
        else
            -- Already targeting them, direct check
            if mq.TLO.Target.Buff(buffName)() then
                return true
            else
                return false
            end
        end
    end
end

function mod.processBuffRequestsFromQueue()
    if #state.buffqueue == 0 then
        return nil
    end

    -- Process the first request
    local request = state.buffqueue[1]
    local requesterID = request.requesterID
    local abil = request.ability

    abil.tarid = requesterID

    return abil
end

function mod.doBuffs()
    if state.paused then return nil end
    if not state.config.doBuffs then return nil end
    local buffAbilities = state.config.buffabils[state.class]
    if not buffAbilities or #buffAbilities == 0 then
        return nil, nil
    end

    local result = mod.processBuffRequestsFromQueue()
    if result then
        return result, "buffs"
    end


    for _, abil in ipairs(buffAbilities) do
        if abil.active then
            local targets = mod.getBuffTargetsForAbility(abil)
            -- targets = { {targetID=..., targetName=...}, ... }

            for _, tinfo in ipairs(targets) do
                local targetID = tinfo.targetID
                abil.tarid = targetID
                if not mod.hasBuff(abil, targetID) then 
                    write.Debug(("Target %s does not have buff %s"):format(tinfo.targetName or targetID, abil.name))
                    local ability, _ = mod.processBuff(abil)
                    if ability then 
                        write.Debug(("Selected %s for buff %s"):format(tinfo.targetName or targetID, abil.name))
                        return ability, "buffs"
                    end
                else
                    write.Debug(("Target %s already has buff %s"):format(tinfo.targetName or targetID, abil.name))
                end
            end
        end
    end

    -- If we get here, no buffs need to be cast at this time
    return nil, nil


end

return mod