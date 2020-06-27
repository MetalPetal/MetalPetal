//
//  MTIRGBColorSpaceConversionFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 2019/2/11.
//

#import <MTIUnaryImageRenderingFilter.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface MTILinearToSRGBToneCurveFilter : MTIUnaryImageRenderingFilter

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image;

@end

__attribute__((objc_subclassing_restricted))
@interface MTISRGBToneCurveToLinearFilter: MTIUnaryImageRenderingFilter

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image;

@end

__attribute__((objc_subclassing_restricted))
@interface MTIITUR709RGBToLinearRGBFilter: MTIUnaryImageRenderingFilter

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image;

@end

__attribute__((objc_subclassing_restricted))
@interface MTIITUR709RGBToSRGBFilter: MTIUnaryImageRenderingFilter

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image;

@end

NS_ASSUME_NONNULL_END
