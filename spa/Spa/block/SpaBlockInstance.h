//
//  SpaBlockInstance.h
//  Spa
//
//  Created by Family Fan on 2018/12/10.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "lua.h"

NS_ASSUME_NONNULL_BEGIN

@interface SpaBlockInstance : NSObject

-(void (^)(void))voidBlock;
- (id)blockWithParamsTypeArray:(NSArray *)paramsTypeArray returnType:(NSString *)returnType;

@end

NS_ASSUME_NONNULL_END
