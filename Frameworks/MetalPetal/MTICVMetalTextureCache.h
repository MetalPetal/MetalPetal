//
//  MTICVMetalTextureCache.h
//  Pods
//
//  Created by Yu Ao on 07/01/2018.
//

#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTICVMetalTextureBridging.h>
#else
#import "MTICVMetalTextureBridging.h"
#endif

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const MTICVMetalTextureCacheErrorDomain;

typedef NS_ERROR_ENUM(MTICVMetalTextureCacheErrorDomain, MTICVMetalTextureCacheError) {
    MTICVMetalTextureCacheErrorMetalIsNotSupported = 10001,
    MTICVMetalTextureCacheErrorFailedToInitialize = 10002,
    MTICVMetalTextureCacheErrorFailedToCreateTexture = 10003
};

/// Thread-safe object-orientated CVMetalTextureCache.
__attribute__((objc_subclassing_restricted))
@interface MTICVMetalTextureCache : NSObject <MTICVMetalTextureBridging>

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (nullable instancetype)initWithDevice:(id<MTLDevice>)device
                        cacheAttributes:(nullable NSDictionary *)cacheAttributes
                      textureAttributes:(nullable NSDictionary *)textureAttributes
                                  error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
