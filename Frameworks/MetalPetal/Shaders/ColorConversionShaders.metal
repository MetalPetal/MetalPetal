//
//  ColorConversionShaders.metal
//  Pods
//
//  Created by jichuan on 2017/7/19.
//
//

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

namespace metalpetal {
    namespace yuv2rgbconvert {
        typedef struct {
            packed_float2 position;
            packed_float2 texcoord;
        } Vertex;

        typedef struct {
            float3x3 matrix;
            float3 offset;
        } ColorConversion;

        typedef struct {
            float4 position [[ position ]];
            float2 texcoord;
        } Varyings;

        vertex Varyings colorConversionVertex(const device Vertex * verticies [[ buffer(0) ]],
                                              unsigned int vid [[ vertex_id ]]) {
            Varyings out;
            Vertex v = verticies[vid];
            out.position = float4(float2(v.position), 0.0, 1.0);
            out.texcoord = v.texcoord;
            return out;
        }

        fragment half4 colorConversionFragment(Varyings in [[ stage_in ]],
                                               texture2d<float, access::sample> yTexture [[ texture(0) ]],
                                               texture2d<float, access::sample> cbcrTexture [[ texture(1) ]],
                                               constant ColorConversion &colorConversion [[ buffer(0) ]]) {
            
            constexpr sampler s(address::clamp_to_edge, filter::linear);
            float3 ycbcr = float3(yTexture.sample(s, in.texcoord).r, cbcrTexture.sample(s, in.texcoord).rg);
            float3 rgb = colorConversion.matrix * (ycbcr + colorConversion.offset);
            return half4(half3(rgb), 1.0);
        }

        kernel void colorConversion(uint2 gid [[ thread_position_in_grid ]],
                                    texture2d<float, access::read> yTexture [[ texture(0) ]],
                                    texture2d<float, access::read> cbcrTexture [[ texture(1) ]],
                                    texture2d<float, access::write> outTexture [[ texture(2) ]],
                                    constant ColorConversion &colorConversion [[ buffer(0) ]]) {
            
            uint2 cbcrCoordinates = uint2(gid.x / 2, gid.y / 2); // half the size because we are using a 4:2:0 chroma subsampling
            float y = yTexture.read(gid).r;
            float2 cbcr = cbcrTexture.read(cbcrCoordinates).rg;
            
            float3 ycbcr = float3(y, cbcr);
            float3 rgb = colorConversion.matrix * (ycbcr + colorConversion.offset);
            
            outTexture.write(float4(float3(rgb), 1.0), gid);
        }
    }
}
