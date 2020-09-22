//
//  SpaConverter.m
//  Spa
//
//  Created by Family Fan on 2018/12/1.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#import "SpaConverter.h"
#import "SpaUtil.h"
#import "SpaDefine.h"
#import "SpaInstance.h"
#import "SpaBlockInstance.h"
#import "lauxlib.h"
#import <objc/runtime.h>
#import <malloc/malloc.h>

#define SPA_LUA_NUMBER_CONVERT(T) else if (type == @encode(T)[0]) { lua_pushnumber(L, *(T *)buffer); }

typedef void (^spa_hoder_free_block_t)(void);

@interface SpaHoderHelper : NSObject

@property (nonatomic, copy) spa_hoder_free_block_t block;

@end

@implementation SpaHoderHelper

- (instancetype)init:(spa_hoder_free_block_t)block
{
    self = [super init];
    if (self) {
        self.block = block;
    }
    return self;
}

-(void)dealloc
{
    if (self.block) {
        self.block();
    }
}

@end

@implementation SpaConverter

+ (void *)toStruct:(lua_State *)L typeDescription:(const char *)typeDescription index:(int)index
{
    NSArray* class2des = spa_parseStructFromTypeDescription([NSString stringWithUTF8String:typeDescription]);
    if (class2des.count > 1) {
        NSString* className = class2des[0];
        className = [NSString stringWithFormat:@"SPA_%@", className];
        NSString* des = class2des[1];
        
        size_t item_count = strlen(des.UTF8String);
        // create a class
        Class klass = objc_allocateClassPair([NSObject class], [className UTF8String], 0);
        // already exist
        if (klass == nil) {
            klass = NSClassFromString(className);
        } else {
            BOOL success = YES;
            for (int i = 0; i < item_count; i++) {
                char type = des.UTF8String[i];
                NSUInteger size;
                NSUInteger alingment;
                NSGetSizeAndAlignment(&type, &size, &alingment);
                success = class_addIvar(klass, [NSString stringWithFormat:@"x%d", i].UTF8String, size, log2(alingment), &type);
                if (!success) {
                    break;
                }
            }
            if (!success) {
                objc_disposeClassPair(klass);
                SPA_ERROR(L, "toStruct function create class failed !");
                return NULL;
            }
            
            objc_registerClassPair(klass);
        }
        
        id __autoreleasing object = [[klass alloc] init];
        for (int i = 1; i <= item_count; i++) {
            lua_pushinteger(L, i);
            lua_gettable(L, index);
            [object setValue:@(lua_tonumber(L, -1)) forKey:[NSString stringWithFormat:@"x%d", i-1]];
            lua_pop(L, 1);
        }
        void* p = (__bridge void *)object;
        p = p + sizeof(void *);
        return p;
    }
    return NULL;
}

+ (void *)createOneKeyHoderObjectPtr:(lua_State *)L type:(const char)type value:(id)value
{
    if (value == nil) {
        return NULL;
    }
    
    BOOL success = YES;
    NSString* className = [NSString stringWithFormat:@"SpaHolderClass_%c", type];
    Class klass = objc_allocateClassPair([NSObject class], className.UTF8String, 0);
    if (klass == nil) {
        klass = NSClassFromString(className);
    } else {
        NSUInteger size;
        NSUInteger alingment;
        NSGetSizeAndAlignment(&type, &size, &alingment);
        success = class_addIvar(klass, "key", size, log2(alingment), &type);
        
        if (!success) {
            luaL_error(L, "[SPA] create %c number class failed !", type);
            return NULL;
        }
        
        objc_registerClassPair(klass);
    }
    id __autoreleasing object = [[klass alloc] init];
    [object setValue:value forKey:@"key"];
    void* p = (__bridge void *)object;
    p = p + sizeof(void *);
    return p;
}

