//
//  MTIMemoryWarningObserver.h
//  MetalPetal
//
//  Created by Yu Ao on 2018/8/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MTIMemoryWarningHandling <NSObject>

- (void)handleMemoryWarning;

@end

@interface MTIMemoryWarningObserver : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (void)addMemoryWarningHandler:(id<MTIMemoryWarningHandling>)memoryWarningHandler;

+ (void)removeMemoryWarningHandler:(id<MTIMemoryWarningHandling>)memoryWarningHandler;

@end

NS_ASSUME_NONNULL_END
