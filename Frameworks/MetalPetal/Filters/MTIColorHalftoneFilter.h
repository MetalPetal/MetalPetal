//
//  MTIColorHalftoneFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 17/01/2018.
//

#import <simd/simd.h>
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIUnaryImageRenderingFilter.h>
#else
#import "MTIUnaryImageRenderingFilter.h"
#endif

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface MTIColorHalftoneFilter : MTIUnaryImageRenderingFilter

/// Specifies the scale of the operation, i.e. the size for the pixels in the resulting image.
@property (nonatomic) float scale;

/// Specifies the angles of the r, g, b channel.
@property (nonatomic) simd_float4 angles;

@end

NS_ASSUME_NONNULL_END
