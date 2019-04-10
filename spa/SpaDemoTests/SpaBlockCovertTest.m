//
//  SpaBlockCovertTest.m
//  SpaDemoTests
//
//  Created by Family Fan on 2018/12/20.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Spa/Spa.h>

@interface Persion3 : NSObject

@property (nonatomic) NSString* name;
@property (nonatomic) int age;

@end

@implementation Persion3

@end

typedef struct _XPoint3
{
    int x;
    int y;
    double z;
}XPoint3;

@interface SpaBlockCovertTest : XCTestCase

@property (nonatomic) char vChar;
@property (nonatomic) int vInt;
@property (nonatomic) short vShort;
@property (nonatomic) long vLong;
@property (nonatomic) long long vLongLong;
@property (nonatomic) float vFloat;
@property (nonatomic) double vDouble;
@property (nonatomic) CGFloat vCGFloat;
@property (nonatomic) bool vBool;
@property (nonatomic) char* vCharX;
@property (nonatomic) NSString* vNSString;
@property (nonatomic) NSNumber* vNSNumber;
@property (nonatomic) NSDictionary* vNSDictionary;
@property (nonatomic) NSArray* vNSArray;
@property (nonatomic) Persion3* vPersion;
@property (nonatomic) XPoint3 vP;
@property (nonatomic) SEL vSel;

@end

@implementation SpaBlockCovertTest

- (void)argInChar:(char(^)(char c))block
{
    self.vChar = block('c');
}

- (void)argInInt:(int(^)(int c))block
{
    self.vInt = block(9);
}

- (void)argInShort:(short(^)(short c))block
{
    self.vShort = block(2);
}

- (void)argInLong:(long(^)(long l))block
{
    self.vLong = block(99);
}

- (void)argInLongLong:(long long(^)(long long l))block
{
    self.vLongLong = block(999);
}

- (void)argInFloat:(float(^)(float f))block
{
    self.vFloat = block(3.14f);
}

- (void)argInDouble:(double(^)(double df))block
{
    self.vDouble = block(3.14);
}

- (void)argInCGFloat:(CGFloat(^)(CGFloat df))block
{
    self.vCGFloat = block(3.14);
}

- (void)argInBool:(bool(^)(bool b))block
{
    self.vBool = block(true);
}

- (void)argInCharX:(char *(^)(char *))block
{
    self.vCharX = block("string");
}

- (void)argInNSString:(NSString *(^)(NSString *))block
{
    self.vNSString = block(@"NSString");
}

- (void)argInNSNumber:(NSNumber *(^)(NSNumber *))block
{
    self.vNSNumber = block(@1);
}

- (void)argInNSArray:(NSArray *(^)(NSArray *))block
{
    self.vNSArray = block(@[@1, @2]);
}

- (void)argInNSDictionary:(NSDictionary *(^)(NSDictionary *))block
{
    self.vNSDictionary = block(@{@"key1":@1, @"key2":@2});
}

- (void)argInPersion:(Persion3 *(^)(Persion3 *))block
{
    Persion3* p = [[Persion3 alloc] init];
    p.name = @"tom";
    p.age = 18;
    self.vPersion = block(p);
}

- (void)argInXPoint:(XPoint3(^)(XPoint3))block
{
    XPoint3 p;
    p.x = 2;
    p.y = 3;
    p.z = 8.8;
    self.vP = block(p);
}

