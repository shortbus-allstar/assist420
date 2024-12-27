local mq = require('mq')
local write = require('utils.Write')
local state = require('utils.state')
local lib = require('utils.lib')

local mod = {}

function mod.handleTarget()
    write.Trace('handleTarget function')
    if (mq.TLO.Target.ID() or 0) ~= (state.assistSpawn.ID() or 0) and lib.combatStatus() ~= 'out' then
        mq.cmdf('/squelch /mqt id %s',state.assistSpawn.ID())
        mq.delay(150)
    end
end

function mod.doFacing()
    write.Trace('doFacing function')
    if state.backoff then return false end
    if mq.TLO.Target.Aggressive() and (mq.gettime() - state.facetimer) > 3000 and not mq.TLO.Me.Moving() then 
        mq.cmd('/squelch /face fast') 
        state.facetimer = mq.gettime()
    elseif not mq.TLO.Target.Aggressive() and mq.TLO.Me.Combat() then
        mq.cmd('/attack off')
        return false
    end
    if mq.TLO.Target.Aggressive() then return true end
end

function mod.initialCombatNav()
    if state.backoff then return false end
    write.Trace('initialCombatNav function')
    if state.assistSpawn.MaxRangeTo() and mq.TLO.Target.ID() ~= 0 and not mq.TLO.Target.Dead() and (mq.TLO.Target.PctHPs() or 100) <= state.config.attackAt and mq.TLO.Target.Aggressive() and (mq.TLO.Target.Distance3D() or 500) <= state.config.attackRange and (mq.TLO.Target.Distance3D() or 0) >= (state.assistSpawn.MaxRangeTo() - 3) and not mq.TLO.Navigation.Active() then
        mq.cmdf('/squelch /multiline ; /stick %s moveback uw ; /attack on ; /if (${Target.Distance3D}>50) /nav target dist=%s',(state.assistSpawn.MaxRangeTo() - 3),(state.assistSpawn.MaxRangeTo() - 3))
        mq.delay(150)
        return true
    end
    return false
end

function mod.keepAttached()
    if state.backoff then return end
    write.Trace('keepAttached function')
    if state.assistSpawn.MaxRangeTo() and mq.TLO.Target.ID() ~= 0 and not mq.TLO.Target.Dead() and (mq.TLO.Target.PctHPs() or 100) <= state.config.attackAt and mq.TLO.Target.Aggressive() and (mq.TLO.Target.Distance3D() or 500) <= state.config.attackRange and not mq.TLO.Navigation.Active() then
        mq.cmdf('/squelch /multiline ; /stick %s moveback uw ; /attack on',(state.assistSpawn.MaxRangeTo() - 3)) 
        mq.delay(10)
    end
end

function mod.checkPet()
    write.Trace('checkPet function')
    if not state.assistSpawn.ID() then return end
    if state.backoff then return end
    if mq.TLO.Me.Pet() and state.assistSpawn.ID ~= 0 and state.assistSpawn.Aggressive() and (state.assistSpawn.PctHPs() or 100) <= state.config.petAttackAt and (not mq.TLO.Pet.Combat() or mq.TLO.Pet.Target.ID() ~= state.assistSpawn.ID()) and (state.assistSpawn.Distance3D() or 500) <= state.config.petRange then
        mq.cmdf('/squelch /pet attack %s', state.assistSpawn.ID())
    end

end

function mod.checkCombat()
    write.Trace('checkCombat function')
    state.updateLoopState()
    if state.backoff then return end
    if state.pulling then return end
    if state.config.movement ~= 'auto' then return end
    if state.paused then return end
    mod.checkPet()
    mod.handleTarget()
    if not mod.doFacing() then return end
    if mod.initialCombatNav() then return end
    mod.keepAttached()
end

return mod