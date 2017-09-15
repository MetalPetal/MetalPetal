//
//  MTIUtilities.h
//  Pods
//
//  Created by yi chen on 2017/7/26.
//
//

#import <Foundation/Foundation.h>

#define MTI_METAMACRO_CONCAT(A, B) \
MTI_METAMACRO_CONCAT_(A, B)

#define MTI_METAMACRO_CONCAT_(A, B) A ## B

#define MTI_DEFER \
try {} @finally {} \
__strong MTIDeferBlock MTI_METAMACRO_CONCAT(MTIExitBlock_, __LINE__) __attribute__((cleanup(MTIExecuteCleanupBlock), unused)) = ^

typedef void (^MTIDeferBlock)(void);

void MTIExecuteCleanupBlock (__strong MTIDeferBlock *block);
