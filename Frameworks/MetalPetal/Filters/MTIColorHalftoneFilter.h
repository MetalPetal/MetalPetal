//
//  MTIColorHalftoneFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 17/01/2018.
//

#import <simd/simd.h>
#import <MTIUnaryImageRenderingFilter.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface MTIColorHalftoneFilter : MTIUnaryImageRenderingFilter

@property (nonatomic) float scale;

@property (nonatomic) simd_float4 angles;

@end

NS_ASSUME_NONNULL_END
