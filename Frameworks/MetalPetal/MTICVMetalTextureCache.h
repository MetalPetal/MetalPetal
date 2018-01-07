//
//  MTICVMetalTextureCache.h
//  Pods
//
//  Created by Yu Ao on 07/01/2018.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <CoreVideo/CoreVideo.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const MTICVMetalTextureCacheErrorDomain;

typedef NS_ERROR_ENUM(MTICVMetalTextureCacheErrorDomain, MTICVMetalTextureCacheError) {
    MTICVMetalTextureCacheErrorMetalIsNotSupported = 10001,
    MTICVMetalTextureCacheErrorFailedToInitialize = 10002,
    MTICVMetalTextureCacheErrorFailedToCreateTexture = 10003
};

@interface MTICVMetalTexture: NSObject

@property (nonatomic, readonly) id<MTLTexture> texture;

@end

/// Thread-safe object-orientated CVMetalTextureCache.

@interface MTICVMetalTextureCache : NSObject

- (nullable instancetype)initWithDevice:(id<MTLDevice>)device
                        cacheAttributes:(nullable NSDictionary *)cacheAttributes
                      textureAttributes:(nullable NSDictionary *)textureAttributes
                                  error:(NSError **)error;

- (nullable MTICVMetalTexture *)newTextureWithCVImageBuffer:(CVImageBufferRef)imageBuffer
                                                 attributes:(nullable NSDictionary *)textureAttributes
                                                pixelFormat:(MTLPixelFormat)pixelFormat
                                                      width:(size_t)width
                                                     height:(size_t)height
                                                 planeIndex:(size_t)planeIndex
                                                      error:(NSError **)error
NS_SWIFT_NAME(makeTexture(with:attributes:pixelFormat:width:height:planeIndex:));

- (void)flush;

@end

NS_ASSUME_NONNULL_END
