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
                priority = 6,
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
                priority = 7,
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
    attackAt = 99,
    attackRange = 75,
    burn = 'auto',
    campRadius = 20,
    chainPullHP = 100,
    chainPullMax = 2,
    chainPullToggle = true,
    chaseAssist = false,
    chaseDistance = 5,
    chaseMaxDistance = 300,
    combatMed = false,
    doMedding = true,
    doPulling = false,
    events = {},
    feignOverride = true,
    medEndAt = 60,
    medManaAt = 60,
    medStop = 90,
    miscGem = 7,
    movement = 'auto',
    petAttackAt = 99,
    petRange = 75,
    pullAbilName = 'Distant Strike',
    pullAbilType = 'AA',
    pullAbilRange = 200,
    pullRadius = 10000,
    pullZRange = 500,
    returnToCamp = false,
    standcond = 'mq.TLO.Me.PctHPs() == 100'
}

function mod.getConfig()
    write.Trace('getConfig Function')
    write.prefix = '\ay[\amASS\ag420\ay]\am:\at ' 
    local configData, err = loadfile(mq.configDir .. '/' .. mod.path)
    if err then 
        write.Help('INI file not found. Hitting the dispo...')
        mq.pickle(mod.path, mod.configSettings)
    elseif configData then
        write.Help('INI file found at %s. Rolling up...',mod.path)
        mod.configSettings = configData()
    end
    return mod.configSettings
end

function mod.saveConfig()
    write.Trace('saveConfig Function')
    write.Help('Saving config to ' .. mod.path)
    mq.pickle(mod.path, mod.configSettings)
end

function mod.loadConfig()
    write.Trace('loadConfig Function')
    local state = require('utils.state')
    write.Help('Loading config from ' .. mod.path)
    state.config = loadfile(mq.configDir .. '/' .. mod.path)
end

return mod





