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

fn get_balamod_version_lua(version: &'static str) -> String {
    format!(r#"
    return "{}"
    "#, version)
}

pub fn get_balamod_dependencies_lua(version: &'static str) -> HashMap<&'static str, Vec<u8>>{
    HashMap::from([
        ("assets.lua", include_str!("dependencies/assets.lua").as_bytes().to_vec()),
        ("balamod_card.lua", include_str!("dependencies/balamod_card.lua").as_bytes().to_vec()),
        ("balamod_game.lua", include_str!("dependencies/balamod_game.lua").as_bytes().to_vec()),
        ("balamod_love.lua", include_str!("dependencies/balamod_love.lua").as_bytes().to_vec()),
        ("balamod_uidefs.lua", include_str!("dependencies/balamod_uidefs.lua").as_bytes().to_vec()),
        ("balamod.lua", include_str!("dependencies/balamod.lua").as_bytes().to_vec()),
        ("console.lua", include_str!("dependencies/console.lua").as_bytes().to_vec()),
        ("joker.lua", include_str!("dependencies/joker.lua").as_bytes().to_vec()),
        ("json.lua", include_str!("dependencies/json.lua").as_bytes().to_vec()),
        ("seal.lua", include_str!("dependencies/seal.lua").as_bytes().to_vec()),
        ("logging.lua", include_str!("dependencies/logging.lua").as_bytes().to_vec()),
        ("mod_menu.lua", include_str!("dependencies/mod_menu.lua").as_bytes().to_vec()),
        ("patches.lua", include_str!("dependencies/patches.lua").as_bytes().to_vec()),
        ("platform.lua", include_str!("dependencies/platform.lua").as_bytes().to_vec()),
        ("tar.lua", include_str!("dependencies/tar.lua").as_bytes().to_vec()),
        ("utils.lua", include_str!("dependencies/utils.lua").as_bytes().to_vec()),
        ("balamod_version.lua", get_balamod_version_lua(version).as_bytes().to_vec()),
    ])
}