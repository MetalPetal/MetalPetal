//
//  MTIColorMatrix.m
//  MetalPetal
//
//  Created by Yu Ao on 25/10/2017.
//

#import "MTIColorMatrix.h"
#import <Accelerate/Accelerate.h>

const MTIColorMatrix MTIColorMatrixIdentity = (MTIColorMatrix){
    .matrix = (matrix_float4x4){
        (simd_float4){1,0,0,0},
        (simd_float4){0,1,0,0},
        (simd_float4){0,0,1,0},
        (simd_float4){0,0,0,1}
    },
    .bias = (simd_float4){0,0,0,0}
};

const MTIColorMatrix MTIColorMatrixRGBColorInvert = (MTIColorMatrix){
    .matrix = (matrix_float4x4){
        (simd_float4){-1,0,0,0},
        (simd_float4){0,-1,0,0},
        (simd_float4){0,0,-1,0},
        (simd_float4){0,0,0,1}
    },
    .bias = (simd_float4){1,1,1,0}
};

static void MTIColorMatrixFillFloat5x5(MTIColorMatrix a, float storage[5][5]) {
    storage[0][0] = a.matrix.columns[0][0];
    storage[1][0] = a.matrix.columns[0][1];
    storage[2][0] = a.matrix.columns[0][2];
    storage[3][0] = a.matrix.columns[0][3];
    
    storage[0][1] = a.matrix.columns[1][0];
    storage[1][1] = a.matrix.columns[1][1];
    storage[2][1] = a.matrix.columns[1][2];
    storage[3][1] = a.matrix.columns[1][3];
    
    storage[0][2] = a.matrix.columns[2][0];
    storage[1][2] = a.matrix.columns[2][1];
    storage[2][2] = a.matrix.columns[2][2];
    storage[3][2] = a.matrix.columns[2][3];
    
    storage[0][3] = a.matrix.columns[3][0];
    storage[1][3] = a.matrix.columns[3][1];
    storage[2][3] = a.matrix.columns[3][2];
    storage[3][3] = a.matrix.columns[3][3];
    
    storage[0][4] = 0;
    storage[1][4] = 0;
    storage[2][4] = 0;
    storage[3][4] = 0;
    
    storage[4][0] = a.bias[0];
    storage[4][1] = a.bias[1];
    storage[4][2] = a.bias[2];
    storage[4][3] = a.bias[3];
    
    storage[4][4] = 1;
}

static MTIColorMatrix MTIColorMatrixMakeFromFloat5x5(float storage[5][5]) {
    MTIColorMatrix m = MTIColorMatrixIdentity;
    
    m.matrix.columns[0][0] = storage[0][0];
    m.matrix.columns[0][1] = storage[1][0];
    m.matrix.columns[0][2] = storage[2][0];
    m.matrix.columns[0][3] = storage[3][0];
    
    m.matrix.columns[1][0] = storage[0][1];
    m.matrix.columns[1][1] = storage[1][1];
    m.matrix.columns[1][2] = storage[2][1];
    m.matrix.columns[1][3] = storage[3][1];
    
    m.matrix.columns[2][0] = storage[0][2];
    m.matrix.columns[2][1] = storage[1][2];
    m.matrix.columns[2][2] = storage[2][2];
    m.matrix.columns[2][3] = storage[3][2];
    
    m.matrix.columns[3][0] = storage[0][3];
    m.matrix.columns[3][1] = storage[1][3];
    m.matrix.columns[3][2] = storage[2][3];
    m.matrix.columns[3][3] = storage[3][3];
    
    m.bias[0] = storage[4][0];
    m.bias[1] = storage[4][1];
    m.bias[2] = storage[4][2];
    m.bias[3] = storage[4][3];
    
    return m;
}

BOOL MTIColorMatrixEqualToColorMatrix(MTIColorMatrix a, MTIColorMatrix b) {
    return simd_equal(a.matrix, b.matrix) && simd_equal(a.bias, b.bias);
}

BOOL MTIColorMatrixIsIdentity(MTIColorMatrix matrix) {
    return MTIColorMatrixEqualToColorMatrix(matrix, MTIColorMatrixIdentity);
}

MTIColorMatrix MTIColorMatrixConcat(MTIColorMatrix matrixA, MTIColorMatrix matrixB) {
    float a[5][5];
    MTIColorMatrixFillFloat5x5(matrixA, a);
    float b[5][5];
    MTIColorMatrixFillFloat5x5(matrixB, b);
    float result[5][5];
    vDSP_mmul(*a, 1, *b, 1, *result, 1, 5, 5, 5);
    return MTIColorMatrixMakeFromFloat5x5(result);
}

MTIColorMatrix MTIColorMatrixMakeWithExposure(float exposure) {
    float power = pow(2, exposure);
    simd_float4x4 matrix = matrix_scale(power, matrix_identity_float4x4);
    matrix.columns[3][3] = 1;
    MTIColorMatrix m = MTIColorMatrixIdentity;
    m.matrix = matrix;
    return m;
}

MTIColorMatrix MTIColorMatrixMakeWithSaturation(float saturation, simd_float3 grayColorTransform) {
    float lumR = grayColorTransform.r;
    float lumG = grayColorTransform.g;
    float lumB = grayColorTransform.b;
    float s = saturation;
    float sr = (1 - s) * lumR;
    float sg = (1 - s) * lumG;
    float sb = (1 - s) * lumB;
    MTIColorMatrix m = MTIColorMatrixIdentity;
    m.matrix.columns[0][0] = sr+s;
    m.matrix.columns[1][0] = sr;
    m.matrix.columns[2][0] = sr;
    m.matrix.columns[0][1] = sg;
    m.matrix.columns[1][1] = sg+s;
    m.matrix.columns[2][1] = sg;
    m.matrix.columns[0][2] = sb;
    m.matrix.columns[1][2] = sb;
    m.matrix.columns[2][2] = sb+s;
    return m;
}

MTIColorMatrix MTIColorMatrixMakeWithBrightness(float brightness) {
    MTIColorMatrix m = MTIColorMatrixIdentity;
    m.bias[0] = brightness;
    m.bias[1] = brightness;
    m.bias[2] = brightness;
    return m;
}

MTIColorMatrix MTIColorMatrixMakeWithContrast(float contrast) {
    float c = contrast;
    float t = (1 - c) / 2.0;
    MTIColorMatrix m = MTIColorMatrixIdentity;
    m.bias[0] = t;
    m.bias[1] = t;
    m.bias[2] = t;
    
    simd_float4x4 matrix = matrix_scale(c, matrix_identity_float4x4);
    matrix.columns[3][3] = 1;
    m.matrix = matrix;
    
    return m;
}

MTIColorMatrix MTIColorMatrixMakeWithOpacity(float opacity) {
    MTIColorMatrix m = MTIColorMatrixIdentity;
    m.matrix.columns[3][3] = opacity;
    return m;
}
