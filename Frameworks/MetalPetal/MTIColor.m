//
//  MTIColor.m
//  MetalPetal
//
//  Created by Yu Ao on 10/10/2017.
//

#import "MTIColor.h"

MTIColor MTIColorMake(float red, float green, float blue, float alpha) {
    return (MTIColor){red,green,blue,alpha};
}

simd_float4 MTIColorToFloat4(MTIColor color) {
    return simd_make_float4(color.red, color.green, color.blue, color.alpha);
}

MTIColor const MTIColorWhite = (MTIColor){.red = 1, .green = 1, .blue = 1, .alpha = 1};
MTIColor const MTIColorBlack = (MTIColor){.red = 0, .green = 0, .blue = 0, .alpha = 1};
MTIColor const MTIColorClear = (MTIColor){.red = 0, .green = 0, .blue = 0, .alpha = 0};

simd_float3 const MTIGrayColorTransform_ITU_R_601 = (simd_float3){0.299f, 0.587f, 0.114f};
simd_float3 const MTIGrayColorTransform_ITU_R_709 = (simd_float3){0.2126f, 0.7152f, 0.0722f};

simd_float3 const MTIGrayColorTransformDefault = MTIGrayColorTransform_ITU_R_601;
