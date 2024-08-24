local mq = require('mq')
local state = require('utils.state')
local write = require('utils.Write')
local lib = require('utils.lib')

local mod = {}

function mod.checkMed()
    write.Trace('checkMed function')
    if not state.config.doMedding then return false end
    if lib.combatStatus() ~= 'out' and not state.config.combatMed then return false end
    if mq.TLO.Me.PctEndurance() <= state.config.medEndAt then 
        state.medding = true
        return true 
    end
    if mq.TLO.Me.PctMana() <= state.config.medManaAt and (state.class == 'BRD' or state.class == 'BST' or state.class == 'CLR' or state.class == 'DRU' or state.class == 'ENC' or state.class == 'MAG' or state.class == 'NEC' or state.class == 'PAL' or state.class == 'RNG' or state.class == 'SHD' or state.class == 'SHM' or state.class == 'WIZ') then 
        state.medding = true
        return true 
    end
    if ((mq.TLO.Me.PctMana() >= state.config.medStop) or state.class == 'MNK' or state.class == 'ROG' or state.class == 'WAR' or state.class == 'BER') and (mq.TLO.Me.PctEndurance() >= state.config.medStop) then
        state.medding = false
        return false
    end
    if state.medding == true then return true end
end

function mod.doMed()
    write.Trace('doMed function')
    state.updateLoopState()
    if state.paused then return end
    if state.config.movement ~= 'auto' then return end
    local shouldIMed = mod.checkMed()
    if not shouldIMed then return
    elseif state.medding == true and not mq.TLO.Me.Sitting() and not mq.TLO.Me.Moving() and mq.TLO.Cast.Timing() == 0 then 
        mq.cmd('/sit')
        write.Info('Sitting down to med')
    end
end

return mod