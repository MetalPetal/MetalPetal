import Foundation

let blendModes = ["Normal","Darken","Multiply","ColorBurn","LinearBurn","DarkerColor","Lighten","Screen","ColorDodge","Add","LighterColor","Overlay","SoftLight","HardLight","VividLight","LinearLight","PinLight","HardMix", "Difference", "Exclusion", "Subtract", "Divide","Hue","Saturation","Color", "Luminosity"]

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
