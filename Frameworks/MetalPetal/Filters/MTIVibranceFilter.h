//
//  MTIVibranceFilter.h
//  MetalPetal
//
//  Created by 杨乃川 on 2017/11/6.
//

#import <simd/simd.h>
#import "MTIUnaryImageRenderingFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIVibranceFilter : MTIUnaryImageRenderingFilter

@property (nonatomic) float amount;

@property (nonatomic) BOOL avoidsSaturatingSkinTones;

@property (nonatomic) simd_float3 grayColorTransform;

@end

NS_ASSUME_NONNULL_END
