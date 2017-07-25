//
//  MTIWeakToStrongMapTable.m
//  Pods
//
//  Created by YuAo on 16/07/2017.
//
//

#import "MTIWeakToStrongObjectsMapTable.h"
#import <objc/runtime.h>

@interface MTIWeakToStrongObjectsMapTable ()

@property (nonatomic,strong,readonly) NSHashTable *items;

@end

@implementation MTIWeakToStrongObjectsMapTable

- (void)dealloc {
    [self removeAllObjects];
}

- (instancetype)init {
    if (self = [super init]) {
        _items = [[NSHashTable alloc] initWithOptions:NSHashTableWeakMemory|NSHashTableObjectPointerPersonality capacity:0];
    }
    return self;
}

- (id)objectForKey:(id)aKey {
    return objc_getAssociatedObject(aKey, (__bridge const void *)(self));
}

- (void)setObject:(id)anObject forKey:(id)aKey {
    objc_setAssociatedObject(aKey, (__bridge const void *)(self), anObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (anObject) {
        [self.items addObject:aKey];
    } else {
        [self.items removeObject:aKey];
    }
}

- (void)removeObjectForKey:(id)aKey {
    [self setObject:nil forKey:aKey];
}

- (void)removeAllObjects {
    NSArray *allObjects = [[self.items allObjects] copy];
    for (id key in allObjects) {
        [self setObject:nil forKey:key];
    }
}

- (NSUInteger)count {
    return self.items.count;
}

@end
