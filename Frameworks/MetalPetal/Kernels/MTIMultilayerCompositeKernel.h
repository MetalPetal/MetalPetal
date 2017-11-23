//
//  MTIMultilayerRenderPipelineKernel.h
//  MetalPetal
//
//  Created by YuAo on 27/09/2017.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MTIKernel.h"
#import "MTIBlendModes.h"
#import "MTITextureDimensions.h"
#import "MTIPixelFormat.h"
#import "MTIImagePromise.h"

NS_ASSUME_NONNULL_BEGIN

@class MTIRenderPipeline, MTIFunctionDescriptor, MTIContext, MTIImage, MTILayer;

@interface MTIMultilayerCompositeKernel : NSObject <MTIKernel>

- (MTIImage *)applyToBackgroundImage:(MTIImage *)image
                              layers:(NSArray<MTILayer *> *)layers
             outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions
                   outputPixelFormat:(MTLPixelFormat)outputPixelFormat;

@end

@class MTIRenderGraphNode;

FOUNDATION_EXPORT void MTIMultilayerCompositingRenderGraphNodeOptimize(MTIRenderGraphNode *node);

NS_ASSUME_NONNULL_END
