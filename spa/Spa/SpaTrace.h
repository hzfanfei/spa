//
//  SpaTrace.h
//  Spa
//
//  Created by Family Fan on 2018/12/13.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "lua.h"

#define SPA_TRACE "spa.trace"

NS_ASSUME_NONNULL_BEGIN

@interface SpaTrace : NSObject

- (void)setup:(lua_State *)L;

@end

NS_ASSUME_NONNULL_END
