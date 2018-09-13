//
//  MTIWeakToStrongMapTable.h
//  Pods
//
//  Created by YuAo on 16/07/2017.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Behaves like NSMapTable with key options: NSMapTableObjectPointerPersonality|NSMapTableWeakMemory, value options: NSMapTableStrongMemory. Entries are purged right away when the weak key is reclaimed.

@interface MTIWeakToStrongObjectsMapTable <KeyType, ObjectType> : NSObject

- (nullable ObjectType)objectForKey:(KeyType)aKey;

- (void)removeObjectForKey:(KeyType)aKey;

- (void)setObject:(nullable ObjectType)anObject forKey:(KeyType)aKey;

- (void)removeAllObjects;

- (void)compact;

@end

NS_ASSUME_NONNULL_END
