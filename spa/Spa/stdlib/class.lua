function spa_class(class_name)
    local class_userdata = spa.class.create(class_name)

    local _M = {self = class_userdata}

    setmetatable(_M, {
        __newindex = function(self, key, value)
            class_userdata[key] = value
        end,
        
        __index = function(self, key)
            return spa.class.create(key) or class_userdata[key] or _G[key]
        end,
    })

    setfenv(2, _M)

    return class_userdata
end

function class_in(class_name, func_name, func)
    spa.setCSToTls(class_name, func_name)
    spa_class(class_name)
    self[func_name] = function(self, ...)
        local cls, sel = spa.getCSFromTls()
        if (cls == class_name and sel == func_name) then
            return func(...)
        else
            return self["ORIG" .. func_name](self, ...)
        end
    end
end

function class_out(class_name, func_name)
    spa.class.recoverMethod(class_name, func_name)
    spa.removeKeyFromTls()
end

function class_deep(class_name, func_name, class_name_in, func_name_in, func)
    spa_class(class_name)[func_name] = function (self, ...)
        class_in(class_name_in, func_name_in, func)
        local result = self["ORIG" .. func_name](self, ...)
        class_out(class_name_in, func_name_in)
        return result
    end
end

function block(func, r_type, args_t)
    local _M = {return_type=r_type, args_type=args_t}
    setmetatable(_M, {__index = _G})
    setfenv(func, _M)
    return func
end
