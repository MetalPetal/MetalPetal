//
//  MTICVMetalTextureBridge.h
//  MetalPetal
//
//  Created by Yu Ao on 2018/10/10.
//

#import <Foundation/Foundation.h>
#import "MTICVMetalTextureBridging.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const MTICVMetalTextureBridgeErrorDomain;

typedef NS_ERROR_ENUM(MTICVMetalTextureBridgeErrorDomain, MTICVMetalTextureBridgeError) {
    MTICVMetalTextureBridgeErrorImageBufferIsNotBackedByIOSurface = 10001,
    MTICVMetalTextureBridgeErrorFailedToCreateTexture = 10002,
    MTICVMetalTextureBridgeErrorCoreVideoDoesNotSupportIOSurface = 10003
};

NS_CLASS_AVAILABLE(10_11, 11_0)
@interface MTICVMetalTextureBridge : NSObject <MTICVMetalTextureBridging>

- (instancetype)initWithDevice:(id<MTLDevice>)device;

@end

NS_ASSUME_NONNULL_END
