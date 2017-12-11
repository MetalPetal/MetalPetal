//
//  MTIColorMatrix.h
//  MetalPetal
//
//  Created by Yu Ao on 25/10/2017.
//

#import <Foundation/Foundation.h>
#import "MTIShaderLib.h"

FOUNDATION_EXPORT const MTIColorMatrix MTIColorMatrixIdentity NS_SWIFT_NAME(MTIColorMatrix.identity);
FOUNDATION_EXPORT const MTIColorMatrix MTIColorMatrixRGBColorInvert NS_SWIFT_NAME(MTIColorMatrix.rgbColorInvert);

FOUNDATION_EXPORT BOOL MTIColorMatrixEqualToColorMatrix(MTIColorMatrix a, MTIColorMatrix b) NS_SWIFT_NAME(MTIColorMatrix.isEqual(self:to:));
FOUNDATION_EXPORT BOOL MTIColorMatrixIsIdentity(MTIColorMatrix matrix) NS_SWIFT_NAME(getter:MTIColorMatrix.isIdentity(self:));

FOUNDATION_EXPORT MTIColorMatrix MTIColorMatrixConcat(MTIColorMatrix a, MTIColorMatrix b) NS_SWIFT_NAME(MTIColorMatrix.concat(self:with:));

FOUNDATION_EXPORT MTIColorMatrix MTIColorMatrixMakeWithExposure(float exposure) NS_SWIFT_NAME(MTIColorMatrix.init(exposure:));
FOUNDATION_EXPORT MTIColorMatrix MTIColorMatrixMakeWithSaturation(float saturation, simd_float3 grayColorTransform) NS_SWIFT_NAME(MTIColorMatrix.init(saturation:grayColorTransform:));
FOUNDATION_EXPORT MTIColorMatrix MTIColorMatrixMakeWithBrightness(float brightness) NS_SWIFT_NAME(MTIColorMatrix.init(brightness:));
FOUNDATION_EXPORT MTIColorMatrix MTIColorMatrixMakeWithContrast(float contrast) NS_SWIFT_NAME(MTIColorMatrix.init(contrast:));
FOUNDATION_EXPORT MTIColorMatrix MTIColorMatrixMakeWithOpacity(float opacity) NS_SWIFT_NAME(MTIColorMatrix.init(opacity:));
