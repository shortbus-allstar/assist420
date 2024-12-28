--[[
    This module logs messages to both the console and a file. The file path
    is read from state.config.logpath.  All levels (trace through help) 
    will also be written to the log file.
]]
local Write = { _version = '2.0', _author = 'Knightly' }
local mq = require('mq')

-- Whether to use colors in the output. If true, log messages will be colored according to their log level.
Write.usecolors = true

-- The current log level. Log levels lower than this will not be shown.
Write.loglevel = 'info'

-- A prefix for log messages. Appears at the beginning of the line. Can be string or function returning a string.
Write.prefix = ''

-- A postfix for log messages. Appears at the end of the write string, just before the separator.
Write.postfix = ''

-- A separator that appears between the write string and the log entry to be printed.
Write.separator = ' :: '

-- Example log levels with color definitions.
local initial_loglevels = {
    ['trace']  = { level = 1, color = '\27[36m',  mqcolor = '\at', abbreviation = '[TRACE]', terminate = false, colors = {}, mqcolors = {} },
    ['debug']  = { level = 2, color = '\27[95m',  mqcolor = '\am', abbreviation = '[DEBUG]', terminate = false, colors = {}, mqcolors = {} },
    ['info']   = { level = 3, color = '\27[92m',  mqcolor = '\ag', abbreviation = '[INFO]',  terminate = false, colors = {}, mqcolors = {} },
    ['warn']   = { level = 4, color = '\27[93m',  mqcolor = '\ay', abbreviation = '[WARN]',  terminate = false, colors = {}, mqcolors = {} },
    ['error']  = { level = 5, color = '\27[31m',  mqcolor = '\ao', abbreviation = '[ERROR]', terminate = false, colors = {}, mqcolors = {} },
    ['fatal']  = { level = 6, color = '\27[91m',  mqcolor = '\ar', abbreviation = '[FATAL]', terminate = true,  colors = {}, mqcolors = {} },
    ['help']   = { level = 7, color = '\27[97m',  mqcolor = '\aw', abbreviation = '[HELP]',  terminate = false, colors = {}, mqcolors = {} },
    ['watchdog'] = { level = 8, color = '\27[91m',  mqcolor = '\a-r', abbreviation = '[WATCHDOG]',  terminate = false, colors = {}, mqcolors = {} },
}

-- At which level the callstring (file:line) is shown. Default is 'info'.
Write.callstringlevel = initial_loglevels['info'].level

-- Set up the log levels in a metatable so adding/removing levels regenerates shortcuts
local loglevels_mt = {
    __newindex = function(t, key, value)
        rawset(t, key, value)
        Write.GenerateShortcuts()
    end,
    __call = function(t, key)
        rawset(t, key, nil)
        Write.GenerateShortcuts()
    end,
}

Write.loglevels = setmetatable(initial_loglevels, loglevels_mt)

-- Optionally require 'mq' if available.

-- If your script environment has a `state` global or module, you can capture the logpath here:
-- (Adjust according to how `state` is actually accessed in your environment.)

-- We'll keep a reference to the open file handle here.
local logFile = nil

--- Attempts to open the log file at `state.config.logpath` in append mode.
local function OpenLogFile()

    local path = mq.TLO.MacroQuest.Path('root')() .. '\\Logs\\Assist420_' .. mq.TLO.Me.CleanName() .. '_' .. mq.TLO.EverQuest.Server() .. ".txt"
    local f, err = io.open(path, "a")
    if not f then
        print(string.format("Write Warning: Could not open log file '%s': %s", path, err))
        return nil
    end
    return f
end

--- Terminates the program, using mq or os exit as appropriate.
local function Terminate()
    if mq then mq.exit() end
    os.exit()
end

--- Get the color start string if usecolors is enabled.
--- @param paramLogLevel string The log level to get the color for
--- @param colortype? string The color type to get, if it exists. Default is 'default'.
--- @return string # color start string or empty if colors not in use or color type not found
local function GetColorStart(paramLogLevel, colortype)
    colortype = colortype or 'default'
    assert(type(paramLogLevel) == "string", "Start colors only take strings")
    assert(type(colortype) == "string", "Color Type only takes strings")

    if Write.usecolors then
        if colortype == 'default' then
            if mq then return Write.loglevels[paramLogLevel].mqcolor end
            return Write.loglevels[paramLogLevel].color
        else
            if mq then
                if Write.loglevels[paramLogLevel].mqcolors and Write.loglevels[paramLogLevel].mqcolors[colortype] then
                    return Write.loglevels[paramLogLevel].mqcolors[colortype]
                end
            else
                if Write.loglevels[paramLogLevel].colors and Write.loglevels[paramLogLevel].colors[colortype] then
                    return Write.loglevels[paramLogLevel].colors[colortype]
                end
            end
        end
    end
    return ''
end

