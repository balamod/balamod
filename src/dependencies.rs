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

pub fn get_balamod_lua() -> &'static str {
    include_str!("dependencies/balamod.lua")
}

pub fn get_console_lua() -> &'static str {
    include_str!("dependencies/console.lua")
}

pub fn get_platform_lua() -> &'static str {
    include_str!("dependencies/platform.lua")
}

pub fn get_logging_lua() -> &'static str {
    include_str!("dependencies/logging.lua")
}

pub fn get_patches_lua() -> &'static str {
    include_str!("dependencies/patches.lua")
}

pub fn get_mod_menu_lua() -> &'static str {
    include_str!("dependencies/mod_menu.lua")
}

pub fn get_joker_lua() -> &'static str{
    include_str!("dependencies/joker.lua")
}

pub fn get_json_lua() -> &'static str {
    include_str!("dependencies/json.lua")
}

pub fn get_utils_lua() -> &'static str {
    include_str!("dependencies/utils.lua")
}

pub fn get_tar_lua() -> &'static str {
    include_str!("dependencies/tar.lua")
}

pub fn get_mod_api_lua() -> &'static str {
    include_str!("dependencies/mod.lua")
}

pub fn get_assets_lua() -> &'static str {
    include_str!("dependencies/assets.lua")
}

pub fn get_balamod_version_lua(version: &'static str) -> String {
    format!(r#"
    return "{}"
    "#, version)
}