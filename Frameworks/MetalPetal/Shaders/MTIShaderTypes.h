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
    
    METAL_FUNC float4 hardLightBlend(float4 uCb, float4 uCf) {
        float4 Ct = select(1.0 - 2.0 * (1.0 - uCf) * (1.0 - uCb), 2.0 * uCf * uCb, uCf < float4(0.5));
        float4 Cb = float4(uCb.rgb * uCb.a, uCb.a);
        Ct = mix(uCf, Ct, uCb.a);
        Ct.a = 1.0;
        return mix(Cb, Ct, uCf.a);
    }
}

#endif

#endif

#endif /* MTIShader_h */
