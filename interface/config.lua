local mq = require('mq')
local write = require('utils.Write')
local mod = {}

mod.path = "Assist420_" .. mq.TLO.Me.CleanName() .. '_' .. mq.TLO.EverQuest.Server() .. ".lua "
mod.configSettings = {
    abilities = {
        BRD = {},
        BER = {},
        BST = {},
        CLR = {},
        DRU = {},
        ENC = {},
        MAG = {},
        MNK = {
            {
                name = 'Flying Kick',
                type = 'Skill',
                target = 'None',
                cond = 'mq.TLO.Me.Combat()',
                custtar = '',
                priority = 1,
                loopdel = 0,
                abilcd = 10,
                active = true,
                usecombat = true,
                useooc = false,
                burn = false,
                feign = false
            },

            {
                name = 'Tiger Claw',
                type = 'Skill',
                target = 'None',
                cond = 'mq.TLO.Me.Combat()',
                custtar = '',
                priority = 2,
                loopdel = 0,
                abilcd = 10,
                active = true,
                usecombat = true,
                useooc = false,
                burn = false,
                feign = false
                }
        },
        NEC = {},
        PAL = {},
        RNG = {},
        ROG = {},
        SHD = {},
        SHM = {},
        WAR = {},
        WIZ = {}
    },
    aggroabils = {
        BRD = {},
        BER = {},
        BST = {},
        CLR = {},
        DRU = {},
        ENC = {},
        MAG = {},
        MNK = {},
        NEC = {},
        PAL = {},
        RNG = {},
        ROG = {},
        SHD = {
            {
                name = 'Terror of Rerekalen',
                type = 'Spell',
                cond = 'mq.TLO.Target.PctAggro() < 100',
                priority = 1,
                active = true,
                ae = false,
                loopdel = 0,
                abilcd = 10
            }
        },
        SHM = {},
        WAR = {},
        WIZ = {}
    },
    aeAggroEnabled = true,
    aeAggroMin = 2,
    assistType = 'Group MA',
    assistTypeCustName = '',
    assistTypeCustID = '',
    attackAt = 99,
    attackRange = 75,
    buffabils = {
        BRD = {},
        BER = {},
        BST = {},
        CLR = {},
        DRU = {},
        ENC = {},
        MAG = {},
        MNK = {},
        NEC = {},
        PAL = {},
        RNG = {},
        ROG = {},
        SHD = {},
        SHM = {},
        WAR = {},
        WIZ = {}
    },
    buffCheckInterval = 60000,
    burn = 'auto',
    campRadius = 20,
    cancelHealsAt = 95,
    chainPullHP = 100,
    chainPullMax = 2,
    chainPullToggle = true,
    charmBreakSpell = "",
    charmBreakType = "Spell",
    charmSpell = "",
    charmType = "Spell",
    chaseAssist = false,
    chaseDistance = 5,
    chaseMaxDistance = 300,
    chaseType = 'Group MA',
    chaseTypeCustName = '',
    chaseTypeCustID = '',
    combatMed = false,
    cureAvoids = {
        'Sunset\'s Shadow',
        'Discordant Detritus',
        'Frenzied Venom',
        'Viscous Venom',
        'Shadowed Venom',
        'Curator\'s Revenge'
    },
    debuffAETargetMin = 2,
    debuffStartAt = 100,
    debuffStopAt = 25,
    debuffZRadius = 50,
    debuffMode = 'Cycle Targets',
    debuffabils = {
        BRD = {},
        BER = {},
        BST = {},
        CLR = {},
        DRU = {},
        ENC = {},
        MAG = {},
        MNK = {},
        NEC = {},
        PAL = {},
        RNG = {},
        ROG = {},
        SHD = {},
        SHM = {},
        WAR = {},
        WIZ = {}
    },
    doBuffs = true,
    doCharm = false,
    doCuring = true,
    doDebuffs = true,
    doHealing = true,
    doMedding = true,
    doPulling = false,
    doRezzing = true,
    doTanking = false,
    events = {},
    feignOverride = true,
    groupEmergencyPct = 40,
    groupEmergencyMemberCount = 2,
    groupHealMemberCount = 3,
    groupHoTMemberCount = 2,
    groupMemberEmergencyPct = 35,
    groupTankEmergencyPct = 40,
    healabils = {
        BRD = {},
        BER = {},
        BST = {},
        CLR = {},
        DRU = {},
        ENC = {},
        MAG = {},
        MNK = {},
        NEC = {},
        PAL = {},
        RNG = {},
        ROG = {},
        SHD = {},
        SHM = {},
        WAR = {},
        WIZ = {}
    },
    healAt = 80,
    hotAt = 90,
    hotRecastTime = 60000,
    hotTargets = {},
    ignores = {},
    interruptToEmergHeal = true,
    keywords = {},
    loglevel = 'info',
    maxDebuffRange = 150,
    maxTrackedAbils = 100,
    medEndAt = 60,
    medManaAt = 60,
    medStop = 90,
    memSpellSetAtStart = false,
    miscGem = 7,
    movement = 'auto',
    otherTankEmergencyPct = 40,
    otherTankList = {},
    petAttackAt = 99,
    petHeals = true,
    petRange = 75,
    petTank = false,
    postPullAbilPause = 300,
    pullAbilName = 'Distant Strike',
    pullAbilType = 'AA',
    pullAbilRange = 200,
    pullPauseHealerMana = 30,
    pullPauseTankMana = 30,
    pullPauseTankEnd = 10,
    pullPauseConds = {
        'mq.TLO.Me.Buff(\'Revival Sickness\')() or mq.TLO.Me.Buff(\'Resurrection Sickness\')()'
    },
    pullRadius = 10000,
    pullZRange = 500,
    returnToCamp = false,
    rezCheckInterval = 10000,
    rezFellowship = true,
    rezGuild = true,
    role = 'assist',
    routines = {
        heals = 1, --Heals, Cures, Rezes
        conditions = 2, -- All conditions (mostly dps)
        buffs = 3, 
        debuffs = 4, -- mezes, slows, tash, malo, snare, root, cripple
        charm = 5,
    },
    standcond = 'mq.TLO.Me.PctHPs() == 100',
    selectedTheme = {
        windowbg = tostring(ImVec4(0.137, 0.224, 0.137, 1)),  
        bg = tostring(ImVec4(0.118, 0.376, 0.118, 1)),       
        hovered = tostring(ImVec4(0.078, 0.306, 0.078, 1)),   
        active = tostring(ImVec4(0.059, 0.267, 0.059, 1)),    
        button = tostring(ImVec4(0.118, 0.376, 0.118, 1)),   
        text = tostring(ImVec4(0.949, 0.949, 0.2, 1)),     
        name = 'Dank Marijuana Cat Piss Ganja'
    },
    selfEmergencyPct = 35,
    spellSetName = "",
    tankPetAttackPct = 99,
    tankTaunting = true,
    tankEngageRadius = 15,
    useMQ2Melee = false,
    xTarHealList = 4,
}


