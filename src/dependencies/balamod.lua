require('logger')
console = require('console')
math = require('math')

logger = getLogger('balamod')
mods = {}

function splitstring(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

table.insert(mods,
    {
        mod_id = "dev_console",
        name = "Dev Console",
        version = "0.6.0",
        author = "sbordeyne & UwUDev",
        description = {
            "Press F2 to open/close the console",
            "Use command `help` for a list of ",
            "available commands and shortcuts",
        },
        enabled = true,
        on_game_load = function(args)
            console.logger:info("Game loaded", args)
            for _, arg in ipairs(args) do
                local split = splitstring(arg, "=")
                if split[0] == "--log-level" then
                    console.logger.level = split[1]:upper()
                    console.log_level = split[1]:upper()
                end
            end
            saveLogs()
        end,
        on_game_quit = function()
            console.logger:info("Quitting Balatro...")
            saveLogs()
        end,
        on_error = function(message)
            console.logger:error("Error: ", message)
            -- on error, write all messages to a file
            saveLogs()
        end,
        on_enable = function()
            console.logger:debug("Dev Console enabled")
            contents, size = love.filesystem.read(console.history_path)
            if contents then
                console.logger:trace("History file size", size)
                for line in contents:gmatch("[^\r\n]+") do
                    if line and line ~= "" then
                        table.insert(console.command_history, line)
                    end
                end
            end

            registerCommand(
                "help",
                function()
                    console.logger:print("Available commands:")
                    for name, cmd in pairs(console.commands) do
                        if cmd.desc then
                            console.logger:print(name .. ": " .. cmd.desc)
                        end
                    end
                    return true
                end,
                "Prints a list of available commands",
                function(current_arg)
                    local completions = {}
                    for name, _ in pairs(console.commands) do
                        if name:find(current_arg, 1, true) == 1 then
                            table.insert(completions, name)
                        end
                    end
                    return completions
                end,
                "Usage: help <command>"
            )

            registerCommand(
                "shortcuts",
                function()
                    console.logger:print("Available shortcuts:")
                    console.logger:print("F2: Open/Close the console")
                    console.logger:print("F4: Toggle debug mode")
                    if platform.is_mac then
                        console.logger:print("Cmd+C: Copy the current command to the clipboard.")
                        console.logger:print("Cmd+Shift+C: Copies all messages to the clipboard")
                        console.logger:print("Cmd+V: Paste the clipboard into the current command")
                    else
                        console.logger:print("Ctrl+C: Copy the current command to the clipboard.")
                        console.logger:print("Ctrl+Shift+C: Copies all messages to the clipboard")
                        console.logger:print("Ctrl+V: Paste the clipboard into the current command")
                    end
                    return true
                end,
                "Prints a list of available shortcuts",
                function(current_arg)
                    return nil
                end,
                "Usage: shortcuts"
            )

            registerCommand(
                "history",
                function()
                    console.logger:print("Command history:")
                    for i, cmd in ipairs(console.command_history) do
                        console.logger:print(i .. ": " .. cmd)
                    end
                    return true
                end,
                "Prints the command history"
            )

            registerCommand(
                "clear",
                function()
                    ALL_MESSAGES = {}
                    return true
                end,
                "Clear the console"
            )

            registerCommand(
                "exit",
                function()
                    console:toggle()
                    return true
                end,
                "Close the console"
            )

            registerCommand(
                "quit",
                function()
                    love.quit()
                    return true
                end,
                "Quit the game"
            )

            registerCommand(
                "give",
                function()
                    console.logger:error("Give command not implemented yet")
                    return false
                end,
                "Give an item to the player"
            )

            registerCommand(
                "money",
                function(args)
                    if args[1] and args[2] then
                        local amount = tonumber(args[2])
                        if amount then
                            if args[1] == "add" then
                                ease_dollars(amount, true)
                                console.logger:info("Added " .. amount .. " money to the player")
                            elseif args[1] == "remove" then
                                ease_dollars(-amount, true)
                                console.logger:info("Removed " .. amount .. " money from the player")
                            elseif args[1] == "set" then
                                local currentMoney = G.GAME.dollars
                                local diff = amount - currentMoney
                                ease_dollars(diff, true)
                                console.logger:info("Set player money to " .. amount)
                            else
                                console.logger:error("Invalid operation, use add, remove or set")
                            end
                        else
                            console.logger:error("Invalid amount")
                            return false
                        end
                    else
                        console.logger:warn("Usage: money <add/remove/set> <amount>")
                        return false
                    end
                    return true
                end,
                "Change the player's money",
                function (current_arg)
                    local subcommands = {"add", "remove", "set"}
                    for i, v in ipairs(subcommands) do
                        if v:find(current_arg, 1, true) == 1 then
                            return {v}
                        end
                    end
                    return nil
                end
            )

            registerCommand(
                "discards",
                function(args)
                    if args[1] and args[2] then
                        local amount = tonumber(args[2])
                        if amount then
                            if args[1] == "add" then
                                ease_discard(amount, true)
                                console.logger:info("Added " .. amount .. " discards to the player")
                            elseif args[1] == "remove" then
                                ease_discard(-amount, true)
                                console.logger:info("Removed " .. amount .. " discards from the player")
                            elseif args[1] == "set" then
                                local currentDiscards = G.GAME.current_round.discards_left
                                local diff = amount - currentDiscards
                                ease_discard(diff, true)
                                console.logger:info("Set player discards to " .. amount)
                            else
                                console.logger:error("Invalid operation, use add, remove or set")
                                return false
                            end
                        else
                            console.logger:error("Invalid amount")
                            return false
                        end
                    else
                        console.logger:warn("Usage: discards <add/remove/set> <amount>")
                        return false
                    end
                    return true
                end,
                "Change the player's discards",
                function (current_arg)
                    local subcommands = {"add", "remove", "set"}
                    for i, v in ipairs(subcommands) do
                        if v:find(current_arg, 1, true) == 1 then
                            return {v}
                        end
                    end
                    return nil
                end
            )

            registerCommand(
                "hands",
                function(args)
                    if args[1] and args[2] then
                        local amount = tonumber(args[2])
                        if amount then
                            if args[1] == "add" then
                                ease_hands_played(amount, true)
                                console.logger:info("Added " .. amount .. " hands to the player")
                            elseif args[1] == "remove" then
                                ease_hands_played(-amount, true)
                                console.logger:info("Removed " .. amount .. " hands from the player")
                            elseif args[1] == "set" then
                                local currentHands = G.GAME.current_round.hands_left
                                local diff = amount - currentHands
                                ease_hands_played(diff, true)
                                console.logger:info("Set player hands to " .. amount)
                            else
                                console.logger:error("Invalid operation, use add, remove or set")
                                return false
                            end
                        else
                            console.logger:error("Invalid amount")
                            return false
                        end
                    else
                        console.logger:warn("Usage: hands <add/remove/set> <amount>")
                        return false
                    end
                    return true
                end,
                "Change the player's remaining hands",
                function (current_arg)
                    local subcommands = {"add", "remove", "set"}
                    for i, v in ipairs(subcommands) do
                        if v:find(current_arg, 1, true) == 1 then
                            return {v}
                        end
                    end
                    return nil
                end
            )

        end,
        on_disable = function()
        end,
        on_key_pressed = function (key_name)
            if key_name == "f2" then
                console:toggle()
                return true
            end
            if console.is_open then
                console:typeKey(key_name)
                return true
            end

            if key_name == "f4" then
                G.DEBUG = not G.DEBUG
                if G.DEBUG then
                    console.logger:info("Debug mode enabled")
                else
                    console.logger:info("Debug mode disabled")
                end
            end
            return false
        end,
        on_post_render = function ()
            console.max_lines = math.floor(love.graphics.getHeight() / console.line_height) - 5  -- 5 lines of bottom padding
            if console.is_open then
                love.graphics.setColor(0, 0, 0, 0.3)
                love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
                for i, message in ipairs(console:getMessagesToDisplay()) do
                    r, g, b = console:getMessageColor(message)
                    love.graphics.setColor(r, g, b, 1)
                    love.graphics.print(message:formatted(), 10, 10 + i * 20)
                end
                love.graphics.setColor(1, 1, 1, 1) -- white
                love.graphics.print(console.cmd, 10, love.graphics.getHeight() - 30)
            end
        end,
        on_key_released = function (key_name)
            if key_name == "capslock" then
                console.modifiers.capslock = not console.modifiers.capslock
                console:modifiersListener()
                return
            end
            if key_name == "scrolllock" then
                console.modifiers.scrolllock = not console.modifiers.scrolllock
                console:modifiersListener()
                return
            end
            if key_name == "numlock" then
                console.modifiers.numlock = not console.modifiers.numlock
                console:modifiersListener()
                return
            end
            if key_name == "lalt" or key_name == "ralt" then
                console.modifiers.alt = false
                console:modifiersListener()
                return false
            end
            if key_name == "lctrl" or key_name == "rctrl" then
                console.modifiers.ctrl = false
                console:modifiersListener()
                return false
            end
            if key_name == "lshift" or key_name == "rshift" then
                console.modifiers.shift = false
                console:modifiersListener()
                return false
            end
            if key_name == "lgui" or key_name == "rgui" then
                console.modifiers.meta = false
                console:modifiersListener()
                return false
            end
            return false
        end,
        on_mouse_pressed = function(x, y, button, touches)
            if console.is_open then
                return true  -- Do not press buttons through the console, this cancels the event
            end
        end,
        on_mouse_released = function(x, y, button)
            if console.is_open then
                return true -- Do not release buttons through the console, this cancels the event
            end
        end,
    }
)

balamodLoaded = false

RESULT = {
    SUCCESS = 0,
    MOD_NOT_FOUND_IN_REPOS = 1,
    MOD_NOT_FOUND_IN_MODS = 2,
    MOD_ALREADY_PRESENT = 3,
    NETWORK_ERROR = 4,
    MOD_FS_LOAD_ERROR = 5,
    MOD_PCALL_ERROR = 6,
}

if not love.filesystem.getInfo("mods", "directory") then -- Create mods folder if it doesn't exist
    love.filesystem.createDirectory("mods")
end

if not love.filesystem.getInfo("logs", "directory") then -- Create logs folder if it doesn't exist
    love.filesystem.createDirectory("logs")
end

if not love.filesystem.getInfo("apis", "directory") then -- Create apis folder if it doesn't exist
    love.filesystem.createDirectory("apis")
end

-- registers a command to be used in the dev console
-- @param name: string, the name of the command
-- @param callback: function, the function to be called when the command is run
-- @param short_description: string, a short description of the command
-- @param autocomplete: function(current_arg: string), a function that returns a list of possible completions for the current argument
-- @param usage: string, a string describing the usage of the command (longer, more detailed description of the command's usage)
function registerCommand(name, callback, short_description, autocomplete, usage)
    if name == nil then
        console.logger:error("registerCommand -- name is required")
    end
    if callback == nil then
        console.logger:error("registerCommand -- callback is required")
    end
    if type(callback) ~= "function" then
        console.logger:error("registerCommand -- callback must be a function")
    end
    if name == nil or callback == nil or type(callback) ~= "function" then
        console.logger:warn("registerCommand -- name and callback are required, ignoring")
        return
    end
    if short_description == nil then
        console.logger:warn("registerCommand -- no description provided, please provide a description for the `help` command")
        short_description = "No help provided"
    end
    if usage == nil then
        usage = short_description
    end
    if autocomplete == nil then
        autocomplete = function(current_arg) return nil end
    end
    if type(autocomplete) ~= "function" then
        console.logger:warn("registerCommand -- autocomplete must be a function")
        autocomplete = function(current_arg) return nil end
    end
    if console.commands[name] then
        console.logger:error("Command " .. name .. " already exists")
        return
    end
    console.commands[name] = {
        call = callback,
        desc = short_description,
        autocomplete = autocomplete,
        usage = usage,
    }
end

function buildPaths(root,ignore)
    local items = love.filesystem.getDirectoryItems(root)
    for _, file in ipairs(items) do
        if root ~= "" then
            file = root.."/"..file
        end
        local info = love.filesystem.getInfo(file)
        if info then
            if info.type == "file" and file:match("%.lua$") then
                table.insert(paths,file)
            elseif info.type == "directory" then
                local valid = true
                for _, i in ipairs(ignore) do
                    if i == file then
                        valid = false
                    end
                end
                if valid then
                    buildPaths(file,ignore)
                end
            end
        end
    end
end

paths = {} -- Paths to the files that will be loaded
buildPaths("",{"mods","apis","resources","localization"})
-- current_game_code = love.filesystem.read(path)
buildPaths = nil -- prevent rerunning (i think)

current_game_code = {}
for _, path in ipairs(paths) do
    current_game_code[path] = love.filesystem.read(path)
end

function request(url)
    logger:debug('Request made with url: ' .. url)
    local https = require 'https'
    local code
    local response
    if love.system.getOS() == 'OS X' then
        response, code = https.request(url)
    else
        code, response = https.request(url, {headers = {['User-Agent'] = 'Balamod-Client'}})
    end
    return code, response
end

function extractFunctionBody(path, function_name)
    local pattern = "\n?%s*function%s+" .. function_name
    local func_begin, fin = current_game_code[path]:find(pattern)

    if not func_begin then
        return "Can't find function begin " .. function_name
    end

    local func_end = current_game_code[path]:find("\n\r?end", fin)

    -- This is to catch functions that have incorrect ending indentation by catching the next function in line.
    -- Can be removed once Card:calculate_joker no longer has this typo.
    local typocatch_func_end = current_game_code[path]:find("\n\r?function", fin)
    if typocatch_func_end and typocatch_func_end < func_end then
        func_end = typocatch_func_end - 3
    end

    if not func_end then
        return "Can't find function end " .. function_name
    end

    local func_body = current_game_code[path]:sub(func_begin, func_end + 3)
    return func_body
end

function inject(path, function_name, to_replace, replacement)
    -- Injects code into a function (replaces a string with another string inside a function)
    local function_body = extractFunctionBody(path, function_name)
    local modified_function_code = function_body:gsub(to_replace, replacement)
    escaped_function_body = function_body:gsub("([^%w])", "%%%1") -- escape function body for use in gsub
    escaped_modified_function_code = modified_function_code:gsub("([^%w])", "%%%1")
    current_game_code[path] = current_game_code[path]:gsub(escaped_function_body, escaped_modified_function_code) -- update current game code in memory

    local new_function, load_error = load(modified_function_code) -- load modified function
    if not new_function then
        logger:error("Error loading modified function", function_name, ": ", (load_error or "Unknown error"))
        logger:error(modified_function_code)
    end

    if setfenv then
        setfenv(new_function, getfenv(original_testFunction))
    end -- Set the environment of the new function to the same as the original function

    local status, result = pcall(new_function) -- Execute the new function
    if status then
        testFunction = result -- Overwrite the original function with the result of the new function
    else
        logger:error("Error executing modified function", function_name, ": ", result) -- Safeguard against errors
        logger:error(modified_function_code)
    end
end

function injectHead(path, function_name, code)
    local function_body = extractFunctionBody(path, function_name)

    local pattern = "(function%s+" .. function_name .. ".-)\n"
    local modified_function_code, number_of_subs = function_body:gsub(pattern, "%1\n" .. code .. "\n")

    if number_of_subs == 0 then
        logger:error("Error: Function start not found in function body or multiple matches encountered.")
        logger:error(modified_function_code)
        return
    end

    escaped_function_body = function_body:gsub("([^%w])", "%%%1")
    escaped_modified_function_code = modified_function_code:gsub("([^%w])", "%%%1")
    current_game_code[path] = current_game_code[path]:gsub(escaped_function_body, escaped_modified_function_code)

    local new_function, load_error = load(modified_function_code)
    if not new_function then
        logger:error("Error loading modified function ", function_name, " with head injection: ", (load_error or "Unknown error"))
        logger:error(modified_function_code)
        return
    end

    if setfenv then
        setfenv(new_function, getfenv(original_testFunction))
    end

    local status, result = pcall(new_function)
    if status then
        testFunction = result
    else
        logger:error("Error executing modified function ", function_name, " with head injection: ", result)
        logger:error(modified_function_code)
    end
end

function injectTail(path, function_name, code)
    local function_body = extractFunctionBody(path, function_name)

    local pattern = "(.-)(end[ \t]*\n?)$"
    local modified_function_code, number_of_subs = function_body:gsub(pattern, "%1" .. string.gsub(code, '(.-)%s*$', '%1') .. "\n" .. "%2")

    if number_of_subs == 0 then
        logger:error("Error: 'end' not found in function '", function_name, "' body or multiple ends encountered.")
        logger:error(modified_function_code)
        return
    end

    escaped_function_body = function_body:gsub("([^%w])", "%%%1")
    escaped_modified_function_code = modified_function_code:gsub("([^%w])", "%%%1")
    current_game_code[path] = current_game_code[path]:gsub(escaped_function_body, escaped_modified_function_code)

    local new_function, load_error = load(modified_function_code)
    if not new_function then
        logger:error("Error loading modified function ", function_name, " with tail injection: ", (load_error or "Unknown error"))
        logger:error(modified_function_code)
        return
    end

    if setfenv then
        setfenv(new_function, getfenv(original_testFunction))
    end

    local status, result = pcall(new_function)
    if status then
        testFunction = result
    else
        logger:error("Error executing modified function ", function_name, " with tail injection: ", result)
        logger:error(modified_function_code)
    end
end

-- apis will be loaded first, then mods

local apis_files = love.filesystem.getDirectoryItems("apis") -- Load all apis
for _, file in ipairs(apis_files) do
	if file:sub(-4) == ".lua" then -- Only load lua files
		local apiPath = "apis/" .. file
		local apiContent, loadErr = love.filesystem.load(apiPath) -- Load the file

		if apiContent then -- Check if the file was loaded successfully
			local success, api = pcall(apiContent)
			if success then -- Check if the file was executed successfully
				table.insert(mods, api) -- Add the api to the list of mods if there is a mod in the file
			else
				logger:error("Error loading api: " .. apiPath) -- Log the error to the console Todo: Log to file
                logger:error(api)
			end
		else
			logger:error("Error reading api: " .. apiPath) -- Log the error to the console Todo: Log to file
            logger:error(loadErr)
		end
	end
end

local files = love.filesystem.getDirectoryItems("mods") -- Load all mods
for _, file in ipairs(files) do
	if file:sub(-4) == ".lua" then -- Only load lua files
		local modPath = "mods/" .. file
		local modContent, loadErr = love.filesystem.load(modPath) -- Load the file

		if modContent then  -- Check if the file was loaded successfully
			local success, mod = pcall(modContent) -- Execute the file
			if success then
				table.insert(mods, mod) -- Add the mod to the list of mods
			else
				logger:error("Error loading mod: " .. modPath) -- Log the error to the console Todo: Log to file
                logger:error(mod)
			end
		else
			logger:error("Error reading mod: " .. modPath) -- Log the error to the console Todo: Log to file
            logger:error(loadErr)
		end
	end
end

for _, mod in ipairs(mods) do
	if mod.enabled and mod.on_pre_load and type(mod.on_pre_load) == "function" then
		pcall(mod.on_pre_load) -- Call the on_pre_load function of the mod if it exists
	end
end

repoMods = {}

function getModByModId(tables, mod_id)
    if not mod_id then
        logger:error('Mod id is nil')
        return nil
    end
    for _, mod in ipairs(tables) do
        if mod.mod_id and mod.mod_id == mod_id then
            return mod
        end
    end
    logger:error('Mod ' .. mod_id .. ' not found')
    return nil
end

function isModPresent(modId)
    if not modId then
        logger:error('Mod id is nil')
        return false
    end
    if getModByModId(mods, modId) then
        return true
    else
        return false
    end
end

function installMod(modId)
    if not modId then
        logger:error('Mod id is nil')
        return RESULT.MOD_NOT_FOUND_IN_REPOS
    end

    local modInfo = getModByModId(repoMods, modId)
    if modInfo == nil then
        logger:error('Mod ' .. modId .. ' not found in repos')
        return RESULT.MOD_NOT_FOUND_IN_REPOS
    end

    local isModPresent = isModPresent(modId)
    if isModPresent then
        logger:debug('Mod ' .. modId .. ' is already present')
        local modVersion = modInfo.version
        local skipUpdate = false
        for _, mod in ipairs(mods) do
            if mod.mod_id == modId then
                if mod.version then
                    if mod.version == modVersion then
                        logger:debug('Mod ' .. modId .. ' is up to date')
                        skipUpdate = true
                        break
                    else
                        logger:info('Mod ' .. modId .. ' is outdated')
                        logger:info('Updating mod ' .. modId)
                    end
                else
                    logger:debug('Mod ' .. modId .. ' is up to date')
                    skipUpdate = true
                    break
                end
            end
        end
        if skipUpdate then
            return RESULT.SUCCESS
        end

        -- remove old mod
        for i, mod in ipairs(mods) do
            if mod.mod_id == modId then
                if mod.on_disable then
                    mod.on_disable()
                end

                table.remove(mods, i)
                break
            end
        end
    end

    logger:debug('Downloading mod ' .. modId)
    local modUrl = modInfo.url

    local owner, repo, branch, path = modUrl:match("https://github%.com/([^/]+)/([^/]+)/tree/([^/]+)/?(.*)")

    if not owner or not repo or not branch then
        owner, repo, branch, path = modUrl:match("https://github%.com/([^/]+)/([^/]+)/blob/([^/]+)/?(.*)")
    end

    logger:debug('Url: ' .. modUrl)
    logger:debug('Owner: ' .. (owner or 'nil'))
    logger:debug('Repo: ' .. (repo or 'nil'))
    logger:debug('Branch: ' .. (branch or 'nil'))
    logger:debug('Path: ' .. (path or 'nil'))

    while path:sub(-1) == '/' do
        path = path:sub(1, -2)
    end

    local url = 'https://api.github.com/repos/' .. owner .. '/' .. repo .. '/git/trees/' .. branch .. '?recursive=1'
    local code, body = request(url)
    if code ~= 200 then
        logger:error('Request failed')
        logger:error('Code: ' .. code)
        logger:error('Response: ' .. body)
        return RESULT.NETWORK_ERROR
    end

    logger:debug('Files to download:')

    local paths = {}

    for p, type in body:gmatch('"path":"(.-)".-"type":"(.-)"') do
        if type == 'blob' then
            if p:sub(1, #path) == path then
                table.insert(paths, p)
            end
        end
    end

    for _, p in ipairs(paths) do
        logger:trace(p)
    end

    for _, p in ipairs(paths) do
        code, body = request(
                         'https://raw.githubusercontent.com/' .. owner .. '/' .. repo .. '/' .. branch .. '/' .. p)
        if code ~= 200 then
            logger:error('Request failed')
            logger:error('Code: ' .. code)
            logger:error('Response: ' .. body)
            return RESULT.NETWORK_ERROR
        end
        logger:debug('Downloaded ' .. p)
        local filePath = p:sub(#path + 2)
        logger:debug('Writing to ' .. filePath)
        local dir = filePath:match('(.+)/[^/]+')
		if dir ~= nil then
			love.filesystem.createDirectory(dir)
			--[[if not love.filesystem.getInfo(filePath) then
				love.filesystem.write(filePath, body)
			else
				logger:warn("File " .. filePath .. " already exists")
			end]] --
			love.filesystem.write(filePath, body)
		else
            logger:warn("File " .. filePath .. " is in the root directory and will not be installed")
        end
    end

    -- apis first
    for _, p in ipairs(paths) do
        if p:match('apis/.*%.lua') then
            logger:info('Loading ' .. p:sub(#path + 2))

            local modContent, loadErr = love.filesystem.load(p:sub(#path + 2))

            if modContent then
                local success, mod = pcall(modContent)
                if success then
                    logger:info('API ' .. p:sub(#path + 2) .. ' loaded')
                else
                    logger:error('Error loading api: ' .. p:sub(#path + 2))
                    logger:error(mod)
                    return RESULT.MOD_PCALL_ERROR
                end
            else
                logger:error('Error reading api: ' .. p:sub(#path + 2))
                logger:error(loadErr)
                return RESULT.MOD_FS_LOAD_ERROR
            end
        end
    end

    -- mods second
    for _, p in ipairs(paths) do
        if p:match('mods/.*%.lua') then
            logger:info('Loading ' .. p:sub(#path + 2))

            local modContent, loadErr = love.filesystem.load(p:sub(#path + 2))

            if modContent then
                local success, mod = pcall(modContent)
                if success then
                    table.insert(mods, mod)
                    logger:info('Mod ' .. p:sub(#path + 2) .. ' loaded')
                else
                    logger:error('Error loading mod: ' .. p:sub(#path + 2))
                    logger:error(mod)
                    return RESULT.MOD_PCALL_ERROR
                end
            else
                logger:error('Error reading mod: ' .. p:sub(#path + 2))
                logger:error(loadErr)
                return RESULT.MOD_FS_LOAD_ERROR
            end
        end
    end

    return RESULT.SUCCESS
end

function refreshRepos()
    local reposIndex = 'https://raw.githubusercontent.com/UwUDev/balamod/master/repos.index'
    local code, body = request(reposIndex)

    if code ~= 200 then
        logger:error('Request failed')
        logger:error('Code: ' .. code)
        logger:error('Response: ' .. body)
        return RESULT.NETWORK_ERROR
    end

    for repoUrl in string.gmatch(body, '([^\n]+)') do
        logger:debug('Refreshing ' .. repoUrl)
        if refreshRepo(repoUrl) ~= RESULT.SUCCESS then
            return RESULT.NETWORK_ERROR
        end
        logger:debug('Refreshed ' .. repoUrl)
    end
    return RESULT.SUCCESS
end

function refreshRepo(url)
    local code, body = request(url)

    if code ~= 200 then
        logger:error('Request failed')
        logger:error('Code: ' .. code)
        logger:error('Response: ' .. body)
        return RESULT.NETWORK_ERROR
    end

    -- clear repoMods
    repoMods = {}
    for modInfo in string.gmatch(body, '([^\n]+)') do
        local modId, modVersion, modName, modDesc, modUrl = string.match(modInfo,
                                                                         '([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)')
        table.insert(repoMods, {
            mod_id = modId,
            name = modName,
            description = modDesc,
            url = modUrl,
            version = modVersion
        })
    end

    logger:debug('Mods available:')
    for i, modInfo in pairs(repoMods) do
        local modId = modInfo.mod_id
        local isModPresent = isModPresent(modId)
        logger:debug(modId .. ' - ' .. modInfo.name .. ' - ' .. modInfo.version .. ' - ' .. modInfo.description .. ' - ' .. tostring(isModPresent))
    end
    return RESULT.SUCCESS
end

saveLogs()
