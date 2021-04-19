//
//  MTIRGBColorSpaceConversionFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 2019/2/11.
//

#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIUnaryImageRenderingFilter.h>
#else
#import "MTIUnaryImageRenderingFilter.h"
#endif

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

typedef NS_ENUM(NSInteger, MTIRGBColorSpace) {
    MTIRGBColorSpaceLinearSRGB = 0,
    MTIRGBColorSpaceSRGB NS_SWIFT_NAME(sRGB) = 1,
    MTIRGBColorSpaceITUR709 NS_SWIFT_NAME(itur709) = 2,
};

__attribute__((objc_subclassing_restricted))
@interface MTIRGBColorSpaceConversionFilter : NSObject <MTIUnaryFilter>

@property (nonatomic) MTIRGBColorSpace inputColorSpace;
@property (nonatomic) MTIRGBColorSpace outputColorSpace;

@property (nonatomic) MTIAlphaType outputAlphaType;

+ (MTIImage *)imageByConvertingImage:(MTIImage *)image
                      fromColorSpace:(MTIRGBColorSpace)inputColorSpace
                        toColorSpace:(MTIRGBColorSpace)outputColorSpace
                     outputAlphaType:(MTIAlphaType)outputAlphaType
                   outputPixelFormat:(MTLPixelFormat)pixelFormat NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
