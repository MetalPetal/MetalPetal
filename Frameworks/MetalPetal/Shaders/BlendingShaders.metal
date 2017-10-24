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

fragment float4 softLightBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return softLightBlend(currentColor,textureColor);
}

fragment float4 softLightBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return softLightBlend(uCb, uCf);
}

fragment float4 screenBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return screenBlend(currentColor,textureColor);
}

fragment float4 screenBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return screenBlend(uCb, uCf);
}

fragment float4 overlayBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return overlayBlend(currentColor,textureColor);
}

fragment float4 overlayBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return overlayBlend(uCb, uCf);
}

fragment float4 darkenBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return darkenBlend(currentColor,textureColor);
}

fragment float4 darkenBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return darkenBlend(uCb, uCf);
}

fragment float4 lightenBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return lightenBlend(currentColor,textureColor);
}

fragment float4 lightenBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return lightenBlend(uCb, uCf);
}

fragment float4 colorDodgeBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return colorDodgeBlend(currentColor,textureColor);
}

fragment float4 colorDodgeBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return colorDodgeBlend(uCb, uCf);
}

fragment float4 colorBurnBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return colorBurnBlend(currentColor,textureColor);
}

fragment float4 colorBurnBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return colorBurnBlend(uCb, uCf);
}

fragment float4 differenceBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return differenceBlend(currentColor,textureColor);
}

fragment float4 differenceBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return differenceBlend(uCb, uCf);
}

fragment float4 exclusionBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return exclusionBlend(currentColor,textureColor);
}

fragment float4 exclusionBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return exclusionBlend(uCb, uCf);
}

fragment float4 hueBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return hueBlend(currentColor,textureColor);
}

fragment float4 hueBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return hueBlend(uCb, uCf);
}

fragment float4 saturationBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return saturationBlend(currentColor,textureColor);
}

fragment float4 saturationBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return saturationBlend(uCb, uCf);
}

fragment float4 colorBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return colorBlend(currentColor,textureColor);
}

fragment float4 colorBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return colorBlend(uCb, uCf);
}

fragment float4 luminosityBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return luminosityBlend(currentColor,textureColor);
}

fragment float4 luminosityBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return luminosityBlend(uCb, uCf);
}

