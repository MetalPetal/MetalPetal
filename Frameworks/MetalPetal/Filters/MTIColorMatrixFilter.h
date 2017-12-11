//
//  MTIColorMatrixFilter.h
//  Pods
//
//  Created by yi chen on 2017/7/27.
//
//

#import "MTIFilter.h"
#import "MTIUnaryImageRenderingFilter.h"
#import "MTIColorMatrix.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const MTIColorMatrixFilterColorMatrixParameterKey;

@interface MTIColorMatrixFilter : MTIUnaryImageRenderingFilter

@property (nonatomic) MTIColorMatrix colorMatrix;

@end

@interface MTIExposureFilter : MTIColorMatrixFilter

- (void)setColorMatrix:(MTIColorMatrix)colorMatrix NS_UNAVAILABLE;

@property (nonatomic) float exposure;

@end

@interface MTISaturationFilter : MTIColorMatrixFilter

- (void)setColorMatrix:(MTIColorMatrix)colorMatrix NS_UNAVAILABLE;

@property (nonatomic) simd_float3 grayColorTransform;

@property (nonatomic) float saturation;

@end

@interface MTIColorInvertFilter : MTIColorMatrixFilter

- (void)setColorMatrix:(MTIColorMatrix)colorMatrix NS_UNAVAILABLE;

@end

@interface MTIOpacityFilter: MTIColorMatrixFilter

- (void)setColorMatrix:(MTIColorMatrix)colorMatrix NS_UNAVAILABLE;

@property (nonatomic) float opacity;

@end

@interface MTIBrightnessFilter: MTIColorMatrixFilter

- (void)setColorMatrix:(MTIColorMatrix)colorMatrix NS_UNAVAILABLE;

@property (nonatomic) float brightness;

@end

@interface MTIContrastFilter: MTIColorMatrixFilter

- (void)setColorMatrix:(MTIColorMatrix)colorMatrix NS_UNAVAILABLE;

@property (nonatomic) float contrast;

@end

NS_ASSUME_NONNULL_END
