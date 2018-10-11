//
//  LensBlur.metal
//  MetalPetal
//
//  Created by Yu Ao on 13/10/2017.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"

using namespace metal;

namespace metalpetal {
    namespace hexagonalbokeh {
        METAL_FUNC float randomize(float3 scale, float seed, float2 position) {
            return fract(sin(dot(float3(position, 0.0) + seed, scale)) * 43758.5453 + seed);
        }
        
        METAL_FUNC float4 sampleWithDelta(texture2d<float, access::sample> texture, sampler textureSampler, float2 position, float2 delta) {
            /* randomize the lookup values to hide the fixed number of samples */
            float offset = randomize(float3(delta, 151.7182), 0.0, position);
            constexpr int samples = 16;
            float3 color = float3(0.0);
            float blurAmount = 0;
            for (int t = 0.0; t <= samples; t++) {
                float percent = (float(t) + offset) / float(samples);
                float4 textureColor = texture.sample(textureSampler, position + delta * percent);
                blurAmount += textureColor.a;
                textureColor *= textureColor.a;
                color += textureColor.rgb;
            }
            return blurAmount < 0.01 ? texture.sample(textureSampler, position) : float4(color / blurAmount, 1.0);
        }
        
        fragment float4 hexagonalBokehBlurPre(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(1) ]],
                                    sampler maskSampler [[ sampler(1) ]],
                                    constant float & power [[ buffer(0) ]],
                                    constant int &maskComponent [[ buffer(1) ]],
                                    constant bool &usesOneMinusMaskValue [[ buffer(2) ]]) {
            float coc = maskTexture.sample(maskSampler, vertexIn.textureCoordinate)[maskComponent];
            float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
            textureColor.rgb = pow(textureColor.rgb, float3(power));
            return float4(textureColor.rgb, usesOneMinusMaskValue ? 1.0 - coc : coc);
        }
        
        typedef struct {
            float4 vertical [[color(0)]];
            float4 diagonal [[color(1)]];
        } HexagonalBokehBlurAlphaPassOutput;
        
        fragment HexagonalBokehBlurAlphaPassOutput hexagonalBokehBlurAlpha(VertexOut vertexIn [[ stage_in ]],
                                                       texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                       sampler colorSampler [[ sampler(0) ]],
                                                       constant float2 & delta0 [[ buffer(0) ]],
                                                       constant float2 & delta1 [[ buffer(1) ]]) {
            float coc = colorTexture.sample(colorSampler, vertexIn.textureCoordinate).a;
            float4 color1 = sampleWithDelta(colorTexture, colorSampler, vertexIn.textureCoordinate, delta0 * coc);
            float4 color2 = sampleWithDelta(colorTexture, colorSampler, vertexIn.textureCoordinate, delta1 * coc);
            HexagonalBokehBlurAlphaPassOutput output;
            output.vertical = float4(color1.rgb, coc);
            output.diagonal = float4((color2 + color1).rgb, coc);
            return output;
        }
        
        fragment float4 hexagonalBokehBlurBravoCharlie(VertexOut vertexIn [[ stage_in ]],
                                             texture2d<float, access::sample> verticalTexture [[ texture(0) ]],
                                             sampler verticalSampler [[ sampler(0) ]],
                                             texture2d<float, access::sample> diagonalTexture [[ texture(1) ]],
                                             sampler diagonalSampler [[ sampler(1) ]],
                                             constant float2 & delta0 [[ buffer(0) ]],
                                             constant float2 & delta1 [[ buffer(1) ]],
                                             constant float & power [[ buffer(2) ]]) {
            float coc = verticalTexture.sample(verticalSampler, vertexIn.textureCoordinate).a;
            float coc2 = diagonalTexture.sample(diagonalSampler, vertexIn.textureCoordinate).a;
            float4 color = (sampleWithDelta(verticalTexture, verticalSampler, vertexIn.textureCoordinate, delta0 * coc) +
                            sampleWithDelta(diagonalTexture, diagonalSampler, vertexIn.textureCoordinate, delta1 * coc2)) * (1.0/3.0);
            color.rgb = pow(color.rgb, float3(power));
            return float4(color.rgb, 1.0);
        }
    }
    
    
}


