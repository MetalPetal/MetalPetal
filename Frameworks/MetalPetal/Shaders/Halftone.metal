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
        
        float4 rgb2cmyki(float3 c) {
            float k = max(max(c.r, c.g), c.b);
            return min(float4(c.rgb / k, k), 1.0);
        }
        
        float3 cmyki2rgb(float4 c)
        {
            return c.rgb * c.a;
        }
        
        float2 mod(float2 x, float2 y) {
            return x - y * floor(x/y);
        }
        
        float4 halftoneColor(float2 fc, float2x2 m, float radius, float dotSize, float2 center, texture2d<float, access::sample> sourceTexture, sampler sourceSampler) {
            float2 px = m * fc;
            float2 smp = ((px - mod(px, float2(radius))) + 0.5 * radius) * m;
            float s = min(length(fc - smp) / (dotSize * 0.5 * radius), 1.0);
            float2 pt = smp + center;
            float2 textureSize = float2(sourceTexture.get_width(),sourceTexture.get_height());
            float3 texc = sourceTexture.sample(sourceSampler,pt/textureSize).rgb;
            texc = pow(texc, float3(2.2)); /* Gamma decode. */
            float4 c = rgb2cmyki(texc);
            return c+s;
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
        
        float4 halftoneIntensityCMYK(float2 textureCoordinate, float2 samplePos, float scale, texture2d<float, access::sample> sourceTexture, sampler sourceSampler) {
            float2 textureSize = float2(sourceTexture.get_width(), sourceTexture.get_height());
            float4 textureColor = sourceTexture.sample(sourceSampler, samplePos/textureSize);
            float4 c = rgb2cmyki(pow(textureColor.rgb, float3(2.2)));
            float4 d = scale * 1.414214 * (1.0 - c);
            float d1 = distance(textureCoordinate + float2(-0.25), samplePos);
            float d2 = distance(textureCoordinate + float2(0.25, -0.25), samplePos);
            float d3 = distance(textureCoordinate + float2(-0.25, 0.25), samplePos);
            float d4 = distance(textureCoordinate + float2(0.25), samplePos);
            return float4(float4(d1,d2,d3,d4) < (d/2.0));
        }
        
        float2 neighborSamplePosition(float2 textureCoordinate, float2 samplePosition, float scale, float2x2 m) {
            float2 p = (textureCoordinate - samplePosition) * m;
            float2 direction;
            if (p.y > p.x) {
                if (-p.x > p.y) {
                    //left
                    direction = float2(-1, 0);
                } else {
                    //top
                    direction = float2(0, 1);
                }
            } else {
                if (-p.y > p.x) {
                    //bottom
                    direction = float2(0, -1);
                } else {
                    //right
                    direction = float2(1, 0);
                }
            }
            return samplePosition + (m * direction) * scale;
        }
    }
}

fragment float4 colorHalftone(
                              VertexOut vertexIn [[stage_in]],
                              texture2d<float, access::sample> sourceTexture [[texture(0)]],
                              sampler sourceSampler [[sampler(0)]],
                              constant float &scale [[buffer(1)]],
                              constant float4 &angles [[buffer(2)]],
                              constant float2 &center [[buffer(3)]]) {
    using namespace metalpetal::halftone;
    /*
     float2x2 m = rotm(angles.x);
     
     float2x2 mc = rotm(angles.x);
     float2x2 mm = rotm(angles.y);
     float2x2 my = rotm(angles.z);
     float2x2 mk = rotm(angles.w);
     
     float2 textureSize = float2(sourceTexture.get_width(), sourceTexture.get_height());
     float2 textureCoordinate = vertexIn.textureCoordinate * textureSize;
     
     float2 rotatedTextureCoordinate = m * textureCoordinate;
     float2 samplePos = (rotatedTextureCoordinate - mod(rotatedTextureCoordinate, float2(scale)) + scale * 0.5) * m;
     
     float4 intensityCMYK = halftoneIntensityCMYK(textureCoordinate, samplePos, scale, sourceTexture, sourceSampler);
     
     float2 samplePosNeighbor = neighborSamplePosition(textureCoordinate, samplePos, scale, m);
     
     float4 intensityNeighborCMYK = halftoneIntensityCMYK(textureCoordinate, samplePosNeighbor, scale, sourceTexture, sourceSampler);
     
     float4 i = (1.0 - intensityCMYK) * (1.0 - intensityNeighborCMYK);
     
     float3 rgb = cmyki2rgb(i);
     rgb = pow(rgb, float3(1.0/2.2)); // Gamma encode.
     
     return float4(rgb,1.0);
     */
    
    //https://www.shadertoy.com/view/Mdf3Dn
    using namespace metalpetal::halftone;
    
    constexpr float dotSize = 1.48;
    constexpr float SST = 0.999;
    constexpr float SSQ = 0.5;
    
    float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
    
    float2 textureSize = float2(sourceTexture.get_width(),sourceTexture.get_height());
    float2 fc = vertexIn.textureCoordinate * textureSize - center;
    
    float2x2 mc = rotm(angles.x);
    float2x2 mm = rotm(angles.y);
    float2x2 my = rotm(angles.z);
    float2x2 mk = rotm(angles.w);
    
    float4 v = float4(halftoneColor(fc, mc, scale, dotSize, center, sourceTexture, sourceSampler).r,
                      halftoneColor(fc, mm, scale, dotSize, center, sourceTexture, sourceSampler).g,
                      halftoneColor(fc, my, scale, dotSize, center, sourceTexture, sourceSampler).b,
                      halftoneColor(fc, mk, scale, dotSize, center, sourceTexture, sourceSampler).a);
    float4 ssv = smoothstep(SST-SSQ, SST+SSQ, v);
    float3 c = cmyki2rgb(ssv);
    c = pow(c, float3(1.0/2.2)); // Gamma encode.
    return float4(c, textureColor.a);
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
    float2x2 m = rotm(angle);
    float2 textureSize = float2(sourceTexture.get_width(), sourceTexture.get_height());
    float2 textureCoordinate = vertexIn.textureCoordinate * textureSize;
    float2 rotatedTextureCoordinate = m * textureCoordinate;
    float2 samplePos = (rotatedTextureCoordinate - mod(rotatedTextureCoordinate, float2(scale)) + scale * 0.5) * m;
    float intensity = halftoneIntensity(textureCoordinate, samplePos, scale, grayColorTransform, sourceTexture, customSampler);
    float2 samplePosNeighbor = neighborSamplePosition(textureCoordinate, samplePos, scale, m);
    float intensityNeighbor = halftoneIntensity(textureCoordinate, samplePosNeighbor, scale, grayColorTransform, sourceTexture, customSampler);
    float i = (1.0 - intensity) * (1.0 - intensityNeighbor);
    return float4(float3(i),1.0);
}
