//
//  File.swift
//  
//
//  Created by YuAo on 2021/2/6.
//

import Foundation

struct BlendFormulaSupport {
    
    static func generateBlendFormulaSupportFiles(sourceDirectory: URL) -> [String: String] {
        let sourceHeaderFile = sourceDirectory.appendingPathComponent("Shaders/MTIShaderLib.h")
        let shaderHeaderContent = try! String(contentsOf: sourceHeaderFile, encoding: .utf8)
        
        let header = """
        //
        // This is an auto-generated source file.
        //
        
        #import <Foundation/Foundation.h>

        FOUNDATION_EXPORT NSString * MTIBuildBlendFormulaShaderSource(NSString *formula);
        
        """
        
        let imp = """
        //
        // This is an auto-generated source file.
        //
        
        #import "MTIBlendFormulaSupport.h"
        
        static const char *MTIBlendFormulaSupportShaderTemplate = R"mtirawstring(
        \(shaderHeaderContent)

        using namespace metalpetal;
        
        {MTIBlendFormula}

        fragment float4 customBlend(VertexOut vertexIn [[ stage_in ]],
                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                            sampler colorSampler [[ sampler(0) ]],
                                            texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                            sampler overlaySampler [[ sampler(1) ]],
                                            constant float &intensity [[buffer(0)]]
                                            ) {
            float4 uCb = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
            #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
            float4 uCf = overlayTexture.sample(overlaySampler, modify_source_texture_coordinates(uCb, vertexIn.textureCoordinate, uint2(overlayTexture.get_width(), overlayTexture.get_height())));
            #else
            float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.textureCoordinate);
            #endif
            float4 blendedColor = blend(uCb, uCf);
            return mix(uCb,blendedColor,intensity);
        }


        #if __HAVE_COLOR_ARGUMENTS__ && !TARGET_OS_SIMULATOR
            
        fragment float4 multilayerCompositeCustomBlend_programmableBlending(
                                                            VertexOut vertexIn [[ stage_in ]],
                                                            float4 currentColor [[color(0)]],
                                                            float4 maskColor [[color(1)]],
                                                            constant MTIMultilayerCompositingLayerShadingParameters & parameters [[buffer(0)]],
                                                            texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                            sampler colorSampler [[ sampler(0) ]]
                                                        ) {
            #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
            float4 textureColor = colorTexture.sample(colorSampler, modify_source_texture_coordinates(currentColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height())));
            #else
            float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
            #endif
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
            return blend(currentColor,textureColor);
        }
        
        #endif

        fragment float4 multilayerCompositeCustomBlend(
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
            #if MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER
            float4 textureColor = colorTexture.sample(colorSampler, modify_source_texture_coordinates(backgroundColor, vertexIn.textureCoordinate, uint2(colorTexture.get_width(), colorTexture.get_height())));
            #else
            float4 textureColor = colorTexture.sample(colorSampler, vertexIn.textureCoordinate);
            #endif
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
            return blend(backgroundColor,textureColor);
        }

        )mtirawstring";

        NSString * MTIBuildBlendFormulaShaderSource(NSString *formula) {
            static NSString *t;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                t = [NSString stringWithCString:MTIBlendFormulaSupportShaderTemplate encoding:NSUTF8StringEncoding];
            });
            NSString *targetConditionals = [NSString stringWithFormat:@"#ifndef TARGET_OS_SIMULATOR\\n#define TARGET_OS_SIMULATOR %@\\n#endif\\n\\n#define MTI_CUSTOM_BLEND_HAS_TEXTURE_COORDINATES_MODIFIER %@\\n\\n",@(TARGET_OS_SIMULATOR),@([formula containsString:@"modify_source_texture_coordinates"])];
        
            return [t stringByReplacingOccurrencesOfString:@"{MTIBlendFormula}" withString:[targetConditionals stringByAppendingString:formula]];
        };

        """
        
        return [
            "MTIBlendFormulaSupport.h": header,
            "MTIBlendFormulaSupport.mm": imp,
        ]
    }
}
