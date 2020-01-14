//
//  MTILock.h
//  Pods
//
//  Created by YuAo on 05/08/2017.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MTILocking <NSLocking>

- (BOOL)tryLock;

@end

///Create a non-recursive lock. Unlocking a lock from a different thread other than the locking thread can result in undefined behavior.
FOUNDATION_EXPORT id<MTILocking> MTILockCreate(void) NS_RETURNS_RETAINED;

NS_ASSUME_NONNULL_END
