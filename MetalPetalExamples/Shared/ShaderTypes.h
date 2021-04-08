//
//  ShaderTypes.h
//  MetalPetalDemo
//
//  Created by YuAo on 2021/4/4.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

struct ParticleData {
    vector_float2 position;
    vector_float2 speed;
    float size;
};

#endif /* ShaderTypes_h */
