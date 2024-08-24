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
    rez = false,
    healpct = 75,
    usextar = true,
    usegroup = true,
    usetank = true,
    useself = true,
    usepets = true,
    groupheal = false,
    quickheal = false,
    hot = false,
    healtars = {}
}

--[[
1. Self
2. Tank -- allow adding multiple tanks manually by ID via state.config.healTanksList
3. Group
4. Xtar
5. Custom -- other custom IDs that aren't tank priority

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

function mod.getHealTarget()
end