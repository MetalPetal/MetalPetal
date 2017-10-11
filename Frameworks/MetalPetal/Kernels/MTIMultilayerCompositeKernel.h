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

NS_ASSUME_NONNULL_BEGIN

@class MTIRenderPipeline, MTIFunctionDescriptor, MTIContext, MTIImage;

@interface MTICompositingLayer: NSObject

@property (nonatomic, strong, readonly) MTIImage *content;

@property (nonatomic, readonly) CGPoint position; //pixel

@property (nonatomic, readonly) CGSize size; //pixel

@property (nonatomic, readonly) CGFloat rotation; //rad

@property (nonatomic, readonly) CGFloat opacity;

@property (nonatomic, copy, readonly) MTIBlendMode blendMode;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithContent:(MTIImage *)content
                       position:(CGPoint)position
                           size:(CGSize)size
                       rotation:(CGFloat)rotation
                        opacity:(CGFloat)opacity
                      blendMode:(MTIBlendMode)blendMode NS_DESIGNATED_INITIALIZER;

@end

@interface MTIMultilayerCompositeKernel : NSObject <MTIKernel>

- (MTIImage *)applyToBackgroundImage:(MTIImage *)image
                              layers:(NSArray<MTICompositingLayer *> *)layers
             outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions;

@end

NS_ASSUME_NONNULL_END
