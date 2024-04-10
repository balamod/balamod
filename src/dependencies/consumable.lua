local balamod = require('balamod')

local consumeable = {}
consumeable._VERSION = "0.1.0"
consumeable.useEffects = {}
consumeable.useConditions = {}
consumeable.loc_vars = {}
consumeable.consumeables = {}
local function add(args)
    if not args.set then logger:error("consumable API: set REQUIRED when adding a consumable"); return end
    if not args.mod_id then logger:error("consumable API: mod_id REQUIRED when adding a consumable"); return end
    local id = args.id or "c_placeholder"..#G.P_CENTER_POOLS[args.set]+1
    local name = args.name or "Consumable Placeholder"
    local use_effect = args.use_effect or function(_) end
    local use_condition = args.use_condition or function(_) end
    local order = #G.P_CENTER_POOLS[args.set] + 1
    local unlocked = nil
    local discovered = nil
    if args.unlocked ~= nil then
        unlocked = args.unlocked
    else
        unlocked = true
    end
    if args.discovered ~= nil then
        discovered = args.discovered
    else
        discovered = true
    end
    local cost = args.cost or 4
    local pos = {x=0, y=0}
    local config = args.config or {}
    local desc = args.desc or {"Placeholder"}
    local alerted = args.alerted or true
    local loc_vars = args.loc_vars or function(_) return {} end
    local set = args.set
    local unlock_condition = args.unlock_condition or nil
    local unlock_condition_desc = args.unlock_condition_desc or {"LOCKED"}
    local no_pool_flag = args.no_pool_flag or nil
    local yes_pool_flag = args.yes_pool_flag or nil

    local newConsumeable = {
        balamod = {
            mod_id = args.mod_id,
            key = id,
            asset_key = args.mod_id .. "_" .. id
        },
        key = id,
        order = order,
        unlocked = unlocked,
        discovered = discovered,
        cost = cost,
        consumeable = true,
        name = name,
        pos = pos,
        set = args.set,
        effect = "",
        cost_mult = 1.0,
        config = config,
        no_pool_flag = no_pool_flag,
        yes_pool_flag = yes_pool_flag,
        unlock_condition = unlock_condition,
        alerted = alerted,
    }

    local save_indices = {}

    --add it to all the game tables
    if not G.P_CENTER_POOLS[args.set] then
        logger:info("Creating new center set: "..args.set)
        G.P_CENTER_POOLS[args.set] = {}
    end
    table.insert(G.P_CENTER_POOLS[args.set], newConsumeable)
    table.insert(G.P_CENTER_POOLS["Consumeables"], newConsumeable)
    if args.set == "Tarot" or args.set == "Planet" then
        table.insert(G.P_CENTER_POOLS["Tarot_Planet"], newConsumeable)
        save_indices["Tarot_Planet"] = #G.P_CENTER_POOLS["Tarot_Planet"]
    end
    G.P_CENTERS[id] = newConsumeable

    --save indices to remove
    save_indices["Consumeables"] = #G.P_CENTER_POOLS["Consumeables"]
    save_indices[args.set] = #G.P_CENTER_POOLS[args.set]

    --add name + description to the localization object
    local consumeableText = {name=name, text=desc, unlock=unlock_condition_desc, text_parsed={}, name_parsed={}, unlock_parsed={}}
    for _, line in ipairs(desc) do
        consumeableText.text_parsed[#consumeableText.text_parsed+1] = loc_parse_string(line)
    end
    for _, line in ipairs(type(consumeableText.name) == 'table' and consumeableText.name or {newJoker.name}) do
        consumeableText.name_parsed[#consumeableText.name_parsed+1] = loc_parse_string(line)
    end
    for _, line in ipairs(consumeableText.unlock) do
        consumeableText.unlock_parsed[#consumeableText.unlock_parsed+1] = loc_parse_string(line)
    end
    if not G.localization.descriptions[args.set] then
        G.localization.descriptions[args.set] = {}
    end
    G.localization.descriptions[args.set][id] = consumeableText

    -- consumeable effects
    consumeable.useEffects[id] = use_effect
    consumeable.useConditions[id] = use_condition

    -- consumeable loc vars
    consumeable.loc_vars[id] = loc_vars

    -- indices for removal
    consumeable.consumeables[id] = {indices=save_indices, set=args.set}
end
local function remove(id)
    for k, v in pairs(consumeable.consumeables[id].indices) do
        G.P_CENTER_POOLS[k][v] = nil
    end
    G.P_CENTERS[id] = nil
    G.localization.descriptions[consumeable.consumeables[id].set][id] = nil
    consumeable.useConditions[id] = nil
    consumeable.useEffects[id] = nil
    consumeable.loc_vars[id] = nil
    consumeable.consumeables[id] = nil
end

local _MODULE = consumeable

_MODULE.add = add
_MODULE.remove = remove

return _MODULE