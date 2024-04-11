local mq = require('mq')
local write = require('utils.Write')
local state = require('utils.state')
local lib = require('utils.lib')

local mod = {}

function mod.handleTarget()
    write.Trace('handleTarget function')
    if (mq.TLO.Target.ID() or 0) ~= (mq.TLO.Me.GroupAssistTarget.ID() or 0) and lib.combatStatus() ~= 'out' then
        mq.cmdf('/squelch /mqt id %s',mq.TLO.Me.GroupAssistTarget.ID())
        mq.delay(150)
    end
end

function mod.doFacing()
    write.Trace('doFacing function')
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
    write.Trace('initialCombatNav function')
    if mq.TLO.Me.GroupAssistTarget.MaxRangeTo() and (mq.TLO.Target.ID() or 0) ~= 0 and not mq.TLO.Target.Dead() and (mq.TLO.Target.PctHPs() or 100) <= state.config.attackAt and mq.TLO.Target.Aggressive() and (mq.TLO.Target.Distance3D() or 500) <= state.config.attackRange and (mq.TLO.Target.Distance3D() or 0) >= (mq.TLO.Me.GroupAssistTarget.MaxRangeTo() - 3) and not mq.TLO.Navigation.Active() then
        mq.cmdf('/squelch /multiline ; /stick %s moveback uw ; /attack on ; /nav target dist=%s',(mq.TLO.Me.GroupAssistTarget.MaxRangeTo() - 3),(mq.TLO.Me.GroupAssistTarget.MaxRangeTo() - 3))
        mq.delay(150)
        return true
    end
    return false
end

function mod.keepAttached()
    write.Trace('keepAttached function')
    if mq.TLO.Me.GroupAssistTarget.MaxRangeTo() and (mq.TLO.Target.ID() or 0) ~= 0 and not mq.TLO.Target.Dead() and (mq.TLO.Target.PctHPs() or 100) <= state.config.attackAt and mq.TLO.Target.Aggressive() and (mq.TLO.Target.Distance3D() or 500) <= (mq.TLO.Me.GroupAssistTarget.MaxRangeTo() - 3) and not mq.TLO.Navigation.Active() then
        mq.cmdf('/squelch /multiline ; /stick %s moveback uw ; /attack on',(mq.TLO.Me.GroupAssistTarget.MaxRangeTo() - 3)) 
        mq.delay(10)
    end
end

function mod.checkPet()
    write.Trace('checkPet function')
    if not mq.TLO.Me.GroupAssistTarget.ID() then return end
    if mq.TLO.Me.Pet() and mq.TLO.Me.GroupAssistTarget.ID ~= 0 and mq.TLO.Me.GroupAssistTarget.Aggressive() and (mq.TLO.Me.GroupAssistTarget.PctHPs() or 100) <= state.config.petAttackAt and (not mq.TLO.Pet.Combat() or mq.TLO.Pet.Target.ID() ~= mq.TLO.Me.GroupAssistTarget.ID()) and (mq.TLO.Me.GroupAssistTarget.Distance3D() or 500) <= state.config.petRange then
        mq.cmdf('/squelch /pet attack %s', mq.TLO.Me.GroupAssistTarget.ID())
    end

end

function mod.checkCombat()
    write.Trace('checkCombat function')
    state.updateLoopState()
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