//
//  MTIColorMatrixFilter.h
//  Pods
//
//  Created by yi chen on 2017/7/27.
//
//

#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIUnaryImageRenderingFilter.h>
#import <MetalPetal/MTIColorMatrix.h>
#else
#import "MTIUnaryImageRenderingFilter.h"
#import "MTIColorMatrix.h"
#endif

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const MTIColorMatrixFilterColorMatrixParameterKey;

@interface MTIColorMatrixFilter : MTIUnaryImageRenderingFilter

@property (nonatomic) MTIColorMatrix colorMatrix;

@end

__attribute__((objc_subclassing_restricted))
@interface MTIExposureFilter : MTIColorMatrixFilter

- (void)setColorMatrix:(MTIColorMatrix)colorMatrix NS_UNAVAILABLE;

@property (nonatomic) float exposure;

@end

__attribute__((objc_subclassing_restricted))
@interface MTISaturationFilter : MTIColorMatrixFilter

- (void)setColorMatrix:(MTIColorMatrix)colorMatrix NS_UNAVAILABLE;

@property (nonatomic) simd_float3 grayColorTransform;

@property (nonatomic) float saturation;

@end

__attribute__((objc_subclassing_restricted))
@interface MTIColorInvertFilter : MTIColorMatrixFilter

- (void)setColorMatrix:(MTIColorMatrix)colorMatrix NS_UNAVAILABLE;

@end

__attribute__((objc_subclassing_restricted))
@interface MTIOpacityFilter: MTIColorMatrixFilter

- (void)setColorMatrix:(MTIColorMatrix)colorMatrix NS_UNAVAILABLE;

@property (nonatomic) float opacity;

@end

__attribute__((objc_subclassing_restricted))
@interface MTIBrightnessFilter: MTIColorMatrixFilter

- (void)setColorMatrix:(MTIColorMatrix)colorMatrix NS_UNAVAILABLE;

@property (nonatomic) float brightness;

@end

__attribute__((objc_subclassing_restricted))
@interface MTIContrastFilter: MTIColorMatrixFilter

- (void)setColorMatrix:(MTIColorMatrix)colorMatrix NS_UNAVAILABLE;

@property (nonatomic) float contrast;

@end

NS_ASSUME_NONNULL_END
