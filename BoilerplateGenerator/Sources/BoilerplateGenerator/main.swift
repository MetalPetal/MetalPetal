import Foundation

let blendModes = ["Normal","Multiply","HardLight", "SoftLight", "Screen", "Overlay", "Darken", "Lighten", "ColorDodge", "ColorBurn", "Difference", "Exclusion", "Hue", "Saturation", "Color", "Luminosity", "Add", "LinearLight"]

if CommandLine.arguments.count > 1 {
    //running in command line mode
    let sourceDirectory = URL(fileURLWithPath: CommandLine.arguments[1])
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
} else {
    //running in playground mode
    print(MTIVectorSIMDTypeSupportCodeGenerator.generate())
    print(MetalPetalBlendingShadersCodeGenerator.generate(blendModes: blendModes))
}
