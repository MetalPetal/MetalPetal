//
//  Halftone.metal
//  MetalPetal
//
//  Created by Yu Ao on 18/01/2018.
//

#include "MTIShaderLib.h"

using namespace metal;
using namespace metalpetal;

namespace metalpetal {
    namespace halftone {
        float2x2 rotm(float r) {
            float cr = cos(r);
            float sr = sin(r);
            return float2x2(float2(cr,-sr),
                            float2(sr,cr));
        }
        
        float2 samplePosition(float2 textureCoordinate, float2x2 m, float scale) {
            float2 rotatedTextureCoordinate = m * textureCoordinate;
            return (rotatedTextureCoordinate - mod(rotatedTextureCoordinate, float2(scale)) + scale * 0.5) * m;
        }
        
        float halftoneIntensity(float2 textureCoordinate, float2 samplePos, float scale, float3 grayColorTransform, texture2d<float, access::sample> sourceTexture, sampler sourceSampler) {
            float2 textureSize = float2(sourceTexture.get_width(), sourceTexture.get_height());
            float4 textureColor = sourceTexture.sample(sourceSampler, samplePos/textureSize);
            float grayscale = dot(textureColor.rgb, grayColorTransform);
            float d = scale * 1.414214 * (1.0 - grayscale);
            float d1 = distance(textureCoordinate + float2(-0.25), samplePos);
            float d2 = distance(textureCoordinate + float2(0.25, -0.25), samplePos);
            float d3 = distance(textureCoordinate + float2(-0.25, 0.25), samplePos);
            float d4 = distance(textureCoordinate + float2(0.25), samplePos);
            return dot(float4(float4(d1,d2,d3,d4) < float4(d/2.0)), float4(0.25));
        }
        
        float3 halftoneIntensityRGB(float2 textureCoordinate, float2 samplePos, float scale, texture2d<float, access::sample> sourceTexture, sampler sourceSampler) {
            float2 textureSize = float2(sourceTexture.get_width(), sourceTexture.get_height());
            float4 textureColor = sourceTexture.sample(sourceSampler, samplePos/textureSize);
            float3 c = textureColor.rgb;
            float3 d = scale * 1.414214 * (1.0 - c);
            float d1 = distance(textureCoordinate + float2(-0.25), samplePos);
            float d2 = distance(textureCoordinate + float2(0.25, -0.25), samplePos);
            float d3 = distance(textureCoordinate + float2(-0.25, 0.25), samplePos);
            float d4 = distance(textureCoordinate + float2(0.25), samplePos);
            return float3(dot(float4(float4(d1,d2,d3,d4) < float4(d.r/2.0)), float4(0.25)),
                          dot(float4(float4(d1,d2,d3,d4) < float4(d.g/2.0)), float4(0.25)),
                          dot(float4(float4(d1,d2,d3,d4) < float4(d.b/2.0)), float4(0.25)));
        }
        
        float2 neighborSamplePosition(float2 textureCoordinate, float2 samplePosition, float scale, float2x2 m) {
            float2 p = (textureCoordinate - samplePosition) * m;
            float2 direction = (p.y > p.x) ? ( -p.x > p.y ? float2(-1, 0) : float2(0, 1)) : (-p.y > p.x ? float2(0, -1) : float2(1, 0));
            return samplePosition + (m * direction) * scale;
        }
        
        
        fragment float4 colorHalftone(VertexOut vertexIn [[stage_in]],
                                      texture2d<float, access::sample> sourceTexture [[texture(0)]],
                                      sampler sourceSampler [[sampler(0)]],
                                      constant float &scale [[buffer(1)]],
                                      constant float4 &angles [[buffer(2)]],
                                      constant bool &singleAngleMode [[buffer(3)]]) {
            using namespace metalpetal::halftone;
            constexpr sampler customSampler(coord::normalized, address::clamp_to_edge, filter:: linear);
            
            float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
            
            float2 textureSize = float2(sourceTexture.get_width(), sourceTexture.get_height());
            float2 textureCoordinate = vertexIn.textureCoordinate * textureSize;
            
            float3 intensityRGB;
            float3 intensityNeighborRGB;
            if (singleAngleMode) {
                float2x2 m = rotm(angles.x);
                float2 samplePos = samplePosition(textureCoordinate, m, scale);
                intensityRGB = halftoneIntensityRGB(textureCoordinate, samplePos, scale, sourceTexture, customSampler);
                intensityNeighborRGB = halftoneIntensityRGB(textureCoordinate, neighborSamplePosition(textureCoordinate, samplePos, scale, m), scale, sourceTexture, customSampler);
            } else {
                float2x2 mr = rotm(angles.x);
                float2x2 mg = rotm(angles.y);
                float2x2 mb = rotm(angles.z);
                
                float2 samplePositionR = samplePosition(textureCoordinate, mr, scale);
                float2 samplePositionG = samplePosition(textureCoordinate, mg, scale);
                float2 samplePositionB = samplePosition(textureCoordinate, mb, scale);
                
                intensityRGB = float3(halftoneIntensityRGB(textureCoordinate, samplePositionR, scale, sourceTexture, customSampler).r,
                                      halftoneIntensityRGB(textureCoordinate, samplePositionG, scale, sourceTexture, customSampler).g,
                                      halftoneIntensityRGB(textureCoordinate, samplePositionB, scale, sourceTexture, customSampler).b);
                
                intensityNeighborRGB = float3(halftoneIntensityRGB(textureCoordinate, neighborSamplePosition(textureCoordinate, samplePositionR, scale, mr), scale, sourceTexture, customSampler).r,
                                              halftoneIntensityRGB(textureCoordinate, neighborSamplePosition(textureCoordinate, samplePositionG, scale, mg), scale, sourceTexture, customSampler).g,
                                              halftoneIntensityRGB(textureCoordinate, neighborSamplePosition(textureCoordinate, samplePositionB, scale, mb), scale, sourceTexture, customSampler).b);
            }
            float3 i = (1.0 - intensityRGB) * (1 - intensityNeighborRGB);
            return float4(i, textureColor.a);
        }
        
        fragment float4 dotScreen(
                                  VertexOut vertexIn [[stage_in]],
                                  texture2d<float, access::sample> sourceTexture [[texture(0)]],
                                  sampler sourceSampler [[sampler(0)]],
                                  constant float &scale [[buffer(0)]],
                                  constant float &angle [[buffer(1)]],
                                  constant float3 &grayColorTransform [[buffer(2)]]) {
            using namespace metalpetal::halftone;
            constexpr sampler customSampler(coord::normalized, address::clamp_to_edge, filter:: linear);
            
            float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
            
            float2x2 m = rotm(angle);
            float2 textureSize = float2(sourceTexture.get_width(), sourceTexture.get_height());
            float2 textureCoordinate = vertexIn.textureCoordinate * textureSize;
            float2 rotatedTextureCoordinate = m * textureCoordinate;
            float2 samplePos = (rotatedTextureCoordinate - mod(rotatedTextureCoordinate, float2(scale)) + scale * 0.5) * m;
            float intensity = halftoneIntensity(textureCoordinate, samplePos, scale, grayColorTransform, sourceTexture, customSampler);
            float2 samplePosNeighbor = neighborSamplePosition(textureCoordinate, samplePos, scale, m);
            float intensityNeighbor = halftoneIntensity(textureCoordinate, samplePosNeighbor, scale, grayColorTransform, sourceTexture, customSampler);
            float i = (1.0 - intensity) * (1.0 - intensityNeighbor);
            return float4(float3(i),textureColor.a);
        }
    }
}

