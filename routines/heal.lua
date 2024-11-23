local mq = require('mq')
local cures = require('routines.cure')
local state = require('utils.state')
local write = require('utils.Write')
local lib = require('utils.lib')

local mod = {}


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

local function findCorpse(searchString)

    local corpseCount = mq.TLO.SpawnCount(searchString)()

    if corpseCount > 0 then
        -- Directly retrieve the first corpse spawn
        local corpse = mq.TLO.Spawn(searchString)
        if corpse() then
            write.Debug("Found corpse for name: %s",searchString)
            return corpse
        else
            write.Warn("Corpse found but unable to retrieve spawn for name: %s", searchString)
            return nil
        end
    else
        return nil
    end
end

local function doTankRezzing()
    if not state.config.doRezzing then return nil end
    local mainTank = mq.TLO.Group and mq.TLO.Group.MainTank or nil

    -- 1. Check Main Tank's Corpse
    if mainTank then
        local mainTankName = mainTank.CleanName()
        local mainTankCorpse = findCorpse(string.format('pccorpse radius 100 zradius 50 %s',mainTankName))
        if mainTankCorpse and (not state.corpsetimers[mainTankCorpse.ID()] or (mq.gettime() - state.corpsetimers[mainTankCorpse.ID()]) >= state.config.rezCheckInterval) then
            return mainTankCorpse, "Group Tank Rez"
        end
    else
        write.Info("Not in a group; mainTank is nil.")
    end

    -- 2. Check Other Tanks' Corpses
    for _, tankName in ipairs(state.config.otherTankList) do
        local otherTankCorpse = findCorpse(string.format('pccorpse radius 100 zradius 50 %s',tankName))
        if otherTankCorpse and (not state.corpsetimers[otherTankCorpse.ID()] or (mq.gettime() - state.corpsetimers[otherTankCorpse.ID()]) >= state.config.rezCheckInterval) then
            return otherTankCorpse, "Other Tank Rez"
        end
    end

    -- 3. No Corpses Found
    return nil, nil
end

local function doGroupRezzing()
    if not state.config.doRezzing then return nil end

    local groupMembers = {}

    for i = 1, (mq.TLO.Group.GroupSize() or 1) - 1 do
        table.insert(groupMembers,mq.TLO.Group.Member(i))
    end

    for _, member in pairs(groupMembers) do
        local groupCorpse = findCorpse(string.format('pccorpse radius 100 zradius 50 %s',member.CleanName()))
        if groupCorpse and (not state.corpsetimers[groupCorpse.ID()] or (mq.gettime() - state.corpsetimers[groupCorpse.ID()]) >= state.config.rezCheckInterval) then
            return groupCorpse, "Group Rez"
        end
    end

    return nil, nil
end

local function doOtherRezzing()
    if not state.config.doRezzing then return nil end

    local selfSearch = string.format('pccorpse radius 100 zradius 50 %s',mq.TLO.Me.CleanName())
    local fellowSearch = 'pccorpse radius 100 zradius 50 fellowship'
    local guildSearch = 'pccorpse radius 100 zradius 50 guild'
    local raidSearch = 'pccorpse radius 100 zradius 50 raid'


    if mq.TLO.SpawnCount(raidSearch)() > 0 and (not state.corpsetimers[mq.TLO.Spawn(raidSearch).ID()] or (mq.gettime() - state.corpsetimers[mq.TLO.Spawn(raidSearch).ID()]) >= state.config.rezCheckInterval)then
        return mq.TLO.Spawn(raidSearch), "Raid Rez"
    end
    if mq.TLO.SpawnCount(fellowSearch)() > 0 and state.config.rezFellowship and (not state.corpsetimers[mq.TLO.Spawn(fellowSearch).ID()] or (mq.gettime() - state.corpsetimers[mq.TLO.Spawn(fellowSearch).ID()]) >= state.config.rezCheckInterval)then
        return mq.TLO.Spawn(fellowSearch), "Fellowship Rez"
    end
    if mq.TLO.SpawnCount(guildSearch)() > 0 and state.config.rezGuild and (not state.corpsetimers[mq.TLO.Spawn(guildSearch).ID()] or (mq.gettime() - state.corpsetimers[mq.TLO.Spawn(guildSearch).ID()]) >= state.config.rezCheckInterval)then
        return mq.TLO.Spawn(guildSearch), "Guild Rez"
    end
    if lib.combatStatus ~= "combat" then
        if mq.TLO.SpawnCount(selfSearch)() > 0 and (not state.corpsetimers[mq.TLO.Spawn(selfSearch).ID()] or (mq.gettime() - state.corpsetimers[mq.TLO.Spawn(selfSearch).ID()]) >= state.config.rezCheckInterval)then
            return mq.TLO.Spawn(selfSearch), "Self Rez"
        end
    end
