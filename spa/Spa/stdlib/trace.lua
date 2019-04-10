require "spa.class"

spa_watchFunction = function (self, ...)
    local class_name, func_name = unpack(getfenv(1))

    local args = spa.toLuaString(spa.toId({...}))
    local start_time = os.time()
    local r = self["ORIG" .. func_name](self, ...)
    local end_time = os.time()

    local log = "\n=================================\n"
    log = log .. "| " .. class_name .. "|" .. func_name .. "\n"
    log = log .. "| watch report                   |\n"
    log = log .. "---------------------------------\n"
    log = log .. "args:                            \n"
    log = log .. args
    log = log .. "\n---------------------------------\n"
    log = log .. "start time: " .. tostring(start_time)
    log = log .. "\n"
    log = log .. "end time  : " .. tostring(end_time)
    log = log .. "\n---------------------------------\n"
    log = log .. "return value:                    \n"
    if (r ~= nil) then
        log = log .. spa.toLuaString(spa.toId(r))
    else
        log = log .. "### no result value ###"
    end
    log = log .. "\n=================================\n"
    spa.log(log)
    spa.class.recoverMethod(class_name, func_name)
    return r
end

function watch(class_name, func_name)
    spa_class(class_name)
    local _M = {class_name, func_name}
    setmetatable(_M, {__index = _G})
    setfenv(spa_watchFunction, _M)
    self[func_name] = spa_watchFunction
end

function watch_in(class_name, func_name)
    spa.setCSToTls(class_name, func_name)
    spa_class(class_name)
    self[func_name] = function(self, ...)
        local cls, sel = spa.getCSFromTls()
        if (cls == class_name and sel == func_name) then
            local _M = {class_name, func_name}
            setmetatable(_M, {__index = _G})
            setfenv(spa_watchFunction, _M)
            spa_watchFunction(self, ...)
        else
            self["ORIG" .. func_name](self, ...)
        end
    end
end

function watch_out(class_name, func_name)
    spa.class.recoverMethod(class_name, func_name)
    spa.removeKeyFromTls()
end

function watch_deep(class_name, func_name, class_name_in, func_name_in)
    spa_class(class_name)[func_name] = function (self, ...)
        watch_in(class_name_in, func_name_in)
        self["ORIG" .. func_name](self, ...)
        watch_out(class_name_in, func_name_in)
        spa.class.recoverMethod(class_name, func_name)
    end
end
