//
//  MTILock.m
//  Pods
//
//  Created by YuAo on 05/08/2017.
//
//

#import "MTILock.h"
#import <os/lock.h>

//https://gist.github.com/steipete/36350a8a60693d440954b95ea6cbbafc

OS_UNFAIR_LOCK_AVAILABILITY
@interface MTILock : NSObject <MTILocking>  {
    os_unfair_lock _unfairlock;
}

@end

@implementation MTILock

- (instancetype)init {
    if (self = [super init]) {
        _unfairlock = OS_UNFAIR_LOCK_INIT;
    }
    return self;
}

- (void)lock {
    os_unfair_lock_lock(&_unfairlock);
}

- (void)unlock {
    os_unfair_lock_unlock(&_unfairlock);
}

- (BOOL)tryLock {
    return os_unfair_lock_trylock(&_unfairlock);
}

@end

id<MTILocking> MTILockCreate(void) {
    return [[MTILock alloc] init];
}
