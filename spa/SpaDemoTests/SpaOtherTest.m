//
//  SpaOtherTest.m
//  SpaDemoTests
//
//  Created by FanFamily on 2018/12/22.
//  Copyright © 2018年 Family Fan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Spa/Spa.h>

@interface SpaOtherTest : XCTestCase

@property (nonatomic) int index;

@end

@implementation SpaOtherTest

- (NSString *)getString
{
    return nil;
}

- (NSString *)deep
{
    NSString* s1 = @"start";
    NSString* s2 = [self center];
    NSString* s3 = @"end";
    
    return [NSString stringWithFormat:@"%@ %@ %@", s1, s2, s3];
}

- (NSString *)center
{
    return @"center";
}

- (void)dispatchAfter
{
    
}

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // toId
    NSString* script = @"\
    spa_class(\"SpaOtherTest\") \n \
    function getString(self)    \n \
    return spa.toId('come back'):substringToIndex_(4) \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];

    XCTAssert([[self getString] isEqualToString:@"come"]);

    // toLuaString
    script = @"\
    spa_class(\"SpaOtherTest\") \n \
    function getString(self)    \n \
    return spa.toLuaString(spa.toId('co')) .. 'me'  \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];

    XCTAssert([[self getString] isEqualToString:@"come"]);
    
    // deep
    script = @"class_deep('SpaOtherTest', 'deep', 'SpaOtherTest', 'center', function () return 'cen' end) \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([[self deep] isEqualToString:@"start cen end"]);
    XCTAssert([[self center] isEqualToString:@"center"]);
    
    // create id
    
    
    // dispatch after
    script = @"spa_class('SpaOtherTest').dispatchAfter = function (self) spa.dispatch_after(function () self.index = 2 end, 2) end \n";
    [[Spa sharedInstace] usePatch:script];
    
    [self dispatchAfter];
    XCTAssert(self.index == 0);
    XCTestExpectation *exp = [self expectationWithDescription:@""];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssert(self.index == 2);
        [exp fulfill];
    });
    
    [Spa performSelectorOnMainThread:@selector(logCurrentStack) withObject:nil waitUntilDone:YES];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}



- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
