local localization = require('localization')
local misc_functions_init_localization = misc_functions_init_localization or init_localization

function init_localization()
    localization.inject()
    misc_functions_init_localization()
end
