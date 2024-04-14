local game_create_UIBox_main_menu_buttons = create_UIBox_main_menu_buttons
local game_create_UIBox_your_collection_tarots = create_UIBox_your_collection_tarots
local game_create_UIBox_your_collection_spectrals = create_UIBox_your_collection_spectrals

function create_UIBox_main_menu_buttons()
    local t = game_create_UIBox_main_menu_buttons()
    local modBtn = {
        n = G.UIT.R,
        config = {
            align = "cm",
            padding = 0.2,
            r = 0.1,
            emboss = 0.1,
            colour = G.C.L_BLACK,
        },
        nodes = {
            {
                n = G.UIT.R,
                config = {
                    align = "cm",
                    padding = 0.15,
                    minw = 1,
                    r = 0.1,
                    hover = true,
                    colour = G.C.PURPLE,
                    button = 'show_mods',
                    shadow = true,
                },
                nodes = {
                    {
                        n = G.UIT.T,
                        config = {
                            text = "MODS",
                            scale = 0.6,
                            colour = G.C.UI.TEXT_LIGHT,
                            shadow = true,
                        },
                    },
                },
            },
        },
    }

    local insertIndex = #t.nodes[2].nodes
    if not G.F_ENGLISH_ONLY then
        insertIndex = insertIndex - 1
    end
    table.insert(t.nodes[2].nodes, insertIndex, modBtn)
    return t
end

function create_UIBox_your_collection_tarots()
    -- change tarot options to properly add new pages
    local tarot_options = {}
    for i = 1, math.ceil(#G.P_CENTER_POOLS.Tarot/11) do
        table.insert(tarot_options, localize('k_page')..' '..tostring(i)..'/'..tostring(math.ceil(#G.P_CENTER_POOLS.Tarot/11)))
    end
    
    local old_return = game_create_UIBox_your_collection_tarots()
    -- remove old option cycle dynatext object
    old_return.nodes[1].nodes[1].nodes[1].nodes[2].nodes[1].nodes[2].nodes[1].nodes[2].nodes[1].nodes[1].nodes[1].config.object:remove()
    -- create new option cycle
    old_return.nodes[1].nodes[1].nodes[1].nodes[2] = create_option_cycle({options = tarot_options, w = 4.5, cycle_shoulders = true, opt_callback = 'your_collection_tarot_page', focus_args = {snap_to = true, nav = 'wide'},current_option = 1, colour = G.C.RED, no_pips = true})
    return old_return 
end

function create_UIBox_your_collection_spectrals()
    local spectral_options = {}
    for i = 1, math.ceil(#G.P_CENTER_POOLS.Spectral/9) do
      table.insert(spectral_options, localize('k_page')..' '..tostring(i)..'/'..tostring(math.ceil(#G.P_CENTER_POOLS.Spectral/9)))
    end

    local old_return = game_create_UIBox_your_collection_spectrals()
    -- remove old option cycle dynatext object
    old_return.nodes[1].nodes[1].nodes[1].nodes[2].nodes[1].nodes[2].nodes[1].nodes[2].nodes[1].nodes[1].nodes[1].config.object:remove()
    -- create new option cycle
    old_return.nodes[1].nodes[1].nodes[1].nodes[2] = create_option_cycle({options = spectral_options, w = 4.5, cycle_shoulders = true, opt_callback = 'your_collection_spectral_page', focus_args = {snap_to = true, nav = 'wide'},current_option = 1, colour = G.C.RED, no_pips = true})
    return old_return 
  end
  