//
//  SpaBlockFunctionTest.m
//  SpaDemoTests
//
//  Created by Family Fan on 2018/12/18.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Spa/Spa.h>

@interface SpaBlockFunctionTest : XCTestCase

@property (nonatomic) int index;

@end

@implementation SpaBlockFunctionTest

- (void)blkVoidVoid:(void(^)(void))block
{
    block();
}

- (void)blkVoidArg:(void(^)(int i))block
{
    block(5);
}

- (void)blkOneVoid:(int(^)(void))block
{
    self.index = block();
}

- (void)blkOneArg:(int(^)(int i))block
{
     self.index = block(11);
}

- (void)blkVoidArgs:(void(^)(int w1, int w2, int w3, int w4, int w5, int w6, int w7, int w8, int w9))block
{
    block(1, 2, 3, 4, 5, 6, 7, 8, 9);
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
    [self blkVoidVoid:^{
        self.index ++;
    }];
    XCTAssert(self.index == 1);
    
    NSString* script = @"\
    spa_class(\"SpaBlockFunctionTest\") \n \
    function blkVoidVoid_(self, blk)         \n \
    blk() \n \
    self:setIndex_(self:index() + 1)   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    [self blkVoidVoid:^{
        self.index ++;
    }];
    XCTAssert(self.index == 3);
    
    // one arg no result
    [self blkVoidArg:^(int i) {
        self.index = i;
    }];
    XCTAssert(self.index == 5);
    script = @"\
    spa_class(\"SpaBlockFunctionTest\") \n \
    function blkVoidArg_(self, blk)         \n \
    blk(6) \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    [self blkVoidArg:^(int i) {
        self.index = i;
    }];
    XCTAssert(self.index == 6);
    
    // one result
    [self blkOneVoid:^int{
        return 9;
    }];
    XCTAssert(self.index == 9);
    script = @"\
    spa_class(\"SpaBlockFunctionTest\") \n \
    function blkOneVoid_(self, blk)         \n \
    self:setIndex_(blk()) \n \
    self:setIndex_(self:index() + 1)   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    [self blkOneVoid:^int{
        return 9;
    }];
    XCTAssert(self.index == 10);
 
    // one result one args
    [self blkOneArg:^int(int i) {
        return i;
    }];
    XCTAssert(self.index == 11);
    script = @"\
    spa_class(\"SpaBlockFunctionTest\") \n \
    function blkOneArg_(self, blk)         \n \
    self:setIndex_(blk(12)) \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    [self blkOneArg:^int(int i) {
        return i;
    }];
    XCTAssert(self.index == 12);
    
    
    // many many args
    [self blkVoidArgs:^(int w1, int w2, int w3, int w4, int w5, int w6, int w7, int w8, int w9) {
        self.index = w1 + w2 + w3 + w4 + w5 + w6 + w7 + w8 + w9;
    }];
    XCTAssert(self.index == 45);
    script = @"\
    spa_class(\"SpaBlockFunctionTest\") \n \
    function blkVoidArgs_(self, blk)         \n \
    blk(1, 1, 1, 1, 1, 1, 1, 1, 1) \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    [self blkVoidArgs:^(int w1, int w2, int w3, int w4, int w5, int w6, int w7, int w8, int w9) {
        self.index = w1 + w2 + w3 + w4 + w5 + w6 + w7 + w8 + w9;
    }];
    XCTAssert(self.index == 9);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
