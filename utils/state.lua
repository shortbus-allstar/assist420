local mq = require('mq')
local write = require('utils.Write')
local conf = require('interface.config')
local https = require("ssl.https")
local ltn12 = require("ltn12")

-- Function to retrieve the latest GitHub version
local function getGitHubVersion()
    local url = "https://api.github.com/repos/shortbus-allstar/assist420/releases"
    local response = {}

    local _, status = https.request{
        url = url,
        method = "GET",
        sink = ltn12.sink.table(response),
    }

    if status == 200 then
        local responseBody = table.concat(response)

        local json = require("cjson")
        local releases = json.decode(responseBody)

        -- Check if there are releases
        if #releases > 0 then
            -- Retrieve the tag name of the latest release
            return releases[1].tag_name
        else
            return 'No releases found'
        end
    else
        return 'Request failed'
    end
end

local state = {
    campxloc = nil,
    campyloc = nil,
    campzloc = nil,
    class = mq.TLO.Me.Class.ShortName(),
    config = conf.getConfig(),
    cooldowns = {},
    dead = false,
    facetimer = 0,
    feigned = false,
    feignOverride = false,
    githubver = getGitHubVersion(),
    loglevel = 'debug',
    medding = false,
    paused = false,
    pulling = false,
    pullIgnores = {},
    queueCombat = {},
    queueOOC = {},
    version = 'v1.0.1-alpha',
}

function state.updateLoopState()
    write.Trace('Update Loop State Function')
    if mq.TLO.MacroQuest.GameState() ~= 'INGAME' then
        write.Help('Not in game, putting the lighter down...')
        mq.exit()
    end
    state.dead = mq.TLO.Me.Dead()
    if state.dead == true then 
        state.paused = true
        return
    end
    write.loglevel = state.loglevel
    mq.doevents()
end

return state