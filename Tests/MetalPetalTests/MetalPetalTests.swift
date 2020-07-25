//
//  File.swift
//  
//
//  Created by YuAo on 2020/3/17.
//

import XCTest
import MetalPetal
import MetalPetalTestHelpers
import MetalPetalObjectiveC.Extension
import VideoToolbox

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

final class CGImageLoadingTests: XCTestCase {
    
    func testCGImageLoading_normal() throws {
        guard let context = try makeContext() else { return }
        let image = MTIImage(cgImage: try ImageGenerator.makeCheckboardImage(), options: .default, isOpaque: true)
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
        let image = MTIImage(cgImage: try ImageGenerator.makeCheckboardImageWithMonochromeColorSpace(), options: .default, isOpaque: true)
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
        let image = MTIImage(cgImage: try ImageGenerator.makeCheckboardImageWith5BitPerComponent(), options: .default, isOpaque: true)
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
    
    func testCGImageLoading_bigEndianAlphaLast() throws {
        guard let context = try makeContext() else { return }
        let image = MTIImage(cgImage: try ImageGenerator.makeR0G128B255CheckboardImageWithBigEndianAlphaLast(), options: .default, isOpaque: true)
        let cgImage = try context.makeCGImage(from: image)
        PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coordinates) in
            if coordinates.x == 0 && coordinates.y == 0 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 0 {
                XCTAssert(pixel.r == 0 && pixel.g == 128 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 0 && coordinates.y == 1 {
                XCTAssert(pixel.r == 0 && pixel.g == 128 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 1 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
        }
    }
    
    func testCGImageLoading_bigEndianAlphaFirst() throws {
        guard let context = try makeContext() else { return }
        let image = MTIImage(cgImage: try ImageGenerator.makeR0G128B255CheckboardImageWithBigEndianAlphaFirst(), options: .default, isOpaque: true)
        let cgImage = try context.makeCGImage(from: image)
        PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coordinates) in
            if coordinates.x == 0 && coordinates.y == 0 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 0 {
                XCTAssert(pixel.r == 0 && pixel.g == 128 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 0 && coordinates.y == 1 {
                XCTAssert(pixel.r == 0 && pixel.g == 128 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 1 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
        }
    }
    
    func testCGImageLoading_defaultEndianAlphaFirst() throws {
        guard let context = try makeContext() else { return }
        let image = MTIImage(cgImage: try ImageGenerator.makeR0G128B255CheckboardImageWithDefaultEndianAlphaFirst(), options: .default, isOpaque: true)
        let cgImage = try context.makeCGImage(from: image)
        PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coordinates) in
            if coordinates.x == 0 && coordinates.y == 0 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 0 {
                XCTAssert(pixel.r == 0 && pixel.g == 128 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 0 && coordinates.y == 1 {
                XCTAssert(pixel.r == 0 && pixel.g == 128 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 1 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
        }
    }
    
    
    func testCGImageLoading_sRGB() throws {
        guard let context = try makeContext() else { return }
        
        let image = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([[128]]), options: MTICGImageLoadingOptions(colorSpace: CGColorSpace(name: CGColorSpace.linearSRGB)!), isOpaque: true)
        let linearImage = try context.makeCGImage(from: image)
        PixelEnumerator.enumeratePixels(in: linearImage) { (pixel, coordinates) in
            if coordinates.x == 0 && coordinates.y == 0 {
                let c = 128.0/255.0
                
                // Should we use `round` here? https://developer.apple.com/documentation/metal/mtlrenderpipelinestate/3608177-texturewriteroundingmode
                let linearValue = UInt8(round((c <= 0.04045) ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) * 255.0))
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
                                 , options: .default, alphaType: .alphaIsOne)
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
                                 , options: .default, alphaType: .alphaIsOne)
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
                                 , options: MTICGImageLoadingOptions(colorSpace: nil, flipsVertically: true), alphaType: .alphaIsOne)
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
}

final class TextureLoaderImageLoadingTests: XCTestCase {
    
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
    
    func testCGImageLoading_bigEndianAlphaLast() throws {
        guard let context = try makeContext() else { return }
        let image = MTIImage(cgImage: try ImageGenerator.makeR0G128B255CheckboardImageWithBigEndianAlphaLast(), options: [.SRGB: false], isOpaque: true)
        let cgImage = try context.makeCGImage(from: image)
        PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coordinates) in
            if coordinates.x == 0 && coordinates.y == 0 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 0 {
                XCTAssert(pixel.r == 0 && pixel.g == 128 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 0 && coordinates.y == 1 {
                XCTAssert(pixel.r == 0 && pixel.g == 128 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 1 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
        }
    }
    
    func testCGImageLoading_bigEndianAlphaFirst() throws {
        guard let context = try makeContext() else { return }
        let image = MTIImage(cgImage: try ImageGenerator.makeR0G128B255CheckboardImageWithBigEndianAlphaFirst(), options: [.SRGB: false], isOpaque: true)
        let cgImage = try context.makeCGImage(from: image)
        PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coordinates) in
            if coordinates.x == 0 && coordinates.y == 0 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 0 {
                XCTAssert(pixel.r == 0 && pixel.g == 128 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 0 && coordinates.y == 1 {
                XCTAssert(pixel.r == 0 && pixel.g == 128 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 1 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
        }
    }
    
    func testCGImageLoading_defaultEndianAlphaFirst() throws {
        guard let context = try makeContext() else { return }
        let image = MTIImage(cgImage: try ImageGenerator.makeR0G128B255CheckboardImageWithDefaultEndianAlphaFirst(), options: [.SRGB: false], isOpaque: true)
        let cgImage = try context.makeCGImage(from: image)
        PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coordinates) in
            if coordinates.x == 0 && coordinates.y == 0 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 1 && coordinates.y == 0 {
                XCTAssert(pixel.r == 0 && pixel.g == 128 && pixel.b == 255 && pixel.a == 255)
            }
            if coordinates.x == 0 && coordinates.y == 1 {
                XCTAssert(pixel.r == 0 && pixel.g == 128 && pixel.b == 255 && pixel.a == 255)
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
                
                // Should we use `round` here? https://developer.apple.com/documentation/metal/mtlrenderpipelinestate/3608177-texturewriteroundingmode
                let linearValue = UInt8(round((c <= 0.04045) ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) * 255.0))
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
}

final class ImageLoadingTests: XCTestCase {
    
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
    func testCoreImageFilter_lanczosScaleTransform() throws {
        let ciFilter = CIFilter(name: "CILanczosScaleTransform")
        ciFilter?.setValue(2, forKey: "inputScale")
        
        let inputImage = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
            [0, 1],
            [1, 0]
        ]), options: [.SRGB: false], isOpaque: true)
        
        let filter = MTICoreImageUnaryFilter()
        filter.filter = ciFilter
        filter.inputImage = inputImage
        let output = filter.outputImage!
        
        guard let context = try makeContext() else { return }
        let outputCGImage = try context.makeCGImage(from: output)
        XCTAssert(outputCGImage.width == Int(inputImage.size.width) * 2)
        XCTAssert(outputCGImage.height == Int(inputImage.size.height) * 2)
        XCTAssert(PixelEnumerator.monochromeImageEqual(image: outputCGImage, target: [
            [0, 0, 1, 1],
            [0, 0, 1, 1],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
        ]))
    }
    
    func testMPSFilter_lanczosScale() throws {
        let kernel = MTIMPSKernel { device in
            return MPSImageLanczosScale(device: device)
        }
        let inputImage = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
            [0, 1],
            [1, 0]
        ]), options: [.SRGB: false], isOpaque: true)
        let scaledDimensions = MTITextureDimensions(cgSize: CGSize(width: inputImage.size.width * 2, height: inputImage.size.height * 2))
        let outputImage = kernel.apply(toInputImages: [inputImage], parameters: [:], outputTextureDimensions: scaledDimensions, outputPixelFormat: .unspecified)
        guard let context = try makeContext() else { return }
        if MTIContext.defaultMetalDeviceSupportsMPS {
            let outputCGImage = try context.makeCGImage(from: outputImage)
            XCTAssert(outputCGImage.width == Int(inputImage.size.width) * 2)
            XCTAssert(outputCGImage.height == Int(inputImage.size.height) * 2)
            XCTAssert(PixelEnumerator.monochromeImageEqual(image: outputCGImage, target: [
                [0, 0, 1, 1],
                [0, 0, 1, 1],
                [1, 1, 0, 0],
                [1, 1, 0, 0],
            ]))
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
    
    func testMultilayerCompositing() throws {
        guard let context = try makeContext() else { return }
        
        let image = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
            [0, 0],
        ]), options: [.SRGB: false], isOpaque: true)
        
        let filter = MultilayerCompositingFilter()
        filter.inputBackgroundImage = image
        filter.rasterSampleCount = 1
        filter.layers = [MultilayerCompositingFilter.makeLayer(content: MTIImage.white, configurator: { layer in
            layer.position = CGPoint(x: 0.5, y: 0.5)
            layer.size = CGSize(width: 1, height: 1)
            layer.opacity = 1
        })]
        let outputImage = try XCTUnwrap(filter.outputImage)
        let outputCGImage = try context.makeCGImage(from: outputImage)
        PixelEnumerator.enumeratePixels(in: outputCGImage) { (pixel, coord) in
            if coord.x == 0 && coord.y == 0 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
            if coord.x == 1 && coord.y == 0 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
            }
        }
    }
    
    func testMultilayerCompositing_tint() throws {
        guard let context = try makeContext() else { return }
        
        let image = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
            [0, 0],
        ]), options: [.SRGB: false], isOpaque: true)
        
        let filter = MultilayerCompositingFilter()
        filter.inputBackgroundImage = image
        filter.rasterSampleCount = 1
        filter.layers = [MultilayerCompositingFilter.makeLayer(content: MTIImage.white, configurator: { layer in
            layer.position = CGPoint(x: 0.5, y: 0.5)
            layer.size = CGSize(width: 1, height: 1)
            layer.opacity = 1
            layer.tintColor = MTIColor(red: 1, green: 1, blue: 0, alpha: 1)
        })]
        let outputImage = try XCTUnwrap(filter.outputImage)
        let outputCGImage = try context.makeCGImage(from: outputImage)
        PixelEnumerator.enumeratePixels(in: outputCGImage) { (pixel, coord) in
            if coord.x == 0 && coord.y == 0 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 0 && pixel.a == 255)
            }
            if coord.x == 1 && coord.y == 0 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
            }
        }
    }
    
    func testMultilayerCompositing_tintWithAlpha() throws {
        guard let context = try makeContext() else { return }
        
        let image = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
            [0, 0],
        ]), options: [.SRGB: false], isOpaque: true)
        
        let filter = MultilayerCompositingFilter()
        filter.inputBackgroundImage = image
        
        try autoreleasepool {
            filter.layers = [MultilayerCompositingFilter.makeLayer(content: MTIImage.white, configurator: { layer in
                layer.position = CGPoint(x: 0.5, y: 0.5)
                layer.size = CGSize(width: 1, height: 1)
                layer.opacity = 1
                layer.tintColor = MTIColor(red: 1, green: 1, blue: 0, alpha: 0.5)
            })]
            let outputImage = try XCTUnwrap(filter.outputImage)
            let outputCGImage = try context.makeCGImage(from: outputImage)
            PixelEnumerator.enumeratePixels(in: outputCGImage) { (pixel, coord) in
                if coord.x == 0 && coord.y == 0 {
                    XCTAssert(pixel.r == 128 && pixel.g == 128 && pixel.b == 0 && pixel.a == 255)
                }
                if coord.x == 1 && coord.y == 0 {
                    XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
                }
            }
        }
        
        try autoreleasepool {
            filter.layers = [MultilayerCompositingFilter.makeLayer(content: MTIImage.white, configurator: { layer in
                layer.position = CGPoint(x: 0.5, y: 0.5)
                layer.size = CGSize(width: 1, height: 1)
                layer.opacity = 1
                layer.tintColor = MTIColor(red: 1, green: 1, blue: 0, alpha: 0)
            })]
            let outputImage = try XCTUnwrap(filter.outputImage)
            let outputCGImage = try context.makeCGImage(from: outputImage)
            PixelEnumerator.enumeratePixels(in: outputCGImage) { (pixel, coord) in
                if coord.x == 0 && coord.y == 0 {
                    XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
                }
                if coord.x == 1 && coord.y == 0 {
                    XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
                }
            }
        }
    }
    
    func testMultilayerCompositing_rotation() throws {
        guard let context = try makeContext() else { return }
        
        let image = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
            [0, 0],
            [0, 0],
        ]), options: [.SRGB: false], isOpaque: true)
        
        let overlayImage = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
            [0, 255],
            [0, 0],
        ]), options: [.SRGB: false], isOpaque: true)
        
        let filter = MultilayerCompositingFilter()
        filter.inputBackgroundImage = image
        filter.rasterSampleCount = 1
        filter.layers = [MultilayerCompositingFilter.makeLayer(content: overlayImage, configurator: { layer in
            layer.position = CGPoint(x: 1, y: 1)
            layer.size = CGSize(width: 2, height: 2)
            layer.rotation = .pi/2
            layer.opacity = 1
        })]
        guard let outputImage = filter.outputImage else {
            XCTFail()
            return
        }
        let outputCGImage = try context.makeCGImage(from: outputImage)
        PixelEnumerator.enumeratePixels(in: outputCGImage) { (pixel, coord) in
            if coord.x == 0 && coord.y == 0 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
            }
            if coord.x == 1 && coord.y == 0 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
            }
            if coord.x == 1 && coord.y == 1 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
            if coord.x == 0 && coord.y == 1 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
            }
        }
    }
    
    @available(iOS 11.0, macOS 10.13, *)
    func testMSAA_multilayerCompositing() throws {
        guard let context = try makeContext() else { return }
        
        let image = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
            [0, 0],
        ]), options: [.SRGB: false], isOpaque: true)
        
        let filter = MultilayerCompositingFilter()
        filter.inputBackgroundImage = image
        filter.rasterSampleCount = 1
        filter.layers = [MultilayerCompositingFilter.makeLayer(content: MTIImage.white, configurator: { layer in
            layer.position = CGPoint(x: 1.6/2, y: 0.5)
            layer.size = CGSize(width: 1.6, height: 1)
            layer.opacity = 1
        })]
        guard let outputImage = filter.outputImage else {
            XCTFail()
            return
        }
        let outputCGImage = try context.makeCGImage(from: outputImage)
        PixelEnumerator.enumeratePixels(in: outputCGImage) { (pixel, coord) in
            if coord.x == 0 && coord.y == 0 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
            if coord.x == 1 && coord.y == 0 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
        }
        
        filter.rasterSampleCount = 4
        guard let outputImageMSAA = filter.outputImage else {
            XCTFail()
            return
        }
        let outputCGImageMSAA = try context.makeCGImage(from: outputImageMSAA)
        PixelEnumerator.enumeratePixels(in: outputCGImageMSAA) { (pixel, coord) in
            if coord.x == 0 && coord.y == 0 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
            if coord.x == 1 && coord.y == 0 {
                let positions = context.device.getDefaultSamplePositions(sampleCount: 4)
                var p: Double = 0
                for position in positions {
                    if position.x < 0.6 {
                        p += 1.0/4.0
                    }
                }
                
                //Should we use `round` here? https://developer.apple.com/documentation/metal/mtlrenderpipelinestate/3608177-texturewriteroundingmode
                let value = UInt8(round(p * 255))
                XCTAssert(pixel.r == value && pixel.g == value && pixel.b == value && pixel.a == 255)
            }
        }
    }
    
    @available(iOS 11.0, macOS 10.13, *)
    func testMSAA_renderCommand() throws {
        guard let context = try makeContext() else { return }
        
        let geometry = MTIVertices.squareVertices(for: CGRect(x: -1, y: -1, width: 1.6, height: 2))
        let command = MTIRenderCommand(kernel: .passthrough, geometry: geometry, images: [MTIImage.white], parameters: [:])
        let outputDescriptor = MTIRenderPassOutputDescriptor(dimensions: MTITextureDimensions(width: 2, height: 1, depth: 1), pixelFormat: .bgra8Unorm, clearColor: MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1), loadAction: .clear, storeAction: .store)
        let image = MTIRenderCommand.images(byPerforming: [command], rasterSampleCount: 1, outputDescriptors: [outputDescriptor]).first
        guard let outputImage = image else {
            XCTFail()
            return
        }
        let outputCGImage = try context.makeCGImage(from: outputImage)
        PixelEnumerator.enumeratePixels(in: outputCGImage) { (pixel, coord) in
            if coord.x == 0 && coord.y == 0 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
            if coord.x == 1 && coord.y == 0 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
        }
        
        let imageMSAA = MTIRenderCommand.images(byPerforming: [command], rasterSampleCount: 4, outputDescriptors: [outputDescriptor]).first
        guard let outputImageMSAA = imageMSAA else {
            XCTFail()
            return
        }
        let outputCGImageMSAA = try context.makeCGImage(from: outputImageMSAA)
        PixelEnumerator.enumeratePixels(in: outputCGImageMSAA) { (pixel, coord) in
            if coord.x == 0 && coord.y == 0 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
            if coord.x == 1 && coord.y == 0 {
                let positions = context.device.getDefaultSamplePositions(sampleCount: 4)
                var p: Double = 0
                for position in positions {
                    if position.x < 0.6 {
                        p += 1.0/4.0
                    }
                }
                
                //Should we use `round` here? https://developer.apple.com/documentation/metal/mtlrenderpipelinestate/3608177-texturewriteroundingmode
                let value = UInt8(round(p * 255))
                XCTAssert(pixel.r == value && pixel.g == value && pixel.b == value && pixel.a == 255)
            }
        }
    }
    
    func testRenderedBuffer() throws {
        guard let context = try makeContext() else { return }
        let image = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
            [255, 255],
            [0, 255],
        ]), options: [.SRGB: false], isOpaque: true)
        
        let filter1 = MTIColorInvertFilter()
        filter1.inputImage = image
        
        let filter2 = MTITransformFilter()
        filter2.transform = CATransform3DMakeRotation(.pi/2, 0, 0, 1)
        filter2.inputImage = filter1.outputImage
        
        var renderedBuffer: MTIImage!
        
        try autoreleasepool {
            let outputImage = try XCTUnwrap(filter2.outputImage?.withCachePolicy(.persistent))
            
            XCTAssert(context.renderedBuffer(for: outputImage) == nil)
            
            try context.startTask(toRender: outputImage, completion: nil)
            
            XCTAssert(context.renderedBuffer(for: outputImage) != nil)
            
            let buffer = try XCTUnwrap(context.renderedBuffer(for: outputImage))
            
            renderedBuffer = buffer
            
            XCTAssert(context.idleResourceCount == 1)
        }
        
        context.reclaimResources()
        
        XCTAssert(context.idleResourceCount == 0)
        
        let outputCGImage = try context.makeCGImage(from: renderedBuffer)
        PixelEnumerator.enumeratePixels(in: outputCGImage) { (pixel, coord) in
            if coord.x == 0 && coord.y == 0 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
            }
            if coord.x == 1 && coord.y == 0 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
            }
            if coord.x == 0 && coord.y == 1 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
            }
            if coord.x == 1 && coord.y == 1 {
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
        }
        
        XCTAssert(context.idleResourceCount == 0)
        
        renderedBuffer = nil
        
        XCTAssert(context.idleResourceCount == 1)
        
        context.reclaimResources()
        
        XCTAssert(context.idleResourceCount == 0)
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
    
    @available(iOS 11.0, macOS 10.13, *)
    func testSKSceneRender() throws {
        let scene = SKScene(size: CGSize(width: 32, height: 32))
        
        let node1 = SKShapeNode(circleOfRadius: 16)
        node1.fillColor = .red
        node1.lineWidth = 1
        node1.strokeColor = .white
        scene.addChild(node1)
        
        let node2 = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 32, height: 32))
        node2.fillColor = .blue
        node2.lineWidth = 0
        scene.addChild(node2)
        
        let node3 = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 32, height: 16))
        node3.fillColor = .green
        node3.lineWidth = 0
        scene.addChild(node3)
        
        let image = MTIImage(skScene: scene)
        guard let context = try makeContext() else { return }
        let output = try context.makeCGImage(from: image)
        PixelEnumerator.enumeratePixels(in: output) { (pixel, coord) in
            if coord.y < 16 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 255 && pixel.a == 255)
            } else {
                XCTAssert(pixel.r == 0 && pixel.g == 255 && pixel.b == 0 && pixel.a == 255)
            }
        }
    }
    
    func testSCNSceneRender() throws {
        let scene = SCNScene()
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)

        let cubeNode = SCNNode()
        cubeNode.geometry = SCNBox(width: 20, height: 20, length: 20, chamferRadius: 0)
        cubeNode.geometry?.firstMaterial?.lightingModel = .constant
        var color: [CGFloat] = [0,0,0.5,1]
        cubeNode.geometry?.firstMaterial?.diffuse.contents = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: &color)!
        cubeNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(cubeNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        var whiteColor: [CGFloat] = [1,1,1,1]
        ambientLightNode.light!.color = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: &whiteColor)!
        scene.rootNode.addChildNode(ambientLightNode)
        
        guard let context = try makeContext() else { return }
        let renderer = MTISCNSceneRenderer(device: context.device)
        renderer.scene = scene
        renderer.scnRenderer.pointOfView = cameraNode
        let image = renderer.snapshot(atTime: CFAbsoluteTimeGetCurrent(), viewport: CGRect(x: 0, y: 0, width: 32, height: 32), pixelFormat: .unspecified, isOpaque: true)
        let sRGBImage = MTILinearToSRGBToneCurveFilter.image(byProcessingImage: image)
        let output = try context.makeCGImage(from: sRGBImage)
        PixelEnumerator.enumeratePixels(in: output) { (pixel, coord) in
            XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 128 && pixel.a == 255)
        }
    }
    
    func testSCNSceneRender_msaa() throws {
        let scene = SCNScene()
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 16)
        
        let cubeNode = SCNNode()
        cubeNode.geometry = SCNBox(width: 8, height: 8, length: 8, chamferRadius: 0)
        cubeNode.geometry?.firstMaterial?.lightingModel = .constant
        var color: [CGFloat] = [1,1,1,1]
        cubeNode.geometry?.firstMaterial?.diffuse.contents = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: &color)!
        cubeNode.position = SCNVector3(x: 0, y: 0, z: 0)
        cubeNode.rotation = SCNVector4(x: 0, y: 0, z: 1, w: .pi/4)
        scene.rootNode.addChildNode(cubeNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        var whiteColor: [CGFloat] = [1,1,1,1]
        ambientLightNode.light!.color = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: &whiteColor)!
        scene.rootNode.addChildNode(ambientLightNode)
        
        guard let context = try makeContext() else { return }
        
        let renderer = MTISCNSceneRenderer(device: context.device)
        renderer.scene = scene
        renderer.scnRenderer.pointOfView = cameraNode
        do {
            // With MSAA
            renderer.antialiasingMode = .multisampling4X
            let image = renderer.snapshot(atTime: 0, viewport: CGRect(x: 0, y: 0, width: 4, height: 4), pixelFormat: .unspecified, isOpaque: false).unpremultiplyingAlpha()
            let sRGBImage = MTILinearToSRGBToneCurveFilter.image(byProcessingImage: image)
            let output = try context.makeCGImage(from: sRGBImage)
            let result: [PixelEnumerator.Coordinates: PixelEnumerator.Pixel] = [
                PixelEnumerator.Coordinates(x: 0, y: 3): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                PixelEnumerator.Coordinates(x: 3, y: 2): PixelEnumerator.Pixel(b: 64, g: 64, r: 64, a: 64),
                PixelEnumerator.Coordinates(x: 0, y: 2): PixelEnumerator.Pixel(b: 64, g: 64, r: 64, a: 64),
                PixelEnumerator.Coordinates(x: 2, y: 2): PixelEnumerator.Pixel(b: 255, g: 255, r: 255, a: 255),
                PixelEnumerator.Coordinates(x: 1, y: 2): PixelEnumerator.Pixel(b: 255, g: 255, r: 255, a: 255),
                PixelEnumerator.Coordinates(x: 3, y: 1): PixelEnumerator.Pixel(b: 64, g: 64, r: 64, a: 64),
                PixelEnumerator.Coordinates(x: 2, y: 1): PixelEnumerator.Pixel(b: 255, g: 255, r: 255, a: 255),
                PixelEnumerator.Coordinates(x: 0, y: 0): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                PixelEnumerator.Coordinates(x: 2, y: 3): PixelEnumerator.Pixel(b: 64, g: 64, r: 64, a: 64),
                PixelEnumerator.Coordinates(x: 3, y: 3): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                PixelEnumerator.Coordinates(x: 1, y: 3): PixelEnumerator.Pixel(b: 64, g: 64, r: 64, a: 64),
                PixelEnumerator.Coordinates(x: 1, y: 1): PixelEnumerator.Pixel(b: 255, g: 255, r: 255, a: 255),
                PixelEnumerator.Coordinates(x: 1, y: 0): PixelEnumerator.Pixel(b: 64, g: 64, r: 64, a: 64),
                PixelEnumerator.Coordinates(x: 2, y: 0): PixelEnumerator.Pixel(b: 64, g: 64, r: 64, a: 64),
                PixelEnumerator.Coordinates(x: 0, y: 1): PixelEnumerator.Pixel(b: 64, g: 64, r: 64, a: 64),
                PixelEnumerator.Coordinates(x: 3, y: 0): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0)]
            PixelEnumerator.enumeratePixels(in: output) { (pixel, coord) in
                XCTAssert(result[coord] == pixel)
            }
        } catch {
            throw error
        }
        
        do {
            // Without MSAA
            renderer.antialiasingMode = .none
            let image = renderer.snapshot(atTime: 0, viewport: CGRect(x: 0, y: 0, width: 4, height: 4), pixelFormat: .unspecified, isOpaque: false).unpremultiplyingAlpha()
            let sRGBImage = MTILinearToSRGBToneCurveFilter.image(byProcessingImage: image)
            let output = try context.makeCGImage(from: sRGBImage)
            let result: [PixelEnumerator.Coordinates: PixelEnumerator.Pixel] = [
                PixelEnumerator.Coordinates(x: 0, y: 3): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                PixelEnumerator.Coordinates(x: 3, y: 2): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                PixelEnumerator.Coordinates(x: 0, y: 2): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                PixelEnumerator.Coordinates(x: 2, y: 2): PixelEnumerator.Pixel(b: 255, g: 255, r: 255, a: 255),
                PixelEnumerator.Coordinates(x: 1, y: 2): PixelEnumerator.Pixel(b: 255, g: 255, r: 255, a: 255),
                PixelEnumerator.Coordinates(x: 3, y: 1): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                PixelEnumerator.Coordinates(x: 2, y: 1): PixelEnumerator.Pixel(b: 255, g: 255, r: 255, a: 255),
                PixelEnumerator.Coordinates(x: 0, y: 0): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                PixelEnumerator.Coordinates(x: 2, y: 3): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                PixelEnumerator.Coordinates(x: 3, y: 3): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                PixelEnumerator.Coordinates(x: 1, y: 3): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                PixelEnumerator.Coordinates(x: 1, y: 1): PixelEnumerator.Pixel(b: 255, g: 255, r: 255, a: 255),
                PixelEnumerator.Coordinates(x: 1, y: 0): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                PixelEnumerator.Coordinates(x: 2, y: 0): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                PixelEnumerator.Coordinates(x: 0, y: 1): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                PixelEnumerator.Coordinates(x: 3, y: 0): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0)]
            PixelEnumerator.enumeratePixels(in: output) { (pixel, coord) in
                XCTAssert(result[coord] == pixel)
            }
        } catch {
            throw error
        }
    }
    
    func testSCNSceneRender_msaa_pixelbuffer() throws {
        let scene = SCNScene()
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 16)
        
        let cubeNode = SCNNode()
        cubeNode.geometry = SCNBox(width: 8, height: 8, length: 8, chamferRadius: 0)
        cubeNode.geometry?.firstMaterial?.lightingModel = .constant
        var color: [CGFloat] = [1,1,1,1]
        cubeNode.geometry?.firstMaterial?.diffuse.contents = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: &color)!
        cubeNode.position = SCNVector3(x: 0, y: 0, z: 0)
        cubeNode.rotation = SCNVector4(x: 0, y: 0, z: 1, w: .pi/4)
        scene.rootNode.addChildNode(cubeNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        var whiteColor: [CGFloat] = [1,1,1,1]
        ambientLightNode.light!.color = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: &whiteColor)!
        scene.rootNode.addChildNode(ambientLightNode)
        
        guard let context = try makeContext() else { return }
        
        let renderer = MTISCNSceneRenderer(device: context.device)
        renderer.scene = scene
        renderer.scnRenderer.pointOfView = cameraNode
        do {
            // With MSAA
            let expection = XCTestExpectation()
            renderer.antialiasingMode = .multisampling4X
            try renderer.render(atTime: 0, viewport: CGRect(x: 0, y: 0, width: 4, height: 4), sRGB: true) { pixelBuffer in
                var cgImage: CGImage!
                VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
                let result: [PixelEnumerator.Coordinates: PixelEnumerator.Pixel] = [
                    PixelEnumerator.Coordinates(x: 0, y: 3): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                    PixelEnumerator.Coordinates(x: 3, y: 2): PixelEnumerator.Pixel(b: 64, g: 64, r: 64, a: 64),
                    PixelEnumerator.Coordinates(x: 0, y: 2): PixelEnumerator.Pixel(b: 64, g: 64, r: 64, a: 64),
                    PixelEnumerator.Coordinates(x: 2, y: 2): PixelEnumerator.Pixel(b: 255, g: 255, r: 255, a: 255),
                    PixelEnumerator.Coordinates(x: 1, y: 2): PixelEnumerator.Pixel(b: 255, g: 255, r: 255, a: 255),
                    PixelEnumerator.Coordinates(x: 3, y: 1): PixelEnumerator.Pixel(b: 64, g: 64, r: 64, a: 64),
                    PixelEnumerator.Coordinates(x: 2, y: 1): PixelEnumerator.Pixel(b: 255, g: 255, r: 255, a: 255),
                    PixelEnumerator.Coordinates(x: 0, y: 0): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                    PixelEnumerator.Coordinates(x: 2, y: 3): PixelEnumerator.Pixel(b: 64, g: 64, r: 64, a: 64),
                    PixelEnumerator.Coordinates(x: 3, y: 3): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                    PixelEnumerator.Coordinates(x: 1, y: 3): PixelEnumerator.Pixel(b: 64, g: 64, r: 64, a: 64),
                    PixelEnumerator.Coordinates(x: 1, y: 1): PixelEnumerator.Pixel(b: 255, g: 255, r: 255, a: 255),
                    PixelEnumerator.Coordinates(x: 1, y: 0): PixelEnumerator.Pixel(b: 64, g: 64, r: 64, a: 64),
                    PixelEnumerator.Coordinates(x: 2, y: 0): PixelEnumerator.Pixel(b: 64, g: 64, r: 64, a: 64),
                    PixelEnumerator.Coordinates(x: 0, y: 1): PixelEnumerator.Pixel(b: 64, g: 64, r: 64, a: 64),
                    PixelEnumerator.Coordinates(x: 3, y: 0): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0)]
                PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coord) in
                    XCTAssert(result[coord] == pixel)
                }
                expection.fulfill()
            }
            wait(for: [expection], timeout: 1)
        } catch {
            throw error
        }
        
        do {
            let expection = XCTestExpectation()
            renderer.antialiasingMode = .none
            try renderer.render(atTime: 0, viewport: CGRect(x: 0, y: 0, width: 4, height: 4), sRGB: true) { pixelBuffer in
                var cgImage: CGImage!
                VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
                let result: [PixelEnumerator.Coordinates: PixelEnumerator.Pixel] = [
                    PixelEnumerator.Coordinates(x: 0, y: 3): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                    PixelEnumerator.Coordinates(x: 3, y: 2): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                    PixelEnumerator.Coordinates(x: 0, y: 2): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                    PixelEnumerator.Coordinates(x: 2, y: 2): PixelEnumerator.Pixel(b: 255, g: 255, r: 255, a: 255),
                    PixelEnumerator.Coordinates(x: 1, y: 2): PixelEnumerator.Pixel(b: 255, g: 255, r: 255, a: 255),
                    PixelEnumerator.Coordinates(x: 3, y: 1): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                    PixelEnumerator.Coordinates(x: 2, y: 1): PixelEnumerator.Pixel(b: 255, g: 255, r: 255, a: 255),
                    PixelEnumerator.Coordinates(x: 0, y: 0): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                    PixelEnumerator.Coordinates(x: 2, y: 3): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                    PixelEnumerator.Coordinates(x: 3, y: 3): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                    PixelEnumerator.Coordinates(x: 1, y: 3): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                    PixelEnumerator.Coordinates(x: 1, y: 1): PixelEnumerator.Pixel(b: 255, g: 255, r: 255, a: 255),
                    PixelEnumerator.Coordinates(x: 1, y: 0): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                    PixelEnumerator.Coordinates(x: 2, y: 0): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                    PixelEnumerator.Coordinates(x: 0, y: 1): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0),
                    PixelEnumerator.Coordinates(x: 3, y: 0): PixelEnumerator.Pixel(b: 0, g: 0, r: 0, a: 0)]
                PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coord) in
                    XCTAssert(result[coord] == pixel)
                }
                expection.fulfill()
            }
            wait(for: [expection], timeout: 1)
        } catch {
            throw error
        }
    }
}

