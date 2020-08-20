//
//  Spa.h
//  Spa
//
//  Created by Family Fan on 2018/11/29.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "lauxlib.h"
#import "lobject.h"
#import "lualib.h"
#import "SpaClass.h"

#define SPA_MODULE "spa"

typedef void (^spa_log_block_t)(NSString *log);
typedef void (^spa_complete_block_t)(BOOL complete,NSString *log);

@interface Spa : NSObject

+ (instancetype)sharedInstace;

- (void)usePatch:(NSString *)patch;
- (void)usePatchAppend:(NSString *)patch;
- (void)usePatch:(NSString *)patch complete:(spa_complete_block_t)completeBlock;

- (void)setLogBlock:(spa_log_block_t)block;
- (void)setCompleteBlock:(spa_complete_block_t)complete;
- (void)setSwizzleBlock:(spa_complete_block_t)block;

- (lua_State *)getLuaState;

@end
