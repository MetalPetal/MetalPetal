//
//  MTIUnpremultiplyAlphaFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 30/09/2017.
//

#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIUnaryImageRenderingFilter.h>
#else
#import "MTIUnaryImageRenderingFilter.h"
#endif

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface MTIUnpremultiplyAlphaFilter : MTIUnaryImageRenderingFilter

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image;

@end

__attribute__((objc_subclassing_restricted))
@interface MTIPremultiplyAlphaFilter : MTIUnaryImageRenderingFilter

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image;

@end

/// Unpremultiply alpha and convert to linear RGB
__attribute__((objc_subclassing_restricted))
@interface MTIUnpremultiplyAlphaWithSRGBToLinearRGBFilter : MTIUnaryImageRenderingFilter

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image;

@end

NS_ASSUME_NONNULL_END
