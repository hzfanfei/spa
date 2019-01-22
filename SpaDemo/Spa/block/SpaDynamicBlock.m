//
//  SpaDynamicBlock.m
//  OCBlock
//
//  Created by familymrfan on 2018/3/13.
//  Copyright © 2018年 niuniu. All rights reserved.
//

#import "SpaDynamicBlock.h"
#import "ffi.h"
#import "SpaUtil.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

NSString* DyVoidType = @"v";
NSString* DyCharType = @"c";
NSString* DyIntType = @"i";
NSString* DyShortType = @"s";
NSString* DyLongType = @"l";
NSString* DyLongLongType = @"q";
NSString* DyFloatType = @"f";
NSString* DyDoubleType = @"d";
NSString* DyBoolType = @"B";
NSString* DyIdType = @"@";
NSString* DyPtrType = @"*";
NSString* DySELType = @":";
NSString* DyClassType = @"#";
NSString* DyCGFloatType = @"g";

#define MAX_PARAMS_COUNT 20

struct Block_literal_1 {
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct Block_descriptor_1 {
        unsigned long int reserved;         // NULL
        unsigned long int size;         // sizeof(struct Block_literal_1)
        // optional helper functions
        void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
        void (*dispose_helper)(void *src);             // IFF (1<<25)
        // required ABI.2010.3.16
        const char *signature;                         // IFF (1<<30)
    } *descriptor;
    // imported variables
};

@interface SpaDynamicBlock()
{
    ffi_cif _cif;
    ffi_closure *_closure;
    void* _invokeFuncPtr;
    ffi_type *_args[MAX_PARAMS_COUNT];
    ffi_type* _struct_type_ptr[20]; // max support 20 struct args
    int _struct_args_count;
    
}

@property (nonatomic, copy) NSArray<NSString *> *argsTypes;
@property (nonatomic, copy) NSString* retType;
@property (nonatomic, copy) void*(^replaceBlock)(void** args);

@end

@implementation SpaDynamicBlock

- (id)initWithArgsTypes:(NSArray<NSString *> *)types retType:(NSString *)retType replaceBlock:(void *(^)(void** args))replaceBlock
{
    self = [super init];
    if (self) {
        _struct_args_count = 0;
        memset(_args, 0, MAX_PARAMS_COUNT * sizeof(ffi_type *));
        _replaceBlock = replaceBlock;
        _invokeBlock = ^(){

        };
        self.argsTypes = types;
        self.retType = retType;
        [self dynamicCreate];
    }
    return self;
}

- (ffi_type *)getffiTypeFromDyType:(NSString *)type
{
    if ([type isEqualToString:DyVoidType]) {
        return &ffi_type_void;
    } else if ([type isEqualToString:DyBoolType] || [type isEqualToString:DyCharType]) {
        return &ffi_type_sint8;
    } else if ([type isEqualToString:DyIntType]) {
        return &ffi_type_sint;
    } else if ([type isEqualToString:DyShortType]) {
        return &ffi_type_sshort;
    } else if ([type isEqualToString:DyLongType]) {
        return &ffi_type_slong;
    } else if ([type isEqualToString:DyLongLongType]) {
        return &ffi_type_sint64; // long long always 64bit
    } else if ([type isEqualToString:DyFloatType]) {
        return &ffi_type_float;
    } else if ([type isEqualToString:DyDoubleType]) {
        return &ffi_type_double;
    } else if ([type isEqualToString:DyCGFloatType]) {
        if (sizeof(CGFloat) == sizeof(double)) {
            return &ffi_type_double;
        } else {
            return &ffi_type_float;
        }
    } else if ([type isEqualToString:DyIdType]
               || [type isEqualToString:DyPtrType]
               || [type isEqualToString:DySELType]
               || [type isEqualToString:DyClassType]
               ) {
        return &ffi_type_pointer;
    } else if ([type characterAtIndex:0] == _C_STRUCT_B) {
        NSArray* struct2des = spa_parseStructFromTypeDescription(type);
        if (struct2des.count == 2) {
            ffi_type* struct_type_ptr = malloc(sizeof(ffi_type));
            struct_type_ptr->size = 0;
            struct_type_ptr->alignment = 0;
            struct_type_ptr->type = FFI_TYPE_STRUCT;
            
            NSString* struct_element_types = struct2des[1];
            size_t len = [struct_element_types length];
            size_t struct_element_size = sizeof(ffi_type *) * (len + 1);
            ffi_type** struct_element_ptr = malloc(struct_element_size);
            memset(struct_element_ptr, 0, struct_element_size);
            for (int i = 0; i < len; i++) {
                ffi_type * type = [self getffiTypeFromDyType:[NSString stringWithFormat:@"%c", [struct_element_types characterAtIndex:i]]];
                struct_element_ptr[i] = type;
            }
            struct_element_ptr[len] = NULL;
            
            struct_type_ptr->elements = struct_element_ptr;
            _struct_type_ptr[_struct_args_count++] = struct_type_ptr;
            return struct_type_ptr;
        } else {
            NSLog(@"[SpaDynamicBlock] struct type define format is {%%struct=xxxx} x shoule be i l q f d g");
        }
    } else {
        NSLog(@"[SpaDynamicBlock] not support arg type %@", type);
    }
    return NULL;
}

