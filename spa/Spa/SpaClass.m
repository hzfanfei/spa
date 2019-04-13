//
//  SpaClass.m
//  Spa
//
//  Created by Family Fan on 2018/11/30.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#import "SpaClass.h"
#import "SpaUtil.h"
#import "Spa+Private.h"
#import "SpaConverter.h"
#import "SpaDefine.h"
#import "SpaInstance.h"
#import "lauxlib.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation SpaClass

static void spa_swizzleForwardInvocation(Class klass)
{
    NSCParameterAssert(klass);
    // get origin forwardInvocation impl, include superClass impl，not NSObject impl, and class method to kClass
    SEL originForwardSelector = NSSelectorFromString(SPA_ORIGIN_FORWARD_INVOCATION_SELECTOR_NAME);
    if (![klass instancesRespondToSelector:originForwardSelector]) {
        Method originalMethod = class_getInstanceMethod(klass, @selector(forwardInvocation:));
        IMP originalImplementation = method_getImplementation(originalMethod);
        class_addMethod(klass, NSSelectorFromString(SPA_ORIGIN_FORWARD_INVOCATION_SELECTOR_NAME), originalImplementation, "v@:@");
        
    }
    // If there is no method, replace will act like class_addMethod.
    class_replaceMethod(klass, @selector(forwardInvocation:), (IMP)__SPA_ARE_BEING_CALLED__, "v@:@");
}

// reference from aspect
__unused static BOOL spa_isMsgForwardIMP(IMP impl)
{
    return impl == _objc_msgForward
#if !defined(__arm64__)
    || impl == (IMP)_objc_msgForward_stret
#endif
    ;
}

static IMP spa_getMsgForwardIMP(Class kClass, SEL selector)
{
    IMP msgForwardIMP = _objc_msgForward;
#if !defined(__arm64__)
    // As an ugly internal runtime implementation detail in the 32bit runtime, we need to determine of the method we hook returns a struct or anything larger than id.
    // https://developer.apple.com/library/mac/documentation/DeveloperTools/Conceptual/LowLevelABI/000-Introduction/introduction.html
    // https://github.com/ReactiveCocoa/ReactiveCocoa/issues/783
    // http://infocenter.arm.com/help/topic/com.arm.doc.ihi0042e/IHI0042E_aapcs.pdf (Section 5.4)
    Method method = class_getInstanceMethod(kClass, selector);
    const char *typeDescription = method_getTypeEncoding(method);
    if (typeDescription[0] == '{') {
        //In some cases that returns struct, we should use the '_stret' API:
        //http://sealiesoftware.com/blog/archive/2008/10/30/objc_explain_objc_msgSend_stret.html
        //NSMethodSignature knows the detail but has no API to return, we can only get the info from debugDescription.
        NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:typeDescription];
        if ([methodSignature.debugDescription rangeOfString:@"is special struct return? YES"].location != NSNotFound) {
            msgForwardIMP = (IMP)_objc_msgForward_stret;
        }
    }
#endif
    return msgForwardIMP;
}

static BOOL isReplaceBySpa(Class klass, SEL sel) {
    SEL originSelector = spa_originForSelector(sel);
    return [klass instancesRespondToSelector:originSelector];
}

+ (NSMutableArray *)replacedClassMethods {
    static NSMutableArray *class2method = nil;
    if (class2method == nil) {
        class2method = [NSMutableArray array];
    }
    return class2method;
}

static void replaceMethod(Class klass, SEL sel)
{
    if (klass == nil || sel == nil) {
        return ;
    }
    SEL originSelector = spa_originForSelector(sel);
    Method targetMethod = class_getInstanceMethod(klass, sel);
    if (targetMethod) {
        const char *typeEncoding = method_getTypeEncoding(targetMethod);
        class_addMethod(klass, originSelector, method_getImplementation(targetMethod), typeEncoding);
        spa_swizzleForwardInvocation(klass);
        // We use forwardInvocation to hook in.
        class_replaceMethod(klass, sel, spa_getMsgForwardIMP(klass, sel), typeEncoding);
        
        [[SpaClass replacedClassMethods] addObject:@{@"class":NSStringFromClass(klass), @"sel":NSStringFromSelector(sel)}];
    }
}

static int create(lua_State *L)
{
    const char* klass_name = lua_tostring(L, 1);
    return [SpaClass createClassUserData:L klass_name:klass_name];
}

