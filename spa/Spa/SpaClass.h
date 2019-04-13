//
//  SpaClass.h
//  Spa
//
//  Created by Family Fan on 2018/11/30.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "lua.h"

#define SPA_CLASS "spa.class" // lua class module
#define SPA_CLASS_META_TABLE "spaClassMetaTable" // class instance meta table
#define SPA_CLASS_LIST_TABLE "spaClassListTable" // for save class

NS_ASSUME_NONNULL_BEGIN

@interface SpaClass : NSObject

- (void)setup:(lua_State *)L;

- (void)load;

+ (int)createClassUserData:(lua_State *)L klass_name:(const char *)klass_name;

@end

NS_ASSUME_NONNULL_END
