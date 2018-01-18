//
//  MTIColorHalftoneFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 17/01/2018.
//

#import "MTIUnaryImageRenderingFilter.h"
#import <simd/simd.h>

@interface MTIColorHalftoneFilter : MTIUnaryImageRenderingFilter

@property (nonatomic) float scale;

@property (nonatomic) simd_float4 angles;

@end
