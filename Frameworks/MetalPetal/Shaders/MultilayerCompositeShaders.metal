#include <metal_stdlib>
#include "MTIShaderTypes.h"

using namespace metal;
using namespace metalpetal;

vertex VertexOut multilayerCompositeVertexShader(
                                        const device VertexIn * vertices [[ buffer(0) ]],
                                        constant float4x4 & transformMatrix [[ buffer(1) ]],
                                        constant float4x4 & orthographicMatrix [[ buffer(2) ]],
                                        uint vid [[ vertex_id ]]
                                        ) {
    VertexOut outVertex;
    VertexIn inVertex = vertices[vid];
    outVertex.position = transformMatrix * inVertex.position * orthographicMatrix;
    outVertex.texcoords = inVertex.textureCoordinate;
    return outVertex;
}

fragment float4 multilayerCompositeNormalBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    textureColor.a *= parameters.opacity;
    return normalBlend(currentColor,textureColor);
}

fragment float4 multilayerCompositeMultiplyBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    textureColor.a *= parameters.opacity;
    return multiplyBlend(currentColor,textureColor);
}

fragment float4 multilayerCompositeHardLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    textureColor.a *= parameters.opacity;
    return hardLightBlend(currentColor,textureColor);
}

fragment float4 multilayerCompositeSoftLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    textureColor.a *= parameters.opacity;
    return softLightBlend(currentColor,textureColor);
}

fragment float4 multilayerCompositeScreenBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    textureColor.a *= parameters.opacity;
    return screenBlend(currentColor,textureColor);
}

fragment float4 multilayerCompositeOverlayBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    textureColor.a *= parameters.opacity;
    return overlayBlend(currentColor,textureColor);
}

fragment float4 multilayerCompositeDarkenBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    textureColor.a *= parameters.opacity;
    return darkenBlend(currentColor,textureColor);
}

fragment float4 multilayerCompositeLightenBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    textureColor.a *= parameters.opacity;
    return lightenBlend(currentColor,textureColor);
}

fragment float4 multilayerCompositeColorDodgeBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    textureColor.a *= parameters.opacity;
    return colorDodgeBlend(currentColor,textureColor);
}

fragment float4 multilayerCompositeColorBurnBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    textureColor.a *= parameters.opacity;
    return colorBurnBlend(currentColor,textureColor);
}

fragment float4 multilayerCompositeDifferenceBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    textureColor.a *= parameters.opacity;
    return differenceBlend(currentColor,textureColor);
}

fragment float4 multilayerCompositeExclusionBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    textureColor.a *= parameters.opacity;
    return exclusionBlend(currentColor,textureColor);
}

fragment float4 multilayerCompositeHueBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    textureColor.a *= parameters.opacity;
    return hueBlend(currentColor,textureColor);
}

fragment float4 multilayerCompositeSaturationBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    textureColor.a *= parameters.opacity;
    return saturationBlend(currentColor,textureColor);
}

fragment float4 multilayerCompositeColorBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    textureColor.a *= parameters.opacity;
    return colorBlend(currentColor,textureColor);
}

fragment float4 multilayerCompositeLuminosityBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    textureColor.a *= parameters.opacity;
    return luminosityBlend(currentColor,textureColor);
}

