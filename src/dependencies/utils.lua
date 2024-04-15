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


-- Returns a slugified version of the input string
-- @param string string
-- @return string
local function slugify(str)
    local tmp = string.gsub(str,'%s+', '_')
    local tmp2 = string.gsub(tmp, '[^%w_]', '')
    return string.lower(tmp2)
end

local function stringify(value)
    if type(value) == "table" then
        local str = "{"
        for k, v in pairs(value) do
            str = str .. k .. "=" .. stringify(v) .. ", "
        end
        str = str .. "}"
        return str
    end

    if type(value) == "function" then
        return "function"
    end

    if value == nil then
        return "nil"
    end

    return tostring(value)
end

-- Returns true if any element in the table is true
-- @param t table
-- @return boolean
local function any(t)
    for i, value in ipairs(t) do
        if value then
            return true
        end
    end
    return false
end

-- Returns true if all elements in the table are true
-- @param t table
-- @param predicate function
-- @return boolean
local function all(t)
    for i, value in ipairs(t) do
        if not value then
            return false
        end
    end
    return true
end

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function copyTable(t, deep)
    if deep then
        return deepcopy(t)
    else
        return shallowcopy(t)
    end
end

-- Merges two key-value tables, overwriting the values of the first table with the values of the second table
-- @param table1 table
-- @param table2 table
-- @return table
local function mergeTables(table1, table2, logger)
    -- copy everything from table1 into the result, so that
    -- they get overwritten by values of table2 without
    -- modifying the original table
    local result = copyTable(table1, true)
    -- now do the merge
    for k, v in pairs(table2) do
        if type(v) == "table" and type(result[k]) == "table" then
            -- both are tables so we recurse, but first, we need to check
            -- whether it's an "array" table or a "dict" table
            local isDictTable = all(map(keys(result), function(k)
                return type(k) ~= "number"
            end))
            if isDictTable then
                result[k] = mergeTables(result[k], v, logger)
            else
                -- we assume it's an array table
                for _, v2 in ipairs(v) do
                    table.insert(result[k], v2)
                end
            end
        else
            result[k] = v
        end
    end
    return result
end

utils.stringify = stringify
utils.contains = contains
utils.filter = filter
utils.map = map
utils.reduce = reduce
utils.parseVersion = parseVersion
utils.v2GreaterThanV1 = v2GreaterThanV1
utils.keys = keys
utils.values = values
utils.slugify = slugify
utils.copyTable = copyTable
utils.mergeTables = mergeTables
utils.any = any
utils.all = all

return utils
