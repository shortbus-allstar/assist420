local mq = require('mq')
local state = require('utils.state')
local write = require('utils.Write')
local lib = require('utils.lib')
local abils = require('routines.abils')
local combat= require('routines.combat')

local mod = {}

function mod.setCamp()
    write.Trace('setCamp function')
    state.campxloc = mq.TLO.Me.X()
    state.campyloc = mq.TLO.Me.Y()
    state.campzloc = mq.TLO.Me.Z()
end

function mod.clearCamp()
    write.Trace('clearCamp function')
    state.campxloc = nil
    state.campyloc = nil
    state.campzloc = nil
end

function mod.checkNav()
    write.Trace('checkNav function')
    if state.config.movement ~= 'auto' then return end
    if state.pulling then return end
    if state.config.chaseAssist and (mq.TLO.Group.MainAssist.Distance3D() or 0) >= state.config.chaseDistance and (mq.TLO.Group.MainAssist.Distance3D() or math.huge) <= state.config.chaseMaxDistance and not mq.TLO.Navigation.Active() and mq.TLO.Group.MainAssist.Type() ~= 'Corpse' and mq.TLO.Navigation.PathExists('id ' .. mq.TLO.Group.MainAssist.ID())() then
        write.Info('Chasing main assist')
        mq.cmdf('/squelch /nav id %s dist=%s',mq.TLO.Group.MainAssist.ID(),state.config.chaseDistance)
    end

    if state.campxloc and state.config.returnToCamp then
        if not mq.TLO.Me.Combat() and not ((state.campxloc - state.config.campRadius < mq.TLO.Me.X() and mq.TLO.Me.X() < state.campxloc + state.config.campRadius) and (state.campyloc - state.config.campRadius < mq.TLO.Me.Y() and mq.TLO.Me.Y() < state.campyloc + state.config.campRadius) and (state.campzloc - 5 < mq.TLO.Me.Z() and mq.TLO.Me.Z() < state.campzloc + 5)) and not mq.TLO.Navigation.Active() and mq.TLO.Navigation.PathExists('locxyz '.. state.campxloc .. ' ' .. state.campyloc .. ' ' .. state.campzloc)() then
            write.Info('Returning to camp')
            mq.cmdf('/squelch /nav locxyz %s %s %s',state.campxloc,state.campyloc,state.campzloc)
        end
    end
end

function mod.addToIgnore(id)
    write.Trace('addToIgnore function')
    table.insert(state.pullIgnores,id)
end

function mod.checkIfIgnored(s)
    for _, v in pairs(state.pullIgnores) do
        if s.ID() == v then return true end
    end
    return false
end

function mod.getPullList()
    write.Trace('getPullList function')
    return mq.getFilteredSpawns(function(s) return s.Type() == 'NPC' and s.Targetable() and not mod.checkIfIgnored(s) and s.Distance() <= state.config.pullRadius and s.DistanceZ() <= state.config.pullZRange and mq.TLO.Navigation.PathExists('id ' .. s.ID())() and s.ID() ~= mq.TLO.Me.GroupAssistTarget.ID() and s.Distance() >= (state.config.attackRange + state.config.campRadius) and not s.Aggressive() end)
end

function mod.getClosestTarget()
    write.Trace('getClosestTarget function')
    local list = mod.getPullList()
    local closestObject = nil
    local minDistance = math.huge -- Set initial distance to a very large number

    for _, v in pairs(list) do
        local distance = v.Distance3D()

        -- Check if the current object is closer than the previously found closest object
        if distance and distance < minDistance then
            closestObject = v
            minDistance = distance
        end
    end

    return closestObject
end

function mod.navToTarget(s)
    write.Trace('navToTarget function')
    mq.cmdf('/squelch /nav id %s',s.ID())
end

function mod.checkPullStatus()
    write.Trace('checkPullStatus function')
    local incamp = false
    if ((state.campxloc - state.config.campRadius < mq.TLO.Me.X() and mq.TLO.Me.X() < state.campxloc + state.config.campRadius) and (state.campyloc - state.config.campRadius < mq.TLO.Me.Y() and mq.TLO.Me.Y() < state.campyloc + state.config.campRadius) and (state.campzloc - 5 < mq.TLO.Me.Z() and mq.TLO.Me.Z() < state.campzloc + 5)) then
        incamp = true
    end

    if incamp then
        if lib.XTAggroCount() > state.config.chainPullMax or lib.fullAggro() then state.pulling = false return false end
        if state.config.chainPullToggle and ((lib.XTAggroCount() or 0) < state.config.chainPullMax or ((not mq.TLO.Me.GroupAssistTarget() or (mq.TLO.Me.GroupAssistTarget.PctHPs() or 100) <= state.config.chainPullHP) and (lib.XTAggroCount() or 0) <= state.config.chainPullMax)) then
            return true
        end
        if not state.config.chainPullToggle and lib.XTAggroCount() == 0 and not mq.TLO.Me.GroupAssistTarget.Aggressive() then
            return true
        end
        return false
    end

    return true
