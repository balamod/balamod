mods = {}

balamodLoaded = false

if not love.filesystem.getInfo("mods", "directory") then -- Create mods folder if it doesn't exist
    love.filesystem.createDirectory("mods")
end

if not love.filesystem.getInfo("apis", "directory") then -- Create apis folder if it doesn't exist
    love.filesystem.createDirectory("apis")
end

paths = {
{paths}
} -- Paths to the files that will be loaded
-- current_game_code = love.filesystem.read(path)
current_game_code = {}
for i, path in ipairs(paths) do
    current_game_code[path] = love.filesystem.read(path)
end

function excractFunctionBody(path, function_name)
    local pattern = "\n?%s*function%s+" .. function_name
    local func_begin, fin = current_game_code[path]:find(pattern)

    if not func_begin then
        return "C'ant find function begin " .. function_name
    end

    local func_end = current_game_code[path]:find("\n\r?end", fin)
    if not func_end then
        return "Can't find function end " .. function_name
    end

    local func_body = current_game_code[path]:sub(func_begin, func_end + 3)
    return func_body
end

function inject(path, function_name, to_replace, replacement)
    -- Injects code into a function (replaces a string with another string inside a function)
    local function_body = excractFunctionBody(path, function_name)
    local modified_function_code = function_body:gsub(to_replace, replacement)
    escaped_function_body = function_body:gsub("([^%w])", "%%%1") -- escape function body for use in gsub
    current_game_code[path] = current_game_code[path]:gsub(escaped_function_body, modified_function_code) -- update current game code in memory

    local new_function, load_error = load(modified_function_code) -- load modified function
    if not new_function then
        -- Safeguard against errors, will be logged in %appdata%/Balatro/err1.txt
        love.filesystem.write("err1.txt", "Error loading modified function: " .. (load_error or "Unknown error"))
    end

    if setfenv then
        setfenv(new_function, getfenv(original_testFunction))
    end -- Set the environment of the new function to the same as the original function

    local status, result = pcall(new_function) -- Execute the new function
    if status then
        testFunction = result -- Overwrite the original function with the result of the new function
    else
        love.filesystem.write("err2.txt", "Error executing modified function: " .. result) -- Safeguard against errors, will be logged in %appdata%/Balatro/err2.txt
    end
end

function injectHead(path, function_name, code)
    local function_body = excractFunctionBody(path, function_name)

    local pattern = "(function.-)\n"
    local modified_function_code, number_of_subs = function_body:gsub(pattern, "%1\n" .. code .. "\n")

    if number_of_subs == 0 then
        love.filesystem.write("err4.txt", "Error: Function start not found in function body or multiple matches encountered.")
        return
    end

    escaped_function_body = function_body:gsub("([^%w])", "%%%1")
    current_game_code[path] = current_game_code[path]:gsub(escaped_function_body, modified_function_code)

    local new_function, load_error = load(modified_function_code)
    if not new_function then
        love.filesystem.write("err1.txt", "Error loading modified function with head injection: " .. (load_error or "Unknown error"))
        return
    end

    if setfenv then
        setfenv(new_function, getfenv(original_testFunction))
    end

    local status, result = pcall(new_function)
    if status then
        testFunction = result
    else
        love.filesystem.write("err2.txt", "Error executing modified function with head injection: " .. result)
    end
end

function injectTail(path, function_name, code)
    local function_body = excractFunctionBody(path, function_name)

    local pattern = "(.-)(end[ \t]*\n?)$"
    local modified_function_code, number_of_subs = function_body:gsub(pattern, "%1" .. code .. "%2")

    if number_of_subs == 0 then
        love.filesystem.write("err3.txt", "Error: 'end' not found in function body or multiple ends encountered.")
        return
    end

    escaped_function_body = function_body:gsub("([^%w])", "%%%1")
    current_game_code[path] = current_game_code[path]:gsub(escaped_function_body, modified_function_code)

    local new_function, load_error = load(modified_function_code)
    if not new_function then
        love.filesystem.write("err1.txt", "Error loading modified function with tail injection: " .. (load_error or "Unknown error"))
        return
    end

    if setfenv then
        setfenv(new_function, getfenv(original_testFunction))
    end

    local status, result = pcall(new_function)
    if status then
        testFunction = result
    else
        love.filesystem.write("err2.txt", "Error executing modified function with tail injection: " .. result)
    end
