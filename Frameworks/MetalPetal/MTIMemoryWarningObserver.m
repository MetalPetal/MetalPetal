//
//  MTIMemoryWarningObserver.m
//  MetalPetal
//
//  Created by Yu Ao on 2018/8/27.
//

#import "MTIMemoryWarningObserver.h"
#import "MTILock.h"

#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#endif

@interface MTIMemoryWarningObserver ()

@property (nonatomic, strong, readonly) NSHashTable *handlers;
@property (nonatomic, strong, readonly) id<MTILocking> lock;

@end

@implementation MTIMemoryWarningObserver

+ (instancetype)sharedObserver {
    static MTIMemoryWarningObserver *observer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        observer = [[MTIMemoryWarningObserver alloc] initForSharedObserver];
    });
    return observer;
}

- (instancetype)initForSharedObserver {
    if (self = [super init]) {
        _handlers = [NSHashTable weakObjectsHashTable];
        _lock = MTILockCreate();
#if __has_include(<UIKit/UIKit.h>)
        [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidReceiveMemoryWarningNotification
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:^(NSNotification * _Nonnull note) {
                                                        [self handleMemoryWarning];
                                                    }];
#endif
    }
    return self;
}

- (void)handleMemoryWarning {
    [_lock lock];
    for (id<MTIMemoryWarningHandling> handler in _handlers) {
        [handler handleMemoryWarning];
    }
    [_lock unlock];
}

- (void)addMemoryWarningHandler:(id<MTIMemoryWarningHandling>)memoryWarningHandler {
    [_lock lock];
    [_handlers addObject:memoryWarningHandler];
    [_lock unlock];
}

- (void)removeMemoryWarningHandler:(id<MTIMemoryWarningHandling>)memoryWarningHandler {
    [_lock lock];
    [_handlers removeObject:memoryWarningHandler];
    [_lock unlock];
}

+ (void)addMemoryWarningHandler:(id<MTIMemoryWarningHandling>)memoryWarningHandler {
    [self.sharedObserver addMemoryWarningHandler:memoryWarningHandler];
}

+ (void)removeMemoryWarningHandler:(id<MTIMemoryWarningHandling>)memoryWarningHandler {
    [self.sharedObserver removeMemoryWarningHandler:memoryWarningHandler];
}

@end
