//
//  Spa+Private.h
//  Spa
//
//  Created by Family Fan on 2018/12/1.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#ifndef Spa_Private_h
#define Spa_Private_h

#import "Spa.h"
#import "lua.h"

@class SpaTrace;
@interface Spa(Private)

- (lua_State *)lua_state;
- (SpaTrace *)spaTrace;
- (spa_log_block_t)spaLogBlock;
- (spa_complete_block_t)spaCompleteBlock;
@end

#endif /* Spa_Private_h */
