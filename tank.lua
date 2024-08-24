local mq = require('mq')
local write = require('utils.Write')
local state = require('utils.state')
local lib = require('utils.lib')

local mod = {}

function mod.isBehind(meHeading, targetHeading,target)
    local diff = math.abs(meHeading - targetHeading)
    if diff > 180 then
        diff = 360 - diff
    end
    return (diff <= 90 or diff >= 270) and target.PctAggro() == 100
end

function mod.checkFacingLogic()
    if state.paused then return end
    local aggroSearch = string.format("npc radius %d zradius %d targetable playerstate 4", state.config.tankEngageRadius, 50)
    local aggroMobCount = mq.TLO.SpawnCount(aggroSearch)()

    local meHeading = mq.TLO.Me.Heading.Degrees()
    local isAnyBehind = false
    local behindID = 0

    for i = 1, aggroMobCount do
        local spawn = mq.TLO.NearestSpawn(i, aggroSearch)
        if spawn() then
            local targetHeading = spawn.Heading.Degrees() or 0
            if mod.isBehind(meHeading, targetHeading, mq.TLO.Target) then
                write.Trace("Spawn %s is behind", spawn.CleanName())
                isAnyBehind = true
                behindID = spawn.ID()
                break
            end
        end
    end

    if isAnyBehind then
        write.Trace('isBehind')
        mq.cmdf('/squelch /mqt id %s',behindID)
        mq.delay(300)
        mq.cmd('/squelch /stick snaproll front moveback 30')
        if not mq.TLO.Me.Combat() then mq.cmd('/attack on') end
        mq.cmd('/keypress back hold')
        mq.delay(1000)
        write.Debug('Tank Sticking')
        if mq.TLO.Target() then mq.cmdf('/squelch /multiline ; /stick %s uw ; /attack on ; /if (${Target.Distance3D}>50) /nav target dist=%s',(mq.TLO.Target.MaxRangeTo() - 3) or 0,(mq.TLO.Target.MaxRangeTo() - 3) or 0) end
        mq.cmd('/keypress back')
        mod.checkFacingLogic()
    end
end

