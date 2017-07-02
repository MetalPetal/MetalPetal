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

namespace metalpetal {
    
    struct VertexIn {
        packed_float4 position [[ attribute(0) ]];
        packed_float2 texcoords [[ attribute(1) ]];
    };
    
    struct VertexOut {
        float4 position [[ position ]];
        float2 texcoords;
    };
    
}

#endif

#endif

#endif /* MTIShader_h */
