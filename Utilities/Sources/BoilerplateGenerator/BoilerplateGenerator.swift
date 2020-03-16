//
//  File.swift
//  
//
//  Created by YuAo on 2020/3/16.
//

import Foundation
import ArgumentParser
import URLExpressibleByArgument
import MetalPetalSourceLocator

public struct BoilerplateGenerator: ParsableCommand {
    
    @Argument(help: "The root directory of the MetalPetal repo.")
    var projectRoot: URL
    
    enum CodingKeys: CodingKey {
        case projectRoot
    }
    
    private let fileManager = FileManager()
    
    public init() { }
    
    public func run() throws {
        // Sources
        let blendModes = ["Normal","Darken","Multiply","ColorBurn","LinearBurn","DarkerColor","Lighten","Screen","ColorDodge","Add","LighterColor","Overlay","SoftLight","HardLight","VividLight","LinearLight","PinLight","HardMix", "Difference", "Exclusion", "Subtract", "Divide","Hue","Saturation","Color", "Luminosity"]
        let sourceDirectory = MetalPetalSourcesRootURL(in: projectRoot)
        let mtiVectorFileDirectory = sourceDirectory
        let shadersFileDirectory = sourceDirectory.appendingPathComponent("Shaders")
        for (file, content) in MTIVectorSIMDTypeSupportCodeGenerator.generate() {
            let url = mtiVectorFileDirectory.appendingPathComponent(file)
            try! content.write(to: url, atomically: true, encoding: .utf8)
        }
        for (file, content) in MetalPetalBlendingShadersCodeGenerator.generate(blendModes: blendModes) {
            let url = shadersFileDirectory.appendingPathComponent(file)
            try! content.write(to: url, atomically: true, encoding: .utf8)
        }
        
        //Umbrella Header
    }
}