end

function mod.getHealingTargets()
    if state.paused then return {} end
    -- Should return a list of targets and priority labels
    local otherTanks = state.config.otherTankList or {}
    local groupMembers = {}


    -- Collect group members (including self)
    for i = 1, mq.TLO.Group.GroupSize() or 0 do
        local member = mq.TLO.Group.Member(i)
        if member() and member.Present() then
            table.insert(groupMembers, member)
        end
    end

    table.insert(groupMembers, mq.TLO.Me)


    -- Variables to track targets
    local healTargets = {}
    local aeEmergencyCount = 0
    local aeHealCount = 0
    local aeHoTCount = 0
    local mostHurtGroupMember = nil
    local mostHurtGroupMemberPct = 100
    local regularHurtMember = nil
    local regularHurtPct = 100
    local mostHurtMem = nil
    local mostHurtMemHp = 100

    -- 1. AE Emergency
    for _, member in ipairs(groupMembers) do
        local memHP = member.PctHPs() or 100
        if memHP <= state.config.groupEmergencyPct and not member.Dead() then
            aeEmergencyCount = aeEmergencyCount + 1
            if memHP < mostHurtMemHp then
                mostHurtMemHp = memHP
                mostHurtMem = member
            end
        end
    end
    if aeEmergencyCount >= state.config.groupEmergencyMemberCount then
        table.insert(healTargets, {target = mostHurtMem, healtype = "AE Emergency"})
    end

    -- 2. Self Emergency
    local myHP = mq.TLO.Me.PctHPs() or 100
    if myHP <= state.config.selfEmergencyPct and not mq.TLO.Me.Dead() then
        table.insert(healTargets, {target = mq.TLO.Me, healtype = "Self Emergency"})
    end

    -- 3. Group Tank Emergency
    local mainTank = mq.TLO.Group and mq.TLO.Group.MainTank or nil
    local mainTankHP = mainTank and mainTank.PctHPs() or 100
    if mainTank and mainTankHP <= state.config.groupTankEmergencyPct and not mainTank.Dead() then
        table.insert(healTargets, {target = mainTank, healtype = "Group Tank Emergency"})
    end

    -- 4. Other Tank Emergency
    local mostHurtOtherTank = nil
    local mostHurtOtherTankPct = 100
    for _, tankName in pairs(otherTanks) do
        local tankSpawn = mq.TLO.Spawn(tankName)
        if tankSpawn() and not tankSpawn.Dead() then
            local tankHP = tankSpawn.PctHPs() or 100
            if tankHP <= state.config.otherTankEmergencyPct and tankHP < mostHurtOtherTankPct then
                mostHurtOtherTank = tankSpawn
                mostHurtOtherTankPct = tankHP
            end
        end
    end
    if mostHurtOtherTank then
        table.insert(healTargets, {target = mostHurtOtherTank, healtype = "Other Tank Emergency"})
    end

    -- 5. Group Member Emergency
    for _, member in ipairs(groupMembers) do
        local memHP = member.PctHPs() or 100
        if memHP <= state.config.groupMemberEmergencyPct and memHP < mostHurtGroupMemberPct and not member.Dead() then
            mostHurtGroupMember = member
            mostHurtGroupMemberPct = memHP
        end
        if memHP <= state.config.healAt and not member.Dead() then
            aeHealCount = aeHealCount + 1
        end
        if memHP <= state.config.hotAt and not member.Dead() then
            aeHoTCount = aeHoTCount + 1
        end
        if memHP <= state.config.healAt and memHP < regularHurtPct and not member.Dead() then
            regularHurtMember = member
            regularHurtPct = memHP
        end
    end
    if mostHurtGroupMember and mostHurtGroupMember ~= mq.TLO.Me then
        table.insert(healTargets, {target = mostHurtGroupMember, healtype = "Group Member Emergency"})
    end

    -- Rezzing functions
    local tankRezTar, tankRezType = doTankRezzing()
    if tankRezTar then
        table.insert(healTargets, {target = tankRezTar, healtype = tankRezType})
    end

    -- 6. AE Heal
    if aeHealCount >= state.config.groupHealMemberCount then
        table.insert(healTargets, {target = mostHurtGroupMember or mq.TLO.Me, healtype = "AE"})
    end

    -- 7. Group Tank
    if mainTank and mainTankHP <= state.config.healAt and not mainTank.Dead() then
        table.insert(healTargets, {target = mainTank, healtype = "Group Tank"})
    end

    -- 8. Self
    if myHP <= state.config.healAt and not mq.TLO.Me.Dead() then
        table.insert(healTargets, {target = mq.TLO.Me, healtype = "Self"})
    end

    -- 9. Group Member
    if regularHurtMember and regularHurtMember ~= mq.TLO.Me then
        table.insert(healTargets, {target = regularHurtMember, healtype = "Group Member"})
    end

    -- 10. Other Tank
    local tankHurt = nil
    local tankHurtPct = 100
    for _, tankName in pairs(otherTanks) do
        local tankSpawn = mq.TLO.Spawn(tankName)
        if tankSpawn() and not tankSpawn.Dead() then
            local tankHP = tankSpawn.PctHPs() or 100
            if tankHP <= state.config.healAt and tankHP < tankHurtPct then
                tankHurt = tankSpawn
                tankHurtPct = tankHP
            end
        end
    end
    if tankHurt then
        table.insert(healTargets, {target = tankHurt, healtype = "Other Tank"})
    end

    -- Rezzing functions
    local groupRezTar, groupRezType = doGroupRezzing()
    if groupRezTar then
        table.insert(healTargets, {target = groupRezTar, healtype = groupRezType})
    end

    -- 11. XTarget Heals
    if state.config.xTarHealList and state.config.xTarHealList > 0 then
        local xtarHurt = nil
        local xtarHurtPct = 100
        for xtarIndex = 1, state.config.xTarHealList do
            local xtar = mq.TLO.Me.XTarget(xtarIndex)
            if xtar() and not xtar.Dead() then
                local xtarHP = xtar.PctHPs() or 100
                if xtarHP <= state.config.healAt and xtarHP < xtarHurtPct then
                    xtarHurt = xtar
                    xtarHurtPct = xtarHP
                end
            end
        end
        if xtarHurt then
            table.insert(healTargets, {target = xtarHurt, healtype = "XTarget"})
        end
    end

    -- 12. Group Pets
    if state.config.petHeals then
        local petHurt = nil
        local petHurtPct = 100
        for _, member in ipairs(groupMembers) do
            local pet = member.Pet or nil
            if pet then 
                if pet.Dead() then
                    local petHP = pet.PctHPs() or 100
                    if petHP <= state.config.healAt and petHP < petHurtPct then
                        petHurt = pet
                        petHurtPct = petHP
                    end
                end
            end
        end
        if petHurt then
            table.insert(healTargets, {target = petHurt, healtype = "Group Pet"})
        end
    end

    -- 13. AE HoT
    if aeHoTCount >= state.config.groupHoTMemberCount and (mq.gettime() - (state.hotTimers[0] or 0)) >= state.config.hotRecastTime and (mq.gettime() - StartTime) >= 20000 then
        table.insert(healTargets, {target = mostHurtGroupMember or mq.TLO.Me, healtype = "AE HoT"})
    end

    -- 14. HoT
    if state.config.hotTargets and #state.config.hotTargets > 0 then
        for _, targetName in ipairs(state.config.hotTargets) do
            local member = mq.TLO.Spawn(targetName)
            if member() and not member.Dead() then
                local lastHoTTime = state.hotTimers[member.ID()]
                local timeSinceLastHoT = 0
                if lastHoTTime then
                    timeSinceLastHoT = mq.gettime() - lastHoTTime
                else
                    timeSinceLastHoT = math.huge -- Assign a large value to allow immediate casting
                end
                local memberHP = member.PctHPs() or 100
                if timeSinceLastHoT >= state.config.hotRecastTime and memberHP <= state.config.hotAt and (mq.gettime() - StartTime) >= 20000 then
                    table.insert(healTargets, {target = member, healtype = "HoT"})
                end
            end
        end
    end


    -- Other Rezzes
    local otherRezTar, otherRezType = doOtherRezzing()
    if otherRezTar then
        table.insert(healTargets, {target = otherRezTar, healtype = otherRezType})
    end

    -- Curing functions
    local cureTar, cureType, groupOk = cures.checkGroupAil()
    if cureTar then
        table.insert(healTargets, {target = cureTar, healtype = cureType, groupcureok = groupOk})
    end

    -- Return the list of heal targets
    return healTargets