end

-- apis will be loaded first, then mods

local apis_files = love.filesystem.getDirectoryItems("apis") -- Load all apis
for _, file in ipairs(apis_files) do
	if file:sub(-4) == ".lua" then -- Only load lua files
		local modPath = "apis/" .. file
		local modContent, loadErr = love.filesystem.load(modPath) -- Load the file

		if modContent then -- Check if the file was loaded successfully
			local success, mod = pcall(modContent)
			if success then -- Check if the file was executed successfully
				table.insert(mods, mod) -- Add the api to the list of mods if there is a mod in the file
			else
				print("Error loading api: " .. modPath .. "\n" .. mod) -- Log the error to the console Todo: Log to file
			end
		else
			print("Error reading api: " .. modPath .. "\n" .. loadErr) -- Log the error to the console Todo: Log to file
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
				print("Error loading mod: " .. modPath .. "\n" .. mod) -- Log the error to the console Todo: Log to file
			end
		else
			print("Error reading mod: " .. modPath .. "\n" .. loadErr) -- Log the error to the console Todo: Log to file
		end
	end
end

for _, mod in ipairs(mods) do
	if mod.enabled and mod.on_pre_load and type(mod.on_pre_load) == "function" then
		pcall(mod.on_pre_load) -- Call the on_pre_load function of the mod if it exists
	end
end

repoMods = {}

function isModPresent(modId)
    for _, mod in ipairs(mods) do
        if mod.mod_id == modId then
            return true
        end
    end
    return false
end

