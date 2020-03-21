//
//  File.swift
//  
//
//  Created by YuAo on 2020/3/17.
//

import XCTest
import MetalPetal
import MetalPetalTestHelpers

fileprivate func listMetalDevices() {
    #if os(macOS)
    let devices = MTLCopyAllDevices()
    for device in devices {
        print(device)
    }
    #else
    if let device = MTLCreateSystemDefaultDevice() {
        print(device)
    }
    #endif
}

fileprivate func makeContext() throws -> MTIContext? {
    if let device = MTLCreateSystemDefaultDevice() {
        let compileOption = MTLCompileOptions()
        compileOption.languageVersion = .version1_2
        let options = MTIContextOptions()
        options.defaultLibraryURL = try BuiltinMetalLibraryWithoutSE0271.makeBuiltinMetalLibrary(compileOptions: compileOption)
        return try MTIContext(device: device, options: options)
    }
    return nil
}

final class ContextTests: XCTestCase {
    
    static override func setUp() {
        super.setUp()
        
        print("----- Metal Devices -----")
        listMetalDevices()
        print("-------------------------")
    }
    
    func testContextCreation() throws {
        let _ = try makeContext()
    }
}

final class ImageLoadingTests: XCTestCase {
    func testCGImageLoading() throws {
        guard let context = try makeContext() else { return }
        let image = MTIImage(cgImage: try ImageGenerator.makeCheckboardImage(), options: [.SRGB: false], isOpaque: true)
        let cgImage = try context.makeCGImage(from: image)
        PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coordinates) in
            if coordinates.x == 0 && coordinates.y == 0 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 0 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
            }
            if coordinates.x == 0 && coordinates.y == 1 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 1 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
        }
    }
}

final class RenderTests: XCTestCase {
    
