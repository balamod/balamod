-- utility functions

local utils = {}

-- Returns true if the table contains the element
-- @param t table
-- @param element any
local function contains(t, element)
    for _, value in pairs(t) do
        if value == element then
            return true
        end
    end
    return false
end


-- Returns a new table with the elements that satisfy the predicate
-- @param t table
-- @param predicate function
local function filter(t, predicate)
    local result = {}
    for _, value in pairs(t) do
        if predicate(value) then
            table.insert(result, value)
        end
    end
    return result
end


-- Returns a new table with the predicate applied to each element
-- @param t table
-- @param mapper function
local function map(t, mapper)
    local result = {}
    for key, value in pairs(t) do
        result[key] = mapper(value)
    end
    return result
end

-- Reduces the table to a single value, starting with `initial` and applying the reducer for each element
-- @param t table
-- @param reducer function
-- @param initial any
local function reduce(t, reducer, initial)
    local result = initial
    for _, value in pairs(t) do
        result = reducer(result, value)
    end
    return result
end

-- Parses a semantic version string into a table
-- @param version string
-- @return table {major = number, minor = number, patch = number}
local function parseVersion(version)
    local major, minor, patch = string.match(version, '(%d+)%.(%d+)%.(%d+)')
    return {
        major = tonumber(major),
        minor = tonumber(minor),
        patch = tonumber(patch)
    }
end

-- Compares two semantic versions, and returns true if v2 is greater than v1
-- @param v1 table {major = number, minor = number, patch = number}
-- @param v2 table {major = number, minor = number, patch = number}
local function v2GreaterThanV1(v1, v2)
    if v2.major > v1.major then
        return true
    end
    if v2.major == v1.major then
        if v2.minor > v1.minor then
            return true
        end
        if v2.minor == v1.minor then
            if v2.patch > v1.patch then
                return true
            end
        end
    end
    return false
end

-- Returns a table with the keys of the input table
-- @param t table
-- @return table
local function keys(t)
    local result = {}
    for key, _ in pairs(t) do
        table.insert(result, key)
    end
    return result
end

-- Returns a table with the values of the input table
-- @param t table
-- @return table
local function values(t)
    local result = {}
    for _, value in pairs(t) do
        table.insert(result, value)
    end
    return result
end

utils.contains = contains
utils.filter = filter
utils.map = map
utils.reduce = reduce
utils.parseVersion = parseVersion
utils.v2GreaterThanV1 = v2GreaterThanV1
utils.keys = keys
utils.values = values

return utils
