//
//  MTIColorHalftoneFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 17/01/2018.
//

#import "MTIUnaryImageRenderingFilter.h"
#import <simd/simd.h>

typedef NS_ENUM(NSInteger, MTIColorHalftoneMode) {
    MTIColorHalftoneModeCMYK = 0,
    MTIColorHalftoneModeGrayscale = 1
};

@interface MTIColorHalftoneFilter : MTIUnaryImageRenderingFilter

@property (nonatomic) MTIColorHalftoneMode mode;

@property (nonatomic) float radius;

@property (nonatomic) simd_float4 angles;

@end
