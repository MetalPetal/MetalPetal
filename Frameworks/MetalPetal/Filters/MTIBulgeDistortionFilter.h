//
//  MTIBulgeDistortionFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 2019/2/14.
//

#import <simd/simd.h>
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIUnaryImageRenderingFilter.h>
#else
#import "MTIUnaryImageRenderingFilter.h"
#endif

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface MTIBulgeDistortionFilter : MTIUnaryImageRenderingFilter

/// Specifies the center of the distortion in pixels.
@property (nonatomic) simd_float2 center;

/// Specifies the radius of the distortion in pixels.
@property (nonatomic) float radius;

/// Specifies the scale of the distortion, 0 being no-change.
@property (nonatomic) float scale;

@end

NS_ASSUME_NONNULL_END
