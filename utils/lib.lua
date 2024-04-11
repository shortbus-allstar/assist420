local mq = require('mq')
local state = require('utils.state')
local write = require('utils.Write')

local mod = {}
local zoneIds = {151, 202, 203, 219, 344, 345, 463, 737, 33480, 33113}

function mod.inControl()
    return not (mq.TLO.Me.Dead() or mq.TLO.Me.Charmed() or mq.TLO.Me.Stunned() or mq.TLO.Me.Silenced() or mq.TLO.Me.Mezzed() or mq.TLO.Me.Invulnerable() or mq.TLO.Me.Hovering())
end

function mod.isBlockingWindowOpen()
    -- check blocking windows -- BigBankWnd, MerchantWnd, GiveWnd, TradeWnd
    return mq.TLO.Window('BigBankWnd').Open() or mq.TLO.Window('MerchantWnd').Open() or mq.TLO.Window('GiveWnd').Open() or mq.TLO.Window('TradeWnd').Open() or mq.TLO.Window('LootWnd').Open() or mq.TLO.Window('SpellBookWnd').Open()
end

function mod.castready()
    return not mq.TLO.Me.Invis() and mq.TLO.Melee.Immobilize() and not mq.TLO.Me.Moving() and mod.inControl() and not mod.isBlockingWindowOpen() and mq.TLO.Cast.Timing() == 0 and not mq.TLO.Me.Feigning()
end

function mod.meleeready()
    return not mq.TLO.Me.Invis() and mod.inControl() and not mod.isBlockingWindowOpen() and not mq.TLO.Me.Feigning()
end

function mod.incombat() 
    return mq.TLO.Me.Combat() and (mq.TLO.Target.Distance3D() or math.huge) < state.config.attackRange and mq.TLO.Target.Aggressive() and mod.meleeready()
end

function mod.debugxtars()
    local xtarheals = tonumber(state.config.General.XTarHealList)
    write.Info('Debugging XTarget...')
    mq.cmd('/squelch /assist off')
    mq.cmd('/squelch /melee plugin=0')
    for i = 1,20 - xtarheals do
        mq.cmdf('/xtar set %s ah',i)
        mq.delay(20)
    end
end

function mod.combatStatus()
    write.Trace('combatStatus function')
    if mq.TLO.Me.Combat() then return 'combat' end
    if mq.TLO.Me.CombatState() == 'COMBAT' then return 'combat' end
    if mq.TLO.Me.GroupAssistTarget() and mq.TLO.Me.GroupAssistTarget.PctHPs() <= state.config.attackAt then return 'combat' end
    local table = mq.getFilteredSpawns(function(s) return s.Aggressive() and s.Distance3D() <= state.config.attackRange and s.Type() == 'NPC' end)
    if #table > 0 then return 'engaged' end
    return 'out' 
end

function mod.XTAggroCount()
    write.Trace('XTAggroCount function')
    local count = 0
    for i = 1,20 do
        if mq.TLO.Me.XTarget(i).ID() ~= 0 and mq.TLO.Me.XTarget(i).TargetType() == 'Auto Hater' then
            count = count + 1
        end
    end
    return count
end

function mod.fullAggro()
    for i = 1,20 do
        if mq.TLO.Me.XTarget(i).ID() ~= 0 and mq.TLO.Me.XTarget(i).PctAggro() == 100 then
            return true
        end
        mq.delay(10)
    end
    return false
end


function mod.findIndex(tbl, value)
    for i, v in pairs(tbl) do
        if v == value then
            return i
        end
    end
    return nil
end

function mod.passiveZone(id)
    for _, zoneId in ipairs(zoneIds) do
        if id == zoneId then
            return true
        end
    end
    return false
end

function mod.checkFD()
    if mq.TLO.Me.Feigning() and (not state.feigned) and state.class ~= 'MNK' and state.class ~= 'BST' and state.class ~= 'SHD' and state.class ~= 'NEC' then
        mq.cmd('/stand')
    end
    if mq.TLO.Me.Ducking() then 
        mq.cmd('/keypress x')
    end
end

return mod