- (NSUInteger)argsCount
{
    return self.argsTypes.count;
}

- (void)dynamicCreate
{
    _closure = ffi_closure_alloc(sizeof(ffi_closure), &_invokeFuncPtr);
    if (_closure) {
        // first arg is a block
        _args[0] = &ffi_type_pointer;
        __block BOOL typeAssign = YES;
        
        [self.argsTypes enumerateObjectsUsingBlock:^(NSString * _Nonnull type, NSUInteger idx, BOOL * _Nonnull stop) {
            ffi_type* ffiType = [self getffiTypeFromDyType:type];
            if (ffiType == NULL) {
                typeAssign = NO;
                *stop = YES;
                return ;
            }
            self->_args[idx + 1] = ffiType;
        }];
        ffi_type* retType = [self getffiTypeFromDyType:self.retType];
        if (retType == NULL) {
            typeAssign = NO;
            return ;
        }
        
        if (!typeAssign) {
            NSAssert(NO, @"[SpaDynamicBlock] type not support !");
            return ;
        }
        
        if (ffi_prep_cif(&_cif, FFI_DEFAULT_ABI, (unsigned int)[self argsCount] + 1,
                         retType, _args) == FFI_OK) {
            if(ffi_prep_closure_loc(_closure, &_cif, dynamicClosureFunc, (__bridge void *)(self), _invokeFuncPtr) == FFI_OK) {
                ((__bridge struct Block_literal_1 *)_invokeBlock)->invoke = _invokeFuncPtr;
            }
        }
    }
}

-(void)dealloc
{
    for (int i = 0; i < _struct_args_count; i++) {
        free(_struct_type_ptr[i]->elements);
        free(_struct_type_ptr[i]);
        _struct_type_ptr[i] = NULL;
    }
    ffi_closure_free(_closure);
}

static void dynamicClosureFunc(ffi_cif *cif, void *ret, void **args, void *userdata)
{
    SpaDynamicBlock* dy = (__bridge SpaDynamicBlock*)userdata;
    void* retPtr = dy.replaceBlock(args);
    if ([dy.retType isEqualToString:DyVoidType]) {
        return ;
    }
    if ([dy.retType isEqualToString:DyIdType]
        || [dy.retType isEqualToString:DyPtrType]
        || [dy.retType isEqualToString:DySELType]
        || [dy.retType isEqualToString:DyClassType]) {
        if (retPtr != nil) {
            *(void **)ret = *(void **)retPtr;
        } else {
            *(void **)ret = nil;
        }
    } else if ([dy.retType isEqualToString:DyCharType]) {
        *(char *)ret = *(char *)retPtr;
    } else if ([dy.retType isEqualToString:DyLongType]) {
        *(long *)ret = *(long *)retPtr;
    } else if ([dy.retType isEqualToString:DyShortType]) {
        *(short *)ret = *(short *)retPtr;
    } else if ([dy.retType isEqualToString:DyBoolType]) {
        *(BOOL *)ret = *(BOOL *)retPtr;
    } else if ([dy.retType isEqualToString:DyIntType]) {
        *(int *)ret = *(int *)retPtr;
    } else if ([dy.retType isEqualToString:DyFloatType]) {
        *(float *)ret = *(float *)retPtr;
    } else if ([dy.retType isEqualToString:DyDoubleType]) {
        *(double *)ret = *(double *)retPtr;
    } else if ([dy.retType isEqualToString:DyLongLongType]) {
        *(long long *)ret = *(long long *)retPtr;
    } else if ([dy.retType isEqualToString:DyCGFloatType]) {
        if (sizeof(CGFloat) == sizeof(double)) {
            *(double *)ret = *(double *)retPtr;
        } else {
            *(float *)ret = *(float *)retPtr;
        }
    } else {
        NSLog(@"[SpaDynamicBlock] not support return type %@", dy.retType);
    }
}

@end
