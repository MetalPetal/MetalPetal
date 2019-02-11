//
//  MTIUnpremultiplyAlphaFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 30/09/2017.
//

#import "MTIFilter.h"
#import "MTIUnaryImageRenderingFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIUnpremultiplyAlphaFilter : MTIUnaryImageRenderingFilter

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image;

@end

@interface MTIPremultiplyAlphaFilter : MTIUnaryImageRenderingFilter

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image;

@end

/// Unpremultiply alpha and convert to linear RGB
@interface MTIUnpremultiplyAlphaWithSRGBToLinearRGBFilter : MTIUnaryImageRenderingFilter

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image;

@end

NS_ASSUME_NONNULL_END
