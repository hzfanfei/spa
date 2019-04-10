//
//  SpaInstance.h
//  Spa
//
//  Created by Family Fan on 2018/12/4.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "lua.h"

#define SPA_INSTANCE "spa.instance" // lua instance module
#define SPA_INSTANCE_META_TABLE "spaInstanceMetaTable" // instance meta table
#define SPA_INSTANCE_LIST_TABLE "spaInstanceListTable" // for save instances

NS_ASSUME_NONNULL_BEGIN

@interface SpaInstance : NSObject

- (void)setup:(lua_State *)L;

+ (int)createInstanceUserData:(lua_State *)L object:(id)object;

@end

NS_ASSUME_NONNULL_END