function mod.getNextTankTarget()
    write.Trace('getNextTankTarget function')
    if state.paused then return end 
    local aggroSearch = string.format("npc radius %d zradius %d targetable playerstate 4", state.config.tankEngageRadius, 50)
    local aggroMobCount = mq.TLO.SpawnCount(aggroSearch)()

    if mq.TLO.Me.Level() >= 20 and not state.config.petTank then
        for i = 1, lib.XTAggroCount() do
            local count = 0
            local aggcount = 0
            local xtSpawn = mq.TLO.Me.XTarget(i)
            if xtSpawn() and xtSpawn.TargetType() == 'Auto Hater' then

                count = count + 1
                write.Trace('xtSpawn: [id: %s name: %s aggro: %s]',xtSpawn.ID(),xtSpawn.CleanName(),xtSpawn.PctAggro()) 

                if xtSpawn.Named() and xtSpawn.PctAggro() < 100 then
                    write.Trace('Need aggro named: %s',xtSpawn.CleanName())
                    return xtSpawn.ID(), aggroMobCount
                end

                if (xtSpawn.Body.Name() or "none"):lower() == "giant" and xtSpawn.PctAggro() < 100 then
                    write.Trace('Need aggro unmezzable: %s',xtSpawn.CleanName())
                    return xtSpawn.ID(), aggroMobCount
                end

                if xtSpawn.PctAggro() < 100 then
                    write.Trace('Need aggro: %s', xtSpawn.CleanName())
                    return xtSpawn.ID(), aggroMobCount
                end

                if xtSpawn.PctAggro() >= 100 then
                    aggcount = aggcount + 1
                end

            end

            if i == lib.XTAggroCount() and count == aggcount and mq.TLO.Me.Level() >= 20 then
                if (mq.TLO.Target.Type() == 'Corpse' or mq.TLO.Target.ID() == 0) then
                    return mq.TLO.Me.XTarget(1).ID(), aggroMobCount
                end
                return mq.TLO.Target.ID(), aggroMobCount
            end
        end
        
    end

    write.Debug('Xtar search failed, checking spawn search')

    if state.paused then return end 

    for i = 1, aggroMobCount do
        local spawn = mq.TLO.NearestSpawn(i, aggroSearch)
        if spawn() then
            
            if spawn.Named() then
                mq.cmdf('/squelch /mqt id %s',spawn.ID())
                mq.delay(350)
                if mq.TLO.Target.PctAggro() < 100 and not state.config.petTank then
                    write.Trace('Need aggro named: %s',spawn.CleanName())
                    return spawn.ID(), aggroMobCount
                elseif state.config.petTank and mq.TLO.Target.AggroHolder.ID() ~= mq.TLO.Me.Pet.ID() then
                    write.Trace('Need aggro named: %s',spawn.CleanName())
                    return spawn.ID(), aggroMobCount
                end
            end

            if (spawn.Body.Name() or "none"):lower() == "giant" and not state.config.petTank then
                mq.cmdf('/squelch /mqt id %s',spawn.ID())
                mq.delay(350)
                if mq.TLO.Target.PctAggro() < 100 then
                   write.Trace('Need aggro unmezzable: %s',spawn.CleanName())
                    return spawn.ID(), aggroMobCount
                elseif state.config.petTank and mq.TLO.Target.AggroHolder.ID() ~= mq.TLO.Me.Pet.ID() then
                    write.Trace('Need aggro unmezzable: %s',spawn.CleanName())
                    return spawn.ID(), aggroMobCount
                end
            end

            mq.cmdf('/squelch /mqt id %s',spawn.ID())
            mq.delay(350)
            if mq.TLO.Target() and mq.TLO.Target.PctAggro() < 100 and not state.config.petTank then
                write.Trace('Need aggro: %s',spawn.CleanName())
                return spawn.ID(), aggroMobCount
            elseif state.config.petTank and mq.TLO.Target.AggroHolder.ID() ~= mq.TLO.Me.Pet.ID() then
                write.Trace('Need aggro: %s',spawn.CleanName())
                return spawn.ID(), aggroMobCount
            end

        end
    end

    if not state.config.petTank then
        aggroMobCount = mq.TLO.SpawnCount(aggroSearch)()
        if (mq.TLO.Target.Type() == 'Corpse' or mq.TLO.Target.ID() == 0) then
            return mq.TLO.Me.XTarget(1).ID(), aggroMobCount
        end
        return mq.TLO.Target.ID(), aggroMobCount
    else
        aggroMobCount = mq.TLO.SpawnCount(aggroSearch)()
        if (mq.TLO.Me.Pet.Target.Type() == 'Corpse' or mq.TLO.Target.ID() == 0) then
            return mq.TLO.Me.XTarget(1).ID(), aggroMobCount
        end
        return mq.TLO.Me.Pet.Target.ID(), aggroMobCount
    end
end

function mod.attemptTaunt()
    write.Trace('attemptTaunt function')
    local abils = require('routines.abils')
    if not mq.TLO.Target() then return false end
    if mq.TLO.Target.Aggressive() then 
        if state.config.tankTaunting and abils.isAbilReady("Taunt", "Skill", 0, false) then
            abils.doAbility("Taunt", "Skill", 'not None')
            return true
        end
    end
    return false
end

function mod.doSingleAggro()
    if state.paused then return end
    local abils = require('routines.abils')
    for _, v in ipairs(state.config.aggroabils[state.class]) do
        if not v.ae and v.active and abils.isAbilReady(v.name, v.type, 0, false) and abils.loadAbilCond(v.cond) then
            abils.doAbility(v.name, v.type, 'not None')
            break
        end
    end
end

