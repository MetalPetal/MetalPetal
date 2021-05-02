//
//  MTIColor.h
//  MetalPetal
//
//  Created by Yu Ao on 10/10/2017.
//

#import <Foundation/Foundation.h>
#import <simd/simd.h>

typedef NS_ENUM(NSInteger, MTIColorComponent) {
    MTIColorComponentRed,
    MTIColorComponentGreen,
    MTIColorComponentBlue,
    MTIColorComponentAlpha
};

struct MTIColor {
    float red;
    float green;
    float blue;
    float alpha;
};
typedef struct MTIColor MTIColor;

NS_INLINE NS_SWIFT_UNAVAILABLE("Use MTIColor.init instead.") MTIColor MTIColorMake(float red, float green, float blue, float alpha) {
    return (MTIColor){ red, green, blue, alpha };
}

NS_INLINE NS_SWIFT_NAME(MTIColor.toFloat4(self:)) simd_float4 MTIColorToFloat4(MTIColor color) {
    return simd_make_float4(color.red, color.green, color.blue, color.alpha);
}

FOUNDATION_EXPORT MTIColor const MTIColorWhite NS_SWIFT_NAME(MTIColor.white);
FOUNDATION_EXPORT MTIColor const MTIColorBlack NS_SWIFT_NAME(MTIColor.black);
FOUNDATION_EXPORT MTIColor const MTIColorClear NS_SWIFT_NAME(MTIColor.clear);

FOUNDATION_EXPORT simd_float3 const MTIGrayColorTransformDefault; //MTIGrayColorTransform_ITU_R_601
FOUNDATION_EXPORT simd_float3 const MTIGrayColorTransform_ITU_R_601; //0.299, 0.587, 0.114
FOUNDATION_EXPORT simd_float3 const MTIGrayColorTransform_ITU_R_709; //0.2126, 0.7152, 0.0722
