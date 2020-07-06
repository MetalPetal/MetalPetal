//
//  MTIImageRenderingContext.h
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import <Metal/Metal.h>

@class MTIImage, MTIContext;

NS_ASSUME_NONNULL_BEGIN

/*! @brief Rendering context related constant for MTIContextImageAssociatedValueTableName. */
FOUNDATION_EXPORT NSString * const MTIContextImagePersistentResolutionHolderTableName;

__attribute__((objc_subclassing_restricted))
@interface MTIImageRenderingContext : NSObject

@property (nonatomic, strong, readonly) MTIContext *context;

@property (nonatomic, strong, readonly) id<MTLCommandBuffer> commandBuffer;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

/// Use this method in -[MTIImagePromise resolveWithContext:error:] to get the resolved dependencies of the promise. The `image` parameter must be one of the resolving promise's dependencies. An exception is thrown when calling this method outside the -[MTIImagePromise resolveWithContext:error:] method or passing an invalid image.
- (id<MTLTexture>)resolvedTextureForImage:(MTIImage *)image;

@end

NS_ASSUME_NONNULL_END

#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIContext.h>
#else
#import "MTIContext.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface MTIContext (RenderedImageBuffer)

- (nullable MTIImage *)renderedBufferForImage:(MTIImage *)targetImage;

@end

NS_ASSUME_NONNULL_END
