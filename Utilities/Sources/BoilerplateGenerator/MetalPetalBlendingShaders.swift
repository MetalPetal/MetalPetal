import Foundation

extension String {
    var lowerCamelCased: String {
        var string = self
        let c = string.removeFirst()
        string.insert(contentsOf: String(c).lowercased(), at: string.startIndex)
        return string
    }
}

public struct MetalPetalBlendingShadersCodeGenerator {
    
    static func generateMultilayerCompositeFilterFragmentShader(shaderFunctionName: String, blendFunctionName: String) -> String {
        return """
        
        #if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
            
        fragment float4 \(shaderFunctionName)_programmableBlending(
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
            return \(blendFunctionName)(currentColor,textureColor);
        }
        
        #endif

        fragment float4 \(shaderFunctionName)(
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
            return \(blendFunctionName)(backgroundColor,textureColor);
        }

        
        """
    }
    
    static func generateBlendFilterFragmentShader(shaderFunctionName: String, blendFunctionName: String) -> String {
        return """
        
        fragment float4 \(shaderFunctionName)(VertexOut vertexIn [[ stage_in ]],
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
            float4 blendedColor = \(blendFunctionName)(uCb, uCf);
            float4 output = mix(uCb,blendedColor,intensity);
            if (blend_filter_outputs_premultiplied_alpha) {
                return premultiply(output);
            } else if (blend_filter_outputs_opaque_image) {
                return float4(output.rgb, 1.0);
            } else {
                return output;
            }
        }

        
        """
    }
    
    static func generateBlendingShaders(blendModes: [String]) -> [String: String] {
        var fileContent = ""
        fileContent += """
        //
        // This is an auto-generated source file.
        //
        
        #include <metal_stdlib>
        #include "MTIShaderLib.h"
        #include "MTIShaderFunctionConstants.h"

        using namespace metal;
        using namespace metalpetal;
        
        namespace metalpetal {
        
        """
        
        for mode in blendModes {
            fileContent += generateBlendFilterFragmentShader(shaderFunctionName: mode.lowerCamelCased + "Blend",
                                                             blendFunctionName: mode.lowerCamelCased + "Blend")
        }
        
        fileContent += """

        }
        
        """
        return ["BlendingShaders.metal": fileContent]
    }
    
    static func generateMultilayerCompositeShaders(blendModes: [String]) -> [String: String] {
        var fileContent = """
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

        
        """
        
        for mode in blendModes {
            fileContent += generateMultilayerCompositeFilterFragmentShader(shaderFunctionName: "multilayerComposite" + mode + "Blend",
                                                                           blendFunctionName: mode.lowerCamelCased + "Blend")
        }
        
        fileContent += """

        }
        
        """
        return ["MultilayerCompositeShaders.metal": fileContent]
    }
    
    public static func generate(blendModes: [String]) -> [String: String] {
        let blendingShaders = self.generateBlendingShaders(blendModes: blendModes)
        let multilayerCompositeShaders = self.generateMultilayerCompositeShaders(blendModes: blendModes)
        return blendingShaders.merging(multilayerCompositeShaders, uniquingKeysWith: { (first, _) in first })
    }
}
