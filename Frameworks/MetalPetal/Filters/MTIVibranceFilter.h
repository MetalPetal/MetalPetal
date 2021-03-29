//
//  MTIVibranceFilter.h
//  MetalPetal
//
//  Created by 杨乃川 on 2017/11/6.
//

#import <simd/simd.h>
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIUnaryImageRenderingFilter.h>
#else
#import "MTIUnaryImageRenderingFilter.h"
#endif

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface MTIVibranceFilter : MTIUnaryImageRenderingFilter

/// Specifies the scale of the operation in the range of -1 to 1, with 0 being no-change.
@property (nonatomic) float amount;

@property (nonatomic) BOOL avoidsSaturatingSkinTones;

@property (nonatomic) simd_float3 grayColorTransform;

@end

NS_ASSUME_NONNULL_END
