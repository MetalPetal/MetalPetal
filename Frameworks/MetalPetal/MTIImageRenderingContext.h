//
//  MTIImageRenderingContext.h
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MTIImagePromise.h"

@class MTIImage, MTIContext;

NS_ASSUME_NONNULL_BEGIN

/*! @brief Rendering context related constant for MTIContextImageAssociatedValueTableName. */
FOUNDATION_EXPORT NSString * const MTIContextImagePersistentResolutionHolderTableName;

@protocol MTIImagePromiseResolution <NSObject>

@property (nonatomic,readonly) id<MTLTexture> texture;

- (void)markAsConsumedBy:(id)consumer;

@end

@interface MTIImageRenderingContext : NSObject

@property (nonatomic, strong, readonly) MTIContext *context;

@property (nonatomic, strong, readonly) id<MTLCommandBuffer> commandBuffer;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithContext:(MTIContext *)context;

- (nullable id<MTIImagePromiseResolution>)resolutionForImage:(MTIImage *)image error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END


#import "MTIContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIContext (RenderedImageBuffer)

- (nullable MTIImage *)renderedBufferForImage:(MTIImage *)targetImage;

@end

NS_ASSUME_NONNULL_END
