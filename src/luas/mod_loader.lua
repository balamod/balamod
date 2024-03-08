G.FUNCS.open_balamod_github = function(e)
    love.system.openURL('https://github.com/UwUDev/balamod')
end
G.FUNCS.open_balamod_discord = function(e)
    love.system.openURL('https://discord.gg/p7DeW7pSzA')
end
G.FUNCS.taggle_mod = function(e)
    local ori_id = string.sub(e.config.id, 7)
    local mod = getModByModId(mods, ori_id)
    if mod == nil then
        sendDebugMessage('Mod ' .. ori_id .. ' not found')
        return
    end

    sendDebugMessage('Taggling mod: ' .. mod.name .. ' id: ' .. ori_id)
    mod.enabled = not mod.enabled
    if mod.enabled and mod.on_enable and type(mod.on_enable) == 'function' then
        pcall(mod.on_enable)
    elseif not mod.enabled and mod.on_disable and type(mod.on_disable) == 'function' then
        pcall(mod.on_disable)
    end
    -- replace mod in mods
    for i, m in ipairs(mods) do
        if m.mod_id == ori_id then
            mods[i] = mod
            break
        end
    end
    e.config.colour = mod.enabled and G.C.GREEN or G.C.RED
    e.children[1].config.text = mod.enabled and 'Enabled' or 'Disabled'
    e.UIBox:recalculate(true)
end
G.FUNCS.install_mod = function(e)
    local mod_id = string.sub(e.config.id, 7)
    local ret = installMod(mod_id)
    sendDebugMessage('Mod ' .. mod_id .. ' install status ' .. tostring(ret))
    if ret == RESULT.SUCCESS then
        sendDebugMessage('Reloading mod tab')
        if G.OVERLAY_MENU then
            G.OVERLAY_MENU:remove()
            G.OVERLAY_MENU = nil
        end
        G.FUNCS.overlay_menu({definition = G.UIDEF.mods()})
    else
        sendDebugMessage('Mod ' .. mod_id .. ' failed to install')
        e.config.colour = G.C.RED
        e.children[1].config.text = 'Failed'
        e.UIBox:recalculate(true)
    end
end

check_need_update = function(mod_id)
    if getModByModId(repoMods, mod_id) and getModByModId(mods, mod_id) then
        local repo_mod = getModByModId(repoMods, mod_id)
        local mod = getModByModId(mods, mod_id)
        if repo_mod.version ~= mod.version then
            return true
        end
    end
    return false
end

