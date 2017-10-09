//
//  MTIImageRenderingContext.h
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@class MTIImage, MTIContext;

NS_ASSUME_NONNULL_BEGIN

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

@interface MTIImageBuffer : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

/// Returns an image representing the render result for the target image. The target image's cache policy must be MTIImageCachePolicyPersistent. You should render the buffer image after the target image is rendered. Rendering the buffer image before the target image is rendered produces an error (MTIErrorFailedToGetRenderedBuffer). The buffer image retains the target image till it is rendered.
+ (MTIImage *)bufferForImage:(MTIImage *)targetImage;

@end

NS_ASSUME_NONNULL_END
