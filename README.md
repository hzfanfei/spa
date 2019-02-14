# SPA

lua hotfix ios app

### before run spa demo

cd serverSample

node server.js

### situation 1

Objective-c

```objective-c
@implementation ViewController

- (void)doSomeThing
{
    [self.view setBackgroundColor:[UIColor grayColor]];
}
```

lua

```lua
spa_class("ViewController")

function doSomeThing(self)
    self:view():setBackgroundColor_(UIColor:grayColor())
end
```

### situation 2

Objective-c

```objective-c
@implementation ViewController

- (void)doSomeThing:(UIColor *)color
{
    [self.view setBackgroundColor:color];
}
```

lua

```lua
spa_class("ViewController")

function doSomeThing_(self, color)
    self:view():setBackgroundColor_(color)
end
```

### situation 3

Objective-c

```objective-c
@implementation ViewController

- (void)doSomeThing:(UIColor *)color
{
    [self.view setBackgroundColor:color];
}
```

lua

```lua
spa_class("ViewController")

function doSomeThing_(self, color)
    self:ORIGdoSomeThing_(color)
end
```

### situation 4

Objective-c

```objective-c
@implementation SUBViewController

- (void)doSomeThing:(UIColor *)color
{
    [super doSomeThing:color];
}
```

lua

```lua
spa_class("ViewController")

function doSomeThing_(self, color)
    self:SUPERdoSomeThing_(color)
end
```
### situation 5

Objective-c

```objective-c
@implementation SUBViewController

- (void)doSomeThing:(void(^)(int i))block
{
    block(5);
}
```

lua

```lua
spa_class("ViewController")

function doSomeThing_(self, block)
    block(5)
end
```

### situation 6

Objective-c

```objective-c
@implementation ViewController

- (void(^)(void))doSomeThing
{
    void(^block)(void) = ^() { };
    return block;
}
```

lua

```lua
spa_class("ViewController")

function doSomeThing_(self, block)
    return function (i)  end
end
```

Objective-c

```objective-c
@implementation ViewController

- (void(^)(int))doSomeThing
{
    void(^block)(int) = ^(int i) { };
    return block;
}
```

lua

```lua
spa_class("ViewController")

function doSomeThing_(self, block)
    return block(function (i)  end, 'v', {'i'})
end
```

### situation 7

Objective-c

```objective-c
@implementation ViewController

- (void)doSomeThing_(CGPoint)p
{
    int x = p.x;
    int y = p.y;
}
```

lua

```lua
spa_class("ViewController")

function doSomeThing_(self, p)
    local x = p.x1
    local y = p.x2
end
```

Objective-c

```objective-c
@implementation ViewController

- (CGPoint)doSomeThing
{
    CGPoint p;
    p.x = 3;
    p.y = 4;
    return p;
}
```

lua

```lua
spa_class("ViewController")

function doSomeThing(self)
    return {3,4}
end
```

### situation 8 

Objective-c

```objective-c
@implementation ViewController

- (void(^)(CGPoint, CGRect))doSomeThing
{
    void(^block)(CGPoint, CGRect) = ^(CGPoint, CGRect) {
        
    };
    return block;
}
```

lua

```lua
spa_class("ViewController")

function doSomeThing()
    return block(function (point, rect)  end, 'v', {'{CGPoint=gg}', '{CGRect=gggg}'})
end
```
### situation 9

```objective-c
@implementation ViewController

- (void)doSomeThing
{
    ...
    [self doSomeThingInternal];
    ...
}

- (void)doSomeThingInternal
{
    ...
}
```

lua

```lua
class_deep('ViewController', 'doSomeThing', 'ViewController', 'doSomeThingInternal', function ()  end) -- remove doSomeThingInternal impl in doSomeThing only
```


