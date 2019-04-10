//
//  SpaTrace.m
//  Spa
//
//  Created by Family Fan on 2018/12/13.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#import "SpaTrace.h"
#import "SpaSimplePing.h"
#import "Spa+Private.h"
#include <netdb.h>
#import "lauxlib.h"

@interface SpaTrace () <SpaSimplePingDelegate>

@property (nonatomic) SpaSimplePing* traceRoute;
@property (nonatomic, copy) spa_log_block_t logBlock;
@property NSTimer *sendTimer;
@property NSTimer *sendTimeoutTimer;
@property (nonatomic) NSString *ipAddress;
@property (nonatomic) NSString* host;
@property NSInteger sendCountDown;
@property NSInteger sendTimeout;
@property NSInteger sendSequence;
#define TRACERT_MAX_TTL 30
@property int currentTTL;               // ttl increase from number 1
@property NSInteger packetCountPerTTL;  // per RTT, send out 3 packets
@property NSDate *startDate;
@property (nonatomic) NSString *icmpSrcAddress;

@end

@implementation SpaTrace

static int traceStart(lua_State *L)
{
    const char* host = lua_tostring(L, -1);
    if (host == NULL) {
        return 0;
    }
    SpaTrace* st = [[Spa sharedInstace] spaTrace];
    [st stop];
    [st startWithHost:[NSString stringWithFormat:@"%s", host]];
    return 0;
}

static int traceStop(lua_State *L)
{
    SpaTrace* st = [[Spa sharedInstace] spaTrace];
    [st stop];
    
    return 0;
}

static const struct luaL_Reg Methods[] = {
    {"start", traceStart},
    {"stop", traceStop},
    {NULL, NULL}
};

- (void)setup:(lua_State *)L
{
    luaL_register(L, SPA_TRACE, Methods);
}

- (void)startWithHost:(NSString *)host
{
    self.traceRoute = [[SpaSimplePing alloc] initWithHostName:host];
    self.host = host;
    self.logBlock = [Spa sharedInstace].spaLogBlock;
    self.traceRoute.delegate = self;
    [self.traceRoute start];
}

#pragma mark - SimplePingDelegate

- (void)simplePing:(SpaSimplePing *)pinger didStartWithAddress:(NSData *)address
{
    self.ipAddress = [self displayAddressForAddress:address];
    NSString *msg = [NSString stringWithFormat:@"Tracert %@ (%@)\n", self.host, self.ipAddress];
    [self appendText:msg];
    
    self.currentTTL = 1; // init ttl
    [self sendPingWithTTL:self.currentTTL];
    
}

- (void)simplePing:(SpaSimplePing *)pinger didFailWithError:(NSError *)error
{
    NSString *msg = [NSString stringWithFormat:@"Failed to resolve %@", self.host];
    [self appendText:msg];
    [self stop];
}

- (void)simplePing:(SpaSimplePing *)pinger didSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber
{
    self.sendSequence = sequenceNumber;
    self.startDate = [NSDate date];
}

- (void)simplePing:(SpaSimplePing *)pinger didFailToSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber error:(NSError *)error
{
    NSLog(@"%s", __func__);
    NSLog(@"%@ %d %@", packet, sequenceNumber, error);
}

- (void)invalidSendTimer
{
    [self.sendTimer invalidate];
    self.sendTimer = nil;
}

- (void)simplePing:(SpaSimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber
{
    [self invalidSendTimer];
    [self.sendTimeoutTimer invalidate];
    if (sequenceNumber != self.sendSequence) {
        return;
    }
    NSString *msg = [NSString stringWithFormat:@"#%u reach the destination %@, test completed", sequenceNumber, self.ipAddress];
    [self appendText:msg];
    
    [self stop];
}

- (void)simplePing:(SpaSimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet
{
    NSString *msg;
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:self.startDate];
    NSString *srcAddr = [self.traceRoute srcAddrInIPv4Packet:packet];
    if (0 == self.packetCountPerTTL) {
        self.icmpSrcAddress = srcAddr;
        self.packetCountPerTTL += 1;
        msg = [NSString stringWithFormat:@"#%ld %@   %0.2lfms", (long)self.sendSequence, self.icmpSrcAddress, interval*1000];
    } else {
        self.packetCountPerTTL += 1;
        msg = [NSString stringWithFormat:@" %0.2lfms", interval*1000];
    }
    
    [self appendTextOneLine:msg];
    
    if (3 == self.packetCountPerTTL) {
        [self invalidSendTimer];
        [self appendText:@"\n"];
        [self sendPing];
    }
}

- (void)appendTextOneLine:(NSString *)msg
{
    if (self.logBlock) {
        self.logBlock(msg);
    }
}

- (void)appendText:(NSString *)msg
{
    if (self.logBlock) {
        self.logBlock([NSString stringWithFormat:@"%@\n", msg]);
    }
}

- (void)sendPingWithTTL:(int)ttl
{
    self.packetCountPerTTL = 0;
    
    [self.traceRoute setTTL:ttl];
    [self.traceRoute sendPing];
    
    self.sendTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(checkSingleRoundTimeout) userInfo:nil repeats:NO];
    
}

- (void)checkSingleRoundTimeout
{
    NSString *msg;
    switch (self.packetCountPerTTL) {
        case 0:
            msg = [NSString stringWithFormat:@"#%ld *  *  *\n", (long)self.sendSequence];
            break;
        case 1:
            msg = [NSString stringWithFormat:@"  *  *\n"];
            break;
        case 2:
            msg = [NSString stringWithFormat:@"  *\n"];
            break;
            
        default:
            break;
    }
    [self appendText:msg];
    
    [self sendPing];
}

- (BOOL)sendPing
{
    self.currentTTL += 1;
    if (self.currentTTL > TRACERT_MAX_TTL) {
        NSString *msg = [NSString stringWithFormat:@"TTL exceed the Max, stop the test"];
        [self appendText:msg];
        [self stop];
        return NO;
    }
    
    [self sendPingWithTTL:self.currentTTL];
    return YES;
}

- (void)stop
{
    [self.sendTimer invalidate];
    self.sendTimer = nil;
    [self.sendTimeoutTimer invalidate];
    self.sendTimeoutTimer = nil;
    
    [self.traceRoute stop];
    self.traceRoute = nil;
}

- (NSString *)displayAddressForAddress:(NSData *)address
{
    
#define    NI_MAXHOST    1025
#define    NI_NUMERICHOST    0x00000002
    int         err;
    NSString *  result;
    char        hostStr[NI_MAXHOST];
    
    result = nil;
    
    if (address != nil) {
        err = getnameinfo(address.bytes, (socklen_t) address.length, hostStr, sizeof(hostStr), NULL, 0, NI_NUMERICHOST);
        if (err == 0) {
            result = @(hostStr);
        }
    }
    
    if (result == nil) {
        result = @"?";
    }
    
    return result;
}

@end