+ (void *)toOCObject:(lua_State *)L typeDescription:(const char *)typeDescription index:(int)index
{
    char type = spa_getTypeFromTypeDescription(typeDescription);
    
    if (type == @encode(void)[0]) {
        return NULL;
    }
    if (type == @encode(char *)[0]) {
        const char* string = lua_tostring(L, index);
        void* p = malloc(strlen(string) + 1);
        memset(p, 0, strlen(string) + 1);
        strcpy(p, string);
        struct S {
            char *p;
        };
        struct S* s = malloc(sizeof(struct S));
        s->p = p;
        __unused SpaHoderHelper* __autoreleasing sh = [[SpaHoderHelper alloc] init:^void{
            free(p);
            free(s);
        }];
        return s;
    } else if (type == @encode(SEL)[0]) {
        const char* string = lua_tostring(L, index);
        struct S {
            SEL p;
        };
        struct S* s = malloc(sizeof(struct S));
        s->p = NSSelectorFromString([NSString stringWithUTF8String:string]);
        __unused SpaHoderHelper* __autoreleasing sh = [[SpaHoderHelper alloc] init:^void{
            free(s);
        }];
        return s;
    } else if (type == @encode(char)[0]) {
        char c = lua_tostring(L, index)[0];
        return [self createOneKeyHoderObjectPtr:L type:type value:@(c)];
    } else if (type == @encode(bool)[0]) {
        return [self createOneKeyHoderObjectPtr:L type:type value:@(lua_toboolean(L, index))];
    } else if (type == @encode(id)[0]) {
        switch (lua_type(L, index)) {
            case LUA_TNIL:
            case LUA_TNONE:
                return NULL;
            case LUA_TBOOLEAN:
                return [self createOneKeyHoderObjectPtr:L type:type value:@(lua_toboolean(L, index))];
            case LUA_TNUMBER:
                return [self createOneKeyHoderObjectPtr:L type:type value:@(lua_tonumber(L, index))];
            case LUA_TSTRING:
            {
                id string = [NSString stringWithUTF8String:lua_tostring(L, index)];
                return [self createOneKeyHoderObjectPtr:L type:type value:string];
            }
            case LUA_TTABLE:
            {
                BOOL dictionary = NO;
                
                lua_pushvalue(L, index); // Push the table reference on the top
                lua_pushnil(L);  /* first key */
                
                while (!dictionary && lua_next(L, -2)) {
                    if (lua_type(L, -2) != LUA_TNUMBER) {
                        dictionary = YES;
                        lua_pop(L, 2); // pop key and value off the stack
                    }
                    else {
                        lua_pop(L, 1);
                    }
                }
                
                id instance = nil;
                if (dictionary) {
                    instance = [NSMutableDictionary dictionary];
                    lua_pushnil(L);  /* first key */
                    while (lua_next(L, -2)) {
                        struct S
                        {
                            id instance;
                        };
                        id key = ((struct S*)[SpaConverter toOCObject:L typeDescription:"@" index:-2])->instance;
                        id object = ((struct S*)[SpaConverter toOCObject:L typeDescription:"@" index:-1])->instance;
                        [instance setObject:object forKey:key];
                        lua_pop(L, 1); // Pop off the value
                    }
                } else {
                    instance = [NSMutableArray array];
                    lua_pushnil(L);  /* first key */
                    while (lua_next(L, -2)) {
                        int index = lua_tonumber(L, -2) - 1;
                        struct S
                        {
                            id instance;
                        };
                        struct S* s = [SpaConverter toOCObject:L typeDescription:"@" index:-1];
                        [instance insertObject:s->instance atIndex:index];
                        lua_pop(L, 1);
                    }
                }
                lua_pop(L, 1); // Pop the table reference off
                return [self createOneKeyHoderObjectPtr:L type:type value:instance];
            }
            case LUA_TUSERDATA:
            {
                SpaInstanceUserdata* userdata = lua_touserdata(L, index);
                if (userdata && userdata->instance) {
                    return [self createOneKeyHoderObjectPtr:L type:type value:userdata->instance];
                } else {
                    return NULL;
                }
            }
            case LUA_TFUNCTION:
            {
                __block NSString* returnType = nil;
                NSMutableArray* argsType = [NSMutableArray array];
                
                SpaBlockInstance* instance = [[SpaBlockInstance alloc] init];
                
                spa_safeInLuaStack(L, ^int{
                    lua_getfenv(L, index);
                    
                    // get return type
                    lua_getfield(L, -1, "return_type");
                    
                    const char* return_type = lua_tostring(L, -1);
                    if (return_type) {
                        returnType = [NSString stringWithUTF8String:return_type];
                    }
                    // get params type
                    lua_getfield(L, -2, "args_type");
                    
                    if (!lua_isnil(L, -1)) {
                        lua_pushnil(L);
                        while (lua_next(L, -2)) {
                            int type = lua_type(L, -1);
                            if (type == LUA_TSTRING) {
                                const char * arg_type = lua_tostring(L, -1);
                                if (arg_type) {
                                    [argsType addObject:[NSString stringWithUTF8String:arg_type]];
                                }
                                lua_pop(L, 1);
                            }
                        }
                    }
                    
                    return 0;
                });
                
                [SpaInstance createInstanceUserData:L object:instance];
                
                // set lua function to env
                lua_newtable(L);
                lua_pushstring(L, "f");
                lua_pushvalue(L, index);
                lua_settable(L, -3);
                lua_setfenv(L, -2);
                
                if (returnType.length == 0 && argsType.count == 0) {
                    return [self createOneKeyHoderObjectPtr:L type:type value:[instance voidBlock]];
                } else {
                    return [self createOneKeyHoderObjectPtr:L type:type value:[instance blockWithParamsTypeArray:argsType returnType:returnType]];
                }
            }
            default:
            {
                NSString* error = [NSString stringWithFormat:@"type %s in not support !", typeDescription];
                SPA_ERROR(L, error.UTF8String);
                return NULL;
            }
        }
    } else if (type == _C_STRUCT_B) {
        return [self toStruct:L typeDescription:typeDescription index:index];
    } else if (type == @encode(int)[0] ||
               type == @encode(short)[0] ||
               type == @encode(long)[0] ||
               type == @encode(long long)[0] ||
               type == @encode(unsigned int)[0] ||
               type == @encode(unsigned short)[0] ||
               type == @encode(unsigned long)[0] ||
               type == @encode(unsigned long long)[0] ||
               type == @encode(float)[0] ||
               type == @encode(double)[0]) {
        return [self createOneKeyHoderObjectPtr:L type:type value:@(lua_tonumber(L, index))];
    } else {
        NSString* error = [NSString stringWithFormat:@"type %s in not support !", typeDescription];
        SPA_ERROR(L, error.UTF8String);
        return NULL;
    }
    return NULL;
}