end


function mod.processHeal(abiltable,cure,rez,hot)
    local abils = require('routines.abils')
    if state.paused then return nil end
    if not abiltable.active then return nil end
    if not abils.isAbilReady(abiltable.name,abiltable.type,abiltable.abilcd,false) then return nil end
    if not abils.loadAbilCond(abiltable.cond) then return nil end
    return abiltable, 'heals', cure, rez, hot
end

function mod.activateHeal(abiltable,delay,cure,rez,hot)
    if mq.TLO.Target.ID() ~= abiltable.tarid then
        if delay then
            if delay < 300 then return end
        end
        mq.cmdf('/squelch /mqt id %s',abiltable.tarid)
        write.Info('Targeting: %s',mq.TLO.Spawn(abiltable.tarid).CleanName())
        mq.delay(300)
    end
    local abils = require('routines.abils')
    local healtype = "Heal"
    if cure then healtype = "Cure" end
    if rez then healtype = "Rez" end
    if hot then healtype = "HoT" end
    if abiltable.aeheal and hot then healtype = "AE HoT" end
    local success, abildelay = abils.doAbility(abiltable.name,abiltable.type,abiltable.target,delay,healtype)
    if success then
        if abiltable.loopdel == 0 then return abildelay 
        else
            mq.delay(abiltable.loopdel)
            abildelay = math.huge
        end
    end
    return abildelay
