//
//  MTIDotScreenFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 18/01/2018.
//

#import <simd/simd.h>
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIUnaryImageRenderingFilter.h>
#else
#import "MTIUnaryImageRenderingFilter.h"
#endif

__attribute__((objc_subclassing_restricted))
@interface MTIDotScreenFilter : MTIUnaryImageRenderingFilter

/// Specifies the angle of the effect.
@property (nonatomic) float angle;

/// Specifies the scale of the operation, i.e. the size for the pixels in the resulting image.
@property (nonatomic) float scale;

@property (nonatomic) simd_float3 grayColorTransform;

@end
