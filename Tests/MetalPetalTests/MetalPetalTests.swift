//
//  File.swift
//  
//
//  Created by YuAo on 2020/3/17.
//

import XCTest
import MetalPetal
import MetalPetalTestHelpers

fileprivate func makeContext() throws -> MTIContext {
    if let device = MTLCreateSystemDefaultDevice() {
        let compileOption = MTLCompileOptions()
        compileOption.languageVersion = .version1_2
        let options = MTIContextOptions()
        options.defaultLibraryURL = try BuiltinMetalLibraryWithoutSE0271.makeBuiltinMetalLibrary(compileOptions: compileOption)
        return try MTIContext(device: device, options: options)
    } else {
        throw MTIError(.deviceNotFound)
    }
}

final class MetalPetalContextTests: XCTestCase {
    
    func testDeviceCreation() {
        let device = MTLCreateSystemDefaultDevice()
        XCTAssertNotNil(device)
    }
    
    func testContextCreation() {
        if let device = MTLCreateSystemDefaultDevice() {
            let options = MTIContextOptions()
            do {
                options.defaultLibraryURL = try BuiltinMetalLibraryWithoutSE0271.makeBuiltinMetalLibrary()
                let _ = try MTIContext(device: device, options: options)
            } catch {
                XCTFail(error.localizedDescription)
            }
        } else {
            XCTAssert(false, "Cannot create system default metal device.")
        }
    }
}

final class MetalPetalRenderTests: XCTestCase {
    
    func testRenderSolidColorImage() {
        do {
            let image = MTIImage(color: MTIColor(red: 1, green: 0, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 2, height: 2))
            let context = try makeContext()
            let cgImage = try context.makeCGImage(from: image)
            PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coordinate) in
                XCTAssert(pixel.r == 255 && pixel.g == 0 && pixel.b == 0 && pixel.a == 255)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testColorInvert() {
        do {
            let image = MTIImage(color: MTIColor(red: 1, green: 0, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 2, height: 2))
            let context = try makeContext()
            let filter = MTIColorInvertFilter()
            filter.inputImage = image
            let output = filter.outputImage
            let cgImage = try context.makeCGImage(from: output!)
            PixelEnumerator.enumeratePixels(in: cgImage) { (pixel, coordinate) in
                XCTAssert(pixel.r == 0 && pixel.g == 255 && pixel.b == 255 && pixel.a == 255)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