function installMod(modId)
    modInfo = repoMods[modId]
    if modInfo == nil then
        sendDebugMessage("Mod " .. modId .. " not found in repos")
        return
    end

    local isModPresent = isModPresent(modId)
    if isModPresent then
        sendDebugMessage("Mod " .. modId .. " is already present")
        local modVersion = modInfo.version
        local skipUpdate = false
        for _, mod in ipairs(mods) do
            if mod.mod_id == modId then
                if mod.version then
                    if mod.version == modVersion then
                        sendDebugMessage("Mod " .. modId .. " is up to date")
                        skipUpdate = true
                        break
                    else
                        sendDebugMessage("Mod " .. modId .. " is outdated")
                        sendDebugMessage("Updating mod " .. modId)
                    end
                else
                    sendDebugMessage("Mod " .. modId .. " is up to date")
                    skipUpdate = true
                    break
                end
            end
        end
        if skipUpdate then
            return
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

    sendDebugMessage("Downloading mod " .. modId)
    local modUrl = modInfo.url

    local owner, repo, branch, path = modUrl:match("https://github%.com/([^/]+)/([^/]+)/tree/([^/]+)/(.*)")

    while path:sub(-1) == "/" do
        path = path:sub(1, -2)
    end

    sendDebugMessage("Owner: " .. owner)
    sendDebugMessage("Repo: " .. repo)
    sendDebugMessage("Branch: " .. branch)
    sendDebugMessage("Path: " .. path)

    local https = require "https"
    local code, body = https.request("https://api.github.com/repos/" .. owner .. "/" .. repo .. "/git/trees/" .. branch .. "?recursive=1")
    if code ~= 200 then
        sendDebugMessage("Request failed")
        sendDebugMessage("Code: " .. code)
        sendDebugMessage("Response: " .. body)
        return
    end

    sendDebugMessage("Files to download:")

    local paths = {}

    for p, type in body:gmatch('"path":"(.-)".-"type":"(.-)"') do
        if type == "blob" then
            if p:sub(1, #path) == path then
                table.insert(paths, p)
            end
        end
    end

    for _, p in ipairs(paths) do
        sendDebugMessage(p)
    end

    for _, p in ipairs(paths) do
        local code, body = https.request("https://raw.githubusercontent.com/" .. owner .. "/" .. repo .. "/" .. branch .. "/" .. p)
        if code ~= 200 then
            sendDebugMessage("Request failed")
            sendDebugMessage("Code: " .. code)
            sendDebugMessage("Response: " .. body)
            return
        end
        sendDebugMessage("Downloaded " .. p)
        local filePath = p:sub(#path + 2)
        sendDebugMessage("Writing to " .. filePath)
        local dir = filePath:match("(.+)/[^/]+")
        love.filesystem.createDirectory(dir)
        --[[if not love.filesystem.getInfo(filePath) then
            love.filesystem.write(filePath, body)
        else
            sendDebugMessage("File " .. filePath .. " already exists")
        end]]--
        love.filesystem.write(filePath, body)
    end

    -- apis first
    for _, p in ipairs(paths) do
        if p:match("apis/.*%.lua") then
            sendDebugMessage("Loading " .. p:sub(#path + 2))

            local modContent, loadErr = love.filesystem.load(p:sub(#path + 2))

            if modContent then
                local success, mod = pcall(modContent)
                if success then
                    sendDebugMessage("API " .. p:sub(#path + 2) .. " loaded")
                else
                    print("Error loading api: " .. p:sub(#path + 2) .. "\n" .. mod)
                end
            else
                print("Error reading api: " .. p:sub(#path + 2) .. "\n" .. loadErr)
            end
        end
    end

    -- mods second
    for _, p in ipairs(paths) do
        if p:match("mods/.*%.lua") then
            sendDebugMessage("Loading " .. p:sub(#path + 2))

            local modContent, loadErr = love.filesystem.load(p:sub(#path + 2))

            if modContent then
                local success, mod = pcall(modContent)
                if success then
                    table.insert(mods, mod)
                    sendDebugMessage("Mod " .. p:sub(#path + 2) .. " loaded")
                else
                    print("Error loading mod: " .. p:sub(#path + 2) .. "\n" .. mod)
                end
            else
                print("Error reading mod: " .. p:sub(#path + 2) .. "\n" .. loadErr)
            end
        end
    end
end

function refreshRepos()
    local reposIndex = "https://raw.githubusercontent.com/UwUDev/balamod/master/repos.index"
    local https = require "https"
    local code, body = https.request(reposIndex)

    if code ~= 200 then
        sendDebugMessage("Request failed")
        sendDebugMessage("Code: " .. code)
        sendDebugMessage("Response: " .. body)
        return
    end

    for repoUrl in string.gmatch(body, "([^\n]+)") do
        sendDebugMessage("Refreshing " .. repoUrl)
        refreshRepo(repoUrl)
        sendDebugMessage("Refreshed " .. repoUrl)
    end
end

function refreshRepo(url)
    local https = require "https"
    local code, body = https.request(url)


    if code ~= 200 then
        sendDebugMessage("Request failed")
        sendDebugMessage("Code: " .. code)
        sendDebugMessage("Response: " .. body)
        return
    end

    for modInfo in string.gmatch(body, "([^\n]+)") do
        local modId, modVersion, modName, modDesc, modUrl = string.match(modInfo, "([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)")
        repoMods[modId] = {name = modName, desc = modDesc, url = modUrl, version = modVersion}
    end

    sendDebugMessage("Mods available:")
    for modId, modInfo in pairs(repoMods) do
        local isModPresent = isModPresent(modId)
        sendDebugMessage(modId .. " - " .. modInfo.name .. " - " .. modInfo.desc .. " - " .. tostring(isModPresent))
    end
end

