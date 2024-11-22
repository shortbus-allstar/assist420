local mq = require('mq')
local state = require('utils.state')
local write = require('utils.Write')
local lib = require('utils.lib')

local mod = {}

mod.healAbilTemplate = {
    name = 'Enter Name Here',
    type = 'AA',
    cond = 'true',
    priority = 1,
    loopdel = 0,
    abilcd = 10,
    active = true,
    cure = false,
    curetype = "poison",
    rez = false,
    healpct = 75,
    usextar = true,
    usegrouptank = true,
    usegroupmember = true,
    useothertank = true,
    useself = true,
    usepets = true,
    aeheal = false,
    emergheal = false,
    hot = false,
    healtars = {}
}

--[[
1. Self
2. Tank -- allow adding multiple tanks manually by ID via state.config.healTanksList
3. Group
4. Xtar

1. Group Quick heal
2. Quick Heal
3. Group Heal
4. Regular Heal
5. Rez
6. Group HoT
7. HoT
8. Cure
]]--

--[[
1. Interrupt to Heal
2. Prioritize Self Heals At
3. Radiant Cure
4. Rez Fellowship
5. Rez Guild
]]--

local function getHealingTarget()
    -- Should return target and priority label
    local otherTanks = state.config.otherTankList or {}
    local groupMembers = {}

    if mq.TLO.Group then
        -- Collect group members (including self)
        for i = 1, mq.TLO.Group.GroupSize() do
            local member = mq.TLO.Group.Member(i)
            if member() then
                table.insert(groupMembers, member)
            end
        end
    else
        table.insert(groupMembers, mq.TLO.Me)
    end
    
    -- Variables to track targets
    local aeEmergencyCount = 0
    local aeHealCount = 0
    local aeHoTCount = 0
    local mostHurtGroupMember = nil
    local mostHurtGroupMemberPct = 100
    local regularHurtMember = nil
    local regularHurtPct = 100

    -- 1. AE Emergency
    for _, member in ipairs(groupMembers) do
        local memHP = member.PctHPs() or 100
        if memHP <= state.config.groupEmergencyPct then
            aeEmergencyCount = aeEmergencyCount + 1
        end
    end
    if aeEmergencyCount >= state.config.groupEmergencyMemberCount then
        return mq.TLO.Me, "AE Emergency"
    end

    -- 2. Self Emergency
    local myHP = mq.TLO.Me.PctHPs() or 100
    if myHP <= state.config.selfEmergencyPct then
        return mq.TLO.Me, "Self Emergency"
    end

    -- 3. Group Tank Emergency
    local mainTank = mq.TLO.Group.MainTank
    local mainTankHP = mainTank and mainTank.PctHPs() or 100
    if mainTankHP <= state.config.groupTankEmergencyPct then
        return mainTank, "Group Tank Emergency"
    end

    -- 4. Other Tank Emergency
    local mostHurtOtherTank = nil
    local mostHurtOtherTankPct = 100
    for _, tankName in pairs(otherTanks) do
        local tankSpawn = mq.TLO.Spawn(tankName)
        if tankSpawn() then
            local tankHP = tankSpawn.PctHPs() or 100
            if tankHP <= state.config.otherTankEmergencyPct and tankHP < mostHurtOtherTankPct then
                mostHurtOtherTank = tankSpawn
                mostHurtOtherTankPct = tankHP
            end
        end
    end
    if mostHurtOtherTank then
        return mostHurtOtherTank, "Other Tank Emergency"
    end

    -- 5. Group Member Emergency
    for _, member in ipairs(groupMembers) do
        local memHP = member.PctHPs() or 100
        if memHP <= state.config.groupMemberEmergencyPct and memHP < mostHurtGroupMemberPct then
            mostHurtGroupMember = member
            mostHurtGroupMemberPct = memHP
        end
        if memHP <= state.config.healAt then
            aeHealCount = aeHealCount + 1
        end
        if memHP <= state.config.hotAt then
            aeHoTCount = aeHoTCount + 1
        end
        if memHP <= state.config.healAt and memHP < regularHurtPct then
            regularHurtMember = member
            regularHurtPct = memHP
        end
    end
    if mostHurtGroupMember and mostHurtGroupMember ~= mq.TLO.Me then
        return mostHurtGroupMember, "Group Member Emergency"
    end

    -- Rezzing functions
    doTankRezzing()

    -- 6. AE Heal
    if aeHealCount >= state.config.groupHealMemberCount then
        return mq.TLO.Me, "AE"
    end

    -- 7. Group Tank
    if mainTank and mainTankHP <= state.config.healAt then
        return mainTank, "Group Tank"
    end

    -- 8. Self
    if myHP <= state.config.healAt then
        return mq.TLO.Me, "Self"
    end

    -- 9. Group Member
    if regularHurtMember and regularHurtMember ~= mq.TLO.Me then
        return regularHurtMember, "Group Member"
    end

    -- 10. Other Tank
    local tankHurt = nil
    local tankHurtPct = 100
    for _, tankName in pairs(otherTanks) do
        local tankSpawn = mq.TLO.Spawn(tankName)
        if tankSpawn() then
            local tankHP = tankSpawn.PctHPs() or 100
            if tankHP <= state.config.healAt and tankHP < tankHurtPct then
                tankHurt = tankSpawn
                tankHurtPct = tankHP
            end
        end
    end
    if tankHurt then
        return tankHurt, "Other Tank"
    end

    -- Rezzing functions
    doGroupRezzing()

    -- 11. XTarget Heals
    if state.config.xTarHealList and #state.config.xTarHealList > 0 then
        local xtarHurt = nil
        local xtarHurtPct = 100
        for xtarIndex = 1, state.config.xTarHealList do
            local xtar = mq.TLO.Me.XTarget(xtarIndex)
            if xtar() then
                local xtarHP = xtar.PctHPs() or 100
                if xtarHP <= state.config.healAt and xtarHP < xtarHurtPct then
                    xtarHurt = xtar
                    xtarHurtPct = xtarHP
                end
            end
        end
        if xtarHurt then
            return xtarHurt, "XTarget"
        end
    end

    -- 12. Group Pets
    if state.config.petHeals then
        local petHurt = nil
        local petHurtPct = 100
        for _, member in ipairs(groupMembers) do
            local pet = member.Pet()
            if pet() then
                local petHP = pet.PctHPs() or 100
                if petHP <= state.config.healAt and petHP < petHurtPct then
                    petHurt = pet
                    petHurtPct = petHP
                end
            end
        end
        if petHurt then
            return petHurt, "Group Pet"
        end
    end

    -- 13. AE HoT
    if aeHoTCount >= state.config.groupHoTMemberCount then
        return mq.TLO.Me, "AE HoT"
    end

    -- 14. HoT
    if state.config.hotTargets and #state.config.hotTargets > 0 then
        for _, targetName in ipairs(state.config.hotTargets) do
            local member = mq.TLO.Spawn(targetName)
            if member() then
                local lastHoTTime = state.config.hotTimers[member.ID()] or 0
                local timeSinceLastHoT = mq.gettime() - lastHoTTime
                local memberHP = member.PctHPs() or 100
                if timeSinceLastHoT >= state.config.hotRecastTime and memberHP <= state.config.hotAt then
                    state.config.hotTimers[member.ID()] = mq.gettime()
                    return member, "HoT"
                end
            end
        end
    end

    --All Rezzes
    doAllRezzes()

    -- Curing functions
    doCuring()

    -- No target found
    return nil, nil
end
