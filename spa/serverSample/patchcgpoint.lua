spa_class("ViewController")

function scroll(self)
    self:tableview():setContentOffset_animated_({0,100},true)
end