    func testSolidColorImageRendering() throws {
        guard let context = try makeContext() else { return }
        let image = MTIImage(color: MTIColor(red: 1, green: 0, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 2, height: 2))
        let cgImage = try context.makeCGImage(from: image)
        PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coordinates) in
            XCTAssert(pixel.r == 255 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
        }
    }
    
    func testColorInvertFilter() throws {
        guard let context = try makeContext() else { return }
        let image = MTIImage(color: MTIColor(red: 1, green: 0, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 2, height: 2))
        let filter = MTIColorInvertFilter()
        filter.inputImage = image
        let output = filter.outputImage
        let cgImage = try context.makeCGImage(from: output!)
        PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coordinates) in
            XCTAssert(pixel.r == 0 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
        }
    }
    
    func testBlendWithMaskFilter() throws {
        guard let context = try makeContext() else { return }
        let image = MTIImage(color: MTIColor(red: 1, green: 0, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 2, height: 2))
        let backgroundImage = MTIImage(color: MTIColor(red: 0, green: 1, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 2, height: 2))
        let filter = MTIBlendWithMaskFilter()
        filter.inputBackgroundImage = backgroundImage
        filter.inputImage = image
        filter.inputMask = MTIMask(content: MTIImage(cgImage: try ImageGenerator.makeCheckboardImage(), options: [.SRGB: false], isOpaque: true), component: .red, mode: .normal)
        let output = filter.outputImage
        let cgImage = try context.makeCGImage(from: output!)
        PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coordinates) in
            if coordinates.x == 0 && coordinates.y == 0 {
                XCTAssert(pixel.r == 255 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 0 {
                XCTAssert(pixel.r == 0 && pixel.g == 255 && pixel.b == 0 && pixel.a == 255)
            }
            if coordinates.x == 0 && coordinates.y == 1 {
                XCTAssert(pixel.r == 0 && pixel.g == 255 && pixel.b == 0 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 1 {
                XCTAssert(pixel.r == 255 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
            }
        }
    }
    
    func testSaturationFilter() throws {
        guard let context = try makeContext() else { return }
        let image = MTIImage(color: MTIColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 1), sRGB: false, size: CGSize(width: 2, height: 2))
        let filter = MTISaturationFilter()
        filter.inputImage = image
        filter.saturation = 0
        let output = filter.outputImage
        let cgImage = try context.makeCGImage(from: output!)
        PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coordinates) in
            XCTAssert(pixel.r == pixel.g && pixel.g == pixel.b && pixel.a == 255)
        }
    }
    
    func testIntermediateTextureGeneration() throws {
        guard let context = try makeContext() else { return }
        let image = MTIImage.black
        let saturationFilter = MTISaturationFilter()
        saturationFilter.saturation = 2
        let blendFilter = MTIBlendFilter(blendMode: .multiply)
        let invertFilter = MTIColorInvertFilter()
        let pixellateFilter = MTIPixellateFilter()
        pixellateFilter.scale = CGSize(width: 2, height: 2)
        let outputImage = FilterGraph.makeImage { output in
            image => saturationFilter => pixellateFilter => blendFilter.inputPorts.inputBackgroundImage
            image => invertFilter => blendFilter.inputPorts.inputImage
            blendFilter => saturationFilter => output
        }
        XCTAssert(context.idleResourceCount == 0)
        let _ = try context.makeCGImage(from: outputImage!)
        XCTAssert(context.idleResourceCount == 3)
        
        context.reclaimResources()
        
        XCTAssert(context.idleResourceCount == 0)
        let outputImage2 = FilterGraph.makeImage { output in
            image => saturationFilter => pixellateFilter => invertFilter => saturationFilter => output
        }
        let _ = try context.makeCGImage(from: outputImage2!)
        XCTAssert(context.idleResourceCount == 2)
    }
    
    func testTextureRenderResultPersistence() throws {
        guard let context = try makeContext() else { return }

        let image = MTIImage.black
        let filter = MTIColorInvertFilter()
        filter.inputImage = image
        let output = filter.outputImage!
        let outputCGImage = try context.makeCGImage(from: output)
        PixelEnumerator.enumeratePixels(in: outputCGImage) { (pixel, coordinates) in
            XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
        }
        
        XCTAssert(context.idleResourceCount == 1)
        context.reclaimResources()
        XCTAssert(context.idleResourceCount == 0)
        
        try autoreleasepool {
            let output2 = filter.outputImage!.withCachePolicy(.persistent)
            let outputCGImage2 = try context.makeCGImage(from: output2)
            XCTAssert(context.idleResourceCount == 0)
            
            PixelEnumerator.enumeratePixels(in: outputCGImage2) { (pixel, coordinates) in
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
            
            XCTAssertNotNil(context.renderedBuffer(for: output2))
            
            XCTAssert(context.idleResourceCount == 0)
        }
      
        XCTAssert(context.idleResourceCount == 1)
        context.reclaimResources()
        XCTAssert(context.idleResourceCount == 0)
    }
    
    func testCoreImageFilter() throws {
        guard let context = try makeContext() else { return }
        
        let image = MTIImage.black
        let filter = MTICoreImageUnaryFilter()
        filter.filter = CIFilter(name: "CIColorInvert")
        filter.inputImage = image
        let output = filter.outputImage!
        let outputCGImage = try context.makeCGImage(from: output)
        PixelEnumerator.enumeratePixels(in: outputCGImage) { (pixel, coordinates) in
            XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
        }
    }
    
    func testCoreImageGenerator() throws {
        guard let context = try makeContext() else { return }
        
        let filter: CIFilter = CIFilter(name: "CICheckerboardGenerator")!
        filter.setValue(CIVector(x: 0, y: 0), forKey: "inputCenter")
        filter.setValue(CIColor.white, forKey: "inputColor0")
        filter.setValue(CIColor.black, forKey: "inputColor1")
        filter.setValue(1, forKey: "inputWidth")
        let ciImage = filter.outputImage!
        let mtiImage = MTICoreImageKernel.image(byProcessing: [], using: {_ in
            return ciImage
        }, outputDimensions: MTITextureDimensions(cgSize: CGSize(width: 2, height: 2)))
        let cgImage = try context.makeCGImage(from: mtiImage)
        PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coordinates) in
            if coordinates.x == 0 && coordinates.y == 0 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 0 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 0 && coordinates.y == 1 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 1 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
            }
        }
        
        let mtiImageFromCIImage = MTIImage(ciImage: ciImage.cropped(to: CGRect(x: 0, y: 0, width: 2, height: 2)), isOpaque: false)
        let cgImage2 = try context.makeCGImage(from: mtiImageFromCIImage)
        PixelEnumerator.enumeratePixels(in: cgImage2) { (pixel, coordinates) in
            if coordinates.x == 0 && coordinates.y == 0 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 0 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 0 && coordinates.y == 1 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 1 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
            }
        }
    }
    
}
