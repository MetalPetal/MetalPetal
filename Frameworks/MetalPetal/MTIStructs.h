//
//  MTIStructs.h
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#import <simd/simd.h>

struct MTIVertex {
    float x, y, z, w, u, v;
};
typedef struct MTIVertex MTIVertex;

struct MTIUniforms {
    matrix_float4x4 modelViewProjectionMatrix;
};
typedef struct MTIUniforms MTIUniforms;

