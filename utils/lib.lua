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

function mod.combatStatus()
    write.Trace('combatStatus function')
    if mq.TLO.Me.Combat() then write.Trace('In Combat') return 'combat' end
    if mq.TLO.Me.CombatState() == 'COMBAT' then write.Trace('Combat State') return 'combat' end
    if state.assistSpawn then
        if (state.assistSpawn.PctHPs() or math.huge) <= state.config.attackAt then 
            write.Trace('Group Engaged') return 'combat' 
        end
    end
    local table = mq.getFilteredSpawns(function(s) return s.Aggressive() and s.Distance3D() <= state.config.attackRange and s.Type() == 'NPC' end)
    if #table > 0 then write.Trace('Engaged') return 'engaged' end
    write.Trace('Out')
    return 'out' 
end

function mod.formatTimestamp(eventTimestamp)
    -- Calculate the elapsed milliseconds since the event occurred
    local elapsedMilliseconds = eventTimestamp - state.scriptStartMilliseconds
    -- Add the elapsed seconds to the script start time
    local absoluteTime = state.scriptStartTime + math.floor(elapsedMilliseconds / 1000)
    -- Format the absolute time into a readable string
    return os.date("%Y-%m-%d %H:%M:%S", absoluteTime)
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
    local aggro = false
    for i = 1,20 do
        if mq.TLO.Me.XTarget(i).ID() ~= 0 and mq.TLO.Me.XTarget(i).PctAggro() == 100 then
            aggro = true
            break
        end
    end
    return aggro
end

function mod.getclassicon()
    local class = mq.TLO.Me.Class.ShortName()
    if class == 'BRD' then return 8644 end
    if class == 'BST' then return 8645 end
    if class == 'BER' then return 8646 end
    if class == 'CLR' then return 8647 end
    if class == 'DRU' then return 8648 end
    if class == 'ENC' then return 8649 end
    if class == 'MAG' then return 8650 end
    if class == 'MNK' then return 8651 end
    if class == 'NEC' then return 8652 end
    if class == 'PAL' then return 8653 end
    if class == 'RNG' then return 8654 end
    if class == 'ROG' then return 8655 end
    if class == 'SHD' then return 8656 end
    if class == 'SHM' then return 8657 end
    if class == 'WAR' then return 8658 end
    if class == 'WIZ' then return 8659 end
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

function mod.unZipIgnores()
    local idtable = {}
    for _, v in pairs(state.config.ignores) do
        if v[1] == mq.TLO.Zone.ShortName() then
            for _, v2 in ipairs(state.config.ignores[mq.TLO.Zone.ShortName()]) do
                if v2 ~= mq.TLO.Zone.ShortName() then table.insert(idtable,mq.TLO.Spawn(v2).ID()) end
            end
            return idtable
        end
    end
    if not state.config.ignores[mq.TLO.Zone.ShortName()] then 
        state.config.ignores[mq.TLO.Zone.ShortName()] = {} 
        return idtable
    end
    return idtable
end

function mod.zipIgnores()
    local nametable = {}
    for _, v in ipairs(state.pullIgnores) do
        table.insert(nametable,mq.TLO.Spawn(v).Name())
    end
    table.insert(nametable,1,mq.TLO.Zone.ShortName())
    return nametable
end

function mod.getAssistTarget()
    local spawntbl = nil
    if state.config.assistType == 'Group MA' then
        state.maname = mq.TLO.Group.MainAssist.Name()
        return mq.TLO.Me.GroupAssistTarget
    elseif state.config.assistType == 'Raid MA' then
        state.maname = mq.TLO.Raid.MainAssist.Name()
        return mq.TLO.Me.RaidAssistTarget
    elseif state.config.assistType == 'Custom Name' then
        spawntbl = mod.initAssistObserver(state.config.assistTypeCustName)
        return spawntbl
    elseif state.config.assistType == 'Custom ID' then
        spawntbl = mod.initAssistObserver(mq.TLO.Spawn(state.config.assistTypeCustID).Name())
        return spawntbl
    end
end

function mod.getChaseTarget()
    if state.config.chaseType == 'Group MA' then
        return mq.TLO.Spawn(mq.TLO.Group.MainAssist.ID())
    elseif state.config.chaseType == 'Group Tank' then
        return mq.TLO.Spawn(mq.TLO.Group.MainTank.ID())
    elseif state.config.chaseType == 'Custom Name' then
        return mq.TLO.Spawn(mq.TLO.Spawn(state.config.chaseTypeCustName).ID())
    elseif state.config.chaseType == 'Custom ID' then
        return mq.TLO.Spawn(state.config.chaseTypeCustID)
    end
end

function mod.initToon(toon)
    write.Help('Initializing DanNet Observers for ' .. toon.Name() .. '...')
    for _, v in ipairs(state.config.cureAvoids) do
        mq.cmdf('/dobserve %s -q "%s"',toon.Name(),"Me.Buff['" .. v .. "']")
        mq.delay(20)
    end

    mq.cmdf('/dobserve %s -q "%s"',toon.Name(),'Me.CountersDisease')
    mq.delay(20)
    mq.cmdf('/dobserve %s -q "%s"',toon.Name(),'Me.CountersPoison')
    mq.delay(20)
    mq.cmdf('/dobserve %s -q "%s"',toon.Name(),'Me.CountersCurse')
    mq.delay(20)
    mq.cmdf('/dobserve %s -q "%s"',toon.Name(),'Me.CountersCorruption')
    mq.delay(20)
    mq.cmdf('/dobserve %s -q "%s"',toon.Name(),'Debuff.Detrimentals')
    mq.delay(20)
    mq.cmdf('/dobserve %s -q "%s"',toon.Name(),'Me.Buff[Resurrection Sickness]')
    mq.delay(20)
    mq.cmdf('/dobserve %s -q "%s"',toon.Name(),'Me.Buff[Revival Sickness]')
    mq.delay(20)
