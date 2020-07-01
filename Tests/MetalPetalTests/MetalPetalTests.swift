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

fileprivate func makeContext(options: MTIContextOptions? = nil) throws -> MTIContext? {
    if let device = MTLCreateSystemDefaultDevice() {
        return try MTIContext(device: device)
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
    
    func testCGImageLoading_normal() throws {
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
    
    func testCGImageLoading_monochrome() throws {
        guard let context = try makeContext() else { return }
        let image = MTIImage(cgImage: try ImageGenerator.makeCheckboardImageWithMonochromeColorSpace(), options: [.SRGB: false], isOpaque: true)
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
    
    func testCGImageLoading_5bpc() throws {
        guard let context = try makeContext() else { return }
        let image = MTIImage(cgImage: try ImageGenerator.makeCheckboardImageWith5BitPerComponent(), options: [.SRGB: false], isOpaque: true)
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
    
    func testCGImageLoading_bigEndian() throws {
        guard let context = try makeContext() else { return }
        let image = MTIImage(cgImage: try ImageGenerator.makeCheckboardImageWithBigEndian(), options: [.SRGB: false], isOpaque: true)
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
    
    func testCGImageLoading_sRGB() throws {
        guard let context = try makeContext() else { return }
        let image = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([[128]]), options: [.SRGB: true], isOpaque: true)
        let linearImage = try context.makeCGImage(from: image)
        PixelEnumerator.enumeratePixels(in: linearImage) { (pixel, coordinates) in
            if coordinates.x == 0 && coordinates.y == 0 {
                let c = 128.0/255.0
                let linearValue = UInt8((c <= 0.04045) ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) * 255.0)
                XCTAssert(pixel.r == linearValue && pixel.g == linearValue && pixel.b == linearValue && pixel.a == 255)
            }
        }
        let sRGBImage = try context.makeCGImage(from: image, sRGB: true)
        PixelEnumerator.enumeratePixels(in: sRGBImage) { (pixel, coordinates) in
            if coordinates.x == 0 && coordinates.y == 0 {
                XCTAssert(pixel.r == 128 && pixel.g == 128 && pixel.b == 128 && pixel.a == 255)
            }
        }
    }
    
    func testURLImageLoading_orientations() throws {
        guard let context = try makeContext() else { return }
        for orientation in 1...8 {
            let image = MTIImage(contentsOf: URL(fileURLWithPath: #file)
                .deletingLastPathComponent().deletingLastPathComponent()
                .appendingPathComponent("Fixture")
                .appendingPathComponent("f\(orientation).png")
                , options: [.SRGB: false], alphaType: .alphaIsOne)
            guard let inputImage = image else {
                XCTFail()
                return
            }
            let cgImage = try context.makeCGImage(from: inputImage)
            XCTAssert(PixelEnumerator.monochromeImageEqual(image: cgImage, target: [
                [0, 0, 0],
                [0, 0, 255],
                [0, 255, 255],
                [0, 255, 255],
            ]))
        }
    }
    
    func testURLImageLoading_grayColorSpace_orientations() throws {
        guard let context = try makeContext() else { return }
        for orientation in 1...8 {
            let image = MTIImage(contentsOf: URL(fileURLWithPath: #file)
                .deletingLastPathComponent().deletingLastPathComponent()
                .appendingPathComponent("Fixture")
                .appendingPathComponent("fgray\(orientation).png")
                , options: [.SRGB: false], alphaType: .alphaIsOne)
            guard let inputImage = image else {
                XCTFail()
                return
            }
            let cgImage = try context.makeCGImage(from: inputImage)
            XCTAssert(PixelEnumerator.monochromeImageEqual(image: cgImage, target: [
                [0, 0, 0],
                [0, 0, 255],
                [0, 255, 255],
                [0, 255, 255],
            ]))
        }
    }
    
    func testURLImageLoading_grayColorSpace_orientations_flip() throws {
        guard let context = try makeContext() else { return }
        for orientation in 1...8 {
            let image = MTIImage(contentsOf: URL(fileURLWithPath: #file)
                .deletingLastPathComponent().deletingLastPathComponent()
                .appendingPathComponent("Fixture")
                .appendingPathComponent("fgray\(orientation).png")
                , options: [.SRGB: false, .origin: MTKTextureLoader.Origin.flippedVertically], alphaType: .alphaIsOne)
            guard let inputImage = image else {
                XCTFail()
                return
            }
            let cgImage = try context.makeCGImage(from: inputImage)
            XCTAssert(PixelEnumerator.monochromeImageEqual(image: cgImage, target: [
                [0, 255, 255],
                [0, 255, 255],
                [0, 0, 255],
                [0, 0, 0],
            ]))
        }
    }
    
    func testURLImageLoading_grayColorSpace_mtkfallback_orientations() throws {
        guard let context = try makeContext() else { return }
        for orientation in 1...8 {
            let image = MTIImage(contentsOf: URL(fileURLWithPath: #file)
                .deletingLastPathComponent().deletingLastPathComponent()
                .appendingPathComponent("Fixture")
                .appendingPathComponent("fgray\(orientation).png")
                , options: [.SRGB: false, .generateMipmaps: true], alphaType: .alphaIsOne)
            guard let inputImage = image else {
                XCTFail()
                return
            }
            let cgImage = try context.makeCGImage(from: inputImage)
            XCTAssert(PixelEnumerator.monochromeImageEqual(image: cgImage, target: [
                [0, 0, 0],
                [0, 0, 255],
                [0, 255, 255],
                [0, 255, 255],
            ]))
        }
    }
    
    func testURLImageLoading_grayColorSpace_mtkfallback_mipmap() throws {
        guard let context = try makeContext() else { return }
        let url = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Fixture")
            .appendingPathComponent("fgray1.png")
        let textureLoader = MTIDefaultTextureLoader.makeTextureLoader(device: context.device)
        let texture = try textureLoader.newTexture(withContentsOf: url, options: [.SRGB: false, .generateMipmaps: true])
        XCTAssert(texture.mipmapLevelCount > 1)
    }

    func testCVPixelBufferLoading_cvMetalTextureCache() throws {
        var buffer: CVPixelBuffer?
        let r = CVPixelBufferCreate(kCFAllocatorDefault, 2, 2, kCVPixelFormatType_32BGRA, [kCVPixelBufferIOSurfacePropertiesKey as String: [:]] as CFDictionary, &buffer)
        guard let pixelBuffer = buffer, r == kCVReturnSuccess else {
            XCTFail("Cannot create pixel buffer.")
            return
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        if let pixels = CVPixelBufferGetBaseAddress(pixelBuffer)?.assumingMemoryBound(to: UInt8.self) {
            pixels.advanced(by: 0).assign(repeating: 255, count: 1)
            pixels.advanced(by: 1).assign(repeating: 0, count: 1)
            pixels.advanced(by: 2).assign(repeating: 0, count: 1)
            pixels.advanced(by: 3).assign(repeating: 255, count: 1)
            pixels.advanced(by: 0 + CVPixelBufferGetBytesPerRow(pixelBuffer)).assign(repeating: 0, count: 1)
            pixels.advanced(by: 1 + CVPixelBufferGetBytesPerRow(pixelBuffer)).assign(repeating: 255, count: 1)
            pixels.advanced(by: 2 + CVPixelBufferGetBytesPerRow(pixelBuffer)).assign(repeating: 0, count: 1)
            pixels.advanced(by: 3 + CVPixelBufferGetBytesPerRow(pixelBuffer)).assign(repeating: 255, count: 1)
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        
        let image = MTIImage(cvPixelBuffer: pixelBuffer, alphaType: .nonPremultiplied)
        let options = MTIContextOptions()
        options.coreVideoMetalTextureBridgeClass = MTICVMetalTextureCache.self
        guard let context = try makeContext(options: options) else { return }
        let cgImage = try context.makeCGImage(from: image)
        PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coordinates) in
            if coordinates.x == 0 && coordinates.y == 0 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 0 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 0 && pixel.a == 0)
            }
            if coordinates.x == 0 && coordinates.y == 1 {
                XCTAssert(pixel.r == 0 && pixel.g == 255 && pixel.b == 0 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 1 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 0 && pixel.a == 0)
            }
        }
    }
    
    @available(iOS 11.0, macOS 10.13, *)
    func testCVPixelBufferLoading_ioSurface() throws {
        var buffer: CVPixelBuffer?
        let r = CVPixelBufferCreate(kCFAllocatorDefault, 2, 2, kCVPixelFormatType_32BGRA, [kCVPixelBufferIOSurfacePropertiesKey as String: [:]] as CFDictionary, &buffer)
        guard let pixelBuffer = buffer, r == kCVReturnSuccess else {
            XCTFail("Cannot create pixel buffer.")
            return
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        if let pixels = CVPixelBufferGetBaseAddress(pixelBuffer)?.assumingMemoryBound(to: UInt8.self) {
            pixels.advanced(by: 0).assign(repeating: 255, count: 1)
            pixels.advanced(by: 1).assign(repeating: 0, count: 1)
            pixels.advanced(by: 2).assign(repeating: 0, count: 1)
            pixels.advanced(by: 3).assign(repeating: 255, count: 1)
            pixels.advanced(by: 0 + CVPixelBufferGetBytesPerRow(pixelBuffer)).assign(repeating: 0, count: 1)
            pixels.advanced(by: 1 + CVPixelBufferGetBytesPerRow(pixelBuffer)).assign(repeating: 255, count: 1)
            pixels.advanced(by: 2 + CVPixelBufferGetBytesPerRow(pixelBuffer)).assign(repeating: 0, count: 1)
            pixels.advanced(by: 3 + CVPixelBufferGetBytesPerRow(pixelBuffer)).assign(repeating: 255, count: 1)
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        
        let image = MTIImage(cvPixelBuffer: pixelBuffer, alphaType: .nonPremultiplied)
        let options = MTIContextOptions()
        options.coreVideoMetalTextureBridgeClass = MTICVMetalIOSurfaceBridge.self
        guard let context = try makeContext(options: options) else { return }
        let cgImage = try context.makeCGImage(from: image)
        PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coordinates) in
            if coordinates.x == 0 && coordinates.y == 0 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 0 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 0 && pixel.a == 0)
            }
            if coordinates.x == 0 && coordinates.y == 1 {
                XCTAssert(pixel.r == 0 && pixel.g == 255 && pixel.b == 0 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 1 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 0 && pixel.a == 0)
            }
        }
    }

    func testBitmapDataLoading() throws {
        let bitmapData: [UInt8] = [
            255, 255, 255, 255,
            255, 255, 0, 255,
        ]
        let image = MTIImage(bitmapData: Data(bytes: bitmapData, count: bitmapData.count), width: 2, height: 1, bytesPerRow: 8, pixelFormat: .rgba8Unorm, alphaType: .alphaIsOne)
        guard let context = try makeContext() else { return }
        let cgImage = try context.makeCGImage(from: image)
        PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coordinates) in
            if coordinates.x == 0 && coordinates.y == 0 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 0 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 0 && pixel.a == 255)
            }
        }
    }
}

