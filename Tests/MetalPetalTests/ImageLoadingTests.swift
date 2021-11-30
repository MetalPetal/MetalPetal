//
//  File.swift
//  
//
//  Created by YuAo on 2021/2/2.
//

import XCTest
import MetalPetal
import MetalPetalTestHelpers
import MetalPetalObjectiveC.Extension
import VideoToolbox

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
        let context = try makeContext(options: options)
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
        let context = try makeContext(options: options)
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
        let context = try makeContext()
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


final class CGImageLoadingTests: XCTestCase {
    
    func testCGImageLoading_normal() throws {
        let context = try makeContext()
        
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
        let context = try makeContext()
        
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
        let context = try makeContext()
        
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
        let context = try makeContext()
        
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
        let context = try makeContext()
        
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
        let context = try makeContext()
        
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
    
    func testCGImageLoading_premultiplied() throws {
        let context = try makeContext()
        
        let cgContext = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        let color: [CGFloat] = [1, 0, 0, 0.5]
        try cgContext?.setFillColor(XCTUnwrap(CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: color)))
        cgContext?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let inputCGImage = try XCTUnwrap(cgContext?.makeImage())
        let image = MTIImage(cgImage: inputCGImage, options: .default, isOpaque: false)
        XCTAssert(image.alphaType == .premultiplied)
        
        let cgImage = try context.makeCGImage(from: image) //output is premultiplied
        PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coordinates) in
            XCTAssert(pixel.r == 128 && pixel.g == 0 && pixel.b == 0 && pixel.a == 128)
        }
    }
    
    func testCGImageLoading_semiTransparentPNG() throws {
        let context = try makeContext()
        let imageSource = CGImageSourceCreateWithURL(URL(fileURLWithPath: #file)
                                                        .deletingLastPathComponent().deletingLastPathComponent()
                                                        .appendingPathComponent("Fixture")
                                                        .appendingPathComponent("semi-transparent-red.png") as CFURL, nil)
        let inputCGImage = try XCTUnwrap(CGImageSourceCreateImageAtIndex(XCTUnwrap(imageSource), 0, nil))
        let image = MTIImage(cgImage: inputCGImage, options: .default, isOpaque: false)
        XCTAssert(image.alphaType == .premultiplied)
        
        let cgImage = try context.makeCGImage(from: image) //output is premultiplied
        PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coordinates) in
            XCTAssert(pixel.r == 128 && pixel.g == 0 && pixel.b == 0 && pixel.a == 128)
        }
    }
    
    func testCGImageLoading_sRGB() throws {
        let context = try makeContext()
        
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
        let context = try makeContext()
        for orientation in 1...8 {
            let image = MTIImage(contentsOf: URL(fileURLWithPath: #file)
                                    .deletingLastPathComponent().deletingLastPathComponent()
                                    .appendingPathComponent("Fixture")
                                    .appendingPathComponent("f\(orientation).png")
                                 , options: .default, isOpaque: true)
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
        let context = try makeContext()
        for orientation in 1...8 {
            let image = MTIImage(contentsOf: URL(fileURLWithPath: #file)
                                    .deletingLastPathComponent().deletingLastPathComponent()
                                    .appendingPathComponent("Fixture")
                                    .appendingPathComponent("fgray\(orientation).png")
                                 , options: .default, isOpaque: true)
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
        let context = try makeContext()
        for orientation in 1...8 {
            let image = MTIImage(contentsOf: URL(fileURLWithPath: #file)
                                    .deletingLastPathComponent().deletingLastPathComponent()
                                    .appendingPathComponent("Fixture")
                                    .appendingPathComponent("fgray\(orientation).png")
                                 , options: MTICGImageLoadingOptions(colorSpace: nil, flipsVertically: true), isOpaque: true)
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
        let context = try makeContext()
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
        let context = try makeContext()
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
        let context = try makeContext()
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
        let context = try makeContext()
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
        let context = try makeContext()
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
        let context = try makeContext()
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
        let context = try makeContext()
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
        let context = try makeContext()
        for orientation in 1...8 {
            let image = MTIImage(contentsOf: URL(fileURLWithPath: #file)
                                    .deletingLastPathComponent().deletingLastPathComponent()
                                    .appendingPathComponent("Fixture")
                                    .appendingPathComponent("f\(orientation).png"),
                                 options: [.SRGB: false],
                                 alphaType: .alphaIsOne)
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
        let context = try makeContext()
        for orientation in 1...8 {
            let image = MTIImage(contentsOf: URL(fileURLWithPath: #file)
                                    .deletingLastPathComponent().deletingLastPathComponent()
                                    .appendingPathComponent("Fixture")
                                    .appendingPathComponent("fgray\(orientation).png"),
                                 options: [.SRGB: false],
                                 alphaType: .alphaIsOne)
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
        let context = try makeContext()
        for orientation in 1...8 {
            let image = MTIImage(contentsOf: URL(fileURLWithPath: #file)
                                    .deletingLastPathComponent().deletingLastPathComponent()
                                    .appendingPathComponent("Fixture")
                                    .appendingPathComponent("fgray\(orientation).png"),
                                 options: [.SRGB: false, .origin: MTKTextureLoader.Origin.flippedVertically],
                                 alphaType: .alphaIsOne)
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
        let context = try makeContext()
        for orientation in 1...8 {
            let image = MTIImage(contentsOf: URL(fileURLWithPath: #file)
                                    .deletingLastPathComponent().deletingLastPathComponent()
                                    .appendingPathComponent("Fixture")
                                    .appendingPathComponent("fgray\(orientation).png"),
                                 options: [.SRGB: false, .generateMipmaps: true],
                                 alphaType: .alphaIsOne)
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
        let context = try makeContext()
        let url = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Fixture")
            .appendingPathComponent("fgray1.png")
        let textureLoader = MTIDefaultTextureLoader.makeTextureLoader(device: context.device)
        let texture = try textureLoader.newTexture(withContentsOf: url, options: [.SRGB: false, .generateMipmaps: true])
        XCTAssert(texture.mipmapLevelCount > 1)
    }
}