end

function mod.findBuffAbility(buffName)
    local buffAbilities = state.config.buffabils[state.class] or {}
    for i, abil in ipairs(buffAbilities) do
        if abil.name:lower() == buffName:lower() then
            return i
        end
    end
    return nil
end

function mod.findCureAbility(cureName)
    local healAbilities = state.config.healabils[state.class] or {}
    for i, abil in ipairs(healAbilities) do
        if abil.cure and abil.name:lower() == cureName:lower() then
            return i
        end
    end
    return nil
end

function mod.initObservers()
    for i = 1, mq.TLO.Me.GroupSize() - 1 do
        mod.initToon(mq.TLO.Group.Member(i))
    end
end

function mod.initAssistObserver(mainassist)
    if not mainassist then write.Error('Custom Main Assist not declared correctly. Defaulting to group main assist.') return mq.TLO.Group.MainAssist end
    if not mq.TLO.DanNet(mainassist)() and (mq.gettime() - state.outAssistTarTimer) > 1000 then
        if mq.TLO.Spawn(mainassist)() and not state.paused then mq.cmdf('/assist %s',mainassist) end
        mq.delay(350)
        if not mq.TLO.Target() then return state.assistSpawn
        else
            local tbl = {}
            local curhp = mq.TLO.Target.PctHPs()
            local agg = mq.TLO.Target.Aggressive()
            local maxrngto = mq.TLO.Target.MaxRangeTo()
            local id = mq.TLO.Target.ID()
            local dis = mq.TLO.Target.Distance3D()
            tbl.hpval = curhp
            state.maname = mainassist
            function tbl.PctHPs() return curhp end
            function tbl.Aggressive() return agg end
            function tbl.MaxRangeTo() return maxrngto end
            function tbl.ID() return id end
            function tbl.Distance3D() return dis end
            state.outAssistTarTimer = mq.gettime()
            return tbl
        end
    end
    if (not mq.TLO.DanNet(mainassist).O('Target.ID')() or mq.TLO.DanNet(mainassist).O('Target.ID')() == 'NULL') and mq.TLO.DanNet(mainassist)() then
        write.Help('Initializing main assist observer on ' .. mainassist)
        mq.cmdf('/dobserve %s -q "%s"',mq.TLO.NearestSpawn(string.format('pc %s',mainassist)).Name(),'Target.PctHPs')
        mq.delay(20)
        mq.cmdf('/dobserve %s -q "%s"',mq.TLO.NearestSpawn(string.format('pc %s',mainassist)).Name(),'Target.Aggressive')
        mq.delay(20)
        mq.cmdf('/dobserve %s -q "%s"',mq.TLO.NearestSpawn(string.format('pc %s',mainassist)).Name(),'Target.MaxRangeTo')
        mq.delay(20)
        mq.cmdf('/dobserve %s -q "%s"',mq.TLO.NearestSpawn(string.format('pc %s',mainassist)).Name(),'Target.ID')
        mq.delay(20)
        mq.cmdf('/dobserve %s -q "%s"',mq.TLO.NearestSpawn(string.format('pc %s',mainassist)).Name(),'Target.Distance3D')
    end
    local tbl = {}
    tbl.hpval = tonumber(mq.TLO.DanNet(mainassist).O('Target.PctHPs')())
    state.maname = mainassist
    function tbl.PctHPs()
        return tonumber(mq.TLO.DanNet(mainassist).O('Target.PctHPs')())
    end
    function tbl.Aggressive()
        return mq.TLO.DanNet(mainassist).O('Target.Aggressive')()
    end
    function tbl.MaxRangeTo()
        return tonumber(mq.TLO.DanNet(mainassist).O('Target.MaxRangeTo')())
    end
    function tbl.ID()
        return tonumber(mq.TLO.DanNet(mainassist).O('Target.ID')())
    end
    function tbl.Distance3D()
        return tonumber(mq.TLO.DanNet(mainassist).O('Target.Distance3D')())
    end
    return tbl
end

function mod.checkCharm()
    if state.currentpet ~= nil and state.currentpet ~= 0 then
        local pet = mq.TLO.Spawn(state.currentpet)
        if pet then
            if not pet.Dead() and (pet.Distance3D() or 500) < 200 and mq.TLO.Pet.ID() == 0 then
                return true
            end
        end
    end
    return false
end


function mod.checkFD()
    mq.doevents("failfeign")
    if mq.TLO.Me.Feigning() and (not state.feigned) and (state.class ~= 'MNK' and state.class ~= 'BST' and state.class ~= 'SHD' and state.class ~= 'NEC') and not state.config.feignOverride then
        mq.cmd('/stand')
    end
    if mq.TLO.Me.Ducking() then 
        mq.cmd('/keypress x')
    end
end

return mod