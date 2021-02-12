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

final class RenderTests: XCTestCase {
    
    func testSolidColorImageRendering() throws {
        let image = MTIImage(color: MTIColor(red: 1, green: 0, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 2, height: 2))
        let context = try makeContext()
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
        let context = try makeContext()
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
        let context = try makeContext()
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
        let context = try makeContext()
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
        let context = try makeContext()
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
        
        let context = try makeContext()
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
        
        let context = try makeContext()
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
        
        let context = try makeContext()
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
        let context = try makeContext()
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
        
        let context = try makeContext()
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
        
        let context = try makeContext()
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
        let context = try makeContext()
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
        let context = try makeContext()
        
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
    
    func testMultilayerCompositing_alpha() throws {
        let context = try makeContext()
        
        let image = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
            [0, 0],
        ]), options: [.SRGB: false], isOpaque: true)
        
        let filter = MultilayerCompositingFilter()
        filter.inputBackgroundImage = image
        filter.rasterSampleCount = 1
        filter.layers = [MultilayerCompositingFilter.makeLayer(content: MTIImage.white, configurator: { layer in
            layer.position = CGPoint(x: 0.5, y: 0.5)
            layer.size = CGSize(width: 1, height: 1)
            layer.opacity = 0.5
        })]
        let outputImage = try XCTUnwrap(filter.outputImage)
        let outputCGImage = try context.makeCGImage(from: outputImage)
        PixelEnumerator.enumeratePixels(in: outputCGImage) { (pixel, coord) in
            if coord.x == 0 && coord.y == 0 {
                XCTAssert(pixel.r == 128 && pixel.g == 128 && pixel.b == 128 && pixel.a == 255)
            }
            if coord.x == 1 && coord.y == 0 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
            }
        }
    }
    
    
    func testMultilayerCompositing_alphaMSAA() throws {
        let context = try makeContext()
        
        let image = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
            [0, 0],
        ]), options: [.SRGB: false], isOpaque: true)
        
        let filter = MultilayerCompositingFilter()
        filter.inputBackgroundImage = image
        filter.rasterSampleCount = 4
        filter.layers = [MultilayerCompositingFilter.makeLayer(content: MTIImage.white, configurator: { layer in
            layer.position = CGPoint(x: 0.5, y: 0.5)
            layer.size = CGSize(width: 1, height: 1)
            layer.opacity = 0.5
        })]
        let outputImage = try XCTUnwrap(filter.outputImage)
        let outputCGImage = try context.makeCGImage(from: outputImage)
        PixelEnumerator.enumeratePixels(in: outputCGImage) { (pixel, coord) in
            if coord.x == 0 && coord.y == 0 {
                XCTAssert(pixel.r == 128 && pixel.g == 128 && pixel.b == 128 && pixel.a == 255)
            }
            if coord.x == 1 && coord.y == 0 {
                XCTAssert(pixel.r == 0 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
            }
        }
    }
    
    func testMultilayerCompositing_tint() throws {
        let context = try makeContext()
        
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
        let context = try makeContext()
        
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
        let context = try makeContext()
        
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
        let context = try makeContext()
        
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
        let context = try makeContext()
        
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
        let context = try makeContext()
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
            let context = try makeContext()
            let output = try context.makeCGImage(from: outputImage)
            PixelEnumerator.enumeratePixels(in: output) { (pixel, _) in
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 0 && pixel.a == 255)
            }
        }
        
        try autoreleasepool {
            let image = MTIImage(color: MTIColor(red: 0, green: 1, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 1, height: 1))
            let outputImage = computeKernel.apply(toInputImages: [image], parameters: ["color": MTIVector(value: SIMD4<Float>(1, 0, 0, 0))], dispatchOptions: nil, outputTextureDimensions: image.dimensions, outputPixelFormat: .unspecified)
            let context = try makeContext()
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
            let context = try makeContext()
            let output = try context.makeCGImage(from: outputImage)
            PixelEnumerator.enumeratePixels(in: output) { (pixel, _) in
                XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 0 && pixel.a == 255)
            }
        }
        
        try autoreleasepool {
            let image = MTIImage(color: MTIColor(red: 0, green: 1, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 1, height: 1))
            let outputImage = computeKernel.apply(toInputImages: [image], parameters: [:], dispatchOptions: nil, outputTextureDimensions: image.dimensions, outputPixelFormat: .unspecified)
            let context = try makeContext()
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
        let context = try makeContext()
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
        let context = try makeContext()
        let output = try context.makeCGImage(from: outputImage)
        PixelEnumerator.enumeratePixels(in: output) { (pixel, _) in
            XCTAssert(pixel.r == 255 && pixel.g == 255 && pixel.b == 0 && pixel.a == 255)
        }
    }
    
    func testMultilayerCompositing_customBlending() throws {
        let name = "customBlend" + String(#line)
        let blendMode = MTIBlendMode(rawValue: name)
        MTIBlendModes.registerBlendMode(blendMode, with: MTIBlendFunctionDescriptors(blendFormula: """
        float4 blend(float4 background, float4 foreground) {
            return background + foreground;
        }
        """))
        defer {
            MTIBlendModes.unregisterBlendMode(blendMode)
        }
        let context = try makeContext()
        
        let image = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
            [64, 64],
        ]), options: [.SRGB: false], isOpaque: true)
        
        let filter = MultilayerCompositingFilter()
        filter.inputBackgroundImage = image
        filter.layers = [MultilayerCompositingFilter.makeLayer(content: MTIImage(color: MTIColor(red: 64/255.0, green: 0, blue: 0, alpha: 0), sRGB: false, size: CGSize(width: 1, height: 1)), configurator: { layer in
            layer.position = CGPoint(x: 0.5, y: 0.5)
            layer.size = CGSize(width: 1, height: 1)
            layer.opacity = 1
            layer.blendMode = blendMode
        })]
        let outputImage = try XCTUnwrap(filter.outputImage)
        let outputCGImage = try context.makeCGImage(from: outputImage)
        PixelEnumerator.enumeratePixels(in: outputCGImage) { (pixel, coord) in
            if coord.x == 0 && coord.y == 0 {
                XCTAssert(pixel.r == 128 && pixel.g == 64 && pixel.b == 64 && pixel.a == 255)
            }
            if coord.x == 1 && coord.y == 0 {
                XCTAssert(pixel.r == 64 && pixel.g == 64 && pixel.b == 64 && pixel.a == 255)
            }
        }
    }
    
    func testMultilayerCompositing_customBlending_textureCoordinatesModifier() throws {
        let name = "customBlend" + String(#line)
        let blendMode = MTIBlendMode(rawValue: name)
        MTIBlendModes.registerBlendMode(blendMode, with: MTIBlendFunctionDescriptors(blendFormula: """
        float2 modify_source_texture_coordinates(float4 backdrop, float2 coordinates, uint2 source_texture_size) {
            return float2(1.5, 0.5) / float2(source_texture_size);
        }
        float4 blend(float4 background, float4 foreground) {
            return background + foreground;
        }
        """))
        defer {
            MTIBlendModes.unregisterBlendMode(blendMode)
        }
        let context = try makeContext()
        
        let image = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
            [64, 64],
        ]), options: [.SRGB: false], isOpaque: true)
        let overlay = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
            [0, 32],
        ]), options: [.SRGB: false], isOpaque: true)
        let filter = MultilayerCompositingFilter()
        filter.inputBackgroundImage = image
        filter.layers = [MultilayerCompositingFilter.makeLayer(content: overlay, configurator: { layer in
            layer.position = CGPoint(x: 1, y: 0.5)
            layer.size = CGSize(width: 2, height: 1)
            layer.opacity = 1
            layer.blendMode = blendMode
        })]
        let outputImage = try XCTUnwrap(filter.outputImage)
        let outputCGImage = try context.makeCGImage(from: outputImage)
        PixelEnumerator.enumeratePixels(in: outputCGImage) { (pixel, coord) in
            if coord.x == 0 && coord.y == 0 {
                XCTAssert(pixel.r == 64 + 32 && pixel.g == 64 + 32 && pixel.b == 64 + 32 && pixel.a == 255)
            }
            if coord.x == 1 && coord.y == 0 {
                XCTAssert(pixel.r == 64 + 32 && pixel.g == 64 + 32 && pixel.b == 64 + 32 && pixel.a == 255)
            }
        }
    }
    
    func testMultilayerCompositing_blendModeRenderPipelineNotFound() throws {
        let name = "customBlend" + String(#line)
        let blendMode = MTIBlendMode(rawValue: name)
        let context = try makeContext()
        
        let image = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
            [64, 64],
        ]), options: [.SRGB: false], isOpaque: true)
        let overlay = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
            [0, 32],
        ]), options: [.SRGB: false], isOpaque: true)
        let filter = MultilayerCompositingFilter()
        filter.inputBackgroundImage = image
        filter.layers = [MultilayerCompositingFilter.makeLayer(content: overlay, configurator: { layer in
            layer.position = CGPoint(x: 1, y: 0.5)
            layer.size = CGSize(width: 2, height: 1)
            layer.opacity = 1
            layer.blendMode = blendMode
        })]
        let outputImage = try XCTUnwrap(filter.outputImage)
        do {
            let _ = try context.makeCGImage(from: outputImage)
            XCTFail()
        } catch {
            XCTAssert(error is MTIError && (error as! MTIError).code == .failedToFetchBlendRenderPipelineForMultilayerCompositing)
        }
    }
    
    func testCustomBlending() throws {
        let name = "customBlend" + String(#line)
        let blendMode = MTIBlendMode(rawValue: name)
        MTIBlendModes.registerBlendMode(blendMode, with: MTIBlendFunctionDescriptors(blendFormula: """
        float4 blend(float4 background, float4 foreground) {
            return background + foreground;
        }
        """))
        defer {
            MTIBlendModes.unregisterBlendMode(blendMode)
        }
        let context = try makeContext()
        
        let image = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
            [64],
        ]), options: [.SRGB: false], isOpaque: true)
        let overlay = MTIImage(color: MTIColor(red: 64/255.0, green: 0, blue: 0, alpha: 0), sRGB: false, size: CGSize(width: 1, height: 1))
        let blendFilter = MTIBlendFilter(blendMode: blendMode)
        blendFilter.inputBackgroundImage = image
        blendFilter.inputImage = overlay
        
        do {
            let outputImage = try XCTUnwrap(blendFilter.outputImage)
            let outputCGImage = try context.makeCGImage(from: outputImage)
            PixelEnumerator.enumeratePixels(in: outputCGImage) { (pixel, coord) in
                if coord.x == 0 && coord.y == 0 {
                    XCTAssert(pixel.r == 128 && pixel.g == 64 && pixel.b == 64 && pixel.a == 255)
                }
            }
        }
        
        do {
            blendFilter.intensity = 0.5
            let outputImage = try XCTUnwrap(blendFilter.outputImage)
            let outputCGImage = try context.makeCGImage(from: outputImage)
            PixelEnumerator.enumeratePixels(in: outputCGImage) { (pixel, coord) in
                if coord.x == 0 && coord.y == 0 {
                    XCTAssert(pixel.r == 64 + 32 && pixel.g == 64 && pixel.b == 64 && pixel.a == 255)
                }
            }
        }
    }
    
    func testCustomBlending_textureCoordinatesModifier() throws {
        let name = "customBlend" + String(#line)
        let blendMode = MTIBlendMode(rawValue: name)
        MTIBlendModes.registerBlendMode(blendMode, with: MTIBlendFunctionDescriptors(blendFormula: """
        float2 modify_source_texture_coordinates(float4 backdrop, float2 coordinates, uint2 source_texture_size) {
            return float2(1.5, 0.5) / float2(source_texture_size);
        }
        float4 blend(float4 background, float4 foreground) {
            return background + foreground;
        }
        """))
        defer {
            MTIBlendModes.unregisterBlendMode(blendMode)
        }
        let context = try makeContext()
        
        let image = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
            [64],
        ]), options: [.SRGB: false], isOpaque: true)
        let overlay = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
            [0, 32],
        ]), options: [.SRGB: false], isOpaque: true)
        let blendFilter = MTIBlendFilter(blendMode: blendMode)
        blendFilter.inputBackgroundImage = image
        blendFilter.inputImage = overlay
        
        do {
            let outputImage = try XCTUnwrap(blendFilter.outputImage)
            let outputCGImage = try context.makeCGImage(from: outputImage)
            PixelEnumerator.enumeratePixels(in: outputCGImage) { (pixel, coord) in
                if coord.x == 0 && coord.y == 0 {
                    XCTAssert(pixel.r == 64 + 32 && pixel.g == 64 + 32 && pixel.b == 64 + 32 && pixel.a == 255)
                }
            }
        }
        
        do {
            blendFilter.intensity = 0.5
            let outputImage = try XCTUnwrap(blendFilter.outputImage)
            let outputCGImage = try context.makeCGImage(from: outputImage)
            PixelEnumerator.enumeratePixels(in: outputCGImage) { (pixel, coord) in
                if coord.x == 0 && coord.y == 0 {
                    XCTAssert(pixel.r == 64 + 16 && pixel.g == 64 + 16 && pixel.b == 64 + 16 && pixel.a == 255)
                }
            }
        }
    }
    
    func testCustomBlending_failure() throws {
        do {
            let name = "customBlend" + String(#line)
            let blendMode = MTIBlendMode(rawValue: name)
            MTIBlendModes.registerBlendMode(blendMode, with: MTIBlendFunctionDescriptors(blendFormula: """
            void blend(float4 background, float4 foreground) {
                return background + foreground;
            }
            """))
            defer {
                MTIBlendModes.unregisterBlendMode(blendMode)
            }
            let context = try makeContext()
            
            let image = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
                [64],
            ]), options: [.SRGB: false], isOpaque: true)
            let overlay = MTIImage(color: MTIColor(red: 64/255.0, green: 0, blue: 0, alpha: 0), sRGB: false, size: CGSize(width: 1, height: 1))
            let blendFilter = MTIBlendFilter(blendMode: blendMode)
            blendFilter.inputBackgroundImage = image
            blendFilter.inputImage = overlay
            
            do {
                let outputImage = try XCTUnwrap(blendFilter.outputImage)
                XCTAssertThrowsError(try context.makeCGImage(from: outputImage))
            }
        }
        
        do {
            let name = "customBlend" + String(#line)
            let blendMode = MTIBlendMode(rawValue: name)
            MTIBlendModes.registerBlendMode(blendMode, with: MTIBlendFunctionDescriptors(blendFormula: """
            float4 my_blend(float4 background, float4 foreground) {
                return background + foreground;
            }
            """))
            defer {
                MTIBlendModes.unregisterBlendMode(blendMode)
            }
            let context = try makeContext()
            
            let image = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
                [64],
            ]), options: [.SRGB: false], isOpaque: true)
            let overlay = MTIImage(color: MTIColor(red: 64/255.0, green: 0, blue: 0, alpha: 0), sRGB: false, size: CGSize(width: 1, height: 1))
            let blendFilter = MTIBlendFilter(blendMode: blendMode)
            blendFilter.inputBackgroundImage = image
            blendFilter.inputImage = overlay
            
            do {
                let outputImage = try XCTUnwrap(blendFilter.outputImage)
                XCTAssertThrowsError(try context.makeCGImage(from: outputImage))
            }
        }
        
        do {
            let name = "customBlend" + String(#line)
            let blendMode = MTIBlendMode(rawValue: name)
            MTIBlendModes.registerBlendMode(blendMode, with: MTIBlendFunctionDescriptors(blendFormula: """
            int modify_source_texture_coordinates = 0;
            float4 my_blend(float4 background, float4 foreground) {
                return background + foreground;
            }
            """))
            defer {
                MTIBlendModes.unregisterBlendMode(blendMode)
            }
            let context = try makeContext()
            
            let image = MTIImage(cgImage: try ImageGenerator.makeMonochromeImage([
                [64],
            ]), options: [.SRGB: false], isOpaque: true)
            let overlay = MTIImage(color: MTIColor(red: 64/255.0, green: 0, blue: 0, alpha: 0), sRGB: false, size: CGSize(width: 1, height: 1))
            let blendFilter = MTIBlendFilter(blendMode: blendMode)
            blendFilter.inputBackgroundImage = image
            blendFilter.inputImage = overlay
            
            do {
                let outputImage = try XCTUnwrap(blendFilter.outputImage)
                XCTAssertThrowsError(try context.makeCGImage(from: outputImage))
            }
        }
    }
    
    func testWriteToDataBuffer() throws {
        let kernelSource = """
        #include <metal_stdlib>
        using namespace metal;
        
        kernel void testCompute(device uint *outBuffer [[buffer(0)]], constant uint &count [[buffer(1)]], uint gid [[thread_position_in_grid]]) {
            if (gid < count) {
                outBuffer[gid] = gid;
            }
        }
        """
        let libraryURL = MTILibrarySourceRegistration.shared.registerLibrary(source: kernelSource, compileOptions: nil)
        let computeKernel = MTIComputePipelineKernel(computeFunctionDescriptor: MTIFunctionDescriptor(name: "testCompute", constantValues: nil, libraryURL: libraryURL))
        do {
            let dataCount: Int = 8
            let dataBuffer = try XCTUnwrap(MTIDataBuffer(values: [UInt32](repeating: 0, count: dataCount)))
            let outputImage = computeKernel.apply(toInputImages: [], parameters: ["outBuffer": dataBuffer, "count": MTIVector(values: [UInt32(dataCount)])], dispatchOptions: nil, outputTextureDimensions: MTITextureDimensions(width: dataCount, height: 1), outputPixelFormat: .unspecified)
            let context = try makeContext()
            let task = try context.startTask(toRender: outputImage, completion: { task in
                
            })
            task.waitUntilCompleted()
            dataBuffer.unsafeAccess({ (buffer: UnsafeMutableBufferPointer<UInt32>) -> Void in
                let output = Array(buffer)
                for item in output.enumerated() {
                    XCTAssert(item.element == UInt32(item.offset))
                }
            })
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
        let context = try makeContext()
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
        
        let context = try makeContext()
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
        
        let context = try makeContext()
        
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
        
        let context = try makeContext()
        
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
    
    func testYCbCrTextureSupport() throws {
        let context = try makeContext()
        if context.isYCbCrPixelFormatSupported {
            let blueImage = MTIImage(color: MTIColor(red: 0, green: 0, blue: 1, alpha: 1), sRGB: false, size: CGSize(width: 4, height: 4))
            var pixelBuffer: CVPixelBuffer!
            CVPixelBufferCreate(kCFAllocatorDefault, 4, 4, kCVPixelFormatType_420YpCbCr10BiPlanarFullRange, [kCVPixelBufferIOSurfacePropertiesKey as String: [:]] as CFDictionary, &pixelBuffer)
            CVBufferSetAttachment(pixelBuffer, kCVImageBufferCGColorSpaceKey, CGColorSpace(name: CGColorSpace.sRGB)!, .shouldPropagate)
            try context.render(blueImage, to: pixelBuffer)
            var cgImage: CGImage!
            VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
            var pixels: [UInt8] = [UInt8](repeating: 0, count: 4 * 4 * 4)
            let cgContext = CGContext(data: &pixels, width: 4, height: 4, bitsPerComponent: 8, bytesPerRow: 4 * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
            cgContext?.draw(cgImage, in: CGRect(x: 0, y: 0, width: 4, height: 4))
            for i in 0..<pixels.count {
                if i % 4 == 0 {
                    XCTAssert(pixels[i] == 254) //b
                    XCTAssert(pixels[i + 1] == 0) //g
                    XCTAssert(pixels[i + 2] == 0) //r
                    XCTAssert(pixels[i + 3] == 255) //a
                }
            }
        }
    }
}
