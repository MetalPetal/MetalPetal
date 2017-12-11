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

simd_float3 const MTIGrayColorTransform_ITU_R_601 = (simd_float3){0.299f, 0.587f, 0.114f};
simd_float3 const MTIGrayColorTransform_ITU_R_709 = (simd_float3){0.2126f, 0.7152f, 0.0722f};

simd_float3 const MTIGrayColorTransformDefault = MTIGrayColorTransform_ITU_R_601;