G.UIDEF.mod_description = function(e)
    local text_scale = 0.75
    local status_btn_id = 's_btn_' .. e.config.id
    local menu_btn_id = 'm_btn_' .. e.config.id
    local dl_up_btn_id = 'd_btn_' .. e.config.id

    local mod = getModByModId(mods_collection, e.config.id)
    local mod_present = isModPresent(e.config.id)
    if not mod.description then
        mod.description = {'This mod dose not offer description'}
    end
    if type(mod.description) == 'string' then
        mod.description = {mod.description}
    end
    local menu = mod.menu or nil
    local version = mod.version or 'v0.1'
    local author = mod.author or 'Jone Doe'
    local status_text = mod.enabled and 'Enabled' or 'Disabled'
    local status_colour = mod.enabled and G.C.GREEN or G.C.RED
    local need_update = check_need_update(mod.mod_id)
    local new_version = need_update and 'New ' .. getModByModId(repoMods, mod.mod_id).version or version
    local show_download_btn = not mod_present or need_update
    sendDebugMessage('Mod ' .. mod.name .. ' present ' .. tostring(mod_present) .. ' need update ' ..
                         tostring(need_update) .. ' new version ' .. new_version)
    local mod_description_text = {}
    for _, v in ipairs(mod.description) do
        mod_description_text[#mod_description_text + 1] = {
            n = G.UIT.R,
            config = {align = 'cl'},
            nodes = {{n = G.UIT.T, config = {text = v, scale = 0.3, colour = G.C.UI.TEXT_DARK}}}
        }
    end
    if not mod_present then
        mod_description_text[#mod_description_text + 1] = {
            n = G.UIT.R,
            config = {align = 'cl'},
            nodes = {{n = G.UIT.T, config = {text = mod.url or '', scale = 0.3, colour = G.C.UI.TEXT_DARK}}}
        }
    end
    local mod_description = {{
        n = G.UIT.R,
        config = {align = 'tm', padding = 0.1, minh = 0.5},
        nodes = {mod_present and {
            n = G.UIT.C,
            config = {align = 'cm', r = 0.1, padding = 0.1, colour = G.C.GREEN},
            nodes = {{n = G.UIT.T, config = {text = author, scale = 0.4, colour = G.C.WHITE, shadow = true}}}
        } or nil, {
            n = G.UIT.C,
            config = {align = 'cm', r = 0.1, padding = 0.1, colour = G.C.PURPLE},
            nodes = {{n = G.UIT.T, config = {text = version, scale = 0.4, colour = G.C.WHITE, shadow = true}}}
        }}
    }, {n = G.UIT.R, config = {align = 'tm', minh = 3, padding = 0.1}, nodes = mod_description_text}}
    local mod_description_btns = {
        n = G.UIT.R,
        config = {align = 'cm', minh = 0.9, padding = 0.1},
        nodes = {mod_present and {
            n = G.UIT.C,
            config = {
                align = 'cm',
                padding = 0.1,
                minh = 0.7,
                r = 0.1,
                hover = true,
                colour = status_colour,
                button = 'taggle_mod',
                shadow = true,
                id = status_btn_id
            },
            nodes = {{
                n = G.UIT.T,
                config = {text = mod_present and status_text or 'Download', scale = 0.5, colour = G.C.UI.TEXT_LIGHT}
            }}
        } or nil, (mod_present and menu) and {
            n = G.UIT.C,
            config = {
                align = 'cm',
                padding = 0.1,
                minh = 0.7,
                r = 0.1,
                hover = true,
                colour = G.C.PURPLE,
                button = menu,
                shadow = true,
                id = menu_btn_id
            },
            nodes = {{n = G.UIT.T, config = {text = 'Menu', scale = 0.5, colour = G.C.UI.TEXT_LIGHT}}}
        } or nil, (not mod_present or need_update) and {
            n = G.UIT.C,
            config = {
                align = 'cm',
                padding = 0.1,
                minh = 0.7,
                r = 0.1,
                hover = true,
                colour = G.C.GREEN,
                button = 'install_mod',
                shadow = true,
                id = dl_up_btn_id
            },
            nodes = {{
                n = G.UIT.T,
                config = {text = mod_present and new_version or 'Download', scale = 0.5, colour = G.C.UI.TEXT_LIGHT}
            }}
        } or nil}
    }
    local mod_description_frame = {
        n = G.UIT.C,
        config = {align = 'cm', minw = 3, r = 0.1, colour = mod_present and G.C.BLUE or G.C.ORANGE},
        nodes = {{
            n = G.UIT.R,
            config = {align = 'cm', padding = 0.08, minh = 0.6},
            nodes = {{n = G.UIT.T, config = {text = mod.name, scale = 0.5, colour = G.C.UI.TEXT_LIGHT, shadow = true}}}
        }, {
            n = G.UIT.R,
            config = {align = 'cm', minh = 4, minw = 6.8, maxw = 6.7, padding = 0.05, r = 0.1, colour = G.C.WHITE},
            nodes = mod_description
        }, mod_description_btns}
    }
    return {
        n = G.UIT.ROOT,
        config = {align = 'cm', padding = 0.05, colour = G.C.CLEAR},
        nodes = {mod_description_frame}
    }
end

