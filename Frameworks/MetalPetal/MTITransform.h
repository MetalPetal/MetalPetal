//
//  MTITransform.h
//  MetalPetal
//
//  Created by Yu Ao on 28/10/2017.
//

#import <Foundation/Foundation.h>
#import <simd/simd.h>
#import <QuartzCore/QuartzCore.h>

FOUNDATION_EXPORT simd_float4x4 MTIMakeOrthographicMatrix(float left, float right, float top, float bottom, float near, float far);

FOUNDATION_EXPORT simd_float4x4 MTIMakePerspectiveMatrix(float left, float right, float top, float bottom, float near, float far);

FOUNDATION_EXPORT simd_float4x4 MTIMakeTransformMatrixFromCATransform3D(CATransform3D transform);
