//
//  MTIWeakToStrongMapTable.m
//  Pods
//
//  Created by YuAo on 16/07/2017.
//
//

#import "MTIWeakToStrongObjectsMapTable.h"
#import <objc/runtime.h>

NSUInteger const MTIWeakToStrongObjectsMapTableCompactThreshold = 1024 * 64; //1024 x 64 x 8 (byte size of a pointer) = 512K

@interface MTIWeakToStrongObjectsMapTable ()

@property (nonatomic,strong,readonly) NSPointerArray *items;
    
@property (nonatomic) NSUInteger compactableItemCount;

@end

@implementation MTIWeakToStrongObjectsMapTable

- (void)dealloc {
    [self removeAllObjects];
}

- (instancetype)init {
    if (self = [super init]) {
        _items = [[NSPointerArray alloc] initWithOptions:NSPointerFunctionsWeakMemory|NSPointerFunctionsObjectPointerPersonality];
    }
    return self;
}

- (id)objectForKey:(id)aKey {
    NSParameterAssert(aKey);
    return objc_getAssociatedObject(aKey, (__bridge const void *)(self));
}

- (void)setObject:(id)anObject forKey:(id)aKey {
    NSParameterAssert(aKey);
    
    //Safe to use `(__bridge const void *)(self)` here, since we'll remove all the associations on deallocation.
    objc_setAssociatedObject(aKey, (__bridge const void *)(self), anObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (anObject) {
        [_items addPointer:(__bridge void *)(aKey)];
        _compactableItemCount += 1;
        if (_compactableItemCount >= MTIWeakToStrongObjectsMapTableCompactThreshold) {
            [self compact];
        }
    } else {
        [self compact];
        NSUInteger index = NSNotFound;
        NSUInteger i = 0;
        for (id object in _items) {
            if (object == aKey) {
                index = i;
                break;
            }
            i += 1;
        }
        if (index != NSNotFound) {
            [_items removePointerAtIndex:index];
        }
    }
}

- (void)removeObjectForKey:(id)aKey {
    [self setObject:nil forKey:aKey];
}

- (void)removeAllObjects {
    [self compact];
    for (id key in _items) {
        objc_setAssociatedObject(key, (__bridge const void *)(self), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    _items.count = 0;
}

- (void)compact {
    // http://www.openradar.me/15396578
    // https://stackoverflow.com/questions/31322290/nspointerarray-weird-compaction
    [_items addPointer:nil];
    [_items compact];
    _compactableItemCount = 0;
}

@end
