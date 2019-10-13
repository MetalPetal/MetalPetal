//
// This is an auto-generated source file.
//

#include <metal_stdlib>
#include <TargetConditionals.h>
#include "MTIShaderLib.h"

#ifndef TARGET_OS_SIMULATOR
    #error TARGET_OS_SIMULATOR not defined. Check <TargetConditionals.h>
#endif

using namespace metal;
using namespace metalpetal;

namespace metalpetal {

vertex VertexOut multilayerCompositeVertexShader(
                                        const device VertexIn * vertices [[ buffer(0) ]],
                                        constant float4x4 & transformMatrix [[ buffer(1) ]],
                                        constant float4x4 & orthographicMatrix [[ buffer(2) ]],
                                        uint vid [[ vertex_id ]]
                                        ) {
    VertexOut outVertex;
    VertexIn inVertex = vertices[vid];
    outVertex.position = inVertex.position * transformMatrix * orthographicMatrix;
    outVertex.textureCoordinate = inVertex.textureCoordinate;
    return outVertex;
}

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeNormalBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return normalBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeNormalBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return normalBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeDarkenBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return darkenBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeDarkenBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return darkenBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeMultiplyBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return multiplyBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeMultiplyBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return multiplyBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeColorBurnBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return colorBurnBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeColorBurnBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return colorBurnBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeLinearBurnBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return linearBurnBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeLinearBurnBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return linearBurnBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeDarkerColorBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return darkerColorBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeDarkerColorBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return darkerColorBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeLightenBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return lightenBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeLightenBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return lightenBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeScreenBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return screenBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeScreenBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return screenBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeColorDodgeBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return colorDodgeBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeColorDodgeBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return colorDodgeBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeAddBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return addBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeAddBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return addBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeLighterColorBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return lighterColorBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeLighterColorBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return lighterColorBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeOverlayBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return overlayBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeOverlayBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return overlayBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeSoftLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return softLightBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeSoftLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return softLightBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeHardLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return hardLightBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeHardLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return hardLightBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeVividLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return vividLightBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeVividLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return vividLightBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeLinearLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return linearLightBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeLinearLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return linearLightBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositePinLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return pinLightBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositePinLightBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return pinLightBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeHardMixBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return hardMixBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeHardMixBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return hardMixBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeDifferenceBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return differenceBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeDifferenceBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return differenceBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeExclusionBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return exclusionBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeExclusionBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return exclusionBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeSubtractBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return subtractBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeSubtractBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return subtractBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeDivideBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return divideBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeDivideBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return divideBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeHueBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return hueBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeHueBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return hueBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeSaturationBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return saturationBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeSaturationBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return saturationBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeColorBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return colorBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeColorBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return colorBlend(backgroundColor,textureColor);
}

#endif

#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR

fragment float4 multilayerCompositeLuminosityBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    float4 maskColor [[color(1)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return luminosityBlend(currentColor,textureColor);
}

#else

fragment float4 multilayerCompositeLuminosityBlend(
                                                    VertexOut vertexIn [[ stage_in ]],
                                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    constant float2 & viewportSize [[buffer(1)]]
                                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / viewportSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    if (parameters.contentHasPremultipliedAlpha) {
        textureColor = unpremultiply(textureColor);
    }
    if (parameters.hasCompositingMask) {
        float4 maskColor = maskTexture.sample(s, location);
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
    }
    textureColor.a *= parameters.opacity;
    return luminosityBlend(backgroundColor,textureColor);
}

#endif

}