//
//  SpaInvokeTest.m
//  SpaDemoTests
//
//  Created by Family Fan on 2018/12/18.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Spa/Spa.h>

@interface SpaInvokeTest : XCTestCase

@end

@interface SpaInvokeTestSubClass : SpaInvokeTest

@end

@implementation SpaInvokeTestSubClass

- (NSString *)getString
{
    return @"sub static";
}

- (void)testExample
{
    // super test
    NSString* script = @"\
    spa_class(\"SpaInvokeTestSubClass\") \n \
    function getString(self)    \n \
    return self:SUPERgetString() \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    XCTAssert([[self getString] isEqualToString:@"static"]);
    
    // origin test
    script = @"\
    spa_class(\"SpaInvokeTestSubClass\") \n \
    function getString(self)    \n \
    return self:ORIGgetString() \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    XCTAssert([[self getString] isEqualToString:@"sub static"]);
}

@end


@implementation SpaInvokeTest

+ (NSString *)getString
{
    return @"dy";
}

- (NSString *)getString
{
    return @"static";
}

+ (NSString *)getStringStatic
{
    return @"dy";
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
    
    // static and dy
    NSString* script = @"\
    spa_class(\"SpaInvokeTest\") \n \
    function STATICgetString(self)    \n \
    return 'static' \n \
    end                            \n \
    function getString(self)    \n \
    return 'dy' \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    XCTAssert([[self getString] isEqualToString:@"dy"]);
    XCTAssert([[SpaInvokeTest getString] isEqualToString:@"static"]);
    
    // dy
    script = @"\
    spa_class(\"SpaInvokeTest\") \n \
    function getString(self)    \n \
    return 'dy' \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    XCTAssert([[self getString] isEqualToString:@"dy"]);
    
    script = @"\
    spa_class(\"SpaInvokeTest\") \n \
    function getStringStatic(self)    \n \
    return 'static' \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    XCTAssert([[SpaInvokeTest getStringStatic] isEqualToString:@"static"]);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
