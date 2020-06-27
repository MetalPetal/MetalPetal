//
//  MTIDotScreenFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 18/01/2018.
//

#import <simd/simd.h>
#import <MTIUnaryImageRenderingFilter.h>

__attribute__((objc_subclassing_restricted))
@interface MTIDotScreenFilter : MTIUnaryImageRenderingFilter

@property (nonatomic) float angle;

@property (nonatomic) float scale;

@property (nonatomic) simd_float3 grayColorTransform;

@end
