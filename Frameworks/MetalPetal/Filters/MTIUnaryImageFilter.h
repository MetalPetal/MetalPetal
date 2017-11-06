//
//  MTIUnaryImageFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 10/10/2017.
//

#import "MTIFilter.h"
#import "MTIImageOrientation.h"
#import "MTIAlphaType.h"

NS_ASSUME_NONNULL_BEGIN

@class MTIRenderPipelineKernel;

@interface MTIUnaryImageFilter : NSObject <MTIFilter>

+ (MTIRenderPipelineKernel *)kernel;

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@property (nonatomic) MTIImageOrientation inputRotation; //Rotate the input image to that orientation.

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image withInputParameters:(NSDictionary<NSString *,id> *)parameters outputPixelFormat:(MTLPixelFormat)outputPixelFormat;

@end

@interface MTIUnaryImageFilter (SubclassingHooks)

@property (nonatomic,copy,readonly) NSDictionary<NSString *, id> *parameters;

+ (NSString *)fragmentFunctionName;

+ (MTIAlphaTypeHandlingRule *)alphaTypeHandlingRule;

@end

NS_ASSUME_NONNULL_END