--- Get the color end string if usecolors is enabled
--- @param colortype? string The color type to get, if it exists. Default is 'default'
--- @return string # The color end string or empty if usecolors is not enabled
local function GetColorEnd(paramLogLevel, colortype)
    colortype = colortype or 'default'
    paramLogLevel = paramLogLevel or 'default'
    assert(type(paramLogLevel) == "string", "Start colors only take strings")
    assert(type(colortype) == "string", "Color Type only takes strings")
    if Write.usecolors then
        if mq then
            if colortype == 'default' or paramLogLevel == 'default' 
               or (Write.loglevels[paramLogLevel].mqcolors and Write.loglevels[paramLogLevel].mqcolors[colortype]) 
            then
                return '\ax'
            end
        end
        if colortype == 'default' or paramLogLevel == 'default' 
           or (Write.loglevels[paramLogLevel].colors and Write.loglevels[paramLogLevel].colors[colortype]) 
        then
            return '\27[0m'
        end
    end
    return ''
end

--- Returns a string representing the caller's source and line number, or an empty string 
--- if the current log level is above the callstring level.
local function GetCallerString()
    if Write.loglevels[Write.loglevel:lower()].level > Write.callstringlevel then
        return ''
    end

    local callString = 'unknown'
    -- Skip 1) GetCallerString, 2) Output, 3) Write.[LevelName] => start from stackLevel=4
    local stackLevel = 4
    local callerInfo = debug.getinfo(stackLevel, 'Sl')
    local currentFile = debug.getinfo(1, 'S').short_src

    if callerInfo and callerInfo.short_src ~= nil and callerInfo.short_src ~= '=[C]' then
        callString = string.format('%s%s%s',
            callerInfo.short_src:match("[^\\^/]*.lua$") or callerInfo.short_src,
            Write.separator,
            callerInfo.currentline
        )
    end

    -- Walk up the stack until we find a caller that isn't this file or a C function
    while callerInfo do
        if callerInfo.short_src ~= nil and callerInfo.short_src ~= currentFile and callerInfo.short_src ~= '=[C]' then
            callString = string.format('%s%s%s',
                callerInfo.short_src:match("[^\\^/]*.lua$") or callerInfo.short_src,
                Write.separator,
                callerInfo.currentline
            )
            break
        end
        stackLevel = stackLevel + 1
        callerInfo = debug.getinfo(stackLevel, 'Sl')
    end

    return string.format('(%s) ', callString)
end

--- Outputs a message at the specified log level, with colors and prefixes/postfixes if specified.
--- Also logs the same output line to a file specified by state.config.logpath (if available).
local function Output(paramLogLevel, message)
    -- If we haven't opened our log file yet, try to do so now.
    if not logFile then
        logFile = OpenLogFile()
    end

    if rawget(Write.loglevels, paramLogLevel) == nil then
        if rawget(Write.loglevels, 'fatal') == nil then
            print(string.format("Write Error: Log level '%s' does not exist.", paramLogLevel))
            Terminate()
        else
            Write.Fatal("Log level '%s' does not exist.", paramLogLevel)
        end
    elseif Write.loglevels[Write.loglevel:lower()].level <= Write.loglevels[paramLogLevel].level then
        -- 1) Build your timestamp.
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")

        -- 2) Construct the console/log string with timestamp first.
        local outStr = string.format(
            "%s%s%s%s%s%s%s%s%s%s",
            (type(Write.prefix) == 'function' and Write.prefix() or Write.prefix),
            GetColorStart(paramLogLevel, 'callstring'),
            GetCallerString(),
            GetColorEnd(paramLogLevel, 'callstring'),
            GetColorStart(paramLogLevel),
            Write.loglevels[paramLogLevel].abbreviation,
            GetColorEnd(),
            (type(Write.postfix) == 'function' and Write.postfix() or Write.postfix),
            Write.separator,
            message
        )

        print(outStr)

        -- 4) Write to log file, stripping color codes for readability
        if logFile then
            local stripped = string.format("%s [%s] %s%s",timestamp,paramLogLevel:upper(),GetCallerString(),message)            
            logFile:write(stripped .. "\n")
            logFile:flush()
        end
    end
end


--- Converts a string to Sentence Case
local function GetSentenceCase(str)
    local firstLetter = str:sub(1, 1):upper()
    local remainingLetters = str:sub(2):lower()
    return firstLetter .. remainingLetters
end

--- Generates shortcut functions like Write.Info(), Write.Trace(), etc.
function Write.GenerateShortcuts()
    for level, level_params in pairs(Write.loglevels) do
        Write[GetSentenceCase(level)] = function(message, ...)
            Output(level, string.format(message, ...))
            if level_params.terminate then
                Terminate()
            end
        end
    end
end

-- Initially generate these shortcuts
Write.GenerateShortcuts()

return Write
