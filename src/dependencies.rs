pub fn get_ssl_so() -> &'static [u8]{
    include_bytes!("dependencies/ssl.so")
}

pub fn get_ssl_lua() -> &'static str {
    include_str!("dependencies/ssl.lua")
}

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

pub fn get_logger_lua() -> &'static str {
    include_str!("dependencies/logging.lua")
}

pub fn get_mod_menu_lua() -> &'static str {
    include_str!("dependencies/mod_menu.lua")
}

pub fn get_balamod_version_lua(version: &'static str) -> String {
    format!(r#"
    return "{}"
    "#, version)
}