+ (int)toLuaObject:(lua_State *)L object:(id)object
{
    return spa_safeInLuaStack(L, ^int{
        if ([object isKindOfClass:[NSString class]]) {
            lua_pushstring(L, [object UTF8String]);
        } else if ([object isKindOfClass:[NSNumber class]]) {
            lua_pushnumber(L, [object doubleValue]);
        } else if ([object isKindOfClass:[NSArray class]]) {
            lua_newtable(L);
            for (NSInteger i = 0; i < [object count]; i++) {
                lua_pushnumber(L, i+1);
                [SpaConverter toLuaObject:L object:object[i]];
                lua_settable(L, -3);
            }
        } else if ([object isKindOfClass:[NSDictionary class]]) {
            lua_newtable(L);
            [object enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                [SpaConverter toLuaObject:L object:key];
                [SpaConverter toLuaObject:L object:obj];
                lua_settable(L, -3);
            }];
        } else {
            [SpaInstance createInstanceUserData:L object:object];
        }
        return 1;
    });
}

+ (int)toLuaTableFromStruct:(lua_State *)L typeDescription:(const char *)typeDescription buffer:(void *)buffer
{
    // create object
    NSArray* class2des = spa_parseStructFromTypeDescription([NSString stringWithUTF8String:typeDescription]);
    if (class2des.count > 1) {
        NSString* className = class2des[0];
        className = [NSString stringWithFormat:@"SPA_%@", className];
        NSString* des = class2des[1];
        
        size_t item_count = strlen(des.UTF8String);
        // create a class
        Class klass = objc_allocateClassPair([NSObject class], [className UTF8String], 0);
        // already exist
        if (klass == nil) {
            klass = NSClassFromString(className);
        } else {
            BOOL success = YES;
            for (int i = 0; i < item_count; i++) {
                char type = des.UTF8String[i];
                NSUInteger size;
                NSUInteger alingment;
                NSGetSizeAndAlignment(&type, &size, &alingment);
                success = class_addIvar(klass, [NSString stringWithFormat:@"x%d", i].UTF8String, size, log2(alingment), &type);
                if (!success) {
                    break;
                }
            }
            if (!success) {
                objc_disposeClassPair(klass);
                SPA_ERROR(L, "toStruct function create class failed !");
                return 0;
            }
            
            objc_registerClassPair(klass);
        }
        
        id __autoreleasing object = [[klass alloc] init];
        void* p = (__bridge void *)object;
        p = p + sizeof(void *);
        memcpy(p, buffer, class_getInstanceSize(klass) - sizeof(void *));
        
        lua_newtable(L);
        for (int i = 1; i <= item_count; i++) {
            NSString* key = [NSString stringWithFormat:@"x%d", i-1];
            NSNumber* value = [object valueForKey:key];
            if ([value isKindOfClass:[NSNumber class]]) {
                lua_pushnumber(L, i);
                lua_pushnumber(L, value.doubleValue);
                lua_settable(L, -3);
            } else {
                SPA_ERROR(L, "struct type only support number type or ptr type");
            }
        }
    }
    return 1;
}

+ (int)toLuaObject:(lua_State *)L typeDescription:(const char *)typeDescription buffer:(void *)buffer
{
    return spa_safeInLuaStack(L, ^int{
        char type = spa_getTypeFromTypeDescription(typeDescription);
        if (type == @encode(bool)[0]) {
            lua_pushboolean(L, *(bool *)buffer);
        } else if (type == @encode(char *)[0] || type == @encode(SEL)[0]) {
            lua_pushstring(L, *(char **)buffer);
        } else if (type == @encode(char)[0]) {
            char s[2];
            s[0] = *(char *)buffer;
            s[1] = '\0';
            lua_pushstring(L, s);
        } else if (type == _C_STRUCT_B) {
            [SpaConverter toLuaTableFromStruct:L typeDescription:typeDescription buffer:buffer];
        }
        SPA_LUA_NUMBER_CONVERT(char)
        SPA_LUA_NUMBER_CONVERT(unsigned char)
        SPA_LUA_NUMBER_CONVERT(int)
        SPA_LUA_NUMBER_CONVERT(short)
        SPA_LUA_NUMBER_CONVERT(long)
        SPA_LUA_NUMBER_CONVERT(long long)
        SPA_LUA_NUMBER_CONVERT(unsigned int)
        SPA_LUA_NUMBER_CONVERT(unsigned long)
        SPA_LUA_NUMBER_CONVERT(unsigned long long)
        SPA_LUA_NUMBER_CONVERT(float)
        SPA_LUA_NUMBER_CONVERT(double)
        else {
            NSString* error = [NSString stringWithFormat:@"type %s in not support !", typeDescription];
            SPA_ERROR(L, error.UTF8String);
            return 0;
        }
        return 1;
    });
}

@end
