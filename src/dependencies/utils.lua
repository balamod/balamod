-- utility functions

local utils = {}

function utils.contains(t, element)
    for _, value in pairs(t) do
        if value == element then
            return true
        end
    end
    return false
end

function utils.filter(t, predicate)
    local result = {}
    for _, value in pairs(t) do
        if predicate(value) then
            table.insert(result, value)
        end
    end
    return result
end

function utils.map(t, predicate)
    local result = {}
    for key, value in pairs(t) do
        result[key] = predicate(value)
    end
    return result
end

function utils.reduce(t, predicate, initial)
    local result = initial
    for _, value in pairs(t) do
        result = predicate(result, value)
    end
    return result
end

return utils
