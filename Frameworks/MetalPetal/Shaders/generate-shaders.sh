#!/usr/bin/env xcrun swift

import Foundation

extension String {
    var lowerCamelCased: String {
        var string = self
        let c = string.removeFirst()
        string.insert(contentsOf: String(c).lowercased(), at: string.startIndex)
        return string
    }
}

struct ShaderTemplate {

    let fileName: String
    
    let header: String
    
    let content: String

    func content(with arguments: [String: String]) -> String {
        var content = self.content
        for (argument, value) in arguments {
            let placeholder = "%\(argument)%"
            content = (content as NSString).replacingOccurrences(of: placeholder, with: value) as String
        }
        return content
    }

    func fileContents(with arguments: [[String: String]]) -> String {
        var contents = self.header
        for arg in arguments {
            contents += self.content(with: arg)
        }
        return contents
    }
}

struct MetalPetalShaderGenerator {
    static let blendModes: [String] = ["Normal","Multiply","HardLight", "SoftLight", "Screen", "Overlay", "Darken", "Lighten", "ColorDodge", "ColorBurn", "Difference", "Exclusion", "Hue", "Saturation", "Color", "Luminosity"]

    static func generateMultilayerCompositeShaders(writeTo shaderDirectoryURL: URL) {
        let multilayerCompositeShaderTemplate = ShaderTemplate(
            fileName: "MultilayerCompositeShaders.metal",
            header: """
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
                outVertex.position = inVertex.position * transformMatrix * orthographicMatrix;
                outVertex.texcoords = inVertex.textureCoordinate;
                return outVertex;
            }

            
            """,
            content: """
            fragment float4 multilayerComposite%BlendModeName%Blend(
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
                return %blendModeName%Blend(currentColor,textureColor);
            }


            """)
        
        var arguments = [[String:String]]()
        for mode in MetalPetalShaderGenerator.blendModes {
            arguments.append([
                "blendModeName": mode.lowerCamelCased,
                "BlendModeName": mode
            ])
        }
        try! multilayerCompositeShaderTemplate.fileContents(with: arguments).write(to: shaderDirectoryURL.appendingPathComponent(multilayerCompositeShaderTemplate.fileName), atomically: true, encoding: String.Encoding.utf8)
    }

    static func generateBlendingShaders(writeTo shaderDirectoryURL: URL) { 
        let blendingShaderTemplate = ShaderTemplate(
            fileName: "BlendingShaders.metal",
            header: """
            #include <metal_stdlib>
            #include "MTIShaderTypes.h"

            using namespace metal;
            using namespace metalpetal;

            
            """,
            content: """
            fragment float4 %blendModeName%BlendInPlace(
                                                        VertexOut vertexIn [[ stage_in ]],
                                                        float4 currentColor [[color(0)]],
                                                        texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                        sampler colorSampler [[ sampler(0) ]],
                                                        constant float &intensity [[buffer(0)]]
                                                        ) {
                float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
                float4 blendedColor = %blendModeName%Blend(currentColor,textureColor);
                return mix(currentColor,blendedColor,intensity);
            }

            fragment float4 %blendModeName%Blend(VertexOut vertexIn [[ stage_in ]],
                                                texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                sampler colorSampler [[ sampler(0) ]],
                                                texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                                sampler overlaySampler [[ sampler(1) ]],
                                                constant float &intensity [[buffer(0)]]
                                                ) {
                float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
                float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
                float4 blendedColor = %blendModeName%Blend(uCb, uCf);
                return mix(uCb,blendedColor,intensity);
            }


            """)
        
        var arguments = [[String:String]]()
        for mode in MetalPetalShaderGenerator.blendModes {
            arguments.append([
                "blendModeName": mode.lowerCamelCased,
                "BlendModeName": mode
            ])
        }
        try! blendingShaderTemplate.fileContents(with: arguments).write(to: shaderDirectoryURL.appendingPathComponent(blendingShaderTemplate.fileName), atomically: true, encoding: String.Encoding.utf8)
    }

    static func run() {
        let currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let scriptURL: URL
        if CommandLine.arguments[0].hasPrefix("/") {
            scriptURL = URL(fileURLWithPath: CommandLine.arguments[0])
        } else {
            scriptURL = currentDirectoryURL.appendingPathComponent(CommandLine.arguments[0])
        }
        let shaderDirectoryURL = scriptURL.deletingLastPathComponent()
        
        MetalPetalShaderGenerator.generateMultilayerCompositeShaders(writeTo: shaderDirectoryURL)
        MetalPetalShaderGenerator.generateBlendingShaders(writeTo: shaderDirectoryURL)
        print("Done!")
    }
}

MetalPetalShaderGenerator.run()
