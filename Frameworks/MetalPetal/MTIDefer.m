//
//  MTIUtilities.m
//  Pods
//
//  Created by yi chen on 2017/7/26.
//
//

#import "MTIDefer.h"

void MTIExecuteCleanupBlock (__strong MTIDeferBlock *block) {
    (*block)();
}
