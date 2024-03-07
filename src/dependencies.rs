pub fn get_ssl_so() -> &'static [u8]{
    include_bytes!("dependencies/ssl.so")
}

pub fn get_ssl_lua() -> &'static str {
    include_str!("dependencies/ssl.lua")
}

pub fn get_https_lua() -> &'static str {
    include_str!("dependencies/https.lua")
}
