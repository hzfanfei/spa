//
//  SpaFunctionTest.m
//  SpaDemoTests
//
//  Created by Family Fan on 2018/12/14.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Spa/Spa.h>

@interface SpaFunctionTest : XCTestCase

@property (nonatomic) NSString* world;

@end

@implementation SpaFunctionTest

- (void)command
{
    self.world = @"dark";
}

- (void)command:(NSString *)words
{
    self.world = words;
}

- (NSString *)front
{
    return @"back";
}

- (NSString *)weAreSame:(NSString *)words
{
    return @"not same";
}

- (NSString *)worried:(NSString *)w1 w2:(NSString *)w2 w3:(NSString *)w3 w4:(NSString *)w4 w5:(NSString *)w5 w6:(NSString *)w6 w7:(NSString *)w7 w8:(NSString *)w8 w9:(NSString *)w9
{
    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@", w1, w2, w3, w4, w5, w6, w7, w8, w9];
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
    
    // no args no result
    NSString* script = @"\
        spa_class(\"SpaFunctionTest\") \n \
        function command(self)         \n \
            self:setWorld_(\"light\")   \n \
        end                            \n";
    [self command];
    XCTAssertEqualObjects(self.world, @"dark");
    [[Spa sharedInstace] usePatch:script];
    [self command];
    XCTAssertEqualObjects(self.world, @"light");
    
    // one arg no result
    [self command:@"You cann't"];
    XCTAssertEqualObjects(self.world, @"You cann't");
    script = @"\
    spa_class(\"SpaFunctionTest\") \n \
    function command_(self, words)         \n \
    self:setWorld_(\"You can\")       \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    [self command:@"You cann't"];
    XCTAssertEqualObjects(self.world, @"You can");
    
    // one result
    XCTAssertEqualObjects([self front], @"back");
    script = @"\
    spa_class(\"SpaFunctionTest\") \n \
    function front()         \n \
        return \"front\"       \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssertEqualObjects([self front], @"front");
    
    // one result one args
    XCTAssertEqualObjects([self weAreSame:@"same"], @"not same");
    script = @"\
    spa_class(\"SpaFunctionTest\") \n \
    function weAreSame_(self, same)         \n \
    return same       \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssertEqualObjects([self weAreSame:@"same"], @"same");
    
    // many many args
    XCTAssertEqualObjects([self worried:@"w1" w2:@"w2" w3:@"w3" w4:@"w4" w5:@"w5" w6:@"w6" w7:@"w7" w8:@"w8" w9:@"w9"], @"w1w2w3w4w5w6w7w8w9");
    script = @"\
    spa_class(\"SpaFunctionTest\") \n \
    function worried_w2_w3_w4_w5_w6_w7_w8_w9_(self, w1, w2, w3, w4, w5, w6, w7, w8, w9)         \n \
    return \"---------\" .. w1 .. w2 .. w3 .. w4 .. w5 .. w6 .. w7 .. w8 .. w9 \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssertEqualObjects([self worried:@"w1" w2:@"w2" w3:@"w3" w4:@"w4" w5:@"w5" w6:@"w6" w7:@"w7" w8:@"w8" w9:@"w9"], @"---------w1w2w3w4w5w6w7w8w9");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
