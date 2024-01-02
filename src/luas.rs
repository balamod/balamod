pub fn get_mod_core() -> &'static str {
    r#"
mods = {}

if not love.filesystem.getInfo("mods", "directory") then
    love.filesystem.createDirectory("mods")
end

if not love.filesystem.getInfo("apis", "directory") then
    love.filesystem.createDirectory("apis")
end

current_game_code = love.data.decompress("string", "deflate", love.filesystem.read("DAT1.jkr"))

function excractFunctionBody(function_name)
    local pattern = "\r\nfunction " .. function_name
    local func_begin, fin = current_game_code:find(pattern)
    if not func_begin then
        return "C'ant find function begin " .. function_name
    end

    local func_end = current_game_code:find("\n\r?end", fin)
    if not func_end then
        return "Can't find function end " .. function_name
    end

    local func_body = current_game_code:sub(func_begin, func_end + 3)
    return func_body
end

function inject(function_name, to_replace, replacement)
    local function_body = excractFunctionBody(function_name)
    local modified_function_code = function_body:gsub(to_replace, replacement)
    escaped_function_body = function_body:gsub("([^%w])", "%%%1")
    current_game_code = current_game_code:gsub(escaped_function_body, modified_function_code)

    local new_function, load_error = load(modified_function_code)
    if not new_function then
        love.filesystem.write("err1.txt", "Error loading modified function: " .. (load_error or "Unknown error"))
    end

    if setfenv then setfenv(new_function, getfenv(original_testFunction)) end

    local status, result = pcall(new_function)
    if status then
        testFunction = result
    else
        love.filesystem.write("err2.txt", "Error executing modified function: " .. result)
    end
end
    "#
}

pub fn get_mod_loader() -> &'static str {
    r#"
function G.UIDEF.mods()
    btn_nodes = {}
    for i, mod in ipairs(mods) do
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

function G.FUNCS.show_mods(arg_733_0)
    G.SETTINGS.paused = true

    G.FUNCS.overlay_menu({
        definition = G.UIDEF.mods()
    })
end

local apis_files = love.filesystem.getDirectoryItems("apis")
for _, file in ipairs(apis_files) do
    if file:sub(-4) == ".lua" then
        local modPath = "apis/" .. file
        local modContent, loadErr = love.filesystem.load(modPath)

        if modContent then
            local success, mod = pcall(modContent)
            if success then
                table.insert(mods, mod)
            else
                print("Error loading api: " .. modPath .. "\n" .. mod)
            end
        else
            print("Error reading api: " .. modPath .. "\n" .. loadErr)
        end
    end
end

local files = love.filesystem.getDirectoryItems("mods")
for _, file in ipairs(files) do
    if file:sub(-4) == ".lua" then
        local modPath = "mods/" .. file
        local modContent, loadErr = love.filesystem.load(modPath)

        if modContent then
            local success, mod = pcall(modContent)
            if success then
                table.insert(mods, mod)
            else
                print("Error loading mod: " .. modPath .. "\n" .. mod)
            end
        else
            print("Error reading mod: " .. modPath .. "\n" .. loadErr)
        end
    end
end

for _, mod in ipairs(mods) do
    if mod.enabled and mod.on_enable and type(mod.on_enable) == "function" then
        pcall(mod.on_enable)
    end
end
    "#
}

pub fn get_mods_menu_button() -> &'static str {
    r#"
        mods_button = UIBox_button({
            minw = 5,
            button = "show_mods",
            label = {
                "Mods"
            }
        })
    "#
}

pub fn get_pre_update_event() -> &'static str {
    r#"
    local cancel_update = false
    for _, mod in ipairs(mods) do
        if mod.on_pre_update then
            if mod.on_pre_update(mod, arg_298_1) then
                cancel_update = true
            end
        end
    end

    if cancel_update then return end
    "#
}

pub fn get_post_update_event() -> &'static str {
    r#"
    for _, mod in ipairs(mods) do
        if mod.on_post_update then
            mod.on_post_update(mod, arg_298_1)
        end
    end
    "#
}

pub fn get_pre_render_event() -> &'static str {
    r#"
    for _, mod in ipairs(mods) do
        if mod.on_pre_render then
            mod.on_pre_render()
        end
    end
    "#
}

pub fn get_post_render_event() -> &'static str {
    r#"
    for _, mod in ipairs(mods) do
        if mod.on_post_render then
            mod.on_post_render()
        end
    end
"#
}

pub fn get_key_pressed_event() -> &'static str {
    r#"
    local cancel_event = false
    for _, mod in ipairs(mods) do
        if mod.on_key_pressed then
            if mod.on_key_pressed(this, key_name, arg_31_2) then
                cancel_event = true
            end
        end
    end

    if cancel_event then return end
    "#
}