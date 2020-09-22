//
//  SpaUtil.m
//  Spa
//
//  Created by Family Fan on 2018/11/30.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#import "SpaUtil.h"
#import "SpaDefine.h"
#import "SpaBlockDescription.h"
#import "SpaInstance.h"
#import "SpaConverter.h"
#import "lauxlib.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <os/lock.h>
#import <libkern/OSAtomic.h>

#define SPA_BEGIN_STACK_MODIFY(L) int __startStackIndex = lua_gettop((L));
#define SPA_END_STACK_MODIFY(L, i) while(lua_gettop((L)) > (__startStackIndex + (i))) lua_remove((L), __startStackIndex + 1);

int spa_safeInLuaStack(lua_State *L, spa_lua_save_stack_block_t block)
{
    return spa_performLocked(^int{
        int result = 0;
        SPA_BEGIN_STACK_MODIFY(L)
        if (block) {
            result = block();
        }
        SPA_END_STACK_MODIFY(L, result)
        return result;
    });
}

static NSRecursiveLock *lock = nil;

int spa_performLocked(spa_lua_perfrom_locked_block_t block) {
    int result = 0;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        lock = [[NSRecursiveLock alloc] init];
    });
    [lock lock];
    result = block();
    [lock unlock];
    return result;
}

void traverse_table(lua_State *L, int index)
{
    lua_pushnil(L);
    while (lua_next(L, index)) {
        lua_pushvalue(L, -2);
        const char* key = lua_tostring(L, -1);
        int type = lua_type(L, -2);
        printf("%s => type %s", key, lua_typename(L, type));
        switch (type) {
            case LUA_TNUMBER:
                printf(" value=%f", lua_tonumber(L, -2));
                break;
            case LUA_TSTRING:
                printf(" value=%s", lua_tostring(L, -2));
                break;
            case LUA_TFUNCTION:
                if (lua_iscfunction(L, -2)) {
                    printf(" C:%p", lua_tocfunction(L, -2));
                }
        }
        printf("\n");
        lua_pop(L, 2);
    }
}

void spa_stackDump(lua_State *L) {
    printf("------------ spa_stackDump begin ------------\n");
    int top = lua_gettop(L);
    for (int i = 0; i < top; i++) {
        int positive = top - i;
        int negative = -(i + 1);
        int type = lua_type(L, positive);
        int typeN = lua_type(L, negative);
        assert(type == typeN);
        const char* typeName = lua_typename(L, type);
        printf("%d/%d: type=%s", positive, negative, typeName);
        switch (type) {
            case LUA_TNUMBER:
                printf(" value=%f", lua_tonumber(L, positive));
                break;
            case LUA_TSTRING:
                printf(" value=%s", lua_tostring(L, positive));
                break;
            case LUA_TFUNCTION:
                if (lua_iscfunction(L, positive)) {
                    printf(" C:%p", lua_tocfunction(L, positive));
                }
            case LUA_TTABLE:
                if (lua_istable(L, positive)) {
                    printf("\nvalue=\n{\n");
                    traverse_table(L, positive);
                    printf("}\n");
                }
                break;
        }
        printf("\n");
    }
    printf("------------ spa_stackDump end ------------\n\n");
}

char spa_getTypeFromTypeDescription(const char *typeDescription)
{
    char type = typeDescription[0];
    switch (type) {
        case 'r':
        case 'n':
        case 'N':
        case 'o':
        case 'O':
        case 'R':
        case 'V':
            type = typeDescription[1];
            break;
    }
    if (type == _C_PTR) {
        type = @encode(long)[0];
    } else if (type == 'l') {
        #if __LP64__
        type = 'q';
        #endif
    } else if (type == 'g') {
        if (sizeof(CGFloat) == sizeof(double)) {
            type = 'd';
        } else {
            type = 'f';
        }
    }
    return type;
}

const char* spa_toObjcSel(const char *luaFuncName)
{
    NSString* __autoreleasing s = [NSString stringWithFormat:@"%s", luaFuncName];
    s = [s stringByReplacingOccurrencesOfString:@"__" withString:@"!"];
    s = [s stringByReplacingOccurrencesOfString:@"_" withString:@":"];
    s = [s stringByReplacingOccurrencesOfString:@"!" withString:@"_"];
    return s.UTF8String;
}

const char* spa_toLuaFuncName(const char *objcSel)
{
    NSString* __autoreleasing s = [NSString stringWithFormat:@"%s", objcSel];
    s = [s stringByReplacingOccurrencesOfString:@"_" withString:@"__"];
    s = [s stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    return s.UTF8String;
}

SEL spa_originForSelector(SEL sel)
{
    NSCParameterAssert(sel);
    return NSSelectorFromString([SPA_ORIGIN_PREFIX stringByAppendingFormat:@"%@", NSStringFromSelector(sel)]);
}

int spa_callBlock(lua_State *L)
{
    SpaInstanceUserdata* instance = lua_touserdata(L, 1);
    id block = instance->instance;
    SpaBlockDescription* blockDescription = [[SpaBlockDescription alloc] initWithBlock:block];
    NSMethodSignature *signature = blockDescription.blockSignature;
    
    int nresults = [signature methodReturnLength] ? 1 : 0;
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:block];
    
    for (NSUInteger i = 1; i < [signature numberOfArguments]; i++) {
        const char *typeDescription = [signature getArgumentTypeAtIndex:i];
        void *pReturnValue = [SpaConverter toOCObject:L typeDescription:typeDescription index:-1];
        [invocation setArgument:pReturnValue atIndex:i];
    }
    
    [invocation invoke];
    
    if (nresults > 0) {
        const char *typeDescription = [signature methodReturnType];
        char type = spa_getTypeFromTypeDescription(typeDescription);
        if (type == @encode(id)[0] || type == @encode(Class)[0]) {
            __unsafe_unretained id object = nil;
            [invocation getReturnValue:&object];
            [SpaConverter toLuaObject:L object:object];
        } else {
            NSUInteger size = 0;
            NSGetSizeAndAlignment(typeDescription, &size, NULL);
            void *buffer = malloc(size);
            [invocation getReturnValue:buffer];
            [SpaConverter toLuaObject:L typeDescription:typeDescription buffer:buffer];
            free(buffer);
        }
    }
    
    return nresults;
}

int spa_invoke(lua_State *L)
{
    return spa_safeInLuaStack(L, ^int{
        SpaInstanceUserdata* instance = lua_touserdata(L, 1);
        if (instance && instance->instance) {
            Class klass = object_getClass(instance->instance);
            const char* func = lua_tostring(L, lua_upvalueindex(1));
            
            // May be you call class function user static prefix, need to be remove
            NSString* selectorName = [NSString stringWithFormat:@"%s", spa_toObjcSel(func)];
            selectorName = [selectorName stringByReplacingOccurrencesOfString:SPA_STATIC_PREFIX withString:@""];
            
            SEL sel = NSSelectorFromString(selectorName);
            NSMethodSignature  *signature = [klass instanceMethodSignatureForSelector:sel];
            if (signature) {
                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
                invocation.target = instance->instance;
                invocation.selector = sel;
                
                // args
                int nresults = [signature methodReturnLength] ? 1 : 0;
                for (int i = 2; i < [signature numberOfArguments]; i++) {
                    const char* typeDescription = [signature getArgumentTypeAtIndex:i];
                    void *argValue = [SpaConverter toOCObject:L typeDescription:typeDescription index:i];
                    if (argValue == NULL) {
                        id object = nil;
                        [invocation setArgument:&object atIndex:i];
                    } else {
                        [invocation setArgument:argValue atIndex:i];
                    }
                }
                [invocation invoke];
                
                if (nresults > 0) {
                    const char *typeDescription = [signature methodReturnType];
                    char type = spa_getTypeFromTypeDescription(typeDescription);
                    if (type == @encode(id)[0] || type == @encode(Class)[0]) {
                        __unsafe_unretained id object = nil;
                        [invocation getReturnValue:&object];
                        [SpaConverter toLuaObject:L object:object];
                    } else {
                        NSUInteger size = 0;
                        NSGetSizeAndAlignment(typeDescription, &size, NULL);
                        void *buffer = malloc(size);
                        [invocation getReturnValue:buffer];
                        [SpaConverter toLuaObject:L typeDescription:typeDescription buffer:buffer];
                        free(buffer);
                    }
                }
                return nresults;
            } else {
                NSString* error = [NSString stringWithFormat:@"selector %s not be found in %@. You may need to use ‘_’ to indicate that there are parameters. If your selector is 'function:', use 'function_', if your selector is 'function:a:b:', use 'function_a_b_'", func, klass];
                SPA_ERROR(L, error.UTF8String);
                return 0;
            }
        }
        return 0;
    });
}

NSArray * spa_parseStructFromTypeDescription(NSString *typeDes)
{
    if (typeDes.length == 0) {
        return nil;
    }
    
    NSError* error = nil;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"^\\{([A-Za-z0-9_]+)=" options:NSRegularExpressionCaseInsensitive error:&error];
    assert(error == nil);
    NSTextCheckingResult *match = [regex firstMatchInString:typeDes options:0 range:NSMakeRange(0, typeDes.length)];
    NSString* klass = match.numberOfRanges > 0?[typeDes substringWithRange:[match rangeAtIndex:1]]:nil;
    error = nil;
    regex = [NSRegularExpression regularExpressionWithPattern:@"=([a-z]+)\\}" options:NSRegularExpressionCaseInsensitive error:&error];
    assert(error == nil);
    NSMutableString* des = [NSMutableString string];
    NSArray *matches = [regex matchesInString:typeDes options:0 range:NSMakeRange(0, typeDes.length)];
    for (NSTextCheckingResult *match in matches) {
        NSRange range = [match rangeAtIndex:1];
        [des appendString:[typeDes substringWithRange:range]];
    }
    
    // fix CGFloat
    NSMutableString* rdes = [NSMutableString string];
    for (int i = 0; i < des.length; i++) {
        char c = [des characterAtIndex:i];
        if (c == 'g') {
            if (sizeof(CGFloat) == sizeof(double)) {
                c = 'd';
            } else {
                c = 'f';
            }
        }
        [rdes appendString:[NSString stringWithFormat:@"%c", c]];
    }
    
    if (klass.length > 0 && rdes.length > 0) {
        return @[klass, rdes];
    } else {
        return nil;
    }
}
