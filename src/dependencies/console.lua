local logging = require("logging")
local platform = require("platform")
local utf8 = require("utf8")
local math = require("math")

local logger = logging.getLogger("console")

return {
    logger = logger,
    log_level = "INFO",
    is_open = false,
    cmd = "> ",
    line_height = 20,
    max_lines = love.graphics.getHeight() / 20,
    start_line_offset = 1,
    history_index = 0,
    command_history = {},
    history_path = "dev_console.history",
    modifiers = {
        capslock = false,
        scrolllock = false,
        numlock = false,
        shift = false,
        ctrl = false,
        alt = false,
        meta = false,
    },
    commands = {},
    toggle = function(self)
        self.is_open = not self.is_open
        love.keyboard.setKeyRepeat(self.is_open)  -- set key repeat to true when console is open
        if self.is_open then
            self.start_line_offset = self.max_lines - 1
            local oldTextInput = love.textinput
            love.textinput = function(character)
                self.cmd = self.cmd .. character
            end
        else
            love.textinput = nil
        end
    end,
    longestCommonPrefix = function(self, strings)
        if #strings == 0 then
            return ""
        end
        local prefix = strings[1]
        for i = 2, #strings do
            local str = strings[i]
            local j = 1
            while j <= #prefix and j <= #str and prefix:sub(j, j) == str:sub(j, j) do
                j = j + 1
            end
            prefix = prefix:sub(1, j - 1)
        end
        return prefix
    end,
    tryAutocomplete = function(self)
        local command = self.cmd:sub(3) -- remove the "> " prefix
        local cmd = {}
        -- split command into parts
        for part in command:gmatch("%S+") do
            table.insert(cmd, part)
        end
        if #cmd == 0 then
            -- no command typed, do nothing (no completions possible)
            logger:trace("No command typed")
            return nil
        end
        local completions = {}
        if #cmd == 1 then
            -- only one part, try to autocomplete the command
            -- find all commands that start with the typed string, then complete the characters until the next character is not a match
            for name, _ in pairs(self.commands) do
                if name:find(cmd[1], 1, true) == 1 then -- name starts with cmd[1]
                    table.insert(completions, name)
                end
            end
        else
            -- more than one part, try to autocomplete the arguments
            local commandName = cmd[1]
            local command = self.commands[commandName]
            if command then
                completions = command.autocomplete(cmd[#cmd]) or {}
            end
        end
        logger:trace("Autocomplete matches: " .. #completions .. " " .. table.concat(completions, ", "))
        if #completions == 0 then
            -- no completions found
            return nil
        elseif #completions == 1 then
            return completions[1]
        else
            -- complete until the common prefix of all matches
            return self:longestCommonPrefix(completions)
        end
    end,
    getMessageColor = function (self, message)
        if message.level == "PRINT" then
            return 1, 1, 1
        end
        if message.level == "INFO" then
            return 0, 0.9, 1
        end
        if message.level == "WARN" then
            return 1, 0.5, 0
        end
        if message.level == "ERROR" then
            return 1, 0, 0
        end
        if message.level == "DEBUG" then
            return 0.16, 0, 1
        end
        if message.level == "TRACE" then
            return 1, 1, 1
        end
        return 1, 1, 1
    end,
    getFilteredMessages = function(self)
        local filtered = {}
        for _, message in ipairs(logging.getAllMessages()) do
            if message.level_numeric >= self.logger.log_levels[self.log_level] then
                table.insert(filtered, message)
            end
        end
        return filtered
    end,
    getMessagesToDisplay = function(self)
        local text = {}
        local i = 1
        local textLength = 0
        local all_messages = self:getFilteredMessages()
        while textLength < self.max_lines do
            local index = #all_messages - i + self.start_line_offset
            if index < 1 then
                break
            end
            local message = all_messages[index]
            if message then
                table.insert(text, message)
                textLength = textLength + 1
            end
            i = i + 1
        end
        -- define locally to not pollute the global namespace scope
        local function reverse(tab)
            for i = 1, math.floor(#tab/2), 1 do
                tab[i], tab[#tab-i+1] = tab[#tab-i+1], tab[i]
            end
            return tab
        end
        text = reverse(text)
        -- pad text table so that we always have max_lines lines in there
        local nLinesToPad = #text - self.max_lines
        for i=1,nLinesToPad do
            table.insert(text, {text = "", level = "PRINT", name = "", time = 0, level_numeric = 1000, formatted = function() return "" end})
        end
        return text
    end,
    modifiersListener = function(self)
        -- disable text input if ctrl or cmd is pressed
        -- this is to fallback to love.keypressed when a modifier is pressed that can
        -- link to a command (like ctrl+c, ctrl+v, etc)
        self.logger:trace("modifiers", self.modifiers)
        if self.modifiers.ctrl or self.modifiers.meta then
            love.textinput = nil
        else
            love.textinput = function(character)
                self.cmd = self.cmd .. character
            end
        end
    end,
    typeKey = function (self, key_name)
        -- cmd+shift+C on mac, ctrl+shift+C on windows/linux
        if key_name == "c" and ((platform.is_mac and self.modifiers.meta and self.modifiers.shift) or (not platform.is_mac and self.modifiers.ctrl and self.modifiers.shift)) then
            local messages = self:getFilteredMessages()
            local text = ""
            for _, message in ipairs(messages) do
                text = text .. message:formatted() .. "\n"
            end
            love.system.setClipboardText(text)
            return
        end
        -- cmd+C on mac, ctrl+C on windows/linux
        if key_name == "c" and ((platform.is_mac and self.modifiers.meta) or (not platform.is_mac and self.modifiers.ctrl)) then
            if self.cmd:sub(3) == "" then
                -- do nothing if the buffer is empty
                return
            end
            love.system.setClipboardText(self.cmd:sub(3))
            return
        end
        -- cmd+V on mac, ctrl+V on windows/linux
        if key_name == "v" and ((platform.is_mac and self.modifiers.meta) or (not platform.is_mac and self.modifiers.ctrl)) then
            self.cmd = self.cmd .. love.system.getClipboardText()
            return
        end
        if key_name == "escape" then
            -- close the console
            self:toggle()
            return
        end
        -- Delete the current command, on mac it's cmd+backspace
        if key_name == "delete" or (platform.is_mac and self.modifiers.meta and key_name == "backspace") then
            self.cmd = "> "
            return
        end
        if key_name == "end" or (platform.is_mac and key_name == "right" and self.modifiers.meta) then
            -- move text to the most recent (bottom)
            self.start_line_offset = self.max_lines
            return
        end
        if key_name == "home" or (platform.is_mac and key_name == "left" and self.modifiers.meta) then
            -- move text to the oldest (top)
            local messages = self:getFilteredMessages()
            self.start_line_offset = self.max_lines - #messages
            return
        end
        if key_name == "pagedown" or (platform.is_mac and key_name == "down" and self.modifiers.meta) then
            -- move text down by max_lines
            self.start_line_offset = math.min(self.start_line_offset + self.max_lines, self.max_lines)
            return
        end
        if key_name == "pageup"  or (platform.is_mac and key_name == "up" and self.modifiers.meta) then
            -- move text up by max_lines
            local messages = self:getFilteredMessages()
            self.start_line_offset = math.max(self.start_line_offset - self.max_lines, self.max_lines - #messages)
            return
        end
        if key_name == "up" then
            -- move to the next command in the history (in reverse order of insertion)
            self.history_index = math.min(self.history_index + 1, #self.command_history)
            if self.history_index == 0 then
                self.cmd = "> "
                return
            end
            self.cmd = "> " .. self.command_history[#self.command_history - self.history_index + 1]
            return
        end
        if key_name == "down" then
            -- move to the previous command in the history (in reverse order of insertion)
            self.history_index = math.max(self.history_index - 1, 0)
            if self.history_index == 0 then
                self.cmd = "> "
                return
            end
            self.cmd = "> " .. self.command_history[#self.command_history - self.history_index + 1]
            return
        end
        if key_name == "tab" then
            local completion = self:tryAutocomplete()
            if completion then
                -- get the last part of the console command
                local lastPart = self.cmd:match("%S+$")
                if lastPart == nil then -- cmd ends with a space, so we stop the completion
                    return
                end
                -- then replace the whole last part with the autocompleted command
                self.cmd = self.cmd:sub(1, #self.cmd - #lastPart) .. completion
            end
            return
        end
        if key_name == "lalt" or key_name == "ralt" then
            self.modifiers.alt = true
            self:modifiersListener()
            return
        end
        if key_name == "lctrl" or key_name == "rctrl" then
            self.modifiers.ctrl = true
            self:modifiersListener()
            return
        end
        if key_name == "lshift" or key_name == "rshift" then
            self.modifiers.shift = true
            self:modifiersListener()
            return
        end
        if key_name == "lgui" or key_name == "rgui" then
            -- windows key / meta / cmd key (on macos)
            self.modifiers.meta = true
            self:modifiersListener()
            return
        end
        if key_name == "backspace" then
            if #self.cmd > 2 then
                local byteoffset = utf8.offset(self.cmd, -1)
                if byteoffset then
                    -- remove the last UTF-8 character.
                    -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
                    self.cmd = string.sub(self.cmd, 1, byteoffset - 1)
                end
            end
            return
        end
        if key_name == "return" or key_name == "kpenter" then
            self.logger:print(self.cmd)
            local cmdName = self.cmd:sub(3)
            cmdName = cmdName:match("%S+")
            if cmdName == nil then
                return
            end
            local args = {}
            local argString = self.cmd:sub(3 + #cmdName + 1)
            if argString then
                for arg in argString:gmatch("%S+") do
                    table.insert(args, arg)
                end
            end
            local success = false
            if self.commands[cmdName] then
                success = self.commands[cmdName].call(args)
            else
                self.logger:error("Command not found: " .. cmdName)
            end
            if success then
                -- only add the command to the history if it was successful
                self:addToHistory(self.cmd:sub(3))
            end

            self.cmd = "> "
            return
        end
    end,
    addToHistory = function(self, command)
        if command == nil or command == "" then
            return
        end
        table.insert(self.command_history, command)
        self.history_index = 0
        local success, errormsg = love.filesystem.append(self.history_path, command .. "\n")
        if not success then
            self.logger:warn("Error appending ", command, " to history file: ", errormsg)
            success, errormsg = love.filesystem.write(self.history_path, command .. "\n")
            if not success then
                self.logger:error("Error writing to history file: ", errormsg)
            end
        end
    end,
    -- registers a command to be used in the dev console
    -- @param name: string, the name of the command
    -- @param callback: function, the function to be called when the command is run
    -- @param short_description: string, a short description of the command
    -- @param autocomplete: function(current_arg: string), a function that returns a list of possible completions for the current argument
    -- @param usage: string, a string describing the usage of the command (longer, more detailed description of the command's usage)
    registerCommand = function(self, name, callback, short_description, autocomplete, usage)
        if name == nil then
            self.logger:error("registerCommand -- name is required")
        end
        if callback == nil then
            self.logger:error("registerCommand -- callback is required on command", name)
        end
        if type(callback) ~= "function" then
            self.logger:error("registerCommand -- callback must be a function on command", name)
        end
        if name == nil or callback == nil or type(callback) ~= "function" then
            return
        end
        if short_description == nil then
            self.logger:warn("registerCommand -- no description provided, please provide a description for the `help` command")
            short_description = "No help provided"
        end
        if usage == nil then
            usage = short_description
        end
        if autocomplete == nil then
            autocomplete = function(current_arg) return nil end
        end
        if type(autocomplete) ~= "function" then
            self.logger:warn("registerCommand -- autocomplete must be a function for command: ", name)
            autocomplete = function(current_arg) return nil end
        end
        if self.commands[name] then
            self.logger:warn("Command " .. name .. " already exists")
            return
        end
        self.logger:info("Registering command: ", name)
        self.commands[name] = {
            call = callback,
            desc = short_description,
            autocomplete = autocomplete,
            usage = usage,
        }
    end,
    removeCommand = function(self, cmd_name)
        if cmd_name == nil then
            self.logger:error("removeCommand -- cmd_name is required")
        end
        if self.commands[cmd_name] == nil then
            self.logger:error("removeCommand -- command not found: ", cmd_name)
            return
        end
        self.commands[cmd_name] = nil
    end,
}