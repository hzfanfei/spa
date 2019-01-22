//
//  SpaDefine.h
//  SpaDemo
//
//  Created by Family Fan on 2018/12/3.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#ifndef SpaDefine_h
#define SpaDefine_h

typedef struct _SpaInstanceUserdata {
    __weak id instance;
    bool isBlock;
} SpaInstanceUserdata;

#define SPA_ORIGIN_PREFIX @"ORIG"
#define SPA_SUPER_PREFIX @"SUPER"
#define SPA_STATIC_PREFIX @"STATIC"
#define SPA_ORIGIN_FORWARD_INVOCATION_SELECTOR_NAME @"__spa_origin_forwardInvocation:"

#endif /* SpaDefine_h */
