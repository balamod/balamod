local localization = require('localization')
local consumable = require("consumable")
local utils = require("utils")

local misc_functions_init_localization = misc_functions_init_localization or init_localization
local misc_generate_card_ui = generate_card_ui

function init_localization()
    localization.inject()
    misc_functions_init_localization()
end

function generate_card_ui(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end)
    local old_return = misc_generate_card_ui(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end)
    if _c.balamod and card_type == "Tarot" and not full_UI_table then
        -- if a modded tarot is the main description, rewrite the main description with correct loc_vars
        local loc_vars = {}
        if consumable.tarot_loc_vars[_c.key] then
            local status, new_loc_vars = pcall(consumable.tarot_loc_vars[_c.key], _c)
            if status and new_loc_vars then
                loc_vars = new_loc_vars
            end
        end
        old_return.main = {}
        localize{type = 'descriptions', key = _c.key, set = _c.set, nodes = old_return.main, vars = loc_vars}
    end
    if full_UI_table then
        -- if a modded tarot is a tooltip, find which tooltip it is, then rewrite the tooltip with correct loc_vars
        for k, tooltip in pairs(full_UI_table.info) do
            local center = utils.getCenterFromName(tooltip.name)
            if center and center.balamod then
                local loc_vars = {}
                if consumable.tarot_loc_vars[center.key] then
                    local status, new_loc_vars = pcall(consumable.tarot_loc_vars[center.key], center)
                    if status and new_loc_vars then
                        loc_vars = new_loc_vars
                    end
                end
                full_UI_table.info[k] = {name = tooltip.name}
                localize{type = 'descriptions', key = _c.key, set = _c.set, nodes = full_UI_table.info[k], vars = loc_vars}
            end
        end
    end
    return old_return
end