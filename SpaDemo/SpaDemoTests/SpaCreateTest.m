//
//  SpaCreateTest.m
//  SpaDemoTests
//
//  Created by Family Fan on 2018/12/18.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Spa/Spa.h>

@interface Persion2 : NSObject

@property (nonatomic) NSString* name;
@property (nonatomic) NSNumber* age;

@end

@implementation Persion2

@end

typedef struct _XPoint2
{
    int x;
    int y;
}XPoint2;

@interface SpaCreateTest : XCTestCase

@end

@implementation SpaCreateTest

- (char)argInChar
{
    return 'c';
}

- (int)argInInt
{
    return 9;
}

- (short)argInShort
{
    return 9;
}

- (long)argInLong
{
    return 9;
}

- (long long)argInLongLong
{
    return 9;
}

- (float)argInFloat
{
    return 3.14f;
}

- (double)argInDouble
{
    return 3.14f;
}

- (bool)argInBool
{
    return true;
}

- (char *)argInCharX
{
    return "string";
}

- (NSString *)argInString
{
    return @"NSString";
}

- (NSNumber *)argInNSNumber
{
    return @9;
}

- (NSArray *)argInNSArray
{
    return @[@1, @2];
}

- (NSDictionary *)argInNSDictionary
{
    return @{@"key1":@1, @"key2":@2};
}

- (Persion2 *)argInPersion
{
    Persion2* p = [[Persion2 alloc] init];
    p.name = @"joy";
    p.age = @18;
    return p;
}

- (XPoint2)argInXPoint
{
    XPoint2 p;
    p.x = 3;
    p.y = 4;
    return p;
}

- (SEL)argInSel
{
    return @selector(argInSel);
}

- (void)setUp {
    [[Spa sharedInstace] setLogBlock:^(NSString *log) {
        NSLog(@"%s", log.UTF8String);
    }];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    NSString* script = @"\
    spa_class(\"SpaCreateTest\") \n \
    function argInXPoint()         \n \
    return {3,4}   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];

    XCTAssert([self argInXPoint].x == 3);
    XCTAssert([self argInXPoint].y == 4);
    
    script = @"\
    spa_class(\"SpaCreateTest\") \n \
    function argInChar()         \n \
    return 'c'   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([self argInChar] == 'c');
    
    script = @"\
    spa_class(\"SpaCreateTest\") \n \
    function argInInt()         \n \
    return 9   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([self argInInt] == 9);
    
    script = @"\
    spa_class(\"SpaCreateTest\") \n \
    function argInShort()         \n \
    return 9   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([self argInShort] == 9);
    
    script = @"\
    spa_class(\"SpaCreateTest\") \n \
    function argInLong()         \n \
    return 9   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([self argInLong] == 9);
    
    script = @"\
    spa_class(\"SpaCreateTest\") \n \
    function argInLongLong()         \n \
    return 9   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([self argInLongLong] == 9);
    
    script = @"\
    spa_class(\"SpaCreateTest\") \n \
    function argInFloat()         \n \
    return 9   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([self argInFloat] == 9);
    
    script = @"\
    spa_class(\"SpaCreateTest\") \n \
    function argInDouble()         \n \
    return 9   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([self argInDouble] == 9);
    
    script = @"\
    spa_class(\"SpaCreateTest\") \n \
    function argInBool()         \n \
    return 9   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([self argInBool] == true);
    
    script = @"\
    spa_class(\"SpaCreateTest\") \n \
    function argInCharX()         \n \
    return 'string'   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert(strcmp([self argInCharX], "string") == 0);
    
    script = @"\
    spa_class(\"SpaCreateTest\") \n \
    function argInString()         \n \
    return 'NSString'   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([[self argInString] isEqualToString:@"NSString"]);
    
    script = @"\
    spa_class(\"SpaCreateTest\") \n \
    function argInNSNumber()         \n \
    return 9   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([[self argInNSNumber] isEqualToNumber:@9]);
    
    script = @"\
    spa_class(\"SpaCreateTest\") \n \
    function argInNSArray()         \n \
    return {1, 2}   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([[[self argInNSArray] objectAtIndex:0] isEqualToNumber:@1]);
    XCTAssert([[[self argInNSArray] objectAtIndex:1] isEqualToNumber:@2]);
    
    script = @"\
    spa_class(\"SpaCreateTest\") \n \
    function argInNSDictionary()         \n \
    return {key1=1, key2=2}   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([[[self argInNSDictionary] objectForKey:@"key1"] isEqualToNumber:@1]);
    XCTAssert([[[self argInNSDictionary] objectForKey:@"key2"] isEqualToNumber:@2]);
    
    script = @"\
    spa_class(\"SpaCreateTest\") \n \
    function argInPersion()         \n \
    local p = Persion2:alloc():init() \n \
    p:setName_('joy')  \n \
    p:setAge_(18)  \n \
    return p   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([[self argInPersion].name isEqualToString:@"joy"]);
    XCTAssert([[self argInPersion].age isEqualToNumber:@18]);
    
    script = @"\
    spa_class(\"SpaCreateTest\") \n \
    function argInSel()         \n \
    return 'argInSel:'   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([self argInSel] == @selector(argInSel:));
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
