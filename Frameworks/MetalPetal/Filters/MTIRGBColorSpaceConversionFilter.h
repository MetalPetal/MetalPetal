//
//  MTIRGBColorSpaceConversionFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 2019/2/11.
//

#import "MTIUnaryImageRenderingFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTILinearToSRGBToneCurveFilter : MTIUnaryImageRenderingFilter

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image;

@end

@interface MTISRGBToneCurveToLinearFilter: MTIUnaryImageRenderingFilter

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image;

@end

NS_ASSUME_NONNULL_END
