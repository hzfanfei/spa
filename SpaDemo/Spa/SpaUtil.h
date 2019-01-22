//
//  SpaUtil.h
//  Spa
//
//  Created by Family Fan on 2018/11/30.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "lua.h"

#define SPA_ERROR(L, err) luaL_error(L, "[Spa] error %s line %d %s: %s", __FILE__, __LINE__, __FUNCTION__, err);

typedef int (^spa_lua_save_stack_block_t)(void);
typedef int (^spa_lua_perfrom_locked_block_t)(void);

extern int spa_safeInLuaStack(lua_State *L, spa_lua_save_stack_block_t block);

extern int spa_performLocked(spa_lua_perfrom_locked_block_t block);

extern void spa_stackDump(lua_State *L);

extern char spa_getTypeFromTypeDescription(const char *typeDescription);

extern const char* spa_toObjcSel(const char *luaFuncName);

extern const char* spa_toLuaFuncName(const char *objcSel);

extern SEL spa_originForSelector(SEL sel);

extern int spa_callBlock(lua_State *L);

extern int spa_invoke(lua_State *L);

extern NSArray* spa_parseStructFromTypeDescription(NSString *typeDes);
