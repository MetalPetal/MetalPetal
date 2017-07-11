//
//  MTIImageRenderingContext.h
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MTIContext.h"
#import "MTIDrawableRendering.h"

@class MTIImage;

NS_ASSUME_NONNULL_BEGIN

@interface MTIImageRenderingContext : NSObject

@property (nonatomic, strong, readonly) MTIContext *context;

@property (nonatomic, strong, readonly) id<MTLCommandBuffer> commandBuffer;

- (instancetype)init NS_UNAVAILABLE;

@end


@interface MTIContext (Rendering)

- (void)renderImage:(MTIImage *)image toPixelBuffer:(CVPixelBufferRef)pixelBuffer error:(NSError **)error;

- (void)renderImage:(MTIImage *)image toDrawableWithRequest:(MTIDrawableRenderingRequest *)request error:(NSError **)error;

- (nullable CIImage *)createCIImage:(MTIImage *)image error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
