mods = {}

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

if (sendDebugMessage == nil) then
    sendDebugMessage = function(_)
    end
end

if not rootDir then
    rootDir = love.filesystem.getSaveDirectory()
end

if not modsDir then
    modsDir = love.filesystem.getSaveDirectory() .. "/mods"
end

if not apiDir then
    apiDir = love.filesystem.getSaveDirectory() .. "/apis"
end

if not love.filesystem.getInfo(rootDir, "directory") then
    love.filesystem.createDirectory(rootDir)
end

if not love.filesystem.getInfo(modsDir, "directory") then
    love.filesystem.createDirectory("mods")
end

if not love.filesystem.getInfo(apiDir, "directory") then
    love.filesystem.createDirectory("apis")
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

function listFiles(directory)
    local i, t, popen = 0, {}, io.popen
    local pfile = popen('dir "'..directory..'" /b')
    for filename in pfile:lines() do
        i = i + 1
        t[i] = filename
    end
    pfile:close()
    return t
end

function fileToString(path)
    local file = io.open(path, "r")
    local content = file:read("*all")
    file:close()
    return content
end

function request(url)
    sendDebugMessage('Request made with url: ' .. url)
    local https = require 'https'
    local code
    local response
    if love.system.getOS() == 'OS X' then
        response, code = https.request(url)
    else
        code, response = https.request(url)
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
        local timeString = os.date("%Y-%m-%d %H:%M:%S")
        local errorFileName = "LoadError " .. timeString .. ".txt"

        sendDebugMessage(errorFileName .. " created because of an injectHead into " .. function_name .. "! Check the file for your error!");
        love.filesystem.write(errorFileName, "Error loading modified function: " .. (load_error or "Unknown error") .. "\n" .. modified_function_code)
    end

    if setfenv then
        setfenv(new_function, getfenv(original_testFunction))
    end -- Set the environment of the new function to the same as the original function

    local status, result = pcall(new_function) -- Execute the new function
    if status then
        testFunction = result -- Overwrite the original function with the result of the new function
    else
        local timeString = os.date("%Y-%m-%d %H:%M:%S")
        local errorFileName = "ExecutionError " .. timeString .. ".txt"
        sendDebugMessage(errorFileName .. " created because of an injectHead into " .. function_name .. "! Check the file for your error!");
        love.filesystem.write(errorFileName, "Error executing modified function: " .. result .. "\n" .. modified_function_code) -- Safeguard against errors
    end
end

function injectHead(path, function_name, code)
    local function_body = extractFunctionBody(path, function_name)

    local pattern = "(function%s+" .. function_name .. ".-)\n"
    local modified_function_code, number_of_subs = function_body:gsub(pattern, "%1\n" .. code .. "\n")

    if number_of_subs == 0 then
        local timeString = os.date("%Y-%m-%d %H:%M:%S")
        local errorFileName = "NoFunctionError " .. timeString .. ".txt"
        sendDebugMessage(errorFileName .. " created because of an injectHead into " .. function_name .. "! Check the file for your error!");
        love.filesystem.write(errorFileName "Error: Function start not found in function body or multiple matches encountered." .. "\n" .. modified_function_code)
        return
    end

    escaped_function_body = function_body:gsub("([^%w])", "%%%1")
    escaped_modified_function_code = modified_function_code:gsub("([^%w])", "%%%1")
    current_game_code[path] = current_game_code[path]:gsub(escaped_function_body, escaped_modified_function_code)

    local new_function, load_error = load(modified_function_code)
    if not new_function then
        local timeString = os.date("%Y-%m-%d %H:%M:%S")
        local errorFileName = "LoadError " .. timeString .. ".txt"
        sendDebugMessage(errorFileName .. " created because of an injectHead into " .. function_name .. "! Check the file for your error!");
        love.filesystem.write(errorFileName, "Error loading modified function with head injection: " .. (load_error or "Unknown error") .. "\n" .. modified_function_code)
        return
    end

    if setfenv then
        setfenv(new_function, getfenv(original_testFunction))
    end

    local status, result = pcall(new_function)
    if status then
        testFunction = result
    else
        local timeString = os.date("%Y-%m-%d %H:%M:%S")
        local errorFileName = "ExecutionError " .. timeString .. ".txt"
        sendDebugMessage(errorFileName .. " created because of an injectHead into " .. function_name .. "! Check the file for your error!");
        love.filesystem.write(errorFileName, "Error executing modified function with head injection: " .. result .. "\n" .. modified_function_code)
    end
end

