#include <metal_stdlib>
#include "MTIShaderTypes.h"

using namespace metal;
using namespace metalpetal;

fragment float4 normalBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]],
                                            constant float &intensity [[buffer(0)]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = normalBlend(currentColor,textureColor);
    return mix(currentColor,blendedColor,intensity);
}

fragment float4 normalBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = normalBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}

fragment float4 multiplyBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]],
                                            constant float &intensity [[buffer(0)]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = multiplyBlend(currentColor,textureColor);
    return mix(currentColor,blendedColor,intensity);
}

fragment float4 multiplyBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = multiplyBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}

fragment float4 hardLightBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]],
                                            constant float &intensity [[buffer(0)]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = hardLightBlend(currentColor,textureColor);
    return mix(currentColor,blendedColor,intensity);
}

fragment float4 hardLightBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = hardLightBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}

fragment float4 softLightBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]],
                                            constant float &intensity [[buffer(0)]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = softLightBlend(currentColor,textureColor);
    return mix(currentColor,blendedColor,intensity);
}

fragment float4 softLightBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = softLightBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}

fragment float4 screenBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]],
                                            constant float &intensity [[buffer(0)]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = screenBlend(currentColor,textureColor);
    return mix(currentColor,blendedColor,intensity);
}

fragment float4 screenBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = screenBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}

fragment float4 overlayBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]],
                                            constant float &intensity [[buffer(0)]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = overlayBlend(currentColor,textureColor);
    return mix(currentColor,blendedColor,intensity);
}

fragment float4 overlayBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = overlayBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}

fragment float4 darkenBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]],
                                            constant float &intensity [[buffer(0)]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = darkenBlend(currentColor,textureColor);
    return mix(currentColor,blendedColor,intensity);
}

fragment float4 darkenBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = darkenBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}

fragment float4 lightenBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]],
                                            constant float &intensity [[buffer(0)]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = lightenBlend(currentColor,textureColor);
    return mix(currentColor,blendedColor,intensity);
}

fragment float4 lightenBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = lightenBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}

fragment float4 colorDodgeBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]],
                                            constant float &intensity [[buffer(0)]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = colorDodgeBlend(currentColor,textureColor);
    return mix(currentColor,blendedColor,intensity);
}

fragment float4 colorDodgeBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = colorDodgeBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}

fragment float4 colorBurnBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]],
                                            constant float &intensity [[buffer(0)]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = colorBurnBlend(currentColor,textureColor);
    return mix(currentColor,blendedColor,intensity);
}

fragment float4 colorBurnBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = colorBurnBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}

fragment float4 differenceBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]],
                                            constant float &intensity [[buffer(0)]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = differenceBlend(currentColor,textureColor);
    return mix(currentColor,blendedColor,intensity);
}

fragment float4 differenceBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = differenceBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}

fragment float4 exclusionBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]],
                                            constant float &intensity [[buffer(0)]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = exclusionBlend(currentColor,textureColor);
    return mix(currentColor,blendedColor,intensity);
}

fragment float4 exclusionBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = exclusionBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}

fragment float4 hueBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]],
                                            constant float &intensity [[buffer(0)]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = hueBlend(currentColor,textureColor);
    return mix(currentColor,blendedColor,intensity);
}

fragment float4 hueBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = hueBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}

fragment float4 saturationBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]],
                                            constant float &intensity [[buffer(0)]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = saturationBlend(currentColor,textureColor);
    return mix(currentColor,blendedColor,intensity);
}

fragment float4 saturationBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = saturationBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}

fragment float4 colorBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]],
                                            constant float &intensity [[buffer(0)]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = colorBlend(currentColor,textureColor);
    return mix(currentColor,blendedColor,intensity);
}

fragment float4 colorBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = colorBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}

fragment float4 luminosityBlendInPlace(
                                            VertexOut vertexIn [[ stage_in ]],
                                            float4 currentColor [[color(0)]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]],
                                            constant float &intensity [[buffer(0)]]
                                            ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = luminosityBlend(currentColor,textureColor);
    return mix(currentColor,blendedColor,intensity);
}

fragment float4 luminosityBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float4 blendedColor = luminosityBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}

