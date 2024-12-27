local mq = require('mq')

local state = require('utils.state')
local write = require('utils.Write')
local lib = require('utils.lib')

local mod = {}

--- DataType for accessing values in the state table
---@class StateType
---@field value any The value at the specified path
---@field path string The dot-separated path to access in the state table

---@type DataType
local stateType = mq.DataType.new('StateType', {
    Members = {
        --- Retrieve the value at the given path
        --- Dynamically determines the type using type(value).
        --- @param stateObj StateType
        Value = function(_, stateObj)
            local value = stateObj and stateObj.value

            -- Determine the type
            local valueType = type(value)

            -- Handle recognized types
            if valueType == "number" then
                return 'int', value
            elseif valueType == "string" then
                return 'string', value
            elseif valueType == "boolean" then
                return 'bool', value
            elseif valueType == "table" then
                return 'table', value
            elseif valueType == "nil" then
                return 'unknown', nil
            else
                -- Unsupported type
                write.Warn("Unsupported type for value: %s", valueType)
                return 'unknown', nil
            end
        end,

        --- Retrieve the path as a string
        --- @param stateObj StateType
        Path = function(_, stateObj)
            return 'string', stateObj.path
        end,
    },

    --- Optional ToString for debugging
    ToString = function(stateObj)
        return string.format("Path: %s, Value: %s", stateObj.path, tostring(stateObj.value))
    end,
})

--- Resolves a dot-separated path into the `state` table.
--- Supports parentheses for array indices, e.g., `MNK(1).abilcd`.
--- @param path string The dot-separated path to resolve.
--- @return any|nil The resolved value or nil if the path is invalid.
local function resolvePath(path)
    -- Start with the state table
    local current = state

    -- Log the initial path
    write.Trace("Resolving path: %s", path)

    -- Traverse the path
    for part in string.gmatch(path, "[^%.%(%)]+") do
        -- Check if part is numeric for array indices
        local index = tonumber(part)
        if index then
            if type(current) == "table" then
                current = current[index] -- Access by numeric index
            else
                write.Warn("Expected a table but found %s for index: %s", type(current), part)
                return nil
            end
        else
            if type(current) == "table" then
                current = current[part] -- Access by key
            else
                write.Warn("Expected a table but found %s for key: %s", type(current), part)
                return nil
            end
        end
    end

    -- Log the resolved value
    write.Debug("Resolved value for path '%s': %s", path, tostring(current))
    return current
end

function mod.stateTLO(param)
    if not param or #param == 0 then
        write.Debug("No path parameter provided to stateTLO.")
        return nil, nil
    end

    local path = param
    local value = resolvePath(path)

    if value ~= nil then
        write.Trace("Returning resolved value for path '%s'", path)
        return stateType, { path = path, value = value }
    else
        write.Warn("Failed to resolve path: %s", path)
        return nil, nil
    end
end

return mod