end

function mod.iAmPulling(tar)
    write.Trace('iAmPulling function')
    state.updateLoopState()
    if state.paused then return 'finished' end
    mq.delay(150)

    if mq.TLO.Me.Dead() then
        write.Info('Navigation interrupted')
        return 'interrupted'
    end

    if mq.TLO.Target.ID() ~= tar.ID() then
        write.Info('Changing target to pull target')
        mq.cmdf('/squelch /mqt id %s',tar.ID())
    end

    if tar.Distance3D() <= math.abs(state.config.pullAbilRange - 10) and tar.LineOfSight() and not tar.Underwater() then 
        mq.cmd('/nav stop')
        write.Info('Arrived at pull target')
        return 'finished'
    elseif tar.Underwater() and tar.Distance3D() <= math.abs(state.config.pullAbilRange - 10) and tar.LineOfSight() and mq.TLO.Me.Underwater() then
        mq.cmd('/nav stop')
        write.Info('Arrived at pull target')
        return 'finished'
    end

    if not mq.TLO.Navigation.Active() and tar.Distance3D() >= (state.config.pullAbilRange + 10) then
        write.Info('Navigation interrupted')
        write.Debug('Nav Stopped and target far ')
        return 'interrupted'
    end

    if not state.config.chainPullToggle and lib.XTAggroCount() > 0 then
        write.Info('Aggro detected, returning to camp')
        state.pulling = false
        return 'aggro'
    end

    if state.config.chainPullToggle and lib.XTAggroCount() > state.config.chainPullMax then
        write.Info('Aggro detected, returning to camp')
        state.pulling = false
        return 'aggro'
    end

    return nil
end

function mod.doPulls()
    write.Trace('doPulls function')
    state.updateLoopState()
    if state.paused then return end
    if not state.campxloc or not state.config.returnToCamp then return end
    if not state.config.doPulling then state.pulling = false return end
    if state.config.chainPullMax < lib.XTAggroCount() then 
        if state.pulling then 
            state.pulling = false 
        end 
        return 
    end
    local shouldPull = mod.checkPullStatus()
    if not shouldPull then 
        state.pulling = false
        return
    end
    if shouldPull == true then 
        if mq.TLO.Me.Combat() then mq.cmd('/attack off') end
        state.pulling = true
        local tar = mod.getClosestTarget()
        if tar then 
            mod.navToTarget(tar)
            write.Info('Pulling target: %s',tar.CleanName())
            mq.delay(250)
            local result = nil
            while result == nil do
                result = mod.iAmPulling(tar)
                mq.delay(500)
            end
            if result == 'interrupted' then return end
            if result == 'aggro' then
                mq.cmdf('/squelch /nav locxyz %s %s %s',state.campxloc,state.campyloc,state.campzloc)
                while not ((state.campxloc - state.config.campRadius < mq.TLO.Me.X() and mq.TLO.Me.X() < state.campxloc + state.config.campRadius) and (state.campyloc - state.config.campRadius < mq.TLO.Me.Y() and mq.TLO.Me.Y() < state.campyloc + state.config.campRadius) and (state.campzloc - 5 < mq.TLO.Me.Z() and mq.TLO.Me.Z() < state.campzloc + 5)) do
                    state.updateLoopState()
                    if state.paused then return end
                    mq.delay(100)
                end
                mq.delay(500)
            end
            if result == 'finished' then
                abils.doAbility(state.config.pullAbilName,state.config.pullAbilType,'None')
                mq.delay(2000)
                if mq.TLO.Me.CombatState() ~= 'COMBAT' then state.pulling = false return end
                mq.cmdf('/squelch /nav locxyz %s %s %s',state.campxloc,state.campyloc,state.campzloc)
                while not ((state.campxloc - state.config.campRadius < mq.TLO.Me.X() and mq.TLO.Me.X() < state.campxloc + state.config.campRadius) and (state.campyloc - state.config.campRadius < mq.TLO.Me.Y() and mq.TLO.Me.Y() < state.campyloc + state.config.campRadius) and (state.campzloc - 5 < mq.TLO.Me.Z() and mq.TLO.Me.Z() < state.campzloc + 5)) do
                    state.updateLoopState()
                    if state.paused then return end
                    mq.delay(100)
                end
                mq.delay(500)
                
                while tar.Distance3D() >= (state.config.attackRange) and not tar.Dead() do
                    write.Trace('checkCombat pull loop')
                    state.updateLoopState()
                    if state.paused then return end
                    combat.checkPet()
                    combat.handleTarget()
                    if not combat.doFacing() then return end
                    if combat.initialCombatNav() then return end
                    combat.keepAttached()
                end
                state.pulling = false
            end
        end
    end
end


return mod


