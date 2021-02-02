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

func makeContext(options: MTIContextOptions? = nil) throws -> MTIContext {
    if let device = MTLCreateSystemDefaultDevice() {
        if let options = options {
            return try MTIContext(device: device, options: options)
        } else {
            return try MTIContext(device: device)
        }
    }
    throw XCTSkip("no metal device found.")
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

final class ContextOptionsTests: XCTestCase {
    
    func testContextTexturePoolClass() throws {
        do {
            let options = MTIContextOptions()
            options.texturePoolClass = MTIDeviceTexturePool.self
            let context = try makeContext(options: options)
            let texturePool = (context.value(forKeyPath: "texturePool") as? NSObject)
            XCTAssert(texturePool?.isKind(of: MTIDeviceTexturePool.self) == true)
        }
        
        do {
            if #available(iOS 13.0, macOS 10.15, *) {
                if let device = MTLCreateSystemDefaultDevice(), MTIHeapTexturePool.isSupported(on: device) {
                    let options = MTIContextOptions()
                    options.texturePoolClass = MTIHeapTexturePool.self
                    let context = try makeContext(options: options)
                    let texturePool = (context.value(forKeyPath: "texturePool") as? NSObject)
                    XCTAssert(texturePool?.isKind(of: MTIHeapTexturePool.self) == true)
                }
            }
        }
    }
    
    func testCoreVideoMetalTextureBridgeClass() throws {
        do {
            let options = MTIContextOptions()
            options.coreVideoMetalTextureBridgeClass = MTICVMetalTextureCache.self
            let context = try makeContext(options: options)
            context.coreVideoTextureBridge.isKind(of: MTICVMetalTextureCache.self)
        }
        
        do {
            if #available(iOS 11.0, macOS 10.11, *) {
                let options = MTIContextOptions()
                options.coreVideoMetalTextureBridgeClass = MTICVMetalIOSurfaceBridge.self
                let context = try makeContext(options: options)
                context.coreVideoTextureBridge.isKind(of: MTICVMetalIOSurfaceBridge.self)
            }
        }
    }
    
    func testWorkingPixelFormat() throws {
        do {
            let options = MTIContextOptions()
            let context = try makeContext(options: options)
            XCTAssertEqual(context.workingPixelFormat, .bgra8Unorm)
        }
        
        do {
            let options = MTIContextOptions()
            options.workingPixelFormat = .r16Float
            let context = try makeContext(options: options)
            XCTAssertEqual(context.workingPixelFormat, .r16Float)
        }
    }
    
    func testContextLabel() throws {
        do {
            let options = MTIContextOptions()
            let context = try makeContext(options: options)
            XCTAssertEqual(context.label, MTIContextDefaultLabel)
        }
        
        do {
            let options = MTIContextOptions()
            options.label = "test"
            let context = try makeContext(options: options)
            XCTAssertEqual(context.label, "test")
        }
    }
    
    func testCoreImageContextOptions() throws {
        do {
            let options = MTIContextOptions()
            options.coreImageContextOptions = [CIContextOption.workingFormat: CIFormat.RGBA8]
            let context = try makeContext(options: options)
            XCTAssertEqual(context.coreImageContext.workingFormat, .RGBA8)
        }
        
        do {
            let options = MTIContextOptions()
            let colorspace = CGColorSpaceCreateDeviceRGB()
            options.coreImageContextOptions = [CIContextOption.workingColorSpace: colorspace]
            let context = try makeContext(options: options)
            XCTAssertEqual(context.coreImageContext.workingColorSpace, colorspace)
        }
    }
}