function mod.doAEAggro(mobCount)
    if state.paused then return end
    local abils = require('routines.abils')
    for _, v in ipairs(state.config.aggroabils[state.class]) do
        if v.ae and v.active and abils.isAbilReady(v.name, v.type, 0, false) and abils.loadAbilCond(v.cond) then
            if mobCount >= v.mobcount then
                abils.doAbility(v.name, v.type, 'not None')
                break
            end
        end
    end
end

function mod.tankNav()
    if state.campxloc and state.config.returnToCamp then
        if not ((state.campxloc - state.config.campRadius < mq.TLO.Me.X() and mq.TLO.Me.X() < state.campxloc + state.config.campRadius) and (state.campyloc - state.config.campRadius < mq.TLO.Me.Y() and mq.TLO.Me.Y() < state.campyloc + state.config.campRadius) and (state.campzloc - 35 < mq.TLO.Me.Z() and mq.TLO.Me.Z() < state.campzloc + 35)) and not mq.TLO.Navigation.Active() and mq.TLO.Navigation.PathExists('locxyz '.. state.campxloc .. ' ' .. state.campyloc .. ' ' .. state.campzloc)() and not mq.TLO.Target.Fleeing() then
            write.Info('Returning to camp')
            mq.cmdf('/squelch /nav locxyz %s %s %s',state.campxloc,state.campyloc,state.campzloc)
        end
    end
end




function mod.doTanking()
    write.Trace('doTanking function')
    if state.paused then return end
    if not state.config.doTanking then return end
    if lib.combatStatus() == 'out' then return end
    if state.config.movement ~= 'auto' then return end

    state.updateLoopState()

    local targetID, aggroMobCount = mod.getNextTankTarget()
    if not targetID then
        write.Debug("No valid tank target found")
        return
    end

    if mq.TLO.Target.ID() ~= targetID then
        mq.cmdf('/squelch /mqt id %s',targetID)
        mq.delay(250)
    end


    write.Trace('tankCombat function')
    if mq.TLO.Target.ID() ~= 0 and mq.TLO.Target.MaxRangeTo() and not mq.TLO.Target.Dead() and mq.TLO.Target.Aggressive() and (mq.TLO.Target.Distance3D() or 500) <= state.config.tankEngageRadius and (mq.TLO.Target.Distance3D() or 0) >= (mq.TLO.Target.MaxRangeTo() - 3) and not mq.TLO.Navigation.Active() then
        write.Debug('Tank Sticking')
        mq.cmdf('/squelch /multiline ; /stick %s uw ; /attack on ; /if (${Target.Distance3D}>50) /nav target dist=%s',(mq.TLO.Target.MaxRangeTo() - 3),(mq.TLO.Target.MaxRangeTo() - 3))
        mq.delay(150)
    elseif mq.TLO.Target.ID() ~= 0 and mq.TLO.Target.MaxRangeTo() and not mq.TLO.Target.Dead() and mq.TLO.Target.Aggressive() and (mq.TLO.Target.Distance3D() or 0) <= (mq.TLO.Target.MaxRangeTo() - 3) and (mq.TLO.Target.Distance3D() or 500) <= state.config.tankEngageRadius and not mq.TLO.Navigation.Active() then
        mq.cmd('/attack on')
        if not mq.TLO.Stick.Active() then mq.cmdf('/squelch /stick %s moveback uw',(mq.TLO.Target.MaxRangeTo() - 3)) end
        if mq.TLO.Target.Aggressive() and (mq.gettime() - state.facetimer) > 3000 and not mq.TLO.Me.Moving() then 
            mq.cmd('/squelch /face fast') 
            state.facetimer = mq.gettime()
        end
    end



    local tauntSuccess = mod.attemptTaunt()

    if not tauntSuccess and mq.TLO.Me.PctAggro() < 100 then
        mod.doSingleAggro()
    end

    mod.doAEAggro(aggroMobCount)

    mod.tankNav()

    mod.checkFacingLogic()

end

return mod