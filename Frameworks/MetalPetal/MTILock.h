//
//  MTILock.h
//  Pods
//
//  Created by YuAo on 05/08/2017.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///Create a non-recursive lock. Unlocking a lock from a different thread other than the locking thread can result in undefined behavior.
FOUNDATION_EXPORT id<NSLocking> MTICreateLock(void);

NS_ASSUME_NONNULL_END
