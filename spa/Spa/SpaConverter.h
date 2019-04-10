//
//  SpaConverter.h
//  Spa
//
//  Created by Family Fan on 2018/12/1.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "lua.h"

NS_ASSUME_NONNULL_BEGIN

@interface SpaConverter : NSObject

+ (void *)toOCObject:(lua_State *)L typeDescription:(const char *)typeDescription index:(int)index;

+ (int)toLuaObject:(lua_State *)L object:(id)object;

+ (int)toLuaObject:(lua_State *)L typeDescription:(const char *)typeDescription buffer:(void *)buffer;

@end

NS_ASSUME_NONNULL_END