final class UtilitiesTests: XCTestCase {
    
    func testLock() throws {
        var counter: Int = 0
        let lock = MTILockCreate()
        DispatchQueue.concurrentPerform(iterations: 1000_000) { _ in
            lock.lock()
            counter += 1
            lock.unlock()
        }
        XCTAssert(counter == 1000_000)
    }

    func testWeakToStrongTable() throws {
        class Key {}
        class Value {}
        let table = MTIWeakToStrongObjectsMapTable<Key,Value>()
        
        var key: Key? = Key()
        var value: Value? = Value()
        table.setObject(value!, forKey: key!)
        
        weak var weakValue = value
        value = nil
        
        XCTAssert(weakValue != nil)
        
        XCTAssert(table.object(forKey: key!) === weakValue)
        
        key = nil
        
        XCTAssert(weakValue == nil)
    }
    
    func testMTILayerModel() throws {
        var propertyCount: UInt32 = 0
        let list = try XCTUnwrap(class_copyPropertyList(MTILayer.self, &propertyCount))
        let properties = [objc_property_t](UnsafeBufferPointer<objc_property_t>(start: list, count: Int(propertyCount)))
        list.deallocate()
        let swiftLayerMirror = Mirror(reflecting: MultilayerCompositingFilter.Layer(content: .white))
        for property in properties {
            XCTAssert(swiftLayerMirror.children.contains { label, value in
                label == String(cString: property_getName(property))
            })
        }
    }
    