end

function mod.doHeals()
    if state.paused then return nil, nil end
    local healabils = state.config.healabils[state.class]
    local queue = "heals"

    local healTargets = mod.getHealingTargets()
    if not healTargets or #healTargets == 0 then
        write.Debug("No heal targets found.")
        return nil, nil
    end

    for _, healData in ipairs(healTargets) do
        local healtarget = healData.target
        local healtype = healData.healtype
        local groupcureok = healData.groupcureok

        local healtargetprint = type(healtarget) ~= "number" and healtarget or mq.TLO.Spawn(healtarget).CleanName()

        write.Warn("Target: %s, Healtype: %s, GroupCure: %s", healtargetprint, healtype, tostring(groupcureok))

        for _, abil in pairs(healabils) do
            if not mod.processHeal(abil, abil.cure, abil.rez) then
                -- Continue to next ability
            else
                if abil.cure then
                    if groupcureok ~= nil then
                        if groupcureok == true then
                            if healtype == 'poison' and abil.curetype == 'Poison' and abil.aeheal then
                                abil["tarid"] = healtarget
                                return abil, queue
                            end
                            if healtype == 'disease' and abil.curetype == 'Disease' and abil.aeheal then
                                abil["tarid"] = healtarget
                                return abil, queue
                            end
                            if healtype == 'curse' and abil.curetype == 'Curse' and abil.aeheal then
                                abil["tarid"] = healtarget
                                return abil, queue
                            end
                            if healtype == 'corr' and abil.curetype == 'Corruption' and abil.aeheal then
                                abil["tarid"] = healtarget
                                return abil, queue
                            end
                            if healtype == 'det' and abil.curetype == 'Detrimental' and abil.aeheal then
                                abil["tarid"] = healtarget
                                return abil, queue
                            end
                            if healtype == 'poison' and abil.curetype == 'Poison' then
                                abil["tarid"] = healtarget
                                return abil, queue
                            end
                            if healtype == 'disease' and abil.curetype == 'Disease' then
                                abil["tarid"] = healtarget
                                return abil, queue
                            end
                            if healtype == 'curse' and abil.curetype == 'Curse' then
                                abil["tarid"] = healtarget
                                return abil, queue
                            end
                            if healtype == 'corr' and abil.curetype == 'Corruption' then
                                abil["tarid"] = healtarget
                                return abil, queue
                            end
                            if healtype == 'det' and abil.curetype == 'Detrimental' then
                                abil["tarid"] = healtarget
                                return abil, queue
                            end
                        elseif groupcureok == false then
                            if healtype == 'poison' and abil.curetype == 'Poison' and not abil.aeheal then
                                abil["tarid"] = healtarget
                                return abil, queue
                            end
                            if healtype == 'disease' and abil.curetype == 'Disease' and not abil.aeheal then
                                abil["tarid"] = healtarget
                                return abil, queue
                            end
                            if healtype == 'curse' and abil.curetype == 'Curse' and not abil.aeheal then
                                abil["tarid"] = healtarget
                                return abil, queue
                            end
                            if healtype == 'corr' and abil.curetype == 'Corruption' and not abil.aeheal then
                                abil["tarid"] = healtarget
                                return abil, queue
                            end
                            if healtype == 'det' and abil.curetype == 'Detrimental' and not abil.aeheal then
                                abil["tarid"] = healtarget
                                return abil, queue
                            end
                        end
                    end
                else
                    if healtype == 'AE Emergency' and abil.aeheal and abil.emergheal then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end
                    if healtype == 'Self Emergency' and abil.useself and abil.emergheal then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end
                    if healtype == 'Group Tank Emergency' and abil.usegrouptank and abil.emergheal then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end
                    if healtype == 'Other Tank Emergency' and abil.useothertank and abil.emergheal then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end
                    if healtype == 'Group Member Emergency' and abil.usegroupmember and abil.emergheal then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end
                    -- Check Tank Rezzes
                    if (healtype == 'Group Tank Rez' and abil.rez and abil.usegrouptank) or
                       (healtype == 'Other Tank Rez' and abil.rez and abil.useothertank) then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end
                    -- AE Heal
                    if healtype == 'AE' and abil.aeheal and not abil.emergheal then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end
                    -- Regular Heals
                    if healtype == 'Group Tank' and abil.usegrouptank and not abil.emergheal then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end
                    if healtype == 'Self' and abil.useself and not abil.emergheal then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end
                    if healtype == 'Group Member' and abil.usegroupmember and not abil.emergheal then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end
                    if healtype == 'Other Tank' and abil.useothertank and not abil.emergheal then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end
                    -- Check Group Rezzes
                    if healtype == 'Group Rez' and abil.rez and abil.usegroupmember then
                        abil["tarid"] = healtarget.ID()
                        write.Warn(abil.name)
                        return abil, queue
                    end
                    -- XTarget Heals
                    if healtype == 'XTarget' and abil.usextar then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end
                    -- Group Pets
                    if healtype == 'Group Pet' and abil.usepets then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end
                    -- AE HoT
                    if healtype == 'AE HoT' and abil.aeheal and abil.hot then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end
                    -- Single Target HoT
                    if healtype == 'HoT' and abil.hot and not abil.aeheal then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end
                    -- Check All Rezzes
                    if (healtype == 'Fellowship Rez' and abil.rez) or
                       (healtype == 'Guild Rez' and abil.rez) or
                       (healtype == 'Self Rez' and abil.rez and abil.useself) then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end

                    --No spell found, ditch emerg tags

                    if (healtype == 'AE Emergency' or healtype == "AE") and abil.aeheal and not abil.cure and not abil.rez and not abil.hot then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end
                    if (healtype == 'Self Emergency' or healtype == "Self") and abil.useself and not abil.cure and not abil.rez and not abil.hot then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end
                    if (healtype == 'Group Tank Emergency' or healtype == "Group Tank") and abil.usegrouptank and not abil.cure and not abil.rez and not abil.hot then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end
                    if (healtype == 'Other Tank Emergency' or healtype == "Other Tank") and abil.useothertank and not abil.cure and not abil.rez and not abil.hot then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end
                    if (healtype == 'Group Member Emergency' or healtype == "Group Member") and abil.usegroupmember and not abil.cure and not abil.rez and not abil.hot then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end

                    --Still no spell found, ditch ae tags

                    if (healtype == 'AE Emergency' or healtype == "AE") and not abil.cure and not abil.rez and not abil.hot then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end
                    if healtype == 'AE HoT' and abil.hot then
                        abil["tarid"] = healtarget.ID()
                        return abil, queue
                    end
                end
            end
        end
        -- If no ability found for this heal target, proceed to the next one
        local tarname = healtarget and type(healtarget) ~= "number" and healtarget.CleanName() or healtarget and mq.TLO.Spawn(healtarget).CleanName()
        write.Error('No matching heal abilities to heal %s! Heal type: %s', tarname, healtype)
    end

    -- No suitable ability found for any heal target
    write.Debug('No matching heal abilities found for any targets.')
    return nil, nil
end


return mod

