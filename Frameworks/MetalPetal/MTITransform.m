//
//  MTITransform.m
//  MetalPetal
//
//  Created by Yu Ao on 28/10/2017.
//

#import "MTITransform.h"

simd_float4x4 MTIMakeOrthographicMatrix(float left, float right, float top, float bottom, float near, float far) {
    float r_l = right - left;
    float t_b = bottom - top;
    float f_n = far - near;
    float tx = - (right + left) / (right - left);
    float ty = - (top + bottom) / (bottom - top);
    float tz = - (far + near) / (far - near);
    
    float scale = 2.0f;
    
    simd_float4x4 matrix;
    
    matrix.columns[0][0] = scale / r_l;
    matrix.columns[0][1] = 0.0f;
    matrix.columns[0][2] = 0.0f;
    matrix.columns[0][3] = tx;
    
    matrix.columns[1][0] = 0.0f;
    matrix.columns[1][1] = scale / t_b;
    matrix.columns[1][2] = 0.0f;
    matrix.columns[1][3] = ty;
    
    matrix.columns[2][0] = 0.0f;
    matrix.columns[2][1] = 0.0f;
    matrix.columns[2][2] = scale / f_n;
    matrix.columns[2][3] = tz;
    
    matrix.columns[3][0] = 0.0f;
    matrix.columns[3][1] = 0.0f;
    matrix.columns[3][2] = 0.0f;
    matrix.columns[3][3] = 1.0f;
    
    return matrix;
}

simd_float4x4 MTIMakePerspectiveMatrix(float left, float right, float top, float bottom, float near, float far) {
    simd_float4x4 matrix;
    near = -near;
    far = -far;
    
    matrix.columns[0][0] = 2 * near / (right - left);
    matrix.columns[0][1] = 0.0f;
    matrix.columns[0][2] = (right + left)/(right - left);
    matrix.columns[0][3] = 0;
    
    matrix.columns[1][0] = 0.0f;
    matrix.columns[1][1] = 2 * near/ (bottom - top);
    matrix.columns[1][2] = (top + bottom) / (bottom - top);
    matrix.columns[1][3] = 0;
    
    matrix.columns[2][0] = 0.0f;
    matrix.columns[2][1] = 0.0f;
    matrix.columns[2][2] = - (far) / (far - near);
    matrix.columns[2][3] = - (far * near) / (far - near);
    
    matrix.columns[3][0] = 0.0f;
    matrix.columns[3][1] = 0.0f;
    matrix.columns[3][2] = -1.0f;
    matrix.columns[3][3] = 0.0f;
    
    return matrix;
}

simd_float4x4 MTIMakeTransformMatrixFromCATransform3D(CATransform3D transform) {
    simd_float4x4 matrix = simd_matrix_from_rows(simd_make_float4((float)transform.m11,(float)transform.m12,(float)transform.m13,(float)transform.m14),
                                       simd_make_float4((float)transform.m21,(float)transform.m22,(float)transform.m23,(float)transform.m24),
                                       simd_make_float4((float)transform.m31,(float)transform.m32,(float)transform.m33,(float)transform.m34),
                                       simd_make_float4((float)transform.m41,(float)transform.m42,(float)transform.m43,(float)transform.m44));
    return matrix;
}
