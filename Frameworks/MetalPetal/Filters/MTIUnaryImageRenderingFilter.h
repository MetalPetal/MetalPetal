//
//  MTIUnaryImageFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 10/10/2017.
//

#import "MTIFilter.h"
#import "MTIImageOrientation.h"
#import "MTIAlphaType.h"
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@class MTIRenderPipelineKernel, MTIFunctionDescriptor;

@interface MTIUnaryImageRenderingFilter : NSObject <MTIUnaryFilter>

+ (MTIRenderPipelineKernel *)kernel;

@property (nonatomic) MTIImageOrientation orientation; //Rotate the canvas to that orientation.

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image withInputParameters:(NSDictionary<NSString *,id> *)parameters outputPixelFormat:(MTLPixelFormat)outputPixelFormat;

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image orientation:(MTIImageOrientation)orientation parameters:(NSDictionary<NSString *,id> *)parameters outputPixelFormat:(MTLPixelFormat)outputPixelFormat;

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image orientation:(MTIImageOrientation)orientation parameters:(NSDictionary<NSString *,id> *)parameters outputPixelFormat:(MTLPixelFormat)outputPixelFormat outputImageSize:(CGSize)outputImageSize;

@end

@interface MTIUnaryImageRenderingFilter (SubclassingHooks)

@property (nonatomic,copy,readonly) NSDictionary<NSString *, id> *parameters;

- (CGSize)outputImageSizeForInputImage:(MTIImage *)inputImage;

+ (MTIFunctionDescriptor *)fragmentFunctionDescriptor;

+ (MTIAlphaTypeHandlingRule *)alphaTypeHandlingRule;

@end

NS_ASSUME_NONNULL_END
