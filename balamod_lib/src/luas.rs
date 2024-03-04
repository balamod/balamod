pub fn get_mod_core() -> &'static str {
    include_str!("luas/mod_core.lua")
}

pub fn get_mod_loader() -> &'static str {
    include_str!("luas/mod_loader.lua")
}

pub fn get_pre_update_event() -> &'static str {
    r#"
    local cancel_update = false
    for _, mod in ipairs(mods) do
        if mod.on_pre_update then
            if mod.on_pre_update(dt) then
                cancel_update = true
            end
        end
    end

    if cancel_update then return end
    "#
}

pub fn get_post_update_event() -> &'static str {
    r#"
    if balamodLoaded == false then
        balamodLoaded = true
        for _, mod in ipairs(mods) do -- Load all mods after eveything else
	        if mod.enabled and mod.on_enable and type(mod.on_enable) == "function" then
		        pcall(mod.on_enable) -- Call the on_enable function of the mod if it exists
	        end
        end
    end

    for _, mod in ipairs(mods) do
        if mod.on_post_update then
            mod.on_post_update(dt)
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
            if mod.on_key_pressed(key) then
                cancel_event = true
            end
        end
    end

    if cancel_event then return end
    "#
}

pub fn get_mouse_pressed_event() -> &'static str {
    r#"
    local cancel_event = false
    for _, mod in ipairs(mods) do
        if mod.on_mouse_pressed then
            if mod.on_mouse_pressed(x, y, button, touches) then
                cancel_event = true
            end
        end
    end
    if cancel_event then return end
    "#
}
