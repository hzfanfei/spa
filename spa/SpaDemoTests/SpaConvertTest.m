//
//  SpaConvertTest.m
//  SpaDemoTests
//
//  Created by FanFamily on 2018/12/16.
//  Copyright © 2018年 Family Fan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Spa/Spa.h>

@interface Persion : NSObject

@property (nonatomic) NSString* name;
@property (nonatomic) NSNumber* age;

@end

@implementation Persion

@end

typedef struct _XPoint
{
    int x;
    int y;
}XPoint;

@interface SpaConvertTest : XCTestCase

@property (nonatomic) char vChar;
@property (nonatomic) int vInt;
@property (nonatomic) short vShort;
@property (nonatomic) long vLong;
@property (nonatomic) long long vLongLong;
@property (nonatomic) float vFloat;
@property (nonatomic) double vDouble;
@property (nonatomic) bool vBool;
@property (nonatomic) char* vCharX;
@property (nonatomic) NSString* vNSString;
@property (nonatomic) NSNumber* vNSNumber;
@property (nonatomic) NSDictionary* vNSDictionary;
@property (nonatomic) NSArray* vNSArray;
@property (nonatomic) Persion* vPersion;
@property (nonatomic) XPoint vP;
@property (nonatomic) SEL vSel;

@end

@implementation SpaConvertTest


- (char)argInChar:(char)vChar
{
    return vChar;
}

- (int)argInInt:(int)vInt
{
    return vInt;
}

- (short)argInShort:(short)vShort
{
    return vShort;
}

- (long)argInLong:(long)vLong
{
    return vLong;
}

- (long long)argInLongLong:(long long)vLongLong
{
    return vLongLong;
}

- (float)argInFloat:(float)vFloat
{
    return vFloat;
}

- (double)argInDouble:(double)vDouble
{
    return vDouble;
}

- (bool)argInBool:(bool)vBool
{
    return vBool;
}

- (char *)argInCharX:(char *)vCharX
{
    return vCharX;
}

- (NSString *)argInString:(NSString *)vNSString
{
    return vNSString;
}

- (NSNumber *)argInNSNumber:(NSNumber *)vNSNumber
{
    return vNSNumber;
}

- (NSArray *)argInNSArray:(NSArray *)vNSArray
{
    return vNSArray;
}

- (NSDictionary *)argInNSDictionary:(NSDictionary *)vNSDictionary
{
    return vNSDictionary;
}

- (Persion *)argInPersion:(Persion *)vPersion
{
    return vPersion;
}

- (XPoint)argInXPoint:(XPoint)vXPoint
{
    return vXPoint;
}

- (SEL)argInSel:(SEL)vSel
{
    return vSel;
}

