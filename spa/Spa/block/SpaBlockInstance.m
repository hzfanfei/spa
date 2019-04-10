//
//  SpaBlockInstance.m
//  Spa
//
//  Created by Family Fan on 2018/12/10.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#import "SpaBlockInstance.h"
#import "SpaUtil.h"
#import "Spa+Private.h"
#import "SpaInstance.h"
#import "SpaDynamicBlock.h"
#import "SpaConverter.h"
#import "lauxlib.h"

@implementation SpaBlockInstance

-(void (^)(void))voidBlock
{
    return ^() {
        lua_State* L = [Spa sharedInstace].lua_state;
        spa_safeInLuaStack(L, ^int{
            luaL_getmetatable(L, SPA_INSTANCE_LIST_TABLE);
            lua_pushlightuserdata(L, (__bridge void *)(self));
            lua_rawget(L, -2);
            lua_remove(L, -2); // remove userdataTable
            
            // get function
            lua_getfenv(L, -1);
            lua_getfield(L, -1, "f");
            
            if (!lua_isnil(L, -1) && lua_type(L, -1) == LUA_TFUNCTION) {
                lua_call(L, 0, 0);
            }
            return 0;
        });
    };
}

- (id)blockWithParamsTypeArray:(NSArray *)paramsTypeArray returnType:(NSString *)returnType
{
    SpaDynamicBlock* __autoreleasing blk = [[SpaDynamicBlock alloc] initWithArgsTypes:paramsTypeArray retType:returnType replaceBlock:^void *(void **args) {
        
        __block void *returnBuffer = nil;
        
        lua_State* L = [Spa sharedInstace].lua_state;
        spa_safeInLuaStack(L, ^int{
            
            luaL_getmetatable(L, SPA_INSTANCE_LIST_TABLE);
            lua_pushlightuserdata(L, (__bridge void *)(self));
            lua_rawget(L, -2);
            lua_remove(L, -2); // remove userdataTable
            
            // get function
            lua_getfenv(L, -1);
            lua_getfield(L, -1, "f");
            
            if (lua_isnil(L, -1) || lua_type(L, -1) != LUA_TFUNCTION) {
                return 0;
            }
            
            // push args
            [paramsTypeArray enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isEqualToString:DyIdType]) {
                    struct S
                    {
                        id instance;
                    };
                    struct S* s = (struct S*)args[idx+1];
                    [SpaConverter toLuaObject:L object:s->instance];
                } else {
                    [SpaConverter toLuaObject:L typeDescription:obj.UTF8String buffer:args[idx+1]];
                }
            }];
            
            NSUInteger paramNum = [paramsTypeArray count];
            
            if (returnType == nil) {
                lua_call(L, (int)paramNum, 0);
            } else {
                lua_call(L, (int)paramNum, 1);
                returnBuffer = [SpaConverter toOCObject:L typeDescription:returnType.UTF8String index:-1];
            }
            
            return 0;
        });
        return returnBuffer;
    }];
    return blk.invokeBlock;
}

@end
