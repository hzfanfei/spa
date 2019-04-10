//
//  SpaBlockCreateTest.m
//  SpaDemoTests
//
//  Created by Family Fan on 2018/12/20.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Spa/Spa.h>

@interface Persion4 : NSObject

@property (nonatomic) NSString* name;
@property (nonatomic) NSNumber* age;

@end

@implementation Persion4

@end

typedef struct _XPoint4
{
    int x;
    int y;
}XPoint4;

@interface SpaBlockCreateTest : XCTestCase

@property (nonatomic) char vChar;
@property (nonatomic) int vInt;
@property (nonatomic) short vShort;
@property (nonatomic) long vLong;
@property (nonatomic) long long vLongLong;
@property (nonatomic) float vFloat;
@property (nonatomic) double vDouble;
@property (nonatomic) double vCGFloat;
@property (nonatomic) bool vBool;
@property (nonatomic) char* vCharX;
@property (nonatomic) NSString* vNSString;
@property (nonatomic) NSNumber* vNSNumber;
@property (nonatomic) NSDictionary* vNSDictionary;
@property (nonatomic) NSArray* vNSArray;
@property (nonatomic) Persion4* vPersion;
@property (nonatomic) XPoint4 vP;
@property (nonatomic) CGRect rect;
@property (nonatomic) SEL vSel;

@end

@implementation SpaBlockCreateTest

- (void(^)(void))blkVoidVoid
{
    return nil;
}

- (void(^)(int))blkVoidOne
{
    return nil;
}

- (int(^)(void))blkOneVoid
{
    return nil;
}

- (void(^)(char, int, short, long, long long, float, double, CGFloat, bool, char*, NSString*, NSNumber*, NSDictionary*, NSArray*, Persion4*))blkVoidTotal
{
    return nil;
}

- (void(^)(XPoint4))blkVoidStruct
{
    return nil;
}

