//
//  MTIShader.h
//  Pods
//
//  Created by YuAo on 02/07/2017.
//
//

#ifndef MTIShader_h
#define MTIShader_h

#if defined(__cplusplus)

#if __has_include(<metal_stdlib>)

#include <metal_stdlib>

using namespace metal;

#endif

#endif

#import <simd/simd.h>

struct MTIVertex {
    vector_float4 position;
    vector_float2 textureCoordinate;
};
typedef struct MTIVertex MTIVertex;

#if defined(__cplusplus)

#if __has_include(<metal_stdlib>)

namespace metalpetal {
    
    typedef ::MTIVertex VertexIn;
    
    struct VertexOut {
        float4 position [[ position ]];
        float2 texcoords;
    };
    
    METAL_FUNC float4 unpremultiply(float4 s) {
        return s.a > 0 ? float4(s.rgb/s.a, s.a) : float4(0);
    }
    
    METAL_FUNC float4 premultiply(float4 s) {
        return float4(s.rgb * s.a, s.a);
    }
    
    //source over blend
    METAL_FUNC float4 normalBlend(float4 Cb, float4 Cf) {
        float4 dst = premultiply(Cb);
        float4 src = premultiply(Cf);
        return unpremultiply(src + dst * (1.0 - src.a));
    }
    
    METAL_FUNC float4 multiplyBlend(float4 Cb, float4 Cs) {
        float3 B = clamp(Cb.rgb * Cs.rgb, float3(0), float3(1));
        return normalBlend(Cb, float4(B, Cs.a));
    }
    
    METAL_FUNC float4 hardLightBlend(float4 Cb, float4 Cs) {
        return Cs;
    }
    
}

#endif

#endif

#endif /* MTIShader_h */