- (void)argInSEL:(SEL(^)(SEL))block
{
    self.vSel = block(@selector(argInSEL:));
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
    spa_class(\"SpaBlockCovertTest\") \n \
    function argInChar_(self, blk)    \n \
    self.vChar = blk('d') \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
     
    [self argInChar:^char(char c) {
        return c;
    }];
    XCTAssert(self.vChar == 'd');
    
    script = @"\
    spa_class(\"SpaBlockCovertTest\") \n \
    function argInInt_(self, blk)    \n \
    self.vInt = blk(10) \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    [self argInInt:^int(int c) {
        return c;
    }];
    XCTAssert(self.vInt == 10);
    
    script = @"\
    spa_class(\"SpaBlockCovertTest\") \n \
    function argInShort_(self, blk)    \n \
    self.vShort = blk(1) \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    [self argInShort:^short(short c) {
        return c;
    }];
    XCTAssert(self.vShort == 1);
    
    script = @"\
    spa_class(\"SpaBlockCovertTest\") \n \
    function argInLong_(self, blk)    \n \
    self.vLong = blk(999) \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    [self argInLong:^long(long c) {
        return c;
    }];
    XCTAssert(self.vLong == 999);
    
    script = @"\
    spa_class(\"SpaBlockCovertTest\") \n \
    function argInLongLong_(self, blk)    \n \
    self.vLongLong = blk(9999) \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    [self argInLongLong:^long long(long long c) {
        return c;
    }];
    XCTAssert(self.vLongLong == 9999);
    
    script = @"\
    spa_class(\"SpaBlockCovertTest\") \n \
    function argInFloat_(self, blk)    \n \
    self.vFloat = blk(4.18) \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    [self argInFloat:^float(float c) {
        return c;
    }];
    XCTAssert(self.vFloat == 4.18f);
    
    script = @"\
    spa_class(\"SpaBlockCovertTest\") \n \
    function argInDouble_(self, blk)    \n \
    self.vDouble = blk(5.72) \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    [self argInDouble:^double(double c) {
        return c;
    }];
    XCTAssert(self.vDouble == 5.72);
    
    script = @"\
    spa_class(\"SpaBlockCovertTest\") \n \
    function argInCGFloat_(self, blk)    \n \
    self.vCGFloat = blk(5.72) \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    [self argInCGFloat:^CGFloat(CGFloat c) {
        return c;
    }];
    XCTAssert(self.vCGFloat == (CGFloat)5.72);
    
    script = @"\
    spa_class(\"SpaBlockCovertTest\") \n \
    function argInBool_(self, blk)    \n \
    self.vBool = blk(false) \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    [self argInBool:^bool(bool c) {
        return c;
    }];
    XCTAssert(self.vBool == false);
    
    script = @"\
    spa_class(\"SpaBlockCovertTest\") \n \
    function argInCharX_(self, blk)    \n \
    self.vCharX = blk('sstring') \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    [self argInCharX:^char *(char * s) {
        return s;
    }];
    XCTAssert(strcmp(self.vCharX, "sstring") == 0);
    
    script = @"\
    spa_class(\"SpaBlockCovertTest\") \n \
    function argInNSString_(self, blk)    \n \
    self.vNSString = blk('NSNSString') \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    [self argInNSString:^NSString *(NSString * s) {
        return s;
    }];
    XCTAssert([self.vNSString isEqualToString:@"NSNSString"]);
    
    script = @"\
    spa_class(\"SpaBlockCovertTest\") \n \
    function argInNSNumber_(self, blk)    \n \
    self.vNSNumber = blk(2) \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    [self argInNSNumber:^NSNumber *(NSNumber * s) {
        return s;
    }];
    XCTAssert([self.vNSNumber isEqualToNumber:@2]);
    
    script = @"\
    spa_class(\"SpaBlockCovertTest\") \n \
    function argInNSArray_(self, blk)    \n \
    self.vNSArray = blk({2, 3}) \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    [self argInNSArray:^NSArray *(NSArray * s) {
        return s;
    }];
    id array = @[@2, @3];
    XCTAssert([self.vNSArray isEqualToArray:array]);
    
    script = @"\
    spa_class(\"SpaBlockCovertTest\") \n \
    function argInNSDictionary_(self, blk)    \n \
    self.vNSDictionary = blk({key1=2, key2=3}) \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    [self argInNSDictionary:^NSDictionary *(NSDictionary * s) {
        return s;
    }];
    id dict = @{@"key1":@2, @"key2":@3};
    XCTAssert([self.vNSDictionary isEqualToDictionary:dict]);
    
    script = @"\
    spa_class(\"SpaBlockCovertTest\") \n \
    function argInPersion_(self, blk)    \n \
    local p = Persion3:alloc():init() \n \
    p.name = 'tom2'; \n \
    p.age = 22; \n \
    self.vPersion = blk(p) \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    [self argInPersion:^Persion3 *(Persion3* s) {
        return s;
    }];
    XCTAssert([self.vPersion.name isEqualToString:@"tom2"]);
    XCTAssert(self.vPersion.age == 22);
    
    script = @"\
    spa_class(\"SpaBlockCovertTest\") \n \
    function argInXPoint_(self, blk)    \n \
    self.vP = blk({3, 4, 9.9}) \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    [self argInXPoint:^XPoint3(XPoint3 xp) {
        return xp;
    }];
    XCTAssert(self.vP.x == 3);
    XCTAssert(self.vP.y == 4);
    XCTAssert(self.vP.z == 9.9);
    
    script = @"\
    spa_class(\"SpaBlockCovertTest\") \n \
    function argInSEL_(self, blk)    \n \
    self.vSel = blk('argInXPoint:') \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    
    [self argInSEL:^SEL(SEL sel) {
        return sel;
    }];
    XCTAssert(self.vSel == @selector(argInXPoint:));
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
