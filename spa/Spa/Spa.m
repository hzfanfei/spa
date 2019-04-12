//
//  Spa.m
//  Spa
//
//  Created by Family Fan on 2018/11/29.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#import "Spa.h"
#import "SpaUtil.h"
#import "SpaClass.h"
#import "SpaInstance.h"
#import "SpaConverter.h"
#import "SpaDefine.h"
#import "SpaTrace.h"
#import "spa_stdlib.h"

@interface Spa ()

@property (nonatomic, assign) lua_State* _lua_state;
@property (nonatomic) SpaClass* spa_class;
@property (nonatomic) SpaInstance* spa_instance;
@property (nonatomic) SpaTrace* spa_trace;
@property (nonatomic, copy) spa_log_block_t spa_logBlock;

@end

@implementation Spa

+ (instancetype)sharedInstace
{
    static Spa* spa = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        spa = [[Spa alloc] init];
        spa.spa_class = [[SpaClass alloc] init];
        spa.spa_instance = [[SpaInstance alloc] init];
        spa.spa_trace = [[SpaTrace alloc] init];
    });
    return spa;
}

static pthread_key_t pthread_key;

// first param is class string, second is selector string
static int setCSToTls(lua_State *L)
{
    pthread_key_create(&pthread_key, NULL);
    // class
    const char* class_name = lua_tostring(L, 1);
    const char* selector_name = lua_tostring(L, 2);
    
    if (class_name && selector_name) {
        NSString* __autoreleasing cs = [NSString stringWithFormat:@"%s %s", class_name, selector_name];
        pthread_setspecific(pthread_key, (__bridge const void * _Nullable)(cs));
    } else {
        SPA_ERROR(L, "check class and selector type, must string type");
    }
    return 0;
}

static int removeKeyFromTls(lua_State *L)
{
    pthread_key_delete(pthread_key);
    return 0;
}

// first result is class string, second is selector string
static int getCSFromTls(lua_State *L)
{
    NSString* cs = (__bridge NSString *)(pthread_getspecific(pthread_key));
    NSArray* classAndSel = [cs componentsSeparatedByString:@" "];
    if (classAndSel.count == 2) {
        lua_pushstring(L, [classAndSel.firstObject UTF8String]);
        lua_pushstring(L, [classAndSel.lastObject UTF8String]);
        return 2;
    } else {
        return 0;
    }
}

static int _log(lua_State *L)
{
    Spa* spa = [Spa sharedInstace];
    return spa_safeInLuaStack(L, ^int{
        struct S
        {
            id instance;
        };
        struct S* s = [SpaConverter toOCObject:L typeDescription:"@" index:-1];
        if (s && s->instance) {
            if (spa.spa_logBlock) {
                spa.spa_logBlock([NSString stringWithFormat:@"%@", s->instance]);
            }
        } else {
            if (spa.spa_logBlock) {
                spa.spa_logBlock(@"null");
            }
        }
        return 0;
    });
}

static int toId(lua_State *L)
{
    return spa_safeInLuaStack(L, ^int{
        struct S
        {
            id instance;
        };
        struct S* s = [SpaConverter toOCObject:L typeDescription:"@" index:-1];
        if (s && s->instance) {
            [SpaInstance createInstanceUserData:L object:s->instance];
            return 1;
        } else {
            SPA_ERROR(L, "the param type not support !");
        }
        return 0;
    });
}

static int toLuaString(lua_State *L)
{
    return spa_safeInLuaStack(L, ^int{
        SpaInstanceUserdata* instance = lua_touserdata(L, -1);
        if (instance->instance) {
            lua_pushstring(L, [instance->instance description].UTF8String);
            return 1;
        } else {
            SPA_ERROR(L, "the param type not support !");
        }
        return 0;
    });
}

static int _dispatch_after(lua_State *L)
{
    int seconds = lua_tonumber(L, 2);
    struct S
    {
        id block;
    };
    
    struct S* s = (struct S*)[SpaConverter toOCObject:L typeDescription:"@" index:1];
    if (s && s->block) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), s->block);
    }
    return 0;
}

static const struct luaL_Reg Methods[] = {
    {"log", _log},
    {"toId", toId},
    {"toLuaString", toLuaString},
    {"setCSToTls", setCSToTls}, // cs is class and selector
    {"removeKeyFromTls", removeKeyFromTls},
    {"getCSFromTls", getCSFromTls},
    {"dispatch_after", _dispatch_after},
    {NULL, NULL}
};

- (void)setup:(lua_State *)L
{
    spa_safeInLuaStack(L, ^int{
        luaL_register(L, SPA_MODULE, Methods);
        [self.spa_class setup:L];
        [self.spa_instance setup:L];
        [self.spa_trace setup:L];
        return 0;
    });
}

- (lua_State *)lua_state
{
    Spa* spa = [Spa sharedInstace];
    return spa._lua_state;
}

- (void)setLogBlock:(spa_log_block_t)block
{
    Spa* spa = [Spa sharedInstace];
    spa.spa_logBlock = block;
}

- (spa_log_block_t)spaLogBlock
{
    return _spa_logBlock;
}

- (void)usePatch:(NSString *)patch
{
    lua_State* L = lua_open();
    Spa* spa = [Spa sharedInstace];
    if (spa._lua_state) {
        lua_close(spa._lua_state);
        spa._lua_state = NULL;
    }
    spa._lua_state = L;
    luaL_openlibs(L);
    
    char stdlib[] = SPA_STDLIB;
    size_t stdlibSize = sizeof(stdlib);
    
    if (luaL_loadbuffer(L, stdlib, stdlibSize, "loading spa stdlib") || lua_pcall(L, 0, LUA_MULTRET, 0)) {
        printf("opening spa stdlib failed: %s\n", lua_tostring(L,-1));
        return ;
    }
    
    [self setup:L];
    
    spa_safeInLuaStack(L, ^int{
        long size = strlen(patch.UTF8String);
        char* appLoadString = malloc(size);
        snprintf(appLoadString, size, "%s", patch.UTF8String); // Strip the extension off the file.
        if (luaL_dostring(L, appLoadString) != 0) {
            printf("opening spa scripts failed: %s\n", lua_tostring(L,-1));
        }
        free(appLoadString);
        return 0;
    });
}

- (lua_State *)getLuaState
{
    return [Spa sharedInstace]._lua_state;
}

- (SpaTrace *)spaTrace
{
    return _spa_trace;
}

- (void)dealloc
{
    if (__lua_state) {
        lua_close(__lua_state);
    }
}

+ (void)logCurrentStack
{
    Spa* spa = [Spa sharedInstace];
    lua_State* L = [spa lua_state];
    spa_stackDump(L);
}

@end
