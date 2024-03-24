local logging = require('logging')
local platform = require('platform')
local math = require('math')
local console = require('console')
local json = require('json')
local utils = require('utils')

logger = logging.getLogger('balamod')
mods = {}
local apis = {
    logging = logging,
    console = console,
    math = math,
    platform = platform,
}
is_loaded = false
local RESULT = {
    SUCCESS = 0,
    MOD_NOT_FOUND_IN_REPOS = 1,
    MOD_NOT_FOUND_IN_MODS = 2,
    MOD_ALREADY_PRESENT = 3,
    NETWORK_ERROR = 4,
    MOD_FS_LOAD_ERROR = 5,
    MOD_PCALL_ERROR = 6,
}
local paths = {} -- Paths to the files that will be loaded
local _VERSION = require('balamod_version')

local function splitstring(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
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

local function request(url)
    logger:debug('Request made with url: ', url)
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

local function extractFunctionBody(path, function_name)
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

local function inject(path, function_name, to_replace, replacement)
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

local function injectHead(path, function_name, code)
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

local function injectTail(path, function_name, code)
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

local function isModPresent(modId)
    if not modId then
        logger:error('Mod id is nil')
        return false
    end
    return mods[modId] ~= nil
end

local function installMod(modInfo)
    if modInfo == nil then
        logger:error('modInfo is nil')
        return RESULT.MOD_NOT_FOUND_IN_REPOS
    end
    local modId = modInfo.id
    if modInfo.present then
        logger:debug('Mod ' .. modInfo.id .. ' is already present')
        local modVersion = modInfo.newVersion
        if not modInfo.needUpdate then
            return RESULT.SUCCESS
        end

        -- remove old mod
        for i, mod in ipairs(mods) do
            if mod.id == modId then
                if mod.on_disable then
                    mod.on_disable()
                end

                table.remove(mods, i)
                break
            end
        end
    end

    logger:debug('Downloading mod ' .. modInfo.id)
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
        code, body = request('https://raw.githubusercontent.com/'..owner..'/'..repo..'/'..branch..'/'..p)
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

local function parseVersion(version)
    local major, minor, patch = string.match(version, '(%d+)%.(%d+)%.(%d+)')
    return {
        major = tonumber(major),
        minor = tonumber(minor),
        patch = tonumber(patch)
    }
end

local function v2GreaterThanV1(v1, v2)
    if v2.major > v1.major then
        return true
    end
    if v2.major == v1.major then
        if v2.minor > v1.minor then
            return true
        end
        if v2.minor == v1.minor then
            if v2.patch > v1.patch then
                return true
            end
        end
    end
    return false
end

local function getRepoMods()
    local repoMods = {}
    local reposIndex = 'https://raw.githubusercontent.com/UwUDev/balamod/master/repos.index'
    logger:info('Requesting ', reposIndex)
    local indexCode, indexBody = request(reposIndex)
    if indexCode ~= 200 then
        logger:error('Request failed')
        logger:error('Code: ', indexCode)
        logger:error('Response: ', indexBody)
        return repoMods
    end

    for repoUrl in string.gmatch(indexBody, '([^\n]+)') do
        local repoCode, repoBody = request(repoUrl)

        if repoCode ~= 200 then
            logger:error('Request failed')
            logger:error('Code: ' .. repoCode)
            logger:error('Response: ' .. repoBody)
        else
            for modInfo in string.gmatch(repoBody, '([^\n]+)') do
                local modId, modVersion, modName, modDesc, modUrl = string.match(
                    modInfo,
                    '([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)'
                )
                local modPresent = isModPresent(modId)
                local needUpdate = true
                local version = modVersion
                if modPresent then
                    local repoVersion = parseVersion(modVersion)
                    local mod = mods[modId]
                    if mod.version then
                        version = mod.version
                        local modVersion = parseVersion(mod.version)
                        needUpdate = v2GreaterThanV1(modVersion, repoVersion)
                    end
                end
                table.insert(repoMods, {
                    id = modId,
                    name = modName,
                    description = modDesc,
                    url = modUrl,
                    version = version,
                    newVersion = modVersion,
                    present = modPresent,
                    needUpdate = needUpdate,
                })
            end
        end
    end
    return repoMods
end

local function validateManifest(modFolder, manifest)
    local expectedFields = {
        id = true,
        name = true,
        version = true,
        description = true,
        author = true,
        load_before = true,
        load_after = true,
        min_balamod_version = false,
        max_balamod_version = false,
    }

    -- check that all manifest expected fields are present
    for field, required in pairs(expectedFields) do
        if manifest[field] == nil and required then
            logger:error('Manifest in folder ', modFolder, ' is missing field: ', field)
            return false
        end
    end
    -- check that none of the manifest fields are not in the expected fields
    for key, _ in pairs(manifest) do
        if expectedFields[key] == nil then
            logger:error('Manifest in folder ', modFolder, ' contains unexpected field: ', key)
            return false
        end
    end

    -- check that the load_before, load_after and description fields are arrays
    if type(manifest.load_before) ~= 'table' then
        logger:error('Manifest in folder ', modFolder, ' has a non-array load_before field')
        return false
    end
    if type(manifest.load_after) ~= 'table' then
        logger:error('Manifest in folder ', modFolder, ' has a non-array load_after field')
        return false
    end
    if type(manifest.description) ~= 'table' then
        logger:error('Manifest in folder ', modFolder, ' has a non-array description field')
        return false
    end

    -- check that the load_before and load_after fields are strings
    for _, modId in ipairs(manifest.load_before) do
        if type(modId) ~= 'string' then
            logger:error('Manifest in folder ', modFolder, ' has a non-string load_before field')
            return false
        end
    end
    for _, modId in ipairs(manifest.load_after) do
        if type(modId) ~= 'string' then
            logger:error('Manifest in folder ', modFolder, ' has a non-string load_after field')
            return false
        end
    end

    -- check that the version field is a string, matching semantic versioning
    if not manifest.version:match('%d+%.%d+%.%d+') then
        logger:error('Manifest in folder ', modFolder, ' has a non-semantic versioning version field')
        return false
    end

    -- check that the author field is a string
    if type(manifest.author) ~= 'string' then
        logger:error('Manifest in folder ', modFolder, ' has a non-string author field')
        return false
    end

    -- check that the id field is a string
    if type(manifest.id) ~= 'string' then
        logger:error('Manifest in folder ', modFolder, ' has a non-string id field')
        return false
    end

    -- check that the name field is a string
    if type(manifest.name) ~= 'string' then
        logger:error('Manifest in folder ', modFolder, ' has a non-string name field')
        return false
    end

    return true
end

local function loadMod(modFolder)
    local mod = {}
    logger:debug('Trying to load mod from: ', modFolder)
    if not love.filesystem.getInfo('mods/' .. modFolder, 'directory') then
        logger:error('Mod folder ', modFolder, ' does not exist')
        return nil
    end
    if not love.filesystem.getInfo('mods/' .. modFolder .. '/main.lua', 'file') then
        logger:error('Mod folder ', modFolder, ' does not contain a main.lua file')
        return nil
    end
    if not love.filesystem.getInfo('mods/' .. modFolder .. '/manifest.json', 'file') then
        logger:error('Mod folder ', modFolder, ' does not contain a manifest.json file')
        return nil
    end
    logger:debug("Loading manifest from: ", 'mods/'..modFolder..'/manifest.json')
    -- load the manifest
    local manifest = json.decode(love.filesystem.read('mods/'..modFolder..'/manifest.json'))
    if not validateManifest(modFolder, manifest) then
        return nil
    end
    logger:debug('Manifest loaded: ', manifest)
    -- check that the mod is compatible with the current version of balamod
    if manifest.min_balamod_version then
        local minVersion = parseVersion(manifest.min_balamod_version)
        if not v2GreaterThanV1(minVersion, _VERSION) then
            logger:error('Mod ', modFolder, ' requires a newer version of balamod')
            return nil
        end
    end
    if manifest.max_balamod_version then
        local maxVersion = parseVersion(manifest.max_balamod_version)
        if v2GreaterThanV1(maxVersion, _VERSION) then
            logger:error('Mod ', modFolder, ' requires an older version of balamod')
            return nil
        end
    end
    -- load the hooks (on_enable, on_game_load, etc...)
    logger:debug("Loading hooks from: ", 'mods/'..modFolder..'/main.lua')
    local modHooks = require('mods/'..modFolder..'/main')
    for hookName, hook in pairs(modHooks) do
        mod[hookName] = hook
    end
    for key, value in pairs(manifest) do
        mod[key] = value
    end
    mod.enabled = true
    logger:debug('Mod loaded: ', mod.id)
    logger:debug("Checking if mod is disabled")
    if love.filesystem.getInfo('mods/' .. modFolder .. '/disable.it', 'file') then
        mod.enabled = false
    end
    logger:debug('Mod enabled: ', mod.enabled)
    if mod.enabled then
        if mod.on_enable and type(mod.on_enable) == 'function' then
            pcall(mod.on_enable)
        end
    end
    return mod
end

local function toggleMod(mod)
    logger:debug('Toggling mod: ' .. mod.id)
    mod.enabled = not mod.enabled
    if mod.enabled and mod.on_enable and type(mod.on_enable) == 'function' then
        if love.filesystem.getInfo('mods/' .. mod.id .. '/disable.it', 'file') then
            love.filesystem.remove('mods/' .. mod.id .. '/disable.it')
        end
        pcall(mod.on_enable)
    elseif not mod.enabled and mod.on_disable and type(mod.on_disable) == 'function' then
        love.filesystem.write('mods/' .. mod.id .. '/disable.it', '')
        pcall(mod.on_disable)
    end
    mods[mod.id] = mod
end

buildPaths("",{"mods","apis","resources","localization"})
-- current_game_code = love.filesystem.read(path)
buildPaths = nil -- prevent rerunning (i think)

current_game_code = {}
for _, path in ipairs(paths) do
    current_game_code[path] = love.filesystem.read(path)
end

if not love.filesystem.getInfo("mods", "directory") then -- Create mods folder if it doesn't exist
    love.filesystem.createDirectory("mods")
end

if not love.filesystem.getInfo("logs", "directory") then -- Create logs folder if it doesn't exist
    love.filesystem.createDirectory("logs")
end

if not love.filesystem.getInfo("apis", "directory") then -- Create apis folder if it doesn't exist
    love.filesystem.createDirectory("apis")
end

-- apis will be loaded first, then mods

table.insert(mods,
    {
        id = "dev_console",
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
            logging.saveLogs()
        end,
        on_game_quit = function()
            console.logger:info("Quitting Balatro...")
            logging.saveLogs()
        end,
        on_error = function(message)
            console.logger:error("Error: ", message)
            -- on error, write all messages to a file
            logging.saveLogs()
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

            console.logger:debug("Registering commands")
            console:registerCommand(
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

            console:registerCommand(
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

            console:registerCommand(
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

            console.logger:debug("Registering command: clear")
            console:registerCommand(
                "clear",
                function()
                    logging.clearLogs()
                    return true
                end,
                "Clear the console"
            )

            console:registerCommand(
                "exit",
                function()
                    console:toggle()
                    return true
                end,
                "Close the console"
            )

            console:registerCommand(
                "give",
                function()
                    console.logger:error("Give command not implemented yet")
                    return false
                end,
                "Give an item to the player"
            )

            console:registerCommand(
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

            console:registerCommand(
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

            console:registerCommand(
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

            console:registerCommand(
                "luamod",
                function(args)
                    if args[1] then
                        local modId = args[1]
                        if isModPresent(modId) then
                            local mod = mods[modId]
                            mod = loadMod(modId)
                            mods[modId] = mod
                            console.logger:info("Reloaded mod: " .. modId)
                        else
                            console.logger:error("Mod not found: " .. modId)
                            return false
                        end
                    else
                        console.logger:error("Usage: luamod <mod_id>")
                        return false
                    end
                    return true
                end,
                "Reload a mod using its id",
                function (current_arg)
                    local completions = {}
                    for modId, _ in pairs(mods) do
                        if modId:find(current_arg, 1, true) == 1 then
                            table.insert(completions, modId)
                        end
                    end
                    return completions
                end,
                "Usage: luamod <mod_id>"
            )

            console:registerCommand(
                "sandbox",
                function (args)
                    G:sandbox()
                end,
                "Goes to the sandbox stage",
                function (current_arg)
                    return nil
                end,
                "Usage: sandbox"
            )

            console.logger:debug("Dev Console on_enable completed")
        end,
        on_disable = function()
            console.removeCommand("help")
            console.removeCommand("shortcuts")
            console.removeCommand("history")
            console.removeCommand("clear")
            console.removeCommand("exit")
            console.removeCommand("quit")
            console.removeCommand("give")
            console.removeCommand("money")
            console.removeCommand("discards")
            console.removeCommand("hands")
            console.logger:debug("Dev Console disabled")
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

return {
    logger = logger,
    mods = mods,
    apis = apis,
    installMod = installMod,
    isModPresent = isModPresent,
    getRepoMods = getRepoMods,
    RESULT = RESULT,
    inject = inject,
    injectHead = injectHead,
    injectTail = injectTail,
    is_loaded = is_loaded,
    _VERSION = _VERSION,
    console = console,
    loadMod = loadMod,
    toggleMod = toggleMod,
}
