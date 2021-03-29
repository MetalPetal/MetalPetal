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
            if (parameters.tintColor.a != 0) {
                textureColor.rgb = parameters.tintColor.rgb;
                textureColor.a *= parameters.tintColor.a;
            }
            if (parameters.hasCompositingMask) {
                float maskValue = maskColor[parameters.compositingMaskComponent];
                textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
            }
            textureColor.a *= parameters.opacity;
            return \(blendFunctionName)(currentColor,textureColor);
        }
        
        #endif

        fragment float4 \(shaderFunctionName)(
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
            if (parameters.tintColor.a != 0) {
                textureColor.rgb = parameters.tintColor.rgb;
                textureColor.a *= parameters.tintColor.a;
            }
            if (parameters.hasCompositingMask) {
                float4 maskColor = maskTexture.sample(s, location);
                float maskValue = maskColor[parameters.compositingMaskComponent];
                textureColor.a *= parameters.usesOneMinusMaskValue ? (1.0 - maskValue) : maskValue;
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
            float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
            float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
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

        using namespace metal;
        using namespace metalpetal;
        
        namespace metalpetal {
            
        constant bool blend_filter_backdrop_has_premultiplied_alpha [[function_constant(0)]];
        constant bool blend_filter_source_has_premultiplied_alpha [[function_constant(1)]];
        constant bool blend_filter_outputs_premultiplied_alpha [[function_constant(2)]];
        constant bool blend_filter_outputs_opaque_image [[function_constant(3)]];

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
