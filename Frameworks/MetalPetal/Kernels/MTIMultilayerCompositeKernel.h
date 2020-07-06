//
//  MTIMultilayerRenderPipelineKernel.h
//  MetalPetal
//
//  Created by YuAo on 27/09/2017.
//

#import <Metal/Metal.h>
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIKernel.h>
#import <MetalPetal/MTITextureDimensions.h>
#else
#import "MTIKernel.h"
#import "MTITextureDimensions.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@class MTIRenderPipeline, MTIFunctionDescriptor, MTIContext, MTIImage, MTILayer;

__attribute__((objc_subclassing_restricted))
@interface MTIMultilayerCompositeKernel : NSObject <MTIKernel>

- (MTIImage *)applyToBackgroundImage:(MTIImage *)image
                              layers:(NSArray<MTILayer *> *)layers
                   rasterSampleCount:(NSUInteger)rasterSampleCount
             outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions
                   outputPixelFormat:(MTLPixelFormat)outputPixelFormat;

@end

@class MTIRenderGraphNode;

FOUNDATION_EXPORT void MTIMultilayerCompositingRenderGraphNodeOptimize(MTIRenderGraphNode *node);

NS_ASSUME_NONNULL_END
