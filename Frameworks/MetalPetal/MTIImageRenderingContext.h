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

- (instancetype)initWithContext:(MTIContext *)context;

- (nullable id<MTIImagePromiseResolution>)resolutionForImage:(MTIImage *)image error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
