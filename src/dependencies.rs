#[cfg(target_os = "macos")]
pub fn get_ssl_so() -> &'static [u8]{
    include_bytes!("dependencies/ssl.so")
}

#[cfg(target_os = "macos")]
pub fn get_ssl_lua() -> &'static str {
    include_str!("dependencies/ssl.lua")
}

#[cfg(target_os = "macos")]
pub fn get_https_lua() -> &'static str {
    include_str!("dependencies/https.lua")
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

pub fn get_json_lua() -> &'static str {
    include_str!("dependencies/json.lua")
}

pub fn get_utils_lua() -> &'static str {
    include_str!("dependencies/utils.lua")
}

pub fn get_balamod_version_lua(version: &'static str) -> String {
    format!(r#"
    return "{}"
    "#, version)
}