+ (int)createClassUserData:(lua_State *)L klass_name:(const char *)klass_name
{
    return spa_safeInLuaStack(L, ^int{
        // get from table
        luaL_getmetatable(L, SPA_CLASS_LIST_TABLE);
        lua_getfield(L, -1, klass_name);
        
        // if create already, not create any more
        if (lua_isnil(L, -1)) {
            Class klass = objc_getClass(klass_name);
            if (klass == nil) {
                return 0;
            }
            size_t nbytes = sizeof(SpaInstanceUserdata);
            SpaInstanceUserdata *instance = (SpaInstanceUserdata *)lua_newuserdata(L, nbytes);
            instance->instance = klass;
            
            luaL_getmetatable(L, SPA_CLASS_META_TABLE);
            lua_setmetatable(L, -2);
            
            lua_newtable(L);
            lua_setfenv(L, -2);
            
            // copy a userdata on stack
            lua_pushvalue(L, -1);
            lua_setfield(L, -4, klass_name);
        }
        return 1;
    });
}

static bool recoverMethod_(const char* class_name, const char* selector_name)
{
    if (class_name && selector_name) {
        Class klass = objc_getClass(class_name);
        Class metaClass = object_getClass(klass);
        SEL sel = NSSelectorFromString([NSString stringWithFormat:@"%s", spa_toObjcSel(selector_name)]);
        
        BOOL canBeReplace = NO;
        NSString* selectorName = [NSString stringWithFormat:@"%s", selector_name];
        if ([selectorName hasPrefix:SPA_STATIC_PREFIX]) {
            sel = NSSelectorFromString([selectorName substringFromIndex:[SPA_STATIC_PREFIX length]]);
            if ([metaClass instancesRespondToSelector:sel]) {
                klass = metaClass;
                canBeReplace = YES;
            }
        } else {
            if ([klass instancesRespondToSelector:sel]) {
                canBeReplace = YES;
            } else {
                if ([metaClass instancesRespondToSelector:sel]) {
                    klass = metaClass;
                    canBeReplace = YES;
                }
            }
        }
        if (canBeReplace) {
            // cancel forward
            SEL originSelector = spa_originForSelector(sel);
            Method originalMethod = class_getInstanceMethod(klass, originSelector);
            const char *typeEncoding = method_getTypeEncoding(originalMethod);
            IMP originalIMP = method_getImplementation(originalMethod);
            class_replaceMethod(klass, sel, originalIMP, typeEncoding);
            
            return true;
        }
    }
    return false;
}

static int recoverMethod(lua_State *L)
{
    // class
    const char* class_name = lua_tostring(L, 1);
    const char* selector_name = lua_tostring(L, 2);
    
    bool r =  recoverMethod_(class_name, selector_name);
    if (r) {
        __block NSMutableIndexSet* indexes = [NSMutableIndexSet indexSet];
        [[SpaClass replacedClassMethods] enumerateObjectsUsingBlock:^(NSDictionary* obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString* klass = obj[@"class"];
            NSString* sel = obj[@"sel"];
            if (strcmp(klass.UTF8String, class_name) == 0
                && strcmp(sel.UTF8String, selector_name) == 0) {
                [indexes addIndex:idx];
                *stop = YES;
            }
        }];
        if (index > 0) {
            [[SpaClass replacedClassMethods] removeObjectsAtIndexes:indexes];
        }
    }
    
    return 0;
}

static const struct luaL_Reg Methods[] = {
    {"create", create},
    {"recoverMethod", recoverMethod},
    {NULL, NULL}
};

static int __index(lua_State *L)
{
    const char* func = lua_tostring(L, -1);
    if (func == NULL) {
        return 0;
    }
    SpaInstanceUserdata* userdata = lua_touserdata(L, -2);
    if (userdata == NULL || userdata->instance == NULL) {
        return 0;
    }
    Class klass = object_getClass(userdata->instance);
    if ([klass instancesRespondToSelector:NSSelectorFromString([NSString stringWithFormat:@"%s", spa_toObjcSel(func)])]) {
        lua_pushcclosure(L, spa_invoke, 1);
        return 1;
    }
    return 0;
}

static int __newIndex(lua_State *L)
{
    return spa_safeInLuaStack(L, ^int{
        if (lua_type(L, 3) == LUA_TFUNCTION) {
            SpaInstanceUserdata *instance = lua_touserdata(L, 1);
            if (instance) {
                const char* func = lua_tostring(L, 2);
                Class klass = instance->instance;
                Class metaClass = object_getClass(klass);
                BOOL canBeReplace = NO;
                NSString* selectorName = [NSString stringWithFormat:@"%s", spa_toObjcSel(func)];
                SEL sel = NSSelectorFromString(selectorName);
                if ([selectorName hasPrefix:SPA_STATIC_PREFIX]) {
                    sel = NSSelectorFromString([selectorName substringFromIndex:[SPA_STATIC_PREFIX length]]);
                    if ([metaClass instancesRespondToSelector:sel]) {
                        klass = metaClass;
                        canBeReplace = YES;
                    }
                } else {
                    if ([klass instancesRespondToSelector:sel]) {
                        canBeReplace = YES;
                    } else {
                        if ([metaClass instancesRespondToSelector:sel]) {
                            klass = metaClass;
                            canBeReplace = YES;
                        }
                    }
                }
                if (canBeReplace) {
                    replaceMethod(klass, sel);
                    
                    lua_getfenv(L, 1);
                    
                    lua_insert(L, 2);
                    lua_rawset(L, 2);
                } else {
                    NSString* error = [NSString stringWithFormat:@"selector %s not be found in %@. You may need to use ‘_’ to indicate that there are parameters. If your selector is 'function:', use 'function_', if your selector is 'function:a:b:', use 'function_a_b_'", func, klass];
                    SPA_ERROR(L, error.UTF8String);
                }
            }
        } else {
            SPA_ERROR(L, "type must function");
        }
        return 0;
    });
}