G.FUNCS.change_mod_description = function(e)
    if not e or not e.config or not e.config.id or e.config.id == 'nil' then
        return
    end
    sendDebugMessage('Changing mod description to ' .. e.config.id)
    if G.OVERLAY_MENU then
        local desc_area = G.OVERLAY_MENU:get_UIE_by_ID('mod_area')
        if desc_area and desc_area.config.oid ~= e.config.id then
            if desc_area.config.old_chosen then
                desc_area.config.old_chosen.config.chosen = nil
            end
            e.config.chosen = 'vert'
            if desc_area.config.object then
                desc_area.config.object:remove()
            end
            desc_area.config.object = UIBox {
                definition = G.UIDEF.mod_description(e),
                config = {offset = {x = 0, y = 0}, align = 'cm', parent = desc_area}
            }
            desc_area.config.oid = e.config.id
            desc_area.config.old_chosen = e
        end
    end
end

G.UIDEF.mod_list_page = function(_page)
    local snapped = false
    local mod_list = {}
    for i, mod in ipairs(mods_collection) do
        sendDebugMessage('Mod index ' .. i .. ' page ' .. _page .. ' name ' .. mod.name .. ' id ' .. mod.mod_id)
        if i > G.MOD_PAGE_SIZE * (_page or 0) and i <= G.MOD_PAGE_SIZE * ((_page or 0) + 1) then
            if G.CONTROLLER.focused.target and G.CONTROLLER.focused.target.config.id == 'mod_page' then
                snapped = true
            end
            local mod_present = isModPresent(mod.mod_id)
            mod_list[#mod_list + 1] = UIBox_button({
                id = mod.mod_id,
                label = {mod.name},
                button = 'change_mod_description',
                colour = mod_present and G.C.RED or G.C.ORANGE,
                minw = 4,
                scale = 0.4,
                minh = 0.6,
                focus_args = {snap_to = not snapped}
            })
            snapped = true
        end
    end

    return {n = G.UIT.ROOT, config = {align = 'cm', padding = 0.1, colour = G.C.CLEAR}, nodes = mod_list}
end

G.FUNCS.change_mod_list_page = function(args)
    if not args or not args.cycle_config then
        return
    end
    if G.OVERLAY_MENU then
        local m_list = G.OVERLAY_MENU:get_UIE_by_ID('mod_list')
        if m_list then
            if m_list.config.object then
                m_list.config.object:remove()
            end
            m_list.config.object = UIBox {
                definition = G.UIDEF.mod_list_page(args.cycle_config.current_option - 1),
                config = {align = 'cm', parent = m_list}
            }
            G.FUNCS.change_mod_description {config = {id = 'nil'}}
        end
    end
end

if refreshRepos() == RESULT.SUCCESS then
    sendDebugMessage('Repo mods refreshed')
else
    sendDebugMessage('Failed to refresh repo mods')
end
mods_collection = {}

