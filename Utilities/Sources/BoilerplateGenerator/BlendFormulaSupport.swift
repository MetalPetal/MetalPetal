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
        
        let functionConstantsHeaderFile = sourceDirectory.appendingPathComponent("Shaders/MTIShaderFunctionConstants.h")
        let functionConstantsContent = try! String(contentsOf: functionConstantsHeaderFile, encoding: .utf8)
        
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
        \(functionConstantsContent)

        using namespace metalpetal;
        
        {MTIBlendFormula}
        
        \(MetalPetalBlendingShadersCodeGenerator.generateBlendFilterFragmentShader(shaderFunctionName: "customBlend", blendFunctionName: "blend"))
        
        \(MetalPetalBlendingShadersCodeGenerator.generateMultilayerCompositeFilterFragmentShader(shaderFunctionName: "multilayerCompositeCustomBlend", blendFunctionName: "blend"))
        
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