function injectTail(path, function_name, code)
    local function_body = extractFunctionBody(path, function_name)

    local pattern = "(.-)(end[ \t]*\n?)$"
    local modified_function_code, number_of_subs = function_body:gsub(pattern, "%1" .. string.gsub(code, '(.-)%s*$', '%1') .. "\n" .. "%2")

    if number_of_subs == 0 then
        local timeString = os.date("%Y-%m-%d %H:%M:%S")
        local errorFileName = "NoFunctionError " .. timeString .. ".txt"
        sendDebugMessage(errorFileName .. " created because of an injectTail into " .. function_name .. "! Check the file for your error!");
        love.filesystem.write(errorFileName, "Error: 'end' not found in function body or multiple ends encountered." .. "\n" .. modified_function_code)
        return
    end

    escaped_function_body = function_body:gsub("([^%w])", "%%%1")
    escaped_modified_function_code = modified_function_code:gsub("([^%w])", "%%%1")
    current_game_code[path] = current_game_code[path]:gsub(escaped_function_body, escaped_modified_function_code)

    local new_function, load_error = load(modified_function_code)
    if not new_function then
        local timeString = os.date("%Y-%m-%d %H:%M:%S")
        local errorFileName = "LoadError " .. timeString .. ".txt"
        sendDebugMessage(errorFileName .. " created because of an injectTail into " .. function_name .. "! Check the file for your error!");
        love.filesystem.write(errorFileName, "Error loading modified function with tail injection: " .. (load_error or "Unknown error") .. "\n" .. modified_function_code)
        return
    end

    if setfenv then
        setfenv(new_function, getfenv(original_testFunction))
    end

    local status, result = pcall(new_function)
    if status then
        testFunction = result
    else
        local timeString = os.date("%Y-%m-%d %H:%M:%S")
        local errorFileName = "ExecutionError " .. timeString .. ".txt"
        sendDebugMessage(errorFileName .. " created because of an injectTail into " .. function_name .. "! Check the file for your error!");
        love.filesystem.write(errorFileName, "Error executing modified function with tail injection: " .. result .. "\n" .. modified_function_code)
    end
end

-- apis will be loaded first, then mods

local apis_files = listFiles(apiDir)
for _, file in ipairs(apis_files) do
    if file:sub(-4) == ".lua" then
        local apiPath = apiDir .. "/" .. file
        local modContent, loadErr = fileToString(apiPath)

        if modContent then
            local modFunction, err = load(modContent, "@"..apiPath, "t")
            if modFunction then
                local success, mod = pcall(modFunction)
                if success then
                    table.insert(mods, mod)
                else
                    sendDebugMessage("Error running api: " .. apiPath .. "\n" .. tostring(mod))
                end
            else
                sendDebugMessage("Error compiling api: " .. apiPath .. "\n" .. err)
            end
        else
            sendDebugMessage("Error reading api: " .. apiPath .. "\n" .. tostring(loadErr)) -- Log file read errors
        end
    end
end


local files = listFiles(modsDir)
for _, file in ipairs(files) do
    if file:sub(-4) == ".lua" then
        local modPath = modsDir .. "/" .. file
        local modContent, loadErr = fileToString(modPath)

        if modContent then
            local modFunction, err = load(modContent, "@"..modPath, "t")
            if modFunction then
                local success, mod = pcall(modFunction)
                if success then
                    table.insert(mods, mod)
                else
                    sendDebugMessage("Error running mod: " .. modPath .. "\n" .. tostring(mod))
                end
            else
                sendDebugMessage("Error compiling mod: " .. modPath .. "\n" .. err)
            end
        else
            sendDebugMessage("Error reading mod: " .. modPath .. "\n" .. tostring(loadErr))
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
    for _, mod in ipairs(tables) do
        if mod.mod_id and mod.mod_id == mod_id then
            return mod
        end
    end
    sendDebugMessage('Mod ' .. mod_id .. ' not found')
    return nil
end

function isModPresent(modId)
    if getModByModId(mods, modId) then
        return true
    else
        return false
    end
end