final class RenderTests: XCTestCase {
    
    func testSolidColorImageRendering() throws {
        let image = MTIImage(color: MTIColor(red: 1, green: 0, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 2, height: 2))
        guard let context = try makeContext() else { return }
        let cgImage = try context.makeCGImage(from: image)
        PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coordinates) in
            XCTAssert(pixel.r == 255 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
        }
    }
    
    func testColorInvertFilter() throws {
        let image = MTIImage(color: MTIColor(red: 1, green: 0, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 2, height: 2))
        let filter = MTIColorInvertFilter()
        filter.inputImage = image
        let output = filter.outputImage
        guard let context = try makeContext() else { return }
        let cgImage = try context.makeCGImage(from: output!)
        PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coordinates) in
            XCTAssert(pixel.r == 0 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
        }
    }
    
    func testBlendWithMaskFilter() throws {
        let image = MTIImage(color: MTIColor(red: 1, green: 0, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 2, height: 2))
        let backgroundImage = MTIImage(color: MTIColor(red: 0, green: 1, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 2, height: 2))
        let filter = MTIBlendWithMaskFilter()
        filter.inputBackgroundImage = backgroundImage
        filter.inputImage = image
        filter.inputMask = MTIMask(content: MTIImage(cgImage: try ImageGenerator.makeCheckboardImage(), options: [.SRGB: false], isOpaque: true), component: .red, mode: .normal)
        let output = filter.outputImage
        guard let context = try makeContext() else { return }
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
        let image = MTIImage(color: MTIColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 1), sRGB: false, size: CGSize(width: 2, height: 2))
        let filter = MTISaturationFilter()
        filter.inputImage = image
        filter.saturation = 0
        let output = filter.outputImage
        guard let context = try makeContext() else { return }
        let cgImage = try context.makeCGImage(from: output!)
        PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coordinates) in
            XCTAssert(pixel.r == pixel.g && pixel.g == pixel.b && pixel.a == 255)
        }
    }
    
    func testIntermediateTextureGeneration() throws {
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
        guard let context = try makeContext() else { return }
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
        let image = MTIImage.black
        let filter = MTIColorInvertFilter()
        filter.inputImage = image
        let output = filter.outputImage!
        
        guard let context = try makeContext() else { return }
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
    
    @available(iOS 11.0, *)
    func testCoreImageFilter() throws {
        let image = MTIImage.black
        let filter = MTICoreImageUnaryFilter()
        filter.filter = CIFilter(name: "CIColorInvert")
        filter.inputImage = image
        let output = filter.outputImage!
        
        guard let context = try makeContext() else { return }
        let outputCGImage = try context.makeCGImage(from: output)
        PixelEnumerator.enumeratePixels(in: outputCGImage) { (pixel, coordinates) in
            XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
        }
    }
    
    @available(iOS 11.0, *)
    func testCoreImageGenerator() throws {
        let filter: CIFilter = CIFilter(name: "CICheckerboardGenerator")!
        filter.setValue(CIVector(x: 0, y: 0), forKey: "inputCenter")
        filter.setValue(CIColor.white, forKey: "inputColor0")
        filter.setValue(CIColor.black, forKey: "inputColor1")
        filter.setValue(1, forKey: "inputWidth")
        let ciImage = filter.outputImage!
        let mtiImage = MTICoreImageKernel.image(byProcessing: [], using: {_ in
            return ciImage
        }, outputDimensions: MTITextureDimensions(cgSize: CGSize(width: 2, height: 2)))
        
        guard let context = try makeContext() else { return }
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
    
    func testImageOrientations() throws {
        let image = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
            [0, 0, 0],
            [0, 0, 255],
            [0, 255, 255],
            [0, 255, 255],
        ]), options: [.SRGB: false], isOpaque: true)
        
        guard let context = try makeContext() else { return }
        let renderResult = try context.makeCGImage(from: image)
        XCTAssert(PixelEnumerator.monochromeImageEqual(image: renderResult, target: [
            [0, 0, 0],
            [0, 0, 255],
            [0, 255, 255],
            [0, 255, 255],
        ]))
        
        // * * *
        // * *
        // *
        // *
        let up = try context.makeCGImage(from: image.oriented(.up))
        XCTAssert(PixelEnumerator.monochromeImageEqual(image: up, target: [
            [0, 0, 0],
            [0, 0, 255],
            [0, 255, 255],
            [0, 255, 255],
        ]))
        
        // * * *
        //   * *
        //     *
        //     *
        let upMirrored = try context.makeCGImage(from: image.oriented(.upMirrored))
        XCTAssert(PixelEnumerator.monochromeImageEqual(image: upMirrored, target: [
            [0,     0,   0],
            [255,   0,   0],
            [255, 255,   0],
            [255, 255,   0],
        ]))
        
        //     *
        //     *
        //   * *
        // * * *
        let down = try context.makeCGImage(from: image.oriented(.down))
        XCTAssert(PixelEnumerator.monochromeImageEqual(image: down, target: [
            [255, 255,   0],
            [255, 255,   0],
            [255,   0,   0],
            [  0,   0,   0],
        ]))
        
        // *
        // *
        // * *
        // * * *
        let downMirrored = try context.makeCGImage(from: image.oriented(.downMirrored))
        XCTAssert(PixelEnumerator.monochromeImageEqual(image: downMirrored, target: [
            [  0, 255, 255],
            [  0, 255, 255],
            [  0,   0, 255],
            [  0,   0,   0],
        ]))
        
        // * * * *
        // * *
        // *
        let leftMirrored = try context.makeCGImage(from: image.oriented(.leftMirrored))
        XCTAssert(PixelEnumerator.monochromeImageEqual(image: leftMirrored, target: [
            [  0,   0,   0,   0],
            [  0,   0, 255, 255],
            [  0, 255, 255, 255]
        ]))
        
        // * * * *
        //     * *
        //       *
        let right = try context.makeCGImage(from: image.oriented(.right))
        XCTAssert(PixelEnumerator.monochromeImageEqual(image: right, target: [
            [  0,   0,   0,   0],
            [255, 255,   0,   0],
            [255, 255, 255,   0],
        ]))
        
        //       *
        //     * *
        // * * * *
        let rightMirrored = try context.makeCGImage(from: image.oriented(.rightMirrored))
        XCTAssert(PixelEnumerator.monochromeImageEqual(image: rightMirrored, target: [
            [255, 255, 255,   0],
            [255, 255,   0,   0],
            [  0,   0,   0,   0],
        ]))
        
        // *
        // * *
        // * * * *
        let left = try context.makeCGImage(from: image.oriented(.left))
        XCTAssert(PixelEnumerator.monochromeImageEqual(image: left, target: [
            [  0, 255, 255, 255],
            [  0,   0, 255, 255],
            [  0,   0,   0,   0],
        ]))
    }
    
    func testImageOrientations_fixture() throws {
        guard let context = try makeContext() else { return }
        for orientation in 1...8 {
            let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: #file)
                .deletingLastPathComponent().deletingLastPathComponent()
                .appendingPathComponent("Fixture")
                .appendingPathComponent("f\(orientation).png") as CFURL, nil)
            guard let imageSource = source,
                CGImageSourceGetCount(imageSource) > 0,
                let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
                    XCTFail()
                    return
            }
            guard let o = CGImagePropertyOrientation(rawValue: UInt32(orientation)) else {
                XCTFail()
                return
            }
            let image = MTIImage(cgImage: cgImage, options: [.SRGB: false], isOpaque: true)
            let outputCGImage = try context.makeCGImage(from: image.oriented(o))
            XCTAssert(PixelEnumerator.monochromeImageEqual(image: outputCGImage, target: [
                [0, 0, 0],
                [0, 0, 255],
                [0, 255, 255],
                [0, 255, 255],
            ]))
        }
    }
    
    func testCustomComputePipeline() throws {
        let kernelSource = """
        #include <metal_stdlib>
        using namespace metal;
        
        kernel void testCompute(
        texture2d<float, access::read> inTexture [[texture(0)]],
        texture2d<float, access::write> outTexture [[texture(1)]],
        constant float4 &color [[buffer(0)]],
        uint2 gid [[thread_position_in_grid]]
        ) {
            if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
                return;
            }
            outTexture.write(inTexture.read(uint2(0,0)) + color, gid);
        }
        """
        let libraryURL = MTILibrarySourceRegistration.shared.registerLibrary(source: kernelSource, compileOptions: nil)
        let computeKernel = MTIComputePipelineKernel(computeFunctionDescriptor: MTIFunctionDescriptor(name: "testCompute", libraryURL: libraryURL))
        
        try autoreleasepool {
            let image = MTIImage(color: MTIColor(red: 0, green: 1, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 32, height: 32))
            let outputImage = computeKernel.apply(toInputImages: [image], parameters: ["color": MTIVector(value: SIMD4<Float>(1, 0, 0, 0))], dispatchOptions: nil, outputTextureDimensions: image.dimensions, outputPixelFormat: .unspecified)
            guard let context = try makeContext() else { return }
            let output = try context.makeCGImage(from: outputImage)
            PixelEnumerator.enumeratePixels(in: output) { (pixel, _) in
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 0 && pixel.a == 255)
            }
        }
        
        try autoreleasepool {
            let image = MTIImage(color: MTIColor(red: 0, green: 1, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 1, height: 1))
            let outputImage = computeKernel.apply(toInputImages: [image], parameters: ["color": MTIVector(value: SIMD4<Float>(1, 0, 0, 0))], dispatchOptions: nil, outputTextureDimensions: image.dimensions, outputPixelFormat: .unspecified)
            guard let context = try makeContext() else { return }
            let output = try context.makeCGImage(from: outputImage)
            PixelEnumerator.enumeratePixels(in: output) { (pixel, _) in
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 0 && pixel.a == 255)
            }
        }
    }
    
    func testCustomComputePipelineWithFunctionConstants() throws {
        let kernelSource = """
        #include <metal_stdlib>
        using namespace metal;
        
        constant float4 constColor [[function_constant(0)]];

        kernel void testCompute(
        texture2d<float, access::read> inTexture [[texture(0)]],
        texture2d<float, access::write> outTexture [[texture(1)]],
        uint2 gid [[thread_position_in_grid]]
        ) {
            if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
                return;
            }
            outTexture.write(inTexture.read(uint2(0,0)) + constColor, gid);
        }
        """
        let libraryURL = MTILibrarySourceRegistration.shared.registerLibrary(source: kernelSource, compileOptions: nil)
        let constantValues = MTLFunctionConstantValues()
        var color = SIMD4<Float>(1, 0, 0, 0)
        constantValues.setConstantValue(&color, type: .float4, withName: "constColor")
        let computeKernel = MTIComputePipelineKernel(computeFunctionDescriptor: MTIFunctionDescriptor(name: "testCompute", constantValues: constantValues, libraryURL: libraryURL))
        
        try autoreleasepool {
            let image = MTIImage(color: MTIColor(red: 0, green: 1, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 32, height: 32))
            let outputImage = computeKernel.apply(toInputImages: [image], parameters: [:], dispatchOptions: nil, outputTextureDimensions: image.dimensions, outputPixelFormat: .unspecified)
            guard let context = try makeContext() else { return }
            let output = try context.makeCGImage(from: outputImage)
            PixelEnumerator.enumeratePixels(in: output) { (pixel, _) in
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 0 && pixel.a == 255)
            }
        }
        
        try autoreleasepool {
            let image = MTIImage(color: MTIColor(red: 0, green: 1, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 1, height: 1))
            let outputImage = computeKernel.apply(toInputImages: [image], parameters: [:], dispatchOptions: nil, outputTextureDimensions: image.dimensions, outputPixelFormat: .unspecified)
            guard let context = try makeContext() else { return }
            let output = try context.makeCGImage(from: outputImage)
            PixelEnumerator.enumeratePixels(in: output) { (pixel, _) in
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 0 && pixel.a == 255)
            }
        }
    }
    
    func testCustomRenderPipeline() throws {
        var librarySource = ""
        let sourceFileDirectory = URL(fileURLWithPath: String(#file)).deletingLastPathComponent().appendingPathComponent("../../Sources/MetalPetalObjectiveC")
        let headerURL = sourceFileDirectory.appendingPathComponent("include/MTIShaderLib.h")
        librarySource += try String(contentsOf: headerURL)
        librarySource += """
        
        using namespace metalpetal;
        
        fragment float4 testRender(
                                VertexOut vertexIn [[stage_in]],
                                texture2d<float, access::sample> sourceTexture [[texture(0)]],
                                sampler sourceSampler [[sampler(0)]],
                                constant float4 &color [[buffer(0)]]
                                ) {
            float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
            return textureColor + color;
        }
        """
        let libraryURL = MTILibrarySourceRegistration.shared.registerLibrary(source: librarySource, compileOptions: nil)
        let renderKernel = MTIRenderPipelineKernel(vertexFunctionDescriptor: .passthroughVertex, fragmentFunctionDescriptor: MTIFunctionDescriptor(name: "testRender", libraryURL: libraryURL))
        let image = MTIImage(color: MTIColor(red: 0, green: 1, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 1, height: 1))
        let outputImage = renderKernel.apply(toInputImages: [image], parameters: ["color": MTIVector(value: SIMD4<Float>(1, 0, 0, 0))], outputTextureDimensions: image.dimensions, outputPixelFormat: .unspecified)
        guard let context = try makeContext() else { return }
        let output = try context.makeCGImage(from: outputImage)
        PixelEnumerator.enumeratePixels(in: output) { (pixel, _) in
            XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 0 && pixel.a == 255)
        }
    }
    
    func testCustomRenderPipelineWithFunctionConstants() throws {
        var librarySource = ""
        let sourceFileDirectory = URL(fileURLWithPath: String(#file)).deletingLastPathComponent().appendingPathComponent("../../Sources/MetalPetalObjectiveC")
        let headerURL = sourceFileDirectory.appendingPathComponent("include/MTIShaderLib.h")
        librarySource += try String(contentsOf: headerURL)
        librarySource += """
        
        using namespace metalpetal;
        
        constant float4 constColor [[function_constant(0)]];
        
        fragment float4 testRender(
            VertexOut vertexIn [[stage_in]],
            texture2d<float, access::sample> sourceTexture [[texture(0)]],
            sampler sourceSampler [[sampler(0)]]
        ) {
            float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
            return textureColor + constColor;
        }
        """
        let libraryURL = MTILibrarySourceRegistration.shared.registerLibrary(source: librarySource, compileOptions: nil)
        let constantValues = MTLFunctionConstantValues()
        var color = SIMD4<Float>(1, 0, 0, 0)
        constantValues.setConstantValue(&color, type: .float4, withName: "constColor")
        let renderKernel = MTIRenderPipelineKernel(vertexFunctionDescriptor: .passthroughVertex, fragmentFunctionDescriptor: MTIFunctionDescriptor(name: "testRender", constantValues: constantValues, libraryURL: libraryURL))
        let image = MTIImage(color: MTIColor(red: 0, green: 1, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 1, height: 1))
        let outputImage = renderKernel.apply(toInputImages: [image], parameters: [:], outputTextureDimensions: image.dimensions, outputPixelFormat: .unspecified)
        guard let context = try makeContext() else { return }
        let output = try context.makeCGImage(from: outputImage)
        PixelEnumerator.enumeratePixels(in: output) { (pixel, _) in
            XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 0 && pixel.a == 255)
        }
    }
}
