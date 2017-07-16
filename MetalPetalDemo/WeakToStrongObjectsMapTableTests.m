//
//  WeakToStrongObjectsMapTableTests.m
//  MetalPetalDemo
//
//  Created by YuAo on 16/07/2017.
//  Copyright © 2017 MetalPetal. All rights reserved.
//

#import "WeakToStrongObjectsMapTableTests.h"
@import MetalPetal;

@implementation WeakToStrongObjectsMapTableTests

+ (void)test {
    MTIWeakToStrongObjectsMapTable *mapTable = [[MTIWeakToStrongObjectsMapTable alloc] init];
    NSDictionary *key1 = @{@"Key": @"Value"};
    NSDictionary *key2 = @{@"Key": @"Value"};
    NSDictionary *key3 = @{@"Key": @3};
    
    NSObject *value1 = [[NSObject alloc] init];
    NSObject *value2 = [[NSObject alloc] init];
    NSObject *value3 = [[NSObject alloc] init];
    
    NSObject __weak *weakValue1 = value1;
    NSObject __weak *weakValue2 = value2;
    NSObject __weak *weakValue3 = value3;
    
    [mapTable setObject:value1 forKey:key1];
    [mapTable setObject:value2 forKey:key2];
    [mapTable setObject:value3 forKey:key3];
    
    value1 = nil;
    value2 = nil;
    value3 = nil;
    
    @autoreleasepool {
        id v1 = [mapTable objectForKey:key1];
        NSAssert(v1 == weakValue1, @"");
        v1 = nil;
    }
    
    key1 = nil;
    NSAssert(weakValue1 == nil, @"");
    
    [mapTable removeObjectForKey:key2];
    NSAssert(weakValue2 == nil, @"");
    
    mapTable = nil;
    NSAssert(weakValue3 == nil, @"");
}

@end