function installMod(modId)
    local modInfo = getModByModId(repoMods, modId)
    if modInfo == nil then
        sendDebugMessage('Mod ' .. modId .. ' not found in repos')
        return RESULT.MOD_NOT_FOUND_IN_REPOS
    end

    local isModPresent = isModPresent(modId)
    if isModPresent then
        sendDebugMessage('Mod ' .. modId .. ' is already present')
        local modVersion = modInfo.version
        local skipUpdate = false
        for _, mod in ipairs(mods) do
            if mod.mod_id == modId then
                if mod.version then
                    if mod.version == modVersion then
                        sendDebugMessage('Mod ' .. modId .. ' is up to date')
                        skipUpdate = true
                        break
                    else
                        sendDebugMessage('Mod ' .. modId .. ' is outdated')
                        sendDebugMessage('Updating mod ' .. modId)
                    end
                else
                    sendDebugMessage('Mod ' .. modId .. ' is up to date')
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

    sendDebugMessage('Downloading mod ' .. modId)
    local modUrl = modInfo.url

    local owner, repo, branch, path = modUrl:match("https://github%.com/([^/]+)/([^/]+)/tree/([^/]+)/?(.*)")

    if not owner or not repo or not branch then
        owner, repo, branch, path = modUrl:match("https://github%.com/([^/]+)/([^/]+)/blob/([^/]+)/?(.*)")
    end

    sendDebugMessage('Url: ' .. modUrl)
    sendDebugMessage('Owner: ' .. (owner or 'nil'))
    sendDebugMessage('Repo: ' .. (repo or 'nil'))
    sendDebugMessage('Branch: ' .. (branch or 'nil'))
    sendDebugMessage('Path: ' .. (path or 'nil'))

    while path:sub(-1) == '/' do
        path = path:sub(1, -2)
    end

    local url = 'https://api.github.com/repos/' .. owner .. '/' .. repo .. '/git/trees/' .. branch .. '?recursive=1'
    local code, body = request(url)
    if code ~= 200 then
        sendDebugMessage('Request failed')
        sendDebugMessage('Code: ' .. code)
        sendDebugMessage('Response: ' .. body)
        return RESULT.NETWORK_ERROR
    end

    sendDebugMessage('Files to download:')

    local paths = {}

    for p, type in body:gmatch('"path":"(.-)".-"type":"(.-)"') do
        if type == 'blob' then
            if p:sub(1, #path) == path then
                table.insert(paths, p)
            end
        end
    end

    for _, p in ipairs(paths) do
        sendDebugMessage(p)
    end

    for _, p in ipairs(paths) do
        code, body = request(
                         'https://raw.githubusercontent.com/' .. owner .. '/' .. repo .. '/' .. branch .. '/' .. p)
        if code ~= 200 then
            sendDebugMessage('Request failed')
            sendDebugMessage('Code: ' .. code)
            sendDebugMessage('Response: ' .. body)
            return RESULT.NETWORK_ERROR
        end
        sendDebugMessage('Downloaded ' .. p)
        local filePath = p:sub(#path + 2)
        sendDebugMessage('Writing to ' .. filePath)
        local dir = filePath:match('(.+)/[^/]+')
		if dir ~= nil then
			love.filesystem.createDirectory(dir)
			--[[if not love.filesystem.getInfo(filePath) then
				love.filesystem.write(filePath, body)
			else
				sendDebugMessage("File " .. filePath .. " already exists")
			end]] --
			love.filesystem.write(filePath, body)
		else
            sendDebugMessage("File " .. filePath .. " is in the root directory and will not be installed")
        end
    end

    -- apis first
    for _, p in ipairs(paths) do
        if p:match('apis/.*%.lua') then
            sendDebugMessage('Loading ' .. p:sub(#path + 2))

            local modContent, loadErr = love.filesystem.load(p:sub(#path + 2))

            if modContent then
                local success, mod = pcall(modContent)
                if success then
                    sendDebugMessage('API ' .. p:sub(#path + 2) .. ' loaded')
                else
                    sendDebugMessage('Error loading api: ' .. p:sub(#path + 2) .. '\n' .. mod)
                    return RESULT.MOD_PCALL_ERROR
                end
            else
                sendDebugMessage('Error reading api: ' .. p:sub(#path + 2) .. '\n' .. loadErr)
                return RESULT.MOD_FS_LOAD_ERROR
            end
        end
    end

    -- mods second
    for _, p in ipairs(paths) do
        if p:match('mods/.*%.lua') then
            sendDebugMessage('Loading ' .. p:sub(#path + 2))

            local modContent, loadErr = love.filesystem.load(p:sub(#path + 2))

            if modContent then
                local success, mod = pcall(modContent)
                if success then
                    table.insert(mods, mod)
                    sendDebugMessage('Mod ' .. p:sub(#path + 2) .. ' loaded')
                else
                    sendDebugMessage('Error loading mod: ' .. p:sub(#path + 2) .. '\n' .. mod)
                    return RESULT.MOD_PCALL_ERROR
                end
            else
                sendDebugMessage('Error reading mod: ' .. p:sub(#path + 2) .. '\n' .. loadErr)
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
        sendDebugMessage('Request failed')
        sendDebugMessage('Code: ' .. code)
        sendDebugMessage('Response: ' .. body)
        return RESULT.NETWORK_ERROR
    end

    for repoUrl in string.gmatch(body, '([^\n]+)') do
        sendDebugMessage('Refreshing ' .. repoUrl)
        if refreshRepo(repoUrl) ~= RESULT.SUCCESS then
            return RESULT.NETWORK_ERROR
        end
        sendDebugMessage('Refreshed ' .. repoUrl)
    end
    return RESULT.SUCCESS
end

function refreshRepo(url)
    local code, body = request(url)

    if code ~= 200 then
        sendDebugMessage('Request failed')
        sendDebugMessage('Code: ' .. code)
        sendDebugMessage('Response: ' .. body)
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

    sendDebugMessage('Mods available:')
    for i, modInfo in pairs(repoMods) do
        local modId = modInfo.mod_id
        local isModPresent = isModPresent(modId)
        sendDebugMessage(modId .. ' - ' .. modInfo.name .. ' - ' .. modInfo.version .. ' - ' .. modInfo.description .. ' - ' .. tostring(isModPresent))
    end
    return RESULT.SUCCESS
end
