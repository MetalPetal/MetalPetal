//
//  MTICVMetalIOSurfaceBridge.h
//  MetalPetal
//
//  Created by Yu Ao on 2018/10/10.
//

#import <Foundation/Foundation.h>
#import "MTICVMetalTextureBridging.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const MTICVMetalIOSurfaceBridgeErrorDomain;

typedef NS_ERROR_ENUM(MTICVMetalIOSurfaceBridgeErrorDomain, MTICVMetalIOSurfaceBridgeError) {
    MTICVMetalIOSurfaceBridgeErrorImageBufferIsNotBackedByIOSurface = 10001,
    MTICVMetalIOSurfaceBridgeErrorFailedToCreateTexture = 10002,
    MTICVMetalIOSurfaceBridgeErrorCoreVideoDoesNotSupportIOSurface = 10003
};

NS_CLASS_AVAILABLE(10_11, 11_0)
@interface MTICVMetalIOSurfaceBridge : NSObject <MTICVMetalTextureBridging>

- (instancetype)initWithDevice:(id<MTLDevice>)device;

@end

NS_ASSUME_NONNULL_END
