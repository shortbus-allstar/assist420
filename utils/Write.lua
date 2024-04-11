-- This module provides a set of logging utilities with support for different log levels and colored output.
local Write = { _version = '2.0', _author = 'Knightly' }

-- Specifies whether to use colors in the output. If true, log messages will be colored according to their log level.
Write.usecolors = true
-- Specifies the current log level.  Log levels lower than this will not be shown.
Write.loglevel = 'info'
-- Sets a prefix for log messages.  This appears at the very beginning of the line and can be a string or a function that returns a string
Write.prefix = ''
-- Sets a postfix for log messages.  This appears at the end of the write string, prior to the separator
Write.postfix = ''
-- Sets a separator that is placed between the write string and the log entry to be printed
Write.separator = ' :: '

local initial_loglevels = {
    ['trace']  = { level = 1, color = '\27[36m',  mqcolor = '\at', abbreviation = '[TRACE]', terminate = false, colors = {}, mqcolors = {} },
    ['debug']  = { level = 2, color = '\27[95m',  mqcolor = '\am', abbreviation = '[DEBUG]', terminate = false, colors = {}, mqcolors = {} },
    ['info']   = { level = 3, color = '\27[92m',  mqcolor = '\ag', abbreviation = '[INFO]' , terminate = false, colors = {}, mqcolors = {} },
    ['warn']   = { level = 4, color = '\27[93m',  mqcolor = '\ay', abbreviation = '[WARN]' , terminate = false, colors = {}, mqcolors = {} },
    ['error']  = { level = 5, color = '\27[31m',  mqcolor = '\ao', abbreviation = '[ERROR]', terminate = false, colors = {}, mqcolors = {} },
    ['fatal']  = { level = 6, color = '\27[91m',  mqcolor = '\ar', abbreviation = '[FATAL]', terminate = true , colors = {}, mqcolors = {} },
    ['help']   = { level = 7, color = '\27[97m',  mqcolor = '\aw', abbreviation = '[HELP]' , terminate = false, colors = {}, mqcolors = {} },
}

-- What level the call string (file and line numbers) should show at.  Default is debug.  When the log level is this or below, it is on for all levels.
Write.callstringlevel = initial_loglevels['debug'].level

-- Handle add/remove for log levels
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

local mq = nil
if package.loaded['mq'] then
    mq = require('mq')
end

--- Terminates the program, using mq or os exit as appropriate
local function Terminate()
    if mq then mq.exit() end
    os.exit()
end

--- Get the color start string if usecolors is enabled.
--- @param paramLogLevel string The log level to get the color for
--- @param colortype? string The color type to get, if it exists.  Default is the default color
--- @return string # color start string or empty string if usecolors is not enabled or the color type is not found
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
--- @param colortype? string The color type to get, if it exists.  Default is the default color
--- @return string # the color end string or empty string if usecolors is not enabled
local function GetColorEnd(paramLogLevel, colortype)
    colortype = colortype or 'default'
    paramLogLevel = paramLogLevel or 'default'
    assert(type(paramLogLevel) == "string", "Start colors only take strings")
    assert(type(colortype) == "string", "Color Type only takes strings")
    if Write.usecolors then
        if mq then
            if colortype == 'default' or paramLogLevel == 'default' or Write.loglevels[paramLogLevel].mqcolors and Write.loglevels[paramLogLevel].mqcolors[colortype] then
                return '\ax'
            end
        end
        if colortype == 'default' or paramLogLevel == 'default' or Write.loglevels[paramLogLevel].colors and Write.loglevels[paramLogLevel].colors[colortype] then
            return '\27[0m'
        end
    end
    return ''
end

--- Returns a string representing the caller's source and line number, or an empty string if the current
--- log level is above the callstring level.  Does not return this file unless there is no other file in
--- call stack.
--- @return string # The file, separator, and line number
local function GetCallerString()
    if Write.loglevels[Write.loglevel:lower()].level > Write.callstringlevel then
        return ''
    end

    local callString = 'unknown'
    -- Skip GetCallerString, Output, and Write.[LevelName]
    local stackLevel = 4
    local callerInfo = debug.getinfo(stackLevel,'Sl')
    local currentFile = debug.getinfo(1, 'S').short_src
    if callerInfo and callerInfo.short_src ~= nil and callerInfo.short_src ~= '=[C]' then
        callString = string.format('%s%s%s', callerInfo.short_src:match("[^\\^/]*.lua$"), Write.separator, callerInfo.currentline)
    end
    while callerInfo do
        if callerInfo.short_src ~= nil and callerInfo.short_src ~= currentFile and callerInfo.short_src ~= '=[C]' then
            callString = string.format('%s%s%s', callerInfo.short_src:match("[^\\^/]*.lua$"), Write.separator, callerInfo.currentline)
            break
        end
        stackLevel = stackLevel + 1
        callerInfo = debug.getinfo(stackLevel, 'Sl')
    end

    return string.format('(%s) ', callString)
end

--- Outputs a message at the specified log level, with colors and prefixes/postfixes if specified.
--- @param paramLogLevel string The log level for output
--- @param message string The message to output
local function Output(paramLogLevel, message)
    if rawget(Write.loglevels, paramLogLevel) == nil then
        if rawget(Write.loglevels, 'fatal') == nil then
            print(string.format("Write Error: Log level '%s' does not exist.", paramLogLevel))
            Terminate()
        else
            Write.Fatal("Log level '%s' does not exist.", paramLogLevel)
        end
    elseif Write.loglevels[Write.loglevel:lower()].level <= Write.loglevels[paramLogLevel].level then
        print((type(Write.prefix) == 'function' and Write.prefix() or Write.prefix) .. GetColorStart(paramLogLevel, 'callstring') .. GetCallerString() .. GetColorEnd(paramLogLevel, 'callstring') .. GetColorStart(paramLogLevel) .. Write.loglevels[paramLogLevel].abbreviation .. GetColorEnd() .. (type(Write.postfix) == 'function' and Write.postfix() or Write.postfix) .. Write.separator .. GetColorStart(paramLogLevel, 'message') .. message .. GetColorEnd(paramLogLevel, 'message'))
    end
end

--- Converts a string to sentence case.
--- @param str string The string to convert
--- @return string # The converted string in sentence case
local function GetSentenceCase(str)
    local firstLetter = str:sub(1, 1):upper()
    local remainingLetters = str:sub(2):lower()
    return firstLetter..remainingLetters
end

--- Generates shortcut functions for each log level defined in Write.loglevels.
--- The generated functions have the same name as the log level with the first letter capitalized.
--- For example, if there is a log level 'info', a function Write.Info() will be generated.
--- The functions output messages at their respective log levels, and a fatal log level message will terminate the program.
function Write.GenerateShortcuts()
    for level, level_params in pairs(Write.loglevels) do
        --- @diagnostic disable-next-line
        Write[GetSentenceCase(level)] = function(message, ...)
            Output(level, string.format(message, ...))
            if level_params.terminate then
                Terminate()
            end
        end
    end
end

Write.GenerateShortcuts()

return Write
