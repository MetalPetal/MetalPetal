//
//  MTIBulgeDistortionFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 2019/2/14.
//

#import "MTIUnaryImageRenderingFilter.h"
#import <simd/simd.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTIBulgeDistortionFilter : MTIUnaryImageRenderingFilter

@property (nonatomic) simd_float2 center; //in pixels

@property (nonatomic) float radius; //in pixels

@property (nonatomic) float scale;


@end

NS_ASSUME_NONNULL_END