- (void(^)(XPoint4, CGRect))blkVoidStruct2
{
    return nil;
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
    spa_class(\"SpaBlockCreateTest\") \n \
    function blkVoidVoid(self)    \n \
    return function () self.vInt = 1 end \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    [self blkVoidVoid]();

    XCTAssert(self.vInt == 1);
    
    script = @"\
    spa_class(\"SpaBlockCreateTest\") \n \
    function blkVoidOne(self)    \n \
    return block(function (i) self.vInt = i end, 'v', {'i'}) \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    [self blkVoidOne](2);
    
    XCTAssert(self.vInt == 2);
    
    script = @"\
    spa_class(\"SpaBlockCreateTest\") \n \
    function blkOneVoid(self)    \n \
    return block(function () return 5 end, 'i') \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([self blkOneVoid]() == 5);
}

- (void)testTotal
{
    NSString* script = @"\
    spa_class(\"SpaBlockCreateTest\") \n \
    function blkVoidTotal(self)    \n \
    return block(function (c, i, s, l, q, f, d, g, B, ss, ns_string, ns_number, ns_dict, ns_array, persion) \n \
    self.vChar = c  \n \
    self.vInt = i  \n \
    self.vShort = s  \n \
    self.vLong = l  \n \
    self.vLongLong = q  \n \
    self.vFloat = f  \n \
    self.vDouble = d  \n \
    self.vCGFloat = g \n \
    self.vBool = B  \n \
    self.vCharX = ss  \n \
    self.vNSString = ns_string  \n \
    self.vNSNumber = ns_number  \n \
    self.vNSDictionary = ns_dict  \n \
    self.vNSArray = ns_array  \n \
    self.vPersion = persion  \n \
    end, 'v', {'c', 'i', 's', 'l', 'q', 'f', 'd', 'g', 'B', '*', '@', '@', '@', '@', '@'}) \n \
    end                            \n";
    
    Persion4* p = [[Persion4 alloc] init];
    p.name = @"kk";
    p.age = @99;
    [[Spa sharedInstace] usePatch:script];
    [self blkVoidTotal]('o', 1, 2, 3, 4, 5.5f, 5.5, 5.7, true, "bbq", @"nsstring", @9, @{@"key1":@1, @"key2":@2}, @[@1, @2], p);
    XCTAssert(self.vChar == 'o');
    XCTAssert(self.vInt == 1);
    XCTAssert(self.vShort == 2);
    XCTAssert(self.vLong == 3);
    XCTAssert(self.vLongLong == 4);
    XCTAssert(self.vFloat == 5.5f);
    XCTAssert(self.vDouble == 5.5);
    XCTAssert(self.vCGFloat == (CGFloat)5.7);
    XCTAssert(self.vBool == true);
    XCTAssert(strcmp(self.vCharX, "bbq") == 0);
    XCTAssert([self.vNSString isEqualToString:@"nsstring"]);
    XCTAssert([self.vNSNumber isEqualToNumber:@9]);
    id dict = @{@"key1":@1, @"key2":@2};
    XCTAssert([self.vNSDictionary isEqualToDictionary:dict]);
    id array = @[@1, @2];
    XCTAssert([self.vNSArray isEqualToArray:array]);
    XCTAssert([self.vPersion.name isEqualToString:@"kk"]);
    XCTAssert([self.vPersion.age isEqualToNumber:@99]);
}

- (void)testStruct
{
    NSString* script = @"\
    spa_class(\"SpaBlockCreateTest\") \n \
    function blkVoidStruct(self)    \n \
    return block(function (point) self.vP = point  end, 'v', {'{XPoint=ii}'}) \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XPoint4 p;
    p.x = 3;
    p.y = 4;
    [self blkVoidStruct](p);
    XCTAssert(self.vP.x == 3);
    XCTAssert(self.vP.y == 4);
    
    script = @"\
    spa_class(\"SpaBlockCreateTest\") \n \
    function blkVoidStruct2(self)    \n \
    return block(function (point, rect) self.vP = point; self.rect = rect  end, 'v', {'{XPoint=ii}', '{CGRect=gggg}'}) \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XPoint4 p2;
    p2.x = 6;
    p2.y = 8;
    [self blkVoidStruct2](p, CGRectMake(1, 2, 3, 4));
    XCTAssert(self.vP.x == 3);
    XCTAssert(self.vP.y == 4);
    XCTAssert(self.rect.origin.x == 1);
    XCTAssert(self.rect.origin.y == 2);
    XCTAssert(self.rect.size.width == 3);
    XCTAssert(self.rect.size.height == 4);
}

- (BOOL(^)(void))blkReturnBool
{
    return nil;
}

- (char *(^)(void))blkReturnCharX
{
    return nil;
}

- (SEL(^)(void))blkReturnSEL
{
    return nil;
}

- (Class(^)(void))blkReturnClass
{
    return nil;
}

- (char(^)(void))blkReturnChar
{
    return nil;
}

- (int(^)(void))blkReturnInt
{
    return nil;
}

- (long(^)(void))blkReturnLong
{
    return nil;
}

- (short(^)(void))blkReturnShort
{
    return nil;
}

- (float(^)(void))blkReturnFloat
{
    return nil;
}

- (double(^)(void))blkReturnDouble
{
    return nil;
}

- (long long(^)(void))blkReturnLongLong
{
    return nil;
}

- (CGFloat(^)(void))blkReturnCGFloat
{
    return nil;
}


- (void)testReturn
{
    NSString* script = @"\
    spa_class(\"SpaBlockCreateTest\") \n \
    function blkReturnBool(self)    \n \
    return block(function () return true end, 'B') \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    XCTAssert([self blkReturnBool]() == true);
    
    script = @"\
    spa_class(\"SpaBlockCreateTest\") \n \
    function blkReturnCharX(self)    \n \
    return block(function () return 'string' end, '*') \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    XCTAssert(strcmp([self blkReturnCharX](), "string") == 0);
    
    script = @"\
    spa_class(\"SpaBlockCreateTest\") \n \
    function blkReturnSEL(self)    \n \
    return block(function () return 'selector' end, '*') \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    XCTAssert(strcmp([self blkReturnSEL]() ,"selector") == 0);
    
    script = @"\
    spa_class(\"SpaBlockCreateTest\") \n \
    function blkReturnClass(self)    \n \
    return block(function () return spa.class.create('UIColor') end, '@') \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    XCTAssert([self blkReturnClass]() == NSClassFromString(@"UIColor"));
    
    script = @"\
    spa_class(\"SpaBlockCreateTest\") \n \
    function blkReturnChar(self)    \n \
    return block(function () return 'c' end, 'c') \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    XCTAssert([self blkReturnChar]() == 'c');
    
    script = @"\
    spa_class(\"SpaBlockCreateTest\") \n \
    function blkReturnInt(self)    \n \
    return block(function () return 1 end, 'i') \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    XCTAssert([self blkReturnInt]() == 1);
    
    script = @"\
    spa_class(\"SpaBlockCreateTest\") \n \
    function blkReturnLong(self)    \n \
    return block(function () return 100 end, 'l') \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    XCTAssert([self blkReturnLong]() == 100);
    
    script = @"\
    spa_class(\"SpaBlockCreateTest\") \n \
    function blkReturnShort(self)    \n \
    return block(function () return 0 end, 's') \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    XCTAssert([self blkReturnShort]() == 0);
    
    script = @"\
    spa_class(\"SpaBlockCreateTest\") \n \
    function blkReturnFloat(self)    \n \
    return block(function () return 3.14 end, 'f') \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    XCTAssert([self blkReturnFloat]() == 3.14f);
    
    script = @"\
    spa_class(\"SpaBlockCreateTest\") \n \
    function blkReturnDouble(self)    \n \
    return block(function () return 7.14 end, 'd') \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    XCTAssert([self blkReturnDouble]() == 7.14);
    
    script = @"\
    spa_class(\"SpaBlockCreateTest\") \n \
    function blkReturnLongLong(self)    \n \
    return block(function () return 70000 end, 'q') \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    XCTAssert([self blkReturnLongLong]() == 70000);
    
    script = @"\
    spa_class(\"SpaBlockCreateTest\") \n \
    function blkReturnCGFloat(self)    \n \
    return block(function () return 5.12 end, 'g') \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    XCTAssert([self blkReturnCGFloat]() == (CGFloat)5.12);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
