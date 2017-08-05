//
//  MTILock.m
//  Pods
//
//  Created by YuAo on 05/08/2017.
//
//

#import "MTILock.h"
#import <os/lock.h>
#import <pthread/pthread.h>

//https://gist.github.com/steipete/36350a8a60693d440954b95ea6cbbafc

@interface MTILock() {
    os_unfair_lock _unfairlock;
    pthread_mutex_t _mutex;
}

@end

@implementation MTILock

- (instancetype)init {
    if (self = [super init]) {
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_9_x_Max) {
            _unfairlock = OS_UNFAIR_LOCK_INIT;
        } else {
            pthread_mutex_init(&_mutex, nil);
        }
    }
    return self;
}

- (void)dealloc {
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_9_x_Max) {
        
    } else {
        pthread_mutex_destroy(&_mutex);
    }
}

- (void)lock {
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_9_x_Max) {
        os_unfair_lock_lock(&_unfairlock);
    } else {
        pthread_mutex_lock(&_mutex);
    }
}

- (void)unlock {
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_9_x_Max) {
        os_unfair_lock_unlock(&_unfairlock);
    } else {
        pthread_mutex_unlock(&_mutex);
    }
}

@end
