//
// This is an auto-generated source file.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"

using namespace metal;
using namespace metalpetal;

namespace metalpetal {

fragment float4 normalBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = normalBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 darkenBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = darkenBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 multiplyBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = multiplyBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 colorBurnBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = colorBurnBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 linearBurnBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = linearBurnBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 darkerColorBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = darkerColorBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 lightenBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = lightenBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 screenBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = screenBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 colorDodgeBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = colorDodgeBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 addBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = addBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 lighterColorBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = lighterColorBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 overlayBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = overlayBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 softLightBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = softLightBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 hardLightBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = hardLightBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 vividLightBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = vividLightBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 linearLightBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = linearLightBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 pinLightBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = pinLightBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 hardMixBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = hardMixBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 differenceBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = differenceBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 exclusionBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = exclusionBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 subtractBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = subtractBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 divideBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = divideBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 hueBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = hueBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 saturationBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = saturationBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 colorBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = colorBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}


fragment float4 luminosityBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float4 blendedColor = luminosityBlend(uCb, uCf);
    return mix(uCb,blendedColor,intensity);
}

}