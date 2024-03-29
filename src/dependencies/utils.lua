-- utility functions

local utils = {}

-- Returns true if the table contains the element
-- @param t table
-- @param element any
function utils.contains(t, element)
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
function utils.filter(t, predicate)
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
function utils.map(t, mapper)
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
function utils.reduce(t, reducer, initial)
    local result = initial
    for _, value in pairs(t) do
        result = reducer(result, value)
    end
    return result
end

return utils

-- Parses a semantic version string into a table
-- @param version string
-- @return table {major = number, minor = number, patch = number}
function utils.parseVersion(version)
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
function utils.v2GreaterThanV1(v1, v2)
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

return utils
