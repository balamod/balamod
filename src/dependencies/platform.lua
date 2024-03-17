return {
    is_mac = love.system.getOS() == "OS X",
    is_windows = love.system.getOS() == "Windows",
    is_linux = love.system.getOS() == "Linux",
    is_mobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS",
    is_desktop = love.system.getOS() == "OS X" or love.system.getOS() == "Windows" or love.system.getOS() == "Linux",
    is_android = love.system.getOS() == "Android",
    is_ios = love.system.getOS() == "iOS",
}
