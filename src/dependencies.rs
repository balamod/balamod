use std::collections::HashMap;

#[cfg(target_os = "macos")]
pub fn get_https_so() -> &'static [u8]{
    include_bytes!("dependencies/macos/https.so")
}

#[cfg(target_os = "windows")]
pub fn get_https_so() -> &'static [u8]{
    include_bytes!("dependencies/windows/https.dll")
}

#[cfg(target_os = "linux")]
pub fn get_https_so() -> &'static [u8]{
    include_bytes!("dependencies/windows/https.dll")
}

pub fn get_balamod_version_lua(version: &'static str) -> String {
    format!(r#"
    return "{}"
    "#, version)
}

pub fn get_balamod_dependencies_lua() -> HashMap<&'static str, &'static str>{
    HashMap::from([
        ("assets.lua", include_str!("dependencies/assets.lua")),
        ("balamod_card.lua", include_str!("dependencies/balamod_card.lua")),
        ("balamod_game.lua", include_str!("dependencies/balamod_game.lua")),
        ("balamod_love.lua", include_str!("dependencies/balamod_love.lua")),
        ("balamod_uidefs.lua", include_str!("dependencies/balamod_uidefs.lua")),
        ("balamod.lua", include_str!("dependencies/balamod.lua")),
        ("console.lua", include_str!("dependencies/console.lua")),
        ("joker.lua", include_str!("dependencies/joker.lua")),
        ("json.lua", include_str!("dependencies/json.lua")),
        ("logging.lua", include_str!("dependencies/logging.lua")),
        ("mod_menu.lua", include_str!("dependencies/mod_menu.lua")),
        ("patches.lua", include_str!("dependencies/patches.lua")),
        ("platform.lua", include_str!("dependencies/platform.lua")),
        ("tar.lua", include_str!("dependencies/tar.lua")),
        ("utils.lua", include_str!("dependencies/utils.lua")),
    ])
}