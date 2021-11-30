//
//  MTICVMetalIOSurfaceBridge.h
//  MetalPetal
//
//  Created by Yu Ao on 2018/10/10.
//

#import <Foundation/Foundation.h>
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTICVMetalTextureBridging.h>
#else
#import "MTICVMetalTextureBridging.h"
#endif

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const MTICVMetalIOSurfaceBridgeErrorDomain;

typedef NS_ERROR_ENUM(MTICVMetalIOSurfaceBridgeErrorDomain, MTICVMetalIOSurfaceBridgeError) {
    MTICVMetalIOSurfaceBridgeErrorImageBufferIsNotBackedByIOSurface = 10001,
    MTICVMetalIOSurfaceBridgeErrorFailedToCreateTexture = 10002,
    MTICVMetalIOSurfaceBridgeErrorCoreVideoDoesNotSupportIOSurface = 10003
};

__attribute__((objc_subclassing_restricted))
@interface MTICVMetalIOSurfaceBridge : NSObject <MTICVMetalTextureBridging>

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDevice:(id<MTLDevice>)device;

@end

NS_ASSUME_NONNULL_END
