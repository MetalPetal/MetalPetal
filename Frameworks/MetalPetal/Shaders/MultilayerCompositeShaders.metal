//
// This is an auto-generated source file.
//

#include <metal_stdlib>
#include <TargetConditionals.h>
#include "MTIShaderLib.h"
#include "MTIShaderFunctionConstants.h"

#ifndef TARGET_OS_SIMULATOR
    #error TARGET_OS_SIMULATOR not defined. Check <TargetConditionals.h>
#endif

using namespace metal;
using namespace metalpetal;

namespace metalpetal {

vertex MTIMultilayerCompositingLayerVertexOut multilayerCompositeVertexShader(
                                        const device MTIMultilayerCompositingLayerVertex * vertices [[ buffer(0) ]],
                                        constant float4x4 & transformMatrix [[ buffer(1) ]],
                                        constant float4x4 & orthographicMatrix [[ buffer(2) ]],
                                        uint vid [[ vertex_id ]]
                                        ) {
    MTIMultilayerCompositingLayerVertexOut outVertex;
    MTIMultilayerCompositingLayerVertex inVertex = vertices[vid];
    outVertex.position = inVertex.position * transformMatrix * orthographicMatrix;
    outVertex.textureCoordinate = inVertex.textureCoordinate;
    outVertex.positionInLayer = inVertex.positionInLayer;
    return outVertex;
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeNormalBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return normalBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeNormalBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return normalBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeDarkenBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return darkenBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeDarkenBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return darkenBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeMultiplyBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return multiplyBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeMultiplyBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return multiplyBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeColorBurnBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return colorBurnBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeColorBurnBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return colorBurnBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeLinearBurnBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return linearBurnBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeLinearBurnBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return linearBurnBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeDarkerColorBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return darkerColorBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeDarkerColorBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return darkerColorBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeLightenBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return lightenBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeLightenBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return lightenBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeScreenBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return screenBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeScreenBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return screenBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeColorDodgeBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return colorDodgeBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeColorDodgeBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return colorDodgeBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeAddBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return addBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeAddBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return addBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeLighterColorBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return lighterColorBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeLighterColorBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return lighterColorBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeOverlayBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return overlayBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeOverlayBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return overlayBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeSoftLightBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return softLightBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeSoftLightBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return softLightBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeHardLightBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return hardLightBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeHardLightBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return hardLightBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeVividLightBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return vividLightBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeVividLightBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return vividLightBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeLinearLightBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return linearLightBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeLinearLightBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return linearLightBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositePinLightBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return pinLightBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositePinLightBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return pinLightBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeHardMixBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return hardMixBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeHardMixBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return hardMixBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeDifferenceBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return differenceBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeDifferenceBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return differenceBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeExclusionBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return exclusionBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeExclusionBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return exclusionBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeSubtractBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return subtractBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeSubtractBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return subtractBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeDivideBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return divideBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeDivideBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return divideBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeHueBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return hueBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeHueBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return hueBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeSaturationBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return saturationBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeSaturationBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return saturationBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeColorBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return colorBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeColorBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return colorBlend(backgroundColor,textureColor);
}


#if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
    
fragment float4 multilayerCompositeLuminosityBlend_programmableBlending(
                                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]],
                                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(1) ]],
                                                    sampler compositingMaskSampler [[ sampler(1) ]],
                                                    texture2d<float, access::sample> maskTexture [[ texture(2) ]],
                                                    sampler maskSampler [[ sampler(2) ]]
                                                ) {
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);

    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float2 location = vertexIn.position.xy / parameters.canvasSize;
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return luminosityBlend(currentColor,textureColor);
}

#endif

fragment float4 multilayerCompositeLuminosityBlend(
                                    MTIMultilayerCompositingLayerVertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> backgroundTexture [[ texture(1) ]],
                                    texture2d<float, access::sample> compositingMaskTexture [[ texture(2) ]],
                                    sampler compositingMaskSampler [[ sampler(2) ]],
                                    texture2d<float, access::sample> maskTexture [[ texture(3) ]],
                                    sampler maskSampler [[ sampler(3) ]],
                                    constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]]
                                ) {
    constexpr sampler s(coord::normalized, address::clamp_to_zero, filter::linear);
    float2 location = vertexIn.position.xy / parameters.canvasSize;
    float4 backgroundColor = backgroundTexture.sample(s, location);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height()));
    #endif
    float4 textureColor = colorTexture.sample(colorSampler, textureCoordinate);
    if (multilayer_composite_content_premultiplied) {
        textureColor = unpremultiply(textureColor);
    }
    if (multilayer_composite_has_mask) {
        float4 maskColor = maskTexture.sample(maskSampler, vertexIn.positionInLayer);
        maskColor = parameters.maskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.maskComponent];
        textureColor.a *= parameters.maskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_compositing_mask) {
        float4 maskColor = compositingMaskTexture.sample(compositingMaskSampler, location);
        maskColor = parameters.compositingMaskHasPremultipliedAlpha ? unpremultiply(maskColor) : maskColor;
        float maskValue = maskColor[parameters.compositingMaskComponent];
        textureColor.a *= parameters.compositingMaskUsesOneMinusValue ? (1.0 - maskValue) : maskValue;
    }
    if (multilayer_composite_has_tint_color) {
        textureColor.rgb = parameters.tintColor.rgb;
        textureColor.a *= parameters.tintColor.a;
    }
    switch (multilayer_composite_corner_curve_type) {
        case 1:
            textureColor.a *= circularCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        case 2:
            textureColor.a *= continuousCornerMask(parameters.layerSize, vertexIn.positionInLayer, parameters.cornerRadius);
            break;
        default:
            break;
    }
    textureColor.a *= parameters.opacity;
    return luminosityBlend(backgroundColor,textureColor);
}


}