    func testDirectSIMDVectorSupport_float4() throws {
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
        let outputImage = renderKernel.apply(toInputImages: [image], parameters: ["color": SIMD4<Float>(1, 0, 0, 0)], outputTextureDimensions: image.dimensions, outputPixelFormat: .unspecified)
        guard let context = try makeContext() else { return }
        let output = try context.makeCGImage(from: outputImage)
        PixelEnumerator.enumeratePixels(in: output) { (pixel, _) in
            XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 0 && pixel.a == 255)
        }
    }
    
    func testDirectSIMDVectorSupport_float2x2() throws {
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
                                constant float2x2 &color [[buffer(0)]]
                                ) {
            float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
            return textureColor + float4(color[0][0],color[1][0],color[0][1],color[1][1]);
        }
        """
        let libraryURL = MTILibrarySourceRegistration.shared.registerLibrary(source: librarySource, compileOptions: nil)
        let renderKernel = MTIRenderPipelineKernel(vertexFunctionDescriptor: .passthroughVertex, fragmentFunctionDescriptor: MTIFunctionDescriptor(name: "testRender", libraryURL: libraryURL))
        let image = MTIImage(color: MTIColor(red: 0, green: 1, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 1, height: 1))
        let outputImage = renderKernel.apply(toInputImages: [image], parameters: ["color": float2x2(rows: [SIMD2<Float>(1,0),SIMD2<Float>(1,0)])], outputTextureDimensions: image.dimensions, outputPixelFormat: .unspecified)
        guard let context = try makeContext() else { return }
        let output = try context.makeCGImage(from: outputImage)
        PixelEnumerator.enumeratePixels(in: output) { (pixel, _) in
            XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
        }
    }
    
    func testDirectSIMDVectorSupport_uchar4() throws {
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
                                constant uchar4 &color [[buffer(0)]]
                                ) {
            float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
            float r = color.r / 255.0;
            float g = color.g / 255.0;
            float b = color.b / 255.0;
            float a = color.a / 255.0;
            return textureColor + float4(r,g,b,a);
        }
        """
        let libraryURL = MTILibrarySourceRegistration.shared.registerLibrary(source: librarySource, compileOptions: nil)
        let renderKernel = MTIRenderPipelineKernel(vertexFunctionDescriptor: .passthroughVertex, fragmentFunctionDescriptor: MTIFunctionDescriptor(name: "testRender", libraryURL: libraryURL))
        let image = MTIImage(color: MTIColor(red: 0, green: 1, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 1, height: 1))
        let outputImage = renderKernel.apply(toInputImages: [image], parameters: ["color": SIMD4<UInt8>(128, 0, 0, 0)], outputTextureDimensions: image.dimensions, outputPixelFormat: .unspecified)
        guard let context = try makeContext() else { return }
        let output = try context.makeCGImage(from: outputImage)
        PixelEnumerator.enumeratePixels(in: output) { (pixel, _) in
            XCTAssert(pixel.r == 128 && pixel.g == 255 && pixel.b == 0 && pixel.a == 255)
        }
    }
    
    func testDirectSIMDVectorSupport_int64_4() throws {
        let kernelSource = """
        #include <metal_stdlib>
        using namespace metal;
        
        kernel void testCompute(
        texture2d<float, access::read> inTexture [[texture(0)]],
        texture2d<float, access::write> outTexture [[texture(1)]],
        constant int4 &color [[buffer(0)]],
        uint2 gid [[thread_position_in_grid]]
        ) {
            if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
                return;
            }
            outTexture.write(inTexture.read(uint2(0,0)), gid);
        }
        """
        let libraryURL = MTILibrarySourceRegistration.shared.registerLibrary(source: kernelSource, compileOptions: nil)
        let computeKernel = MTIComputePipelineKernel(computeFunctionDescriptor: MTIFunctionDescriptor(name: "testCompute", libraryURL: libraryURL))
        
        guard let context = try makeContext() else { return }
        context.lockForRendering()
        let state = try context.kernelState(for: computeKernel, configuration: nil) as! MTIComputePipeline
        context.unlockForRendering()
        let commandEncoder = context.commandQueue.makeCommandBuffer()?.makeComputeCommandEncoder()
        defer {
            commandEncoder?.endEncoding()
        }
        do {
            try MTIFunctionArgumentsEncoder.encode(state.reflection.arguments, values: ["color": SIMD4<Int>(128, 0, 0, 0)], functionType: .kernel, encoder: commandEncoder!)
        } catch {
            let nsError = error as NSError
            XCTAssert(nsError.domain == MTIErrorDomain)
            XCTAssert(nsError.code == MTIError.Code.parameterDataTypeNotSupported.rawValue)
        }
    }
    
    func testDirectSIMDVectorSupport_typeMismatch() throws {
        let kernelSource = """
        #include <metal_stdlib>
        using namespace metal;
        
        kernel void testCompute(
        texture2d<float, access::read> inTexture [[texture(0)]],
        texture2d<float, access::write> outTexture [[texture(1)]],
        constant int4 &color [[buffer(0)]],
        uint2 gid [[thread_position_in_grid]]
        ) {
            if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
                return;
            }
            outTexture.write(inTexture.read(uint2(0,0)), gid);
        }
        """
        let libraryURL = MTILibrarySourceRegistration.shared.registerLibrary(source: kernelSource, compileOptions: nil)
        let computeKernel = MTIComputePipelineKernel(computeFunctionDescriptor: MTIFunctionDescriptor(name: "testCompute", libraryURL: libraryURL))
        
        guard let context = try makeContext() else { return }
        context.lockForRendering()
        let state = try context.kernelState(for: computeKernel, configuration: nil) as! MTIComputePipeline
        context.unlockForRendering()
        let commandEncoder = context.commandQueue.makeCommandBuffer()?.makeComputeCommandEncoder()
        defer {
            commandEncoder?.endEncoding()
        }
        do {
            try MTIFunctionArgumentsEncoder.encode(state.reflection.arguments, values: ["color": SIMD4<Float>(128, 0, 0, 0)], functionType: .kernel, encoder: commandEncoder!)
        } catch {
            let encoderError = try XCTUnwrap(error as? MTISIMDArgumentEncoder.Error)
            XCTAssert(encoderError == .argumentTypeMismatch)
        }
    }
    
    func testDirectSIMDVectorSupport_int32_4() throws {
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
                                constant int4 &color [[buffer(0)]]
                                ) {
            float4 textureColor = sourceTexture.sample(sourceSampler, vertexIn.textureCoordinate);
            float r = color.r / 255.0;
            float g = color.g / 255.0;
            float b = color.b / 255.0;
            float a = color.a / 255.0;
            return textureColor + float4(r,g,b,a);
        }
        """
        let libraryURL = MTILibrarySourceRegistration.shared.registerLibrary(source: librarySource, compileOptions: nil)
        let renderKernel = MTIRenderPipelineKernel(vertexFunctionDescriptor: .passthroughVertex, fragmentFunctionDescriptor: MTIFunctionDescriptor(name: "testRender", libraryURL: libraryURL))
        let image = MTIImage(color: MTIColor(red: 0, green: 1, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 1, height: 1))
        let outputImage = renderKernel.apply(toInputImages: [image], parameters: ["color": SIMD4<Int32>(128, 0, 0, 0)], outputTextureDimensions: image.dimensions, outputPixelFormat: .unspecified)
        guard let context = try makeContext() else { return }
        let output = try context.makeCGImage(from: outputImage)
        PixelEnumerator.enumeratePixels(in: output) { (pixel, _) in
            XCTAssert(pixel.r == 128 && pixel.g == 255 && pixel.b == 0 && pixel.a == 255)
        }
    }
    
    func testMTIVector() throws {
        let randomFloat = Float.random(in: 0...1)
        XCTAssert(MTIVector(value: SIMD2<Float>(repeating: randomFloat)).float2Value == SIMD2<Float>(repeating: randomFloat))
        XCTAssert(MTIVector(value: SIMD3<Float>(repeating: randomFloat)).float3Value == SIMD3<Float>(repeating: randomFloat))
        XCTAssert(MTIVector(value: SIMD4<Float>(repeating: randomFloat)).float4Value == SIMD4<Float>(repeating: randomFloat))
        
        let randomInt32 = Int32.random(in: Int32.min...Int32.max)
        XCTAssert(MTIVector(value: SIMD2<Int32>(repeating: randomInt32)).int2Value == SIMD2<Int32>(repeating: randomInt32))
        XCTAssert(MTIVector(value: SIMD3<Int32>(repeating: randomInt32)).int3Value == SIMD3<Int32>(repeating: randomInt32))
        XCTAssert(MTIVector(value: SIMD4<Int32>(repeating: randomInt32)).int4Value == SIMD4<Int32>(repeating: randomInt32))

        let randomInt16 = Int16.random(in: Int16.min...Int16.max)
        XCTAssert(MTIVector(value: SIMD2<Int16>(repeating: randomInt16)).short2Value == SIMD2<Int16>(repeating: randomInt16))
        XCTAssert(MTIVector(value: SIMD3<Int16>(repeating: randomInt16)).short3Value == SIMD3<Int16>(repeating: randomInt16))
        XCTAssert(MTIVector(value: SIMD4<Int16>(repeating: randomInt16)).short4Value == SIMD4<Int16>(repeating: randomInt16))

        let randomInt8 = Int8.random(in: Int8.min...Int8.max)
        XCTAssert(MTIVector(value: SIMD2<Int8>(repeating: randomInt8)).char2Value == SIMD2<Int8>(repeating: randomInt8))
        XCTAssert(MTIVector(value: SIMD3<Int8>(repeating: randomInt8)).char3Value == SIMD3<Int8>(repeating: randomInt8))
        XCTAssert(MTIVector(value: SIMD4<Int8>(repeating: randomInt8)).char4Value == SIMD4<Int8>(repeating: randomInt8))

        let randomUInt32 = UInt32.random(in: UInt32.min...UInt32.max)
        XCTAssert(MTIVector(value: SIMD2<UInt32>(repeating: randomUInt32)).uint2Value == SIMD2<UInt32>(repeating: randomUInt32))
        XCTAssert(MTIVector(value: SIMD3<UInt32>(repeating: randomUInt32)).uint3Value == SIMD3<UInt32>(repeating: randomUInt32))
        XCTAssert(MTIVector(value: SIMD4<UInt32>(repeating: randomUInt32)).uint4Value == SIMD4<UInt32>(repeating: randomUInt32))
        
        let randomUInt16 = UInt16.random(in: UInt16.min...UInt16.max)
        XCTAssert(MTIVector(value: SIMD2<UInt16>(repeating: randomUInt16)).ushort2Value == SIMD2<UInt16>(repeating: randomUInt16))
        XCTAssert(MTIVector(value: SIMD3<UInt16>(repeating: randomUInt16)).ushort3Value == SIMD3<UInt16>(repeating: randomUInt16))
        XCTAssert(MTIVector(value: SIMD4<UInt16>(repeating: randomUInt16)).ushort4Value == SIMD4<UInt16>(repeating: randomUInt16))
        
        let randomUInt8 = UInt8.random(in: UInt8.min...UInt8.max)
        XCTAssert(MTIVector(value: SIMD2<UInt8>(repeating: randomUInt8)).uchar2Value == SIMD2<UInt8>(repeating: randomUInt8))
        XCTAssert(MTIVector(value: SIMD3<UInt8>(repeating: randomUInt8)).uchar3Value == SIMD3<UInt8>(repeating: randomUInt8))
        XCTAssert(MTIVector(value: SIMD4<UInt8>(repeating: randomUInt8)).uchar4Value == SIMD4<UInt8>(repeating: randomUInt8))

        XCTAssert(MTIVector(value: SIMD4<Float>(repeating: randomFloat)).float3Value == SIMD3<Float>(randomFloat, randomFloat, randomFloat))
    }
}
