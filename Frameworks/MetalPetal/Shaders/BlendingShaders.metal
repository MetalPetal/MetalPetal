#include <metal_stdlib>
#include "MTIShaderTypes.h"

using namespace metal;
using namespace metalpetal;

fragment float4 normalBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return normalBlend(currentColor,textureColor);
}

fragment float4 normalBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return normalBlend(uCb, uCf);
}

fragment float4 multiplyBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return multiplyBlend(currentColor,textureColor);
}

fragment float4 multiplyBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return multiplyBlend(uCb, uCf);
}

fragment float4 hardLightBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return hardLightBlend(currentColor,textureColor);
}

fragment float4 hardLightBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return hardLightBlend(uCb, uCf);
}

