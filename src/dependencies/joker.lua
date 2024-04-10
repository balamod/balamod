local balamod = require('balamod')

local joker = {}
joker._VERSION = "0.9.0"
joker.jokers = {}
joker.calculateJokerEffects = {}
joker.dollarBonusEffects = {}
joker.addToDeckEffects = {}
joker.removeFromDeckEffects = {}
joker.loc_vars = {}
local function add_joker(args)
    if not args.mod_id then logger:error("jokerAPI: mod_id REQUIRED when adding a joker"); return; end
    local id = args.id or "j_Joker_Placeholder" .. #G.P_CENTER_POOLS["Joker"] + 1
    local name = args.name or "Joker Placeholder"
    local calculate_joker_effect = args.calculate_joker_effect or function(_) end
    local order = #G.P_CENTER_POOLS["Joker"] + 1
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
    local effect = args.effect or ""
    local config = args.config or {}
    local desc = args.desc or {"Placeholder"}
    local rarity = args.rarity or 1
    local blueprint_compat = args.blueprint_compat or true
    local eternal_compat = args.eternal_compat or true
    local no_pool_flag = args.no_pool_flag or nil
    local yes_pool_flag = args.yes_pool_flag or nil
    local unlock_condition = args.unlock_condition or nil
    local alerted = args.alerted or true
    local loc_vars = args.loc_vars or function(_) return {} end
    local unlock_condition_desc = args.unlock_condition_desc or {"LOCKED"}
    local calculate_dollar_bonus_effect = args.calculate_dollar_bonus_effect or function(_) end
    local add_to_deck_effect = args.add_to_deck_effect or function(_) end
    local remove_from_deck_effect = args.remove_from_deck_effect or function(_) end

    --joker object
    local newJoker = {
        balamod = {
            mod_id = args.mod_id,
            key = id,
            asset_key = args.mod_id .. "_" .. id
        },
        order = order,
        discovered = discovered,
        cost = cost,
        consumeable = false,
        name = name,
        pos = pos,
        set = "Joker",
        effect = "",
        cost_mult = 1.0,
        config = config,
        key = id, 
        rarity = rarity, 
        unlocked = unlocked,
        blueprint_compat = blueprint_compat,
        eternal_compat = eternal_compat,
        no_pool_flag = no_pool_flag,
        yes_pool_flag = yes_pool_flag,
        unlock_condition = unlock_condition,
        alerted = alerted,
    }

    --add it to all the game tables
    table.insert(G.P_CENTER_POOLS["Joker"], newJoker)
    table.insert(G.P_JOKER_RARITY_POOLS[rarity], newJoker)
    G.P_CENTERS[id] = newJoker

    --add name + description to the localization object
    local newJokerText = {name=name, text=desc, unlock=unlock_condition_desc, text_parsed={}, name_parsed={}, unlock_parsed={}}
    for _, line in ipairs(desc) do
        newJokerText.text_parsed[#newJokerText.text_parsed+1] = loc_parse_string(line)
    end
    for _, line in ipairs(type(newJokerText.name) == 'table' and newJokerText.name or {newJoker.name}) do
        newJokerText.name_parsed[#newJokerText.name_parsed+1] = loc_parse_string(line)
    end
    for _, line in ipairs(newJokerText.unlock) do
        newJokerText.unlock_parsed[#newJokerText.unlock_parsed+1] = loc_parse_string(line)
    end
    
    G.localization.descriptions.Joker[id] = newJokerText



    --add joker effects to game
    joker.calculateJokerEffects[id] = calculate_joker_effect
    joker.dollarBonusEffects[id] = calculate_dollar_bonus_effect
    joker.addToDeckEffects[id] = add_to_deck_effect
    joker.removeFromDeckEffects[id] = remove_from_deck_effect

    --add joker loc vars to the game
    joker.loc_vars[id] = loc_vars

    --save indices for removal
    joker.jokers[id] = {
        pool_indices={#G.P_CENTER_POOLS["Joker"], #G.P_JOKER_RARITY_POOLS[rarity]}, 
    }
    return newJoker, newJokerText
end

local function remove_joker(id)
    local rarity = G.P_CENTERS[id].rarity
    G.P_CENTER_POOLS['Joker'][joker.jokers[id].pool_indices[1]] = nil
    G.P_JOKER_RARITY_POOLS[rarity][joker.jokers[id].pool_indices[2]] = nil
    G.P_CENTERS[id] = nil
    G.localization.descriptions.Joker[id] = nil
    joker.calculateJokerEffects[id] = nil
    joker.dollarBonusEffects[id] = nil
    joker.addToDeckEffects[id] = nil
    joker.removeFromDeckEffects[id] = nil
    joker.loc_vars[id] = nil
    joker.jokers[id] = nil
end

local _MODULE = joker

_MODULE.add = add_joker
_MODULE.remove = remove_joker

return _MODULE