function G.UIDEF.mods()
    btn_nodes = {}
    for _, mod in ipairs(mods) do
        col = G.C.RED
        if mod.enabled then
            col = G.C.GREEN
        end
        table.insert(btn_nodes, UIBox_button({
            minw = 6,
            button = "usage",
            minh = 0.8,
            colour = col,
            label = {
                mod.name
            }
        }))
    end
    return (create_UIBox_generic_options({
        snap_back = true,
        back_func = "options",
        contents = {
            {
                n = G.UIT.C,
                config = {
                    r = 0.1,
                    align = "cm",
                    padding = 0.1,
                    colour = G.C.CLEAR
                },
                nodes = btn_nodes
            }
        }
    }))

end

function G.FUNCS.show_mods(_)
    G.SETTINGS.paused = true

    G.FUNCS.overlay_menu({
        definition = G.UIDEF.mods()
    })
end

G.VERSION = G.VERSION .. "\nBalamod {balamod_version}"
