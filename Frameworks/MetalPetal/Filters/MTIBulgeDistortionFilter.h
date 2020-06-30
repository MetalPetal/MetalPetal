//
//  MTIBulgeDistortionFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 2019/2/14.
//

#import <simd/simd.h>
#import <MTIUnaryImageRenderingFilter.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface MTIBulgeDistortionFilter : MTIUnaryImageRenderingFilter

@property (nonatomic) simd_float2 center; //in pixels

@property (nonatomic) float radius; //in pixels

@property (nonatomic) float scale;


@end

NS_ASSUME_NONNULL_END