function mod.getConfig()
    write.Trace('getConfig Function')
    write.prefix = '\ay[\amASS\ag420\ay]\am:\at ' 
    local defaultcfg = mod.configSettings
    local configData, err = loadfile(mq.configDir .. '/' .. mod.path)
    
    if err then 
        write.Help('INI file not found. Hitting the dispo...')
        mq.pickle(mod.path, mod.configSettings)
    elseif configData then
        write.Help('INI file found at %s. Rolling up...', mod.path)
        mod.configSettings = configData()
        
        -- Update configSettings with missing or outdated values from defaultcfg
        local changed = false
        for key, value in pairs(defaultcfg) do
            if key ~= "abilities" then -- Skip the 'abilities' table
                if type(value) == "table" then
                    if not mod.configSettings[key] then
                        mod.configSettings[key] = {}
                        changed = true
                    end
                    for subkey, subvalue in pairs(value) do
                        if mod.configSettings[key][subkey] == nil then
                            mod.configSettings[key][subkey] = subvalue
                            write.Error('Your config file is out of date. Adding config entry: %s with value: %s', subkey, subvalue)
                            changed = true
                        end
                    end
                elseif mod.configSettings[key] == nil then -- Check for nil values instead of false
                    changed = true
                    write.Error('Your config file is out of date. Adding config entry: %s with value: %s', key, value)
                    mod.configSettings[key] = value
                end
            end
        end

        if changed == true then
            mq.pickle(mod.path, mod.configSettings)
        end
        
    end
    
    return mod.configSettings
end




function mod.zipTheme()
    write.Trace('zipTheme function')
    local state = require('utils.state')
    local tbl = {}
    tbl.windowbg = tostring(state.activeTheme.windowbg)
    tbl.bg = tostring(state.activeTheme.bg)
    tbl.hovered = tostring(state.activeTheme.hovered)
    tbl.active = tostring(state.activeTheme.active)
    tbl.button = tostring(state.activeTheme.button)
    tbl.text = tostring(state.activeTheme.text)
    tbl.name = state.activeTheme.name
    tbl.index = state.activeTheme.index
    return tbl
end

function mod.saveConfig()
    write.Trace('saveConfig Function')
    write.Help('Saving config to ' .. mod.path)
    local state = require('utils.state')
    local lib = require('utils.lib')
    local tbl = state.config
    tbl.ignores[mq.TLO.Zone.ShortName()] = lib.zipIgnores()
    tbl.selectedTheme = mod.zipTheme()
    mq.pickle(mod.path, tbl)
end

function mod.loadConfig()
    write.Trace('loadConfig Function')
    local state = require('utils.state')
    write.Help('Loading config from ' .. mod.path)
    local configsettings = {}
    local cfgtbl, err = loadfile(mq.configDir .. '/' .. mod.path)
    if err then 
        write.Help('Config file not found. Hitting the dispo...')
        mq.pickle(mod.path, mod.configSettings)
    elseif cfgtbl then
        write.Help('Config file found at %s.',mod.path)
        configsettings = cfgtbl()
    end
    if configsettings then 
        state.config = configsettings
    end
    local ui = require('interface.GUI.gui')
    ui.loadTheme()
    local lib = require('utils.lib')
    state.pullIgnores = lib.unZipIgnores()
end

return mod





