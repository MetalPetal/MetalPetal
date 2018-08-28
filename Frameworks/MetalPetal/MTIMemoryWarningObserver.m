//
//  MTIMemoryWarningObserver.m
//  MetalPetal
//
//  Created by Yu Ao on 2018/8/27.
//

#import "MTIMemoryWarningObserver.h"

#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#endif

@interface MTIMemoryWarningObserver ()

@property (nonatomic, strong, readonly) NSHashTable *handlers;

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
#if __has_include(<UIKit/UIKit.h>)
        [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidReceiveMemoryWarningNotification
                                                        object:UIApplication.sharedApplication
                                                         queue:nil
                                                    usingBlock:^(NSNotification * _Nonnull note) {
                                                        [self handleMemoryWarning];
                                                    }];
#endif
    }
    return self;
}

- (void)handleMemoryWarning {
    for (id<MTIMemoryWarningHandling> handler in _handlers) {
        [handler handleMemoryWarning];
    }
}

- (void)addMemoryWarningHandler:(id<MTIMemoryWarningHandling>)memoryWarningHandler {
    [_handlers addObject:memoryWarningHandler];
}

- (void)removeMemoryWarningHandler:(id<MTIMemoryWarningHandling>)memoryWarningHandler {
    [_handlers removeObject:memoryWarningHandler];
}

+ (void)addMemoryWarningHandler:(id<MTIMemoryWarningHandling>)memoryWarningHandler {
    [self.sharedObserver addMemoryWarningHandler:memoryWarningHandler];
}

+ (void)removeMemoryWarningHandler:(id<MTIMemoryWarningHandling>)memoryWarningHandler {
    [self.sharedObserver removeMemoryWarningHandler:memoryWarningHandler];
}

@end
