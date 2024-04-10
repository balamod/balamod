local localization = require('localization')
local misc_functions_init_localization = misc_functions_init_localization or init_localization
local consumable = require("consumable")

function init_localization()
    localization.inject()
    misc_functions_init_localization()
end

function create_UIBox_your_collection_tarots()
    local deck_tables = {}
  
    G.your_collection = {}
    for j = 1, 2 do
        G.your_collection[j] = CardArea(
            G.ROOM.T.x + 0.2*G.ROOM.T.w/2,G.ROOM.T.h,
            (4.25+j)*G.CARD_W,
            1*G.CARD_H, 
            {card_limit = 4 + j, type = 'title', highlight_limit = 0, collection = true}
        )
        table.insert(deck_tables, 
            {n=G.UIT.R, config={align = "cm", padding = 0, no_fill = true}, nodes={
                {n=G.UIT.O, config={object = G.your_collection[j]}}
            }}
        )
    end
  
    local tarot_options = {}
    for i = 1, math.ceil(#G.P_CENTER_POOLS.Tarot/11) do
        table.insert(tarot_options, localize('k_page')..' '..tostring(i)..'/'..tostring(math.ceil(#G.P_CENTER_POOLS.Tarot/11)))
    end
  
    for j = 1, #G.your_collection do
        for i = 1, 4+j do
            local center = G.P_CENTER_POOLS["Tarot"][i+(j-1)*(5)]
            local card = Card(G.your_collection[j].T.x + G.your_collection[j].T.w/2, G.your_collection[j].T.y, G.CARD_W, G.CARD_H, nil, center)
            card:start_materialize(nil, i>1 or j>1)
            G.your_collection[j]:emplace(card)
        end
    end
  
    INIT_COLLECTION_CARD_ALERTS()
    
    local t = create_UIBox_generic_options({ back_func = 'your_collection', contents = {
        {n=G.UIT.R, config={align = "cm", minw = 2.5, padding = 0.1, r = 0.1, colour = G.C.BLACK, emboss = 0.05}, nodes=deck_tables},
            {n=G.UIT.R, config={align = "cm"}, nodes={
                create_option_cycle({options = tarot_options, w = 4.5, cycle_shoulders = true, opt_callback = 'your_collection_tarot_page', focus_args = {snap_to = true, nav = 'wide'},current_option = 1, colour = G.C.RED, no_pips = true})
            }}
        }})
    return t
end

local misc_generate_card_ui = generate_card_ui
function generate_card_ui(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end)
    if _c.set == "Tarot" then
        local first_pass = nil
        if not full_UI_table then 
            first_pass = true
            full_UI_table = {
                main = {},
                info = {},
                type = {},
                name = nil,
                badges = badges or {}
            }
        end

        local desc_nodes = (not full_UI_table.name and full_UI_table.main) or full_UI_table.info
        local name_override = nil
        local info_queue = {}

        if full_UI_table.name then
            full_UI_table.info[#full_UI_table.info+1] = {}
            desc_nodes = full_UI_table.info[#full_UI_table.info]
        end

        if not full_UI_table.name then
            if specific_vars and specific_vars.no_name then
                full_UI_table.name = true
            elseif card_type == 'Locked' then
                full_UI_table.name = localize{type = 'name', set = 'Other', key = 'locked', nodes = {}}
            elseif card_type == 'Undiscovered' then 
                full_UI_table.name = localize{type = 'name', set = 'Other', key = 'undiscovered_'..(string.lower(_c.set)), name_nodes = {}}
            elseif specific_vars and (card_type == 'Default' or card_type == 'Enhanced') then
                if (_c.name == 'Stone Card') then full_UI_table.name = true end
                if (specific_vars.playing_card and (_c.name ~= 'Stone Card')) then
                    full_UI_table.name = {}
                    localize{type = 'other', key = 'playing_card', set = 'Other', nodes = full_UI_table.name, vars = {localize(specific_vars.value, 'ranks'), localize(specific_vars.suit, 'suits_plural'), colours = {specific_vars.colour}}}
                    full_UI_table.name = full_UI_table.name[1]
                end
            elseif card_type == 'Booster' then
                
            else
                full_UI_table.name = localize{type = 'name', set = _c.set, key = _c.key, nodes = full_UI_table.name}
            end
            full_UI_table.card_type = card_type or _c.set
        end 

        local loc_vars = {}
        if main_start then 
            desc_nodes[#desc_nodes+1] = main_start 
        end

    
        if _c.name == "The Fool" then
            local fool_c = G.GAME.last_tarot_planet and G.P_CENTERS[G.GAME.last_tarot_planet] or nil
            local last_tarot_planet = fool_c and localize{type = 'name_text', key = fool_c.key, set = fool_c.set} or localize('k_none')
            local colour = (not fool_c or fool_c.name == 'The Fool') and G.C.RED or G.C.GREEN
            main_end = {
                {n=G.UIT.C, config={align = "bm", padding = 0.02}, nodes={
                    {n=G.UIT.C, config={align = "m", colour = colour, r = 0.05, padding = 0.05}, nodes={
                        {n=G.UIT.T, config={text = ' '..last_tarot_planet..' ', colour = G.C.UI.TEXT_LIGHT, scale = 0.3, shadow = true}},
                    }}
                }}
            }
            loc_vars = {last_tarot_planet}
            if not (not fool_c or fool_c.name == 'The Fool') then
                    info_queue[#info_queue+1] = fool_c
            end
        elseif _c.name == "The Magician" then loc_vars = {_c.config.max_highlighted, localize{type = 'name_text', set = 'Enhanced', key = _c.config.mod_conv}}; info_queue[#info_queue+1] = G.P_CENTERS[_c.config.mod_conv]
        elseif _c.name == "The High Priestess" then loc_vars = {_c.config.planets}
        elseif _c.name == "The Empress" then loc_vars = {_c.config.max_highlighted, localize{type = 'name_text', set = 'Enhanced', key = _c.config.mod_conv}}; info_queue[#info_queue+1] = G.P_CENTERS[_c.config.mod_conv]
        elseif _c.name == "The Emperor" then loc_vars = {_c.config.tarots}
        elseif _c.name == "The Hierophant" then loc_vars = {_c.config.max_highlighted, localize{type = 'name_text', set = 'Enhanced', key = _c.config.mod_conv}}; info_queue[#info_queue+1] = G.P_CENTERS[_c.config.mod_conv]
        elseif _c.name == "The Lovers" then loc_vars = {_c.config.max_highlighted, localize{type = 'name_text', set = 'Enhanced', key = _c.config.mod_conv}}; info_queue[#info_queue+1] = G.P_CENTERS[_c.config.mod_conv]
        elseif _c.name == "The Chariot" then loc_vars = {_c.config.max_highlighted, localize{type = 'name_text', set = 'Enhanced', key = _c.config.mod_conv}}; info_queue[#info_queue+1] = G.P_CENTERS[_c.config.mod_conv]
        elseif _c.name == "Justice" then loc_vars = {_c.config.max_highlighted, localize{type = 'name_text', set = 'Enhanced', key = _c.config.mod_conv}}; info_queue[#info_queue+1] = G.P_CENTERS[_c.config.mod_conv]
        elseif _c.name == "The Hermit" then loc_vars = {_c.config.extra}
        elseif _c.name == "The Wheel of Fortune" then loc_vars = {G.GAME.probabilities.normal, _c.config.extra};  info_queue[#info_queue+1] = G.P_CENTERS.e_foil; info_queue[#info_queue+1] = G.P_CENTERS.e_holo; info_queue[#info_queue+1] = G.P_CENTERS.e_polychrome; 
        elseif _c.name == "Strength" then loc_vars = {_c.config.max_highlighted}
        elseif _c.name == "The Hanged Man" then loc_vars = {_c.config.max_highlighted}
        elseif _c.name == "Death" then loc_vars = {_c.config.max_highlighted}
        elseif _c.name == "Temperance" then
            local _money = 0
            if G.jokers then
                for i = 1, #G.jokers.cards do
                    if G.jokers.cards[i].ability.set == 'Joker' then
                        _money = _money + G.jokers.cards[i].sell_cost
                    end
                end
            end
            loc_vars = {_c.config.extra, math.min(_c.config.extra, _money)}
        elseif _c.name == "The Devil" then loc_vars = {_c.config.max_highlighted, localize{type = 'name_text', set = 'Enhanced', key = _c.config.mod_conv}}; info_queue[#info_queue+1] = G.P_CENTERS[_c.config.mod_conv]
        elseif _c.name == "The Tower" then loc_vars = {_c.config.max_highlighted, localize{type = 'name_text', set = 'Enhanced', key = _c.config.mod_conv}}; info_queue[#info_queue+1] = G.P_CENTERS[_c.config.mod_conv]
        elseif _c.name == "The Star" then loc_vars = {_c.config.max_highlighted,  localize(_c.config.suit_conv, 'suits_plural'), colours = {G.C.SUITS[_c.config.suit_conv]}}
        elseif _c.name == "The Moon" then loc_vars = {_c.config.max_highlighted, localize(_c.config.suit_conv, 'suits_plural'), colours = {G.C.SUITS[_c.config.suit_conv]}}
        elseif _c.name == "The Sun" then loc_vars = {_c.config.max_highlighted, localize(_c.config.suit_conv, 'suits_plural'), colours = {G.C.SUITS[_c.config.suit_conv]}}
        elseif _c.name == "Judgement" then
        elseif _c.name == "The World" then loc_vars = {_c.config.max_highlighted, localize(_c.config.suit_conv, 'suits_plural'), colours = {G.C.SUITS[_c.config.suit_conv]}}
        end
        if _c.balamod then
            for k,v in pairs(consumable.tarot_loc_vars) do
                if k == _c.key then 
                    local status, new_loc_vars = pcall(v, _c)
                    if new_loc_vars then
                        loc_vars = new_loc_vars
                    end
                end
            end
        end
        
        localize{type = 'descriptions', key = _c.key, set = _c.set, nodes = desc_nodes, vars = loc_vars}
        
        if main_end then 
            desc_nodes[#desc_nodes+1] = main_end 
        end
    
       --Fill all remaining info if this is the main desc
        if not ((specific_vars and not specific_vars.sticker) and (card_type == 'Default' or card_type == 'Enhanced')) then
            if desc_nodes == full_UI_table.main and not full_UI_table.name then
                localize{type = 'name', key = _c.key, set = _c.set, nodes = full_UI_table.name} 
                if not full_UI_table.name then full_UI_table.name = {} end
            elseif desc_nodes ~= full_UI_table.main then 
                desc_nodes.name = localize{type = 'name_text', key = name_override or _c.key, set = name_override and 'Other' or _c.set} 
            end
        end
    
        if first_pass and not (_c.set == 'Edition') and badges then
            for k, v in ipairs(badges) do
                if v == 'foil' then info_queue[#info_queue+1] = G.P_CENTERS['e_foil'] end
                if v == 'holographic' then info_queue[#info_queue+1] = G.P_CENTERS['e_holo'] end
                if v == 'polychrome' then info_queue[#info_queue+1] = G.P_CENTERS['e_polychrome'] end
                if v == 'negative' then info_queue[#info_queue+1] = G.P_CENTERS['e_negative'] end
                if v == 'negative_consumable' then info_queue[#info_queue+1] = {key = 'e_negative_consumable', set = 'Edition', config = {extra = 1}} end
                if v == 'gold_seal' then info_queue[#info_queue+1] = {key = 'gold_seal', set = 'Other'} end
                if v == 'blue_seal' then info_queue[#info_queue+1] = {key = 'blue_seal', set = 'Other'} end
                if v == 'red_seal' then info_queue[#info_queue+1] = {key = 'red_seal', set = 'Other'} end
                if v == 'purple_seal' then info_queue[#info_queue+1] = {key = 'purple_seal', set = 'Other'} end
                if v == 'eternal' then info_queue[#info_queue+1] = {key = 'eternal', set = 'Other'} end
                if v == 'perishable' then info_queue[#info_queue+1] = {key = 'perishable', set = 'Other', vars = {G.GAME.perishable_rounds or 1, specific_vars.perish_tally or G.GAME.perishable_rounds}} end
                if v == 'rental' then info_queue[#info_queue+1] = {key = 'rental', set = 'Other', vars = {G.GAME.rental_rate or 1}} end
                if v == 'pinned_left' then info_queue[#info_queue+1] = {key = 'pinned_left', set = 'Other'} end
            end
        end
    
        for _, v in ipairs(info_queue) do
            generate_card_ui(v, full_UI_table)
        end
    
        return full_UI_table
    end
    return misc_generate_card_ui(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end)
end

function create_UIBox_your_collection_spectrals()
    local deck_tables = {}
  
    G.your_collection = {}
    for j = 1, 2 do
      G.your_collection[j] = CardArea(
        G.ROOM.T.x + 0.2*G.ROOM.T.w/2,G.ROOM.T.h,
        (3.25+j)*G.CARD_W,
        1*G.CARD_H, 
        {card_limit = 3+j, type = 'title', highlight_limit = 0, collection = true})
      table.insert(deck_tables, 
      {n=G.UIT.R, config={align = "cm", padding = 0, no_fill = true}, nodes={
        {n=G.UIT.O, config={object = G.your_collection[j]}}
      }}
      )
    end
  
      for j = 1, #G.your_collection do
        for i = 1, 3+j do
        local center = G.P_CENTER_POOLS["Spectral"][i+(j-1)*3 + j - 1]
        
        local card = Card(G.your_collection[j].T.x + G.your_collection[j].T.w/2, G.your_collection[j].T.y, G.CARD_W, G.CARD_H, nil, center)
        card:start_materialize(nil, i>1 or j>1)
        G.your_collection[j]:emplace(card)
      end
    end
  
    local spectral_options = {}
    for i = 1, math.ceil(#G.P_CENTER_POOLS.Spectral/9) do
      table.insert(spectral_options, localize('k_page')..' '..tostring(i)..'/'..tostring(math.ceil(#G.P_CENTER_POOLS.Spectral/9)))
    end
  
    INIT_COLLECTION_CARD_ALERTS()
    
    local t = create_UIBox_generic_options({ back_func = 'your_collection', contents = {
              {n=G.UIT.R, config={align = "cm", minw = 2.5, padding = 0.1, r = 0.1, colour = G.C.BLACK, emboss = 0.05}, nodes=deck_tables},
              {n=G.UIT.R, config={align = "cm", padding = 0}, nodes={
                create_option_cycle({options = spectral_options, w = 4.5, cycle_shoulders = true, opt_callback = 'your_collection_spectral_page', focus_args = {snap_to = true, nav = 'wide'},current_option = 1, colour = G.C.RED, no_pips = true})
              }},
            }})
    return t
  end