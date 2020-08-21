//
//  SpaInstance.m
//  Spa
//
//  Created by Family Fan on 2018/12/4.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#import "SpaInstance.h"
#import "SpaUtil.h"
#import "Spa+Private.h"
#import "SpaConverter.h"
#import "SpaDefine.h"
#import "lauxlib.h"
#import <objc/runtime.h>
#import <objc/message.h>

static int __index(lua_State *L)
{
    const char* func = lua_tostring(L, -1);
    if (func) {
        NSString* selector = [NSString stringWithFormat:@"%s", func];
        // if super
        if ([selector hasPrefix:SPA_SUPER_PREFIX]) {
            spa_safeInLuaStack(L, ^int{
                // make a super selector
                SEL superSelector = NSSelectorFromString(selector);
                SEL sel = NSSelectorFromString([selector substringFromIndex:[SPA_SUPER_PREFIX length]]);
                SpaInstanceUserdata* instance = lua_touserdata(L, -2);
                Class klass = object_getClass(instance->instance);
                Class superClass = class_getSuperclass(klass);
                Method superMethod = class_getInstanceMethod(superClass, sel);
                IMP superMethodImp = method_getImplementation(superMethod);
                char *typeDescription = (char *)method_getTypeEncoding(superMethod);
                BOOL b = class_addMethod(klass, superSelector, superMethodImp, typeDescription);
                assert(b);
                return 0;
            });
        }
        lua_pushcclosure(L, spa_invoke, 1);
        return 1;
    }
    return 0;
}

char *propName2funcName(const char *prop)
{
    if (!prop) {
        return NULL;
    }
    size_t len = strlen(prop) + 3 + 2;
    char* func = malloc(len);
    memset(func, 0, len);
    
    char c = prop[0];
    if(c >= 'a' && c <= 'z') {
        c = c - 32;
    }
    
    strcpy(func, "set");
    memset(func+3, c, 1);
    strcpy(func+4, prop+1);
    strcat(func, ":");
    return func;
}

static int __newIndex(lua_State *L)
{
    SpaInstanceUserdata* instance = lua_touserdata(L, -3);
    if (!instance || !instance->instance) {
        return 0;
    }
    const char* prop = lua_tostring(L, -2);
    char* func = propName2funcName(prop);
    if (!func) {
        return 0;
    }
    
    SEL sel = NSSelectorFromString([NSString stringWithFormat:@"%s", func]);
    Class klass = object_getClass(instance->instance);
    NSMethodSignature  *signature = [klass instanceMethodSignatureForSelector:sel];
    if (signature) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.target = instance->instance;
        invocation.selector = sel;
        const char* typeDescription = [signature getArgumentTypeAtIndex:2];
        if (typeDescription) {
            void *argValue = [SpaConverter toOCObject:L typeDescription:typeDescription index:-1];
            if (argValue == NULL) {
                id object = nil;
                [invocation setArgument:&object atIndex:2];
            } else {
                [invocation setArgument:argValue atIndex:2];
            }
            [invocation invoke];
        } else {
            NSString* error = [NSString stringWithFormat:@"can not found param [%@ %s]", klass, func];
            SPA_ERROR(L, error.UTF8String);
        }
    } else {
        NSString* error = [NSString stringWithFormat:@"can not found prop [%@ %s]", klass, func];
        SPA_ERROR(L, error.UTF8String);
    }
    free(func);
    return 0;
}

static bool isBlock(id object)
{
    Class klass = object_getClass(object);
    if (klass == NSClassFromString(@"__NSGlobalBlock__")
        || klass == NSClassFromString(@"__NSStackBlock__")
        || klass == NSClassFromString(@"__NSMallocBlock__")) {
        return true;
    }
    return false;
}

static int __call(lua_State *L)
{
    SpaInstanceUserdata* instance = lua_touserdata(L, 1);
    id object = instance->instance;
    if (isBlock(object)) {
        return spa_callBlock(L);
    }
    return 0;
}

static int __gc(lua_State *L)
{
    SpaInstanceUserdata* instance = lua_touserdata(L, -1);
    if (instance && !instance->isBlock && instance->instance) {
        [SpaInstance createInstanceUserData:L object:instance->instance];
    }
    return 0;
}

static const struct luaL_Reg Methods[] = {
    {NULL, NULL}
};

static const struct luaL_Reg MetaMethods[] = {
    {"__index", __index},
    {"__newindex", __newIndex},
    {"__call", __call},
    {"__gc", __gc},
    {NULL, NULL}
};

@implementation SpaInstance

- (void)setup:(lua_State *)L
{
    luaL_register(L, SPA_INSTANCE, Methods);
    luaL_newmetatable(L, SPA_INSTANCE_META_TABLE);
    luaL_register(L, NULL, MetaMethods);
    luaL_newmetatable(L, SPA_INSTANCE_LIST_TABLE);
    
    lua_newtable(L);
    lua_pushstring(L, "k");
    lua_setfield(L, -2, "__mode");  // Make weak table
    lua_setmetatable(L, -2);
}

+ (int)createInstanceUserData:(lua_State *)L object:(id)object
{
    return spa_safeInLuaStack(L, ^int{
//        printf("create instance\n");
//        spa_stackDump(L);
        // get from table
        luaL_getmetatable(L, SPA_INSTANCE_LIST_TABLE);
        lua_pushlightuserdata(L, (__bridge void *)(object));
        lua_rawget(L, -2);
        lua_remove(L, -2); // remove userdataTable
        
        // if create already, not create any more
        if (lua_isnil(L, -1)) {
            lua_pop(L, 1); // pop nil stack
            size_t nbytes = sizeof(SpaInstanceUserdata);
            SpaInstanceUserdata *instance = (SpaInstanceUserdata *)lua_newuserdata(L, nbytes);
            instance->instance = object;
            instance->isBlock = isBlock(object);
            
            luaL_getmetatable(L, SPA_INSTANCE_META_TABLE);
            lua_setmetatable(L, -2);
            
            // block not push in weak table
            if (!instance->isBlock) {
                luaL_getmetatable(L, SPA_INSTANCE_LIST_TABLE);
                // copy a userdata on stack
                lua_pushlightuserdata(L, (__bridge void *)(instance->instance));
                lua_pushvalue(L, -3);
                lua_rawset(L, -3);
                lua_pop(L, 1); // pop list table
            }
            
            // clean env
            lua_newtable(L);
            lua_setfenv(L, -2);
        } else {
            if ([object isKindOfClass:NSClassFromString(@"TestViewController").class]) {
                spa_stackDump(L);
                NSLog(@"[SPASELF] not nil ? %@",object);
            }
        }
        return 1;
    });
}


@end
