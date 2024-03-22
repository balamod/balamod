pub fn get_imports() -> &'static str {
    r#"
local balamod = require('balamod')
mods = balamod.mods
-- for compatibility with older mods
inject = balamod.inject
injectHead = balamod.injectHead
injectTail = balamod.injectTail
    "#
}
