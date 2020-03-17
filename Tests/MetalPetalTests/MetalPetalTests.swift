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
    let devices = MTLCopyAllDevices()
    for device in devices {
        print(device)
    }
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

final class MetalPetalContextTests: XCTestCase {
    
    static override func setUp() {
        super.setUp()
        
        print("----- Metal Devices -----")
        listMetalDevices()
        print("-------------------------")
    }
    
    func testContextCreation() {
        do {
            let _ = try makeContext()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}

final class MetalPetalRenderTests: XCTestCase {
    
    func testRenderSolidColorImage() {
        do {
            guard let context = try makeContext() else { return }
            let image = MTIImage(color: MTIColor(red: 1, green: 0, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 2, height: 2))
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
            guard let context = try makeContext() else { return }
            let image = MTIImage(color: MTIColor(red: 1, green: 0, blue: 0, alpha: 1), sRGB: false, size: CGSize(width: 2, height: 2))
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
