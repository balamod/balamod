LOGGERS = {}
ALL_MESSAGES = {}

function stringify(value)
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
        log=function(self, level, ...)
            local args = {...}
            local text = ""
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
                        return string.format("%s [%s] - %s :: %s", os.date("!%Y-%m-%dT%TZ", self.time), self.name, self.level, self.text)
                    end
                    return string.format("[%s] - %s :: %s", self.name, self.level, self.text)
                end,
            }
            table.insert(ALL_MESSAGES, message)
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

function getLogger(name, level)
    if LOGGERS[name] then
        return LOGGERS[name]
    else
        local logger = createLogger(name, level)
        LOGGERS[name] = logger
        return logger
    end
end
