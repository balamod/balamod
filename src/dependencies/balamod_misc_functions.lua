local localization = require('localization')
local consumable = require("consumable")

local misc_functions_init_localization = misc_functions_init_localization or init_localization
local misc_generate_card_ui = generate_card_ui

function init_localization()
    localization.inject()
    misc_functions_init_localization()
end

function generate_card_ui(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end)
    local old_return = misc_generate_card_ui(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end)
    -- tarot loc vars are defined in this function. 
    -- if a modded tarot is called on generate_card_ui, regenerate its description with the modded loc_vars
    if _c.balamod and card_type == "Tarot" and not full_UI_table then
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
    return old_return
end