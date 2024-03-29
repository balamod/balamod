LOGGERS = {}
START_TIME = os.time()

local _MODULE = {
    _VERSION = "0.1.0",
    LOGGERS = LOGGERS,
}

local function stringify(value)
    if type(value) == "table" then
        local str = "{"
        for k, v in pairs(value) do
            str = str .. k .. "=" .. stringify(v) .. ", "
        end
        str = str .. "}"
        return str
    end

    if type(value) == "function" then
        return "function"
    end

    if value == nil then
        return "nil"
    end

    return tostring(value)
end

local function createLogger(name, lvl)
    local log_levels = {
        TRACE = 10,
        DEBUG = 20,
        INFO = 30,
        WARN = 40,
        ERROR = 50,
        PRINT = 1000,
    }
    return {
        name=name,
        log_levels=log_levels,
        level=lvl or "INFO",
        numeric_level=log_levels[lvl] or 30,
        messages={},
        log=function(self, level, ...)
            local args = {...}
            local text = ""
            if not love.filesystem.getInfo("logs/" .. generateDateTime(START_TIME) .. ".log") then
                love.filesystem.write("logs/" .. generateDateTime(START_TIME) .. ".log", "")
            end
            for i, v in ipairs(args) do
                text = text .. stringify(v) .. " "
            end
            local message = {
                level=level,
                level_numeric=self.log_levels[level] or 0,
                text=text,
                time=os.time(),
                name=self.name,
                formatted=function(self, dump)
                    if self.level == "PRINT" and not dump then
                        return self.text
                    end
                    if dump then
                        return string.format("%s [%s] - %s :: %s", generateDateTime(self.time), self.name, self.level, self.text)
                    end
                    return string.format("[%s] - %s :: %s", self.name, self.level, self.text)
                end,
            }
            table.insert(self.messages, message)
            love.filesystem.append("logs/" .. generateDateTime(START_TIME) .. ".log", message:formatted(true) .. "\n")
            love.filesystem.append("console.txt", message:formatted(true) .. "\n")
        end,
        info=function(self, ...)
            self:log("INFO", ...)
        end,
        warn=function(self, ...)
            self:log("WARN", ...)
        end,
        error=function(self, ...)
            self:log("ERROR", ...)
        end,
        debug=function(self, ...)
            self:log("DEBUG", ...)
        end,
        trace=function(self, ...)
            self:log("TRACE", ...)
        end,
        print=function(self, message)
            self:log("PRINT", message)
        end,
    }
end

local function getLogger(name, level)
    if LOGGERS[name] then
        return LOGGERS[name]
    else
        local logger = createLogger(name, level)
        LOGGERS[name] = logger
        return logger
    end
end

local function getAllMessages()
    local messages = {}
    for name, logger in pairs(LOGGERS) do
        for i, message in ipairs(logger.messages) do
            table.insert(messages, message)
        end
    end
    table.sort(messages, function(a, b) return a.time < b.time end)
    return messages
end

function generateDateTime(start)
    local dateTimeTable = os.date('*t', start)
    local dateTime = dateTimeTable.year .. "-"
            .. addZeroForLessThan10(dateTimeTable.month) .. "-"
            .. addZeroForLessThan10(dateTimeTable.day) .. "-"
            .. addZeroForLessThan10(dateTimeTable.hour) .. "-"
            .. addZeroForLessThan10(dateTimeTable.min) .. "-"
            .. addZeroForLessThan10(dateTimeTable.sec)
    return dateTime
end

function addZeroForLessThan10(number)
    if(number < 10) then
        return 0 .. number
    else
        return number
    end
end

function saveLogs()
    local filename = "logs/" .. generateDateTime() .. ".log"
    love.filesystem.write(filename, "")
    for _, message in ipairs(ALL_MESSAGES) do
        love.filesystem.append(filename, message:formatted(true) .. "\n")
    end
end


local function clearLogs()
    for name, logger in pairs(LOGGERS) do
        logger.messages = {}
    end
end

_MODULE.getLogger = getLogger
_MODULE.saveLogs = saveLogs
_MODULE.getAllMessages = getAllMessages
_MODULE.clearLogs = clearLogs

return _MODULE