- (void)setUp {
    [[Spa sharedInstace] setLogBlock:^(NSString *log) {
        NSLog(@"%s", log.UTF8String);
    }];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testChar {
    XCTAssert([self argInChar:'a'] == 'a');
    NSString* script = @"\
    spa_class(\"SpaConvertTest\") \n \
    function argInChar_(self, a)         \n \
    self:setVChar_(a) \n \
    return a   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([self argInChar:'a'] == 'a');
    XCTAssert(self.vChar == 'a');
}

- (void)testNumber {
    // int
    XCTAssert([self argInInt:9] == 9);
    NSString* script = @"\
    spa_class(\"SpaConvertTest\") \n \
    function argInInt_(self, a)         \n \
    self:setVInt_(a) \n \
    return a   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([self argInInt:9] == 9);
    XCTAssert(self.vInt == 9);
    
    // short
    XCTAssert([self argInShort:10] == 10);
    script = @"\
    spa_class(\"SpaConvertTest\") \n \
    function argInShort_(self, a)         \n \
    self:setVShort_(a) \n \
    return a   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([self argInShort:10] == 10);
    XCTAssert(self.vShort == 10);
    
    // long
    XCTAssert([self argInLong:0x100060000277e000] == 0x100060000277e000);
    script = @"\
    spa_class(\"SpaConvertTest\") \n \
    function argInLong_(self, a)         \n \
    self:setVLong_(a) \n \
    return a   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([self argInLong:0x100060000277e000] == 0x100060000277e000);
    XCTAssert(self.vLong == 0x100060000277e000);
    
    // float
    XCTAssert([self argInFloat:3.14f] == 3.14f);
    script = @"\
    spa_class(\"SpaConvertTest\") \n \
    function argInFloat_(self, a)         \n \
    self:setVFloat_(a) \n \
    return a   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([self argInFloat:3.14f] == 3.14f);
    XCTAssert(self.vFloat == 3.14f);
    
    // double
    XCTAssert([self argInDouble:4E+38] == 4E+38);
    script = @"\
    spa_class(\"SpaConvertTest\") \n \
    function argInDouble_(self, a)         \n \
    self:setVDouble_(a) \n \
    return a   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([self argInDouble:4E+38] == 4E+38);
    XCTAssert(self.vDouble == 4E+38);
    
    // bool
    XCTAssert([self argInBool:true] == true);
    script = @"\
    spa_class(\"SpaConvertTest\") \n \
    function argInBool_(self, a)         \n \
    self:setVBool_(a) \n \
    return a   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([self argInBool:true] == true);
    XCTAssert(self.vBool == true);
}

- (void)testPtr
{
    XCTAssert(strcmp([self argInCharX:"abc"], "abc") == 0);
    NSString* script = @"\
    spa_class(\"SpaConvertTest\") \n \
    function argInCharX_(self, a)         \n \
    self:setVCharX_(a) \n \
    return a   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert(strcmp([self argInCharX:"abc"], "abc") == 0);
    XCTAssert(strcmp(self.vCharX, "abc") == 0);
    
    Persion* persion = [[Persion alloc] init];
    persion.name = @"blue";
    persion.age = @18;
    
    Persion* r = [self argInPersion:persion];
    XCTAssert([r.name isEqualToString:@"blue"] && [r.age isEqualToNumber:@18]);
    script = @"\
    spa_class(\"SpaConvertTest\") \n \
    function argInPersion_(self, a)         \n \
    self:setVPersion_(a) \n \
    return a   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    r = [self argInPersion:persion];
    XCTAssert([r.name isEqualToString:@"blue"] && [r.age isEqualToNumber:@18]);
    XCTAssert([self.vPersion.name isEqualToString:@"blue"] && [self.vPersion.age isEqualToNumber:@18]);
}

- (void)testObject
{
    XCTAssert([[self argInString:@"abc"] isEqualToString:@"abc"]);
    NSString* script = @"\
    spa_class(\"SpaConvertTest\") \n \
    function argInString_(self, a) \n \
    self:setVNSString_(a) \n \
    return a   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([[self argInString:@"abc"] isEqualToString:@"abc"]);
    XCTAssert([self.vNSString isEqualToString:@"abc"]);

    XCTAssert([[self argInNSNumber:@1024] isEqualToNumber:@1024]);
    script = @"\
    spa_class(\"SpaConvertTest\") \n \
    function argInNSNumber_(self, a) \n \
    self:setVNSNumber_(a) \n \
    return a   \n \
    end \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([[self argInNSNumber:@1024] isEqualToNumber:@1024]);
    XCTAssert([self.vNSNumber isEqualToNumber:@1024]);


    BOOL b = [[[self argInNSArray:@[@1, @2]] objectAtIndex:0] isEqualToNumber:@1];
    XCTAssert(b);
    b = [[[self argInNSArray:@[@1, @2]] objectAtIndex:1] isEqualToNumber:@2];
    XCTAssert(b);

    script = @"\
    spa_class(\"SpaConvertTest\") \n \
    function argInNSArray_(self, a) \n \
    local l = #a \n \
    self:setVNSArray_(a) \n \
    return a   \n \
    end \n";
    [[Spa sharedInstace] usePatch:script];
    b = [[[self argInNSArray:@[@1, @2]] objectAtIndex:0] isEqualToNumber:@1];
    XCTAssert(b);
    b = [[[self argInNSArray:@[@1, @2]] objectAtIndex:1] isEqualToNumber:@2];
    XCTAssert(b);
    b = [[self.vNSArray objectAtIndex:0] isEqualToNumber:@1];
    XCTAssert(b);
    b = [[self.vNSArray objectAtIndex:1] isEqualToNumber:@2];
    XCTAssert(b);

    b = [[[self argInNSDictionary:@{@"key1":@1, @"key2":@2}] objectForKey:@"key1"] isEqualToNumber:@1];
    XCTAssert(b);
    b = [[[self argInNSDictionary:@{@"key1":@1, @"key2":@2}] objectForKey:@"key2"] isEqualToNumber:@2];
    XCTAssert(b);

    script = @"\
    spa_class(\"SpaConvertTest\") \n \
    function argInNSDictionary_(self, a) \n \
    local l = #a \n \
    self:setVNSDictionary_(a) \n \
    return a   \n \
    end \n";
    [[Spa sharedInstace] usePatch:script];

    b = [[[self argInNSDictionary:@{@"key1":@1, @"key2":@2}] objectForKey:@"key1"] isEqualToNumber:@1];
    XCTAssert(b);
    b = [[[self argInNSDictionary:@{@"key1":@1, @"key2":@2}] objectForKey:@"key2"] isEqualToNumber:@2];
    XCTAssert(b);
    b = [[self.vNSDictionary objectForKey:@"key1"] isEqualToNumber:@1];
    XCTAssert(b);
    b = [[self.vNSDictionary objectForKey:@"key2"] isEqualToNumber:@2];
    XCTAssert(b);

    XCTAssert([self argInSel:@selector(argInSel:)] == @selector(argInSel:));
    script = @"\
    spa_class(\"SpaConvertTest\") \n \
    function argInSel_(self, a) \n \
    self:setVSel_(a) \n \
    return a   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    XCTAssert([self argInSel:@selector(argInSel:)] == @selector(argInSel:));
    XCTAssert(self.vSel == @selector(argInSel:));
    
    XPoint xp;
    xp.x = 3;
    xp.y = 4;
    XPoint p = [self argInXPoint:xp];
    XCTAssert(p.x == 3 && p.y == 4);
    script = @"\
    spa_class(\"SpaConvertTest\") \n \
    function argInXPoint_(self, a)         \n \
    self:setVP_(a) \n \
    return a   \n \
    end                            \n";
    [[Spa sharedInstace] usePatch:script];
    p = [self argInXPoint:xp];
    XCTAssert(p.x == 3 && p.y == 4);
    XCTAssert(self.vP.x == 3 && self.vP.y == 4);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
