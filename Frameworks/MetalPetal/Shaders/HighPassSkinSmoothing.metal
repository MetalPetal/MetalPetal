//
//  HighPassSkinSmoothing.metal
//  MetalPetal
//
//  Created by Yu Ao on 15/01/2018.
//
#include "MTIShaderLib.h"

using namespace metal;

namespace metalpetal {

    fragment float4 highPassSkinSmoothingGBChannelOverlay(
                            VertexOut vertexIn [[stage_in]],
                            texture2d<float, access::sample> sourceTexture [[texture(0)]],
                            sampler sourceSampler [[sampler(0)]]
                            ) {
        float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
        textureColor.rgb = textureColor.rgb * pow(2.0, -1.0);
        return overlayBlend(float4(float3(textureColor.g), 1.0), float4(float3(textureColor.b), 1.0));
    }

    fragment float4 highPassSkinSmoothingMaskProcessAndComposite(
                                                                    VertexOut vertexIn [[stage_in]],
                                                                    texture2d<float, access::sample> sourceTexture [[texture(0)]],
                                                                    sampler sourceSampler [[sampler(0)]],
                                                                    texture2d<float, access::sample> bgChannelOverlayTexture [[texture(1)]],
                                                                    sampler bgChannelOverlayTextureSampler [[sampler(1)]],
                                                                    texture2d<float, access::sample> blurredBGChannelOverlayTexture [[texture(2)]],
                                                                    sampler blurredBGChannelOverlayTextureSampler [[sampler(2)]],
                                                                    texture2d<float, access::sample> toneCurveLUT [[texture(3)]],
                                                                    sampler toneCurveLUTSampler [[sampler(3)]],
                                                                    constant float &amount [[buffer(0)]]
                                                                    ) {
        float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
        
        float r = toneCurveLUT.sample(toneCurveLUTSampler, float2((textureColor.r * 255.0 + 0.5)/256.0, 0.5)).r;
        float g = toneCurveLUT.sample(toneCurveLUTSampler, float2((textureColor.g * 255.0 + 0.5)/256.0, 0.5)).g;
        float b = toneCurveLUT.sample(toneCurveLUTSampler, float2((textureColor.b * 255.0 + 0.5)/256.0, 0.5)).b;
        float4 toneCurvedColor = mix(textureColor, float4(r,g,b,textureColor.a), amount);

        float4 bgChannelOverlayColor = bgChannelOverlayTexture.sample(bgChannelOverlayTextureSampler, vertexIn.textureCoordinate);
        float4 blurredBGChannelOverlayColor = blurredBGChannelOverlayTexture.sample(blurredBGChannelOverlayTextureSampler, vertexIn.textureCoordinate);
        
        float3 mask = bgChannelOverlayColor.rgb - blurredBGChannelOverlayColor.rgb + float3(0.5);
        mask = hardLightBlend(float4(mask, 1.0), float4(mask, 1.0)).rgb;
        mask = hardLightBlend(float4(mask, 1.0), float4(mask, 1.0)).rgb;
        mask = hardLightBlend(float4(mask, 1.0), float4(mask, 1.0)).rgb;
        
        float k = 255.0 / (164.0 - 75.0);
        float maskValue = clamp((mask.r - 75.0 / 255.0) * k, 0.0, 1.0);

        return mix(toneCurvedColor, textureColor, maskValue);
    }
    
}
