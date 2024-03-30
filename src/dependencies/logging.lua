LOGGERS = {}
local START_TIME = os.time()

local LOG_LEVELS = {
    TRACE = 10,
    DEBUG = 20,
    INFO = 30,
    WARN = 40,
    ERROR = 50,
    PRINT = 1000,
}

local _MODULE = {
    _VERSION = "0.2.0",
    LOGGERS = LOGGERS,
    LOG_LEVELS = LOG_LEVELS,
    START_TIME = START_TIME,
}

local function addZeroForLessThan10(number)
    if(number < 10) then
        return 0 .. number
    else
        return number
    end
end

local function generateDateTime(start)
    local dateTimeTable = os.date('*t', start)
    local dateTime = dateTimeTable.year .. "-"
            .. addZeroForLessThan10(dateTimeTable.month) .. "-"
            .. addZeroForLessThan10(dateTimeTable.day) .. "-"
            .. addZeroForLessThan10(dateTimeTable.hour) .. "-"
            .. addZeroForLessThan10(dateTimeTable.min) .. "-"
            .. addZeroForLessThan10(dateTimeTable.sec)
    return dateTime
end

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

local Message = {}
function Message:init(level, text, loggerName)
    self.level = level
    self.level_numeric = LOG_LEVELS[level] or 0
    self.text = text
    self.time = os.time()
    self.name = loggerName
    return self
end

function Message:formatted(dump)
    if self.level == "PRINT" and not dump then
        return self.text
    end
    if dump then
        return string.format("%s [%s] - %s :: %s", generateDateTime(self.time), self.name, self.level, self.text)
    end
    return string.format("[%s] - %s :: %s", self.name, self.level, self.text)
end

local Logger = {}
function Logger:init(name, level)
    self.name = name
    self.level = level or "INFO"
    self.numeric_level = LOG_LEVELS[level] or 30
    self.messages = {}
    return self
end

function Logger:log(level, ...)
    local args = {...}
    local text = ""
    for i, v in ipairs(args) do
        text = text .. stringify(v) .. " "
    end
    table.insert(self.messages, Message:init(level, text, self.name))
end

function Logger:info(...)
    self:log("INFO", ...)
end

function Logger:warn(...)
    self:log("WARN", ...)
end

function Logger:error(...)
    self:log("ERROR", ...)
end

function Logger:debug(...)
    self:log("DEBUG", ...)
end

function Logger:trace(...)
    self:log("TRACE", ...)
end

function Logger:print(message)
    self:log("PRINT", message)
end

local function getLogger(name, level)
    if LOGGERS[name] then
        return LOGGERS[name]
    else
        local logger = Logger:init(name, level)
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


local function saveLogs()
    local filename = "logs/" .. generateDateTime() .. ".log"
    love.filesystem.write(filename, "")
    for _, message in ipairs(getAllMessages()) do
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
_MODULE.Logger = Logger
_MODULE.Message = Message

return _MODULE
