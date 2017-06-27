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

@interface MTIImageRenderingContext : NSObject

@property (nonatomic, strong, readonly) MTIContext *context;

@property (nonatomic, strong, readonly) id<MTLCommandBuffer> commandBuffer;

- (instancetype)initWithContext:(MTIContext *)context;

- (void)renderImage:(MTIImage *)image toPixelBuffer:(CVPixelBufferRef)pixelBuffer error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