create_mod_tab_definition = function()
    G.MOD_PAGE_SIZE = 7
    mods_collection = {}
    for _, mod in ipairs(mods) do
        if not getModByModId(mods_collection, mod.mod_id) then
            table.insert(mods_collection, mod)
        else
            sendDebugMessage('Mod ' .. mod.name .. ' already in collection')
        end
    end
    for index, mod in ipairs(repoMods) do
        local cur_mod = getModByModId(mods_collection, mod.mod_id)
        if not cur_mod then
            table.insert(mods_collection, mod)
        else
            sendDebugMessage('Mod ' .. mod.name .. ' already in collection')
        end
    end
    local mod_pages = {}
    for i = 1, math.ceil(#mods_collection / G.MOD_PAGE_SIZE) do
        table.insert(mod_pages, localize('k_page') .. ' ' .. tostring(i) .. '/' ..
                         tostring(math.ceil(#mods_collection / G.MOD_PAGE_SIZE)))
    end
    G.E_MANAGER:add_event(Event({
        func = (function()
            G.FUNCS.change_mod_list_page {cycle_config = {current_option = 1}}
            return true
        end)
    }))

    return {
        n = G.UIT.ROOT,
        config = {align = 'cm', padding = 0.05, colour = G.C.BLACK, r = 0.1, emboss = 0.05, minh = 6, minw = 6},
        nodes = {{
            n = G.UIT.C,
            config = {align = 'cm', padding = 0.0},
            nodes = {{
                n = G.UIT.R,
                config = {align = 'cm', padding = 0.1, minh = 5, minw = 4, colour = G.C.CLEAR},
                nodes = {{n = G.UIT.O, config = {id = 'mod_list', object = Moveable()}}}
            }, {
                n = G.UIT.R,
                config = {align = 'cm', padding = 0.1, minh = 1, minw = 4},
                nodes = {create_option_cycle({
                    id = 'mod_page',
                    scale = 0.9,
                    h = 0.5,
                    w = 3,
                    options = mod_pages,
                    cycle_shoulders = false,
                    opt_callback = 'change_mod_list_page',
                    current_option = 1,
                    colour = G.C.RED,
                    no_pips = true,
                    focus_args = {snap_to = true}
                })}
            }}
        }, {
            n = G.UIT.C,
            config = {align = 'cm', minh = 5, minw = 7},
            nodes = {{n = G.UIT.O, config = {id = 'mod_area', object = Moveable()}}}
        }}
    }
end

G.UIDEF.mods = function()
    local text_scale = 0.75
    -- LuaFormatter off
    local credits_text = {
        'A Modloader/Decompiler/Code Injector for Balatro',
        '',
        'Usage: ',
        '1. Shutdown the game',
        '2. Place the mod in the mods folder',
        '3. Run the game and the mod will be loaded',
        '',
    }
    -- LuaFormatter on
    for i, v in ipairs(credits_text) do
        credits_text[i] = {
            n = G.UIT.R,
            config = {align = 'cl', padding = 0.1},
            nodes = {{
                n = G.UIT.T,
                config = {text = v, scale = text_scale * 0.5, colour = G.C.UI.TEXT_LIGHT, shadow = true}
            }}
        }
    end
    local t = create_UIBox_generic_options({
        contents = {{
            n = G.UIT.R,
            config = {align = 'cm', padding = 0},
            nodes = {create_tabs({
                tabs = {{label = 'Mods', chosen = true, tab_definition_function = create_mod_tab_definition}, {
                    label = 'Credits',
                    tab_definition_function = function()
                        return {
                            n = G.UIT.ROOT,
                            config = {align = 'cm', padding = 0.2, colour = G.C.BLACK, r = 0.1, emboss = 0.05, minh = 4},
                            nodes = {{
                                n = G.UIT.R,
                                config = {
                                    align = 'cm',
                                    padding = 0.1,
                                    outline_colour = G.C.JOKER_GREY,
                                    r = 0.1,
                                    outline = 1,
                                    minw = 4
                                },
                                nodes = {{
                                    n = G.UIT.R,
                                    config = {align = 'cm', padding = 0.1},
                                    nodes = {create_badge('Balamod', G.C.DARK_EDITION, G.C.UI.TEXT_LIGHT, 1.5)}
                                }, {n = G.UIT.R, config = {align = 'cl', padding = 0}, nodes = credits_text}, {
                                    n = G.UIT.R,
                                    config = {align = 'cm', padding = 0.1, colour = G.C.CLEAR},
                                    nodes = {G.F_EXTERNAL_LINKS and {
                                        n = G.UIT.C,
                                        config = {align = 'cm', padding = 0},
                                        nodes = {UIBox_button({
                                            scale = text_scale * 0.5,
                                            label = {'Github'},
                                            button = 'open_balamod_github'
                                        })}
                                    } or nil, G.F_EXTERNAL_LINKS and {
                                        n = G.UIT.C,
                                        config = {align = 'cm', padding = 0},
                                        nodes = {UIBox_button({
                                            scale = text_scale * 0.5,
                                            label = {'Discord'},
                                            button = 'open_balamod_discord'
                                        })}
                                    } or nil}
                                }}
                            }}
                        }
                    end
                }},
                snap_to_nav = true
            })}
        }}
    })
    return t
end

G.FUNCS.show_mods = function(e)
    G.SETTINGS.paused = true

    G.FUNCS.overlay_menu({definition = G.UIDEF.mods()})
end

G.VERSION = G.VERSION .. '\nBalamod {balamod_version}'
dec_api.hook()