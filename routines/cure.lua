local mq = require('mq')
local state = require('utils.state')
local write = require('utils.Write')
local mod = {}

function mod.dontcure(toon)
    for _, v in pairs(state.config.cureAvoids) do
        if mq.TLO.DanNet(toon).O(v) ~= 'NULL' then 
            return true
        end
    end
    return false
end

function mod.selfdontcure()
    for _, v in pairs(state.config.cureAvoids) do
        if mq.TLO.Me.Buff(v)() then 
            return true
        end
    end
    return false
end

function mod.getCounts(toon)
    local diseaseCounters = 'Me.CountersDisease'
    local poisonCounters = 'Me.CountersPoison'
    local curseCounters = 'Me.CountersCurse'
    local corCounters = 'Me.CountersCorruption'
    local dcount = tonumber(mq.TLO.DanNet(toon).O(diseaseCounters)())
    local pcount = tonumber(mq.TLO.DanNet(toon).O(poisonCounters)())
    local cucount = tonumber(mq.TLO.DanNet(toon).O(curseCounters)())
    local cocount = tonumber(mq.TLO.DanNet(toon).O(corCounters)())
    return dcount, pcount, cucount, cocount
end

function mod.rezSickCount(toon)
    local cnt = 0
    if mq.TLO.DanNet(toon).O('Me.Buff[Resurrection Sickness]') then
        cnt = cnt + 1
    end
    if mq.TLO.DanNet(toon).O('Me.Buff[Revival Sickness]') then
        cnt = cnt + 1
    end
    return cnt
end

function mod.rezSickSelf()
    local cnt = 0
    if mq.TLO.Me.Buff('Resurrection Sickness')() then
        cnt = cnt + 1
    end
    if mq.TLO.Me.Buff('Revival Sickness')() then
        cnt = cnt + 1
    end
    return cnt
end

function mod.shouldCastDetrimentals(toon)
    -- Determine the return value type for 'Debuff.Detrimentals'
    local detrimentals = mq.TLO.DanNet(toon).O('Debuff.Detrimentals')()
    local rezSickCount = mod.rezSickCount(toon)

    -- Check if detrimentals is a number or a boolean
    if type(detrimentals) == "number" then
        -- Integer version: Cast detrimentals if number of detrimentals > rezSick count
        return detrimentals > rezSickCount
    elseif type(detrimentals) == "boolean" then
        -- Boolean version: Cast detrimentals if true and rezSick count is 0
        return detrimentals and rezSickCount == 0
    end

    -- If the return type is unexpected, return false
    return false
end

function mod.shouldCastDetrimentalsSelf()
    -- Determine the return value type for 'Debuff.Detrimentals'
    local detrimentals = mq.TLO.Debuff.Detrimentals()
    local rezSickCount = mod.rezSickSelf()

    -- Check if detrimentals is a number or a boolean
    if type(detrimentals) == "number" then
        -- Integer version: Cast detrimentals if number of detrimentals > rezSick count
        return detrimentals > rezSickCount
    elseif type(detrimentals) == "boolean" then
        -- Boolean version: Cast detrimentals if true and rezSick count is 0
        return detrimentals and rezSickCount == 0
    end

    -- If the return type is unexpected, return false
    return false
end

function mod.checkGroupAil()
    if not state.config.doCuring then return nil end
    local curetarget = nil
    local curetype = nil
    local groupcureok = true
    local selfcureok = true
    local tocure = {}
    local grpSize = mq.TLO.Group.GroupSize() or 0
    if mod.selfdontcure() then
        write.Debug('Cant cure self, no group')
        groupcureok = false
        selfcureok = false
    end
    for i = 1, grpSize - 1 do
        local grpMem = mq.TLO.Group.Member(i).Name()
        if mq.TLO.DanNet(grpMem).ObserveCount() then
            local insert = true
            local hasbuff = mod.dontcure(grpMem)
            if hasbuff == true then
                groupcureok = false
                insert = false
            end
            if not mq.TLO.Group.Member(grpMem).Dead() and mq.TLO.Group.Member(grpMem).Present() and mod.shouldCastDetrimentals(grpMem) then
                curetype = 'det'
                curetarget = mq.TLO.Group.Member(grpMem).ID()
            end
            if insert == true then table.insert(tocure,grpMem) end
        end
    end
    if selfcureok == true then
        if mq.TLO.Me.CountersDisease() > 0 then
            curetarget = mq.TLO.Me.ID()
            curetype = 'disease'
            return curetarget, curetype, groupcureok
        end
        if mq.TLO.Me.CountersPoison() > 0 then
            curetarget = mq.TLO.Me.ID()
            curetype = 'poison'
            return curetarget, curetype, groupcureok
        end
        if mq.TLO.Me.CountersCurse() > 0 then
            curetarget = mq.TLO.Me.ID()
            curetype = 'curse'
            return curetarget, curetype, groupcureok
        end
        if mq.TLO.Me.CountersCorruption() > 0 then
            curetarget = mq.TLO.Me.ID()
            curetype = 'corr'
            return curetarget, curetype, groupcureok
        end
        if mod.shouldCastDetrimentalsSelf() then
            curetarget = mq.TLO.Me.ID()
            curetype = 'det'
            return curetarget, curetype, groupcureok
        end
    end
    for _, v in pairs(tocure) do
        local grpMem = mq.TLO.Group.Member(v).Name()
        local dcount, pcount, cucount, cocount = mod.getCounts(grpMem)
        write.Trace('DisCount: %s, PoiCount: %s, CoCount: %s, CuCount: %s',dcount, pcount, cocount, cucount)
        if dcount and dcount > 0 then
            curetarget = mq.TLO.Group.Member(v).ID()
            curetype = 'disease'
            if curetarget ~= nil then return curetarget, curetype, groupcureok end
        end
        if pcount and pcount > 0 then
            curetarget = mq.TLO.Group.Member(v).ID()
            curetype = 'poison'
            if curetarget ~= nil then return curetarget, curetype, groupcureok end
        end
        if cucount and cucount > 0 then
            curetarget = mq.TLO.Group.Member(v).ID()
            curetype = 'curse'
            if curetarget ~= nil then return curetarget, curetype, groupcureok end
        end
        if cocount and cocount > 0 then
            curetarget = mq.TLO.Group.Member(v).ID()
            curetype = 'corr'
            if curetarget ~= nil then return curetarget, curetype, groupcureok end
        end
    end
    return curetarget, curetype, groupcureok
end


return mod