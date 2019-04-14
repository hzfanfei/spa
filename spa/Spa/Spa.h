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

#define SPA_MODULE "spa"

typedef void (^spa_log_block_t)(NSString *log);

@interface Spa : NSObject

+ (instancetype)sharedInstace;

- (void)usePatch:(NSString *)patch;
- (void)usePatchAppend:(NSString *)patch;

- (void)setLogBlock:(spa_log_block_t)block;

- (lua_State *)getLuaState;

@end