static const struct luaL_Reg MetaMethods[] = {
    {"__index", __index},
    {"__newindex", __newIndex},
    {NULL, NULL}
};

- (void)load
{
    //  recover add replace method
    [[SpaClass replacedClassMethods] enumerateObjectsUsingBlock:^(NSDictionary* obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString* klass = obj[@"class"];
        NSString* sel = obj[@"sel"];
        recoverMethod_(klass.UTF8String, sel.UTF8String);
    }];
    [[SpaClass replacedClassMethods] removeAllObjects];
}

- (void)setup:(lua_State *)L
{
    luaL_register(L, SPA_CLASS, Methods);
    luaL_newmetatable(L, SPA_CLASS_META_TABLE);
    luaL_register(L, NULL, MetaMethods);
    luaL_newmetatable(L, SPA_CLASS_LIST_TABLE);
}

static int callLuaFunction(lua_State *L, id self, SEL selector, NSInvocation *invocation)
{
    return spa_safeInLuaStack(L, ^int{
        NSMethodSignature *signature = [self methodSignatureForSelector:selector];
        int nargs = (int)[signature numberOfArguments] - 1;
        int nresults = [signature methodReturnLength] ? 1 : 0;
        // get from table
        luaL_getmetatable(L, SPA_CLASS_LIST_TABLE);
        lua_getfield(L, -1, object_getClassName(self));
        lua_getfenv(L, -1);

        if ([self class] == self) {
            NSString* staticSelectorName = [NSString stringWithFormat:@"%@%s", SPA_STATIC_PREFIX, sel_getName(selector)];
            lua_getfield(L, -1, spa_toLuaFuncName(staticSelectorName.UTF8String));
            
            if (lua_isnil(L, -1)) {
                lua_pop(L, 1);
                lua_getfield(L, -1, spa_toLuaFuncName(sel_getName(selector)));
            }
        } else {
            lua_getfield(L, -1, spa_toLuaFuncName(sel_getName(selector)));
        }
        
        if (lua_isnil(L, -1)) {
            NSString* error = [NSString stringWithFormat:@"%s lua function get failed", sel_getName(selector)];
            SPA_ERROR(L, error);
        }
        
        [SpaInstance createInstanceUserData:L object:self];
        
        for (NSUInteger i = 2; i < [signature numberOfArguments]; i++) { // start at 2 because to skip the automatic self and _cmd arugments
            const char *typeDescription = [signature getArgumentTypeAtIndex:i];
            char type = spa_getTypeFromTypeDescription(typeDescription);
            if (type == @encode(id)[0] || type == @encode(Class)[0]) {
                id __autoreleasing object;
                [invocation getArgument:&object atIndex:i];
                [SpaConverter toLuaObject:L object:object];
            } else {
                NSUInteger size = 0;
                NSGetSizeAndAlignment(typeDescription, &size, NULL);
                void *buffer = malloc(size);
                [invocation getArgument:buffer atIndex:i];
                [SpaConverter toLuaObject:L typeDescription:typeDescription buffer:buffer];
                free(buffer);
            }
        }
        
        lua_call(L, nargs, nresults);
        return nresults;
    });
}

static void __SPA_ARE_BEING_CALLED__(__unsafe_unretained NSObject *self, SEL selector, NSInvocation *invocation)
{
    lua_State* L = [[Spa sharedInstace] lua_state];
    spa_safeInLuaStack(L, ^int{
        if (isReplaceBySpa(object_getClass(self), invocation.selector)) {
            int nresults = callLuaFunction(L, self, invocation.selector, invocation);
            if (nresults > 0) {
                NSMethodSignature *signature = [self methodSignatureForSelector:invocation.selector];
                void *pReturnValue = [SpaConverter toOCObject:L typeDescription:[signature methodReturnType] index:-1];
                if (pReturnValue != NULL) {
                    [invocation setReturnValue:pReturnValue];
                }
            }
        } else {
            SEL origin_selector = NSSelectorFromString(SPA_ORIGIN_FORWARD_INVOCATION_SELECTOR_NAME);
            ((void(*)(id, SEL, id))objc_msgSend)(self, origin_selector, invocation);
        }
        return 0;
    });
}

@end
