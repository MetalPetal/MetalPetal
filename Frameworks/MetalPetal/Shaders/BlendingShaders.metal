//
// This is an auto-generated source file.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
#include "MTIShaderFunctionConstants.h"

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
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = normalBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 darkenBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = darkenBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 multiplyBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = multiplyBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 colorBurnBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = colorBurnBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 linearBurnBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = linearBurnBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 darkerColorBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = darkerColorBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 lightenBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = lightenBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 screenBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = screenBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 colorDodgeBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = colorDodgeBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 addBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = addBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 lighterColorBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = lighterColorBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 overlayBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = overlayBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 softLightBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = softLightBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 hardLightBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = hardLightBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 vividLightBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = vividLightBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 linearLightBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = linearLightBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 pinLightBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = pinLightBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 hardMixBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = hardMixBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 differenceBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = differenceBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 exclusionBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = exclusionBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 subtractBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = subtractBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 divideBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = divideBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 hueBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = hueBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 saturationBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = saturationBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 colorBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = colorBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


fragment float4 luminosityBlend(VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                    sampler overlaySampler [[ sampler(1) ]],
                                    constant float &intensity [[buffer(0)]]
                                    ) {
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
    float2 textureCoordinate = vertexIn.textureCoordinate;
    #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
    textureCoordinate = modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height()));
    #endif
    float4 uCf = overlayTexture.sample(overlaySampler, textureCoordinate);
    
    if (blend_filter_backdrop_has_premultiplied_alpha) {
        uCb = unpremultiply(uCb);
    }
    if (blend_filter_source_has_premultiplied_alpha) {
        uCf = unpremultiply(uCf);
    }
    float4 blendedColor = luminosityBlend(uCb, uCf);
    float4 output = mix(uCb,blendedColor,intensity);
    if (blend_filter_outputs_premultiplied_alpha) {
        return premultiply(output);
    } else if (blend_filter_outputs_opaque_image) {
        return float4(output.rgb, 1.0);
    } else {
        return output;
    }
}


}
