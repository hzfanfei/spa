spa_class("ViewController")

function doSomeThing(self)
local block = function(i)
    spa.log(i)
end
self:doSomeBlock_(block)
end


