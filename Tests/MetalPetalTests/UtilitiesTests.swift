//
//  File.swift
//  
//
//  Created by YuAo on 2021/2/2.
//

import Foundation
import XCTest
import MetalPetal
import MetalPetalTestHelpers
import MetalPetalObjectiveC.Extension

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
        let context = try makeContext()
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
        let context = try makeContext()
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
        let context = try makeContext()
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
        
        let context = try makeContext()
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
            XCTAssert(nsError.code == MTIError.Code.unsupportedParameterType.rawValue)
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
        
        let context = try makeContext()
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
        let context = try makeContext()
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
    
    func testArgumentsEncoding_basic() throws {
        let kernelSource = """
        #include <metal_stdlib>
        using namespace metal;
        
        kernel void testCompute(
            constant int &intValue [[buffer(0)]],
            constant uint &uintValue [[buffer(1)]],
            constant char &charValue [[buffer(2)]],
            constant uchar &ucharValue [[buffer(3)]],
            constant short &shortValue [[buffer(4)]],
            constant ushort &ushortValue [[buffer(5)]],
            constant float &floatValue [[buffer(6)]],
            constant half &halfValue [[buffer(7)]],
            constant bool &boolValue [[buffer(8)]],
            
            constant float2 &float2Value [[buffer(10)]],
            constant float4x4 &float4x4Value [[buffer(11)]],
            constant int2 &int2Value [[buffer(12)]],
            constant uchar2 &uchar2Value [[buffer(13)]]
        ) {}
        """
        let libraryURL = MTILibrarySourceRegistration.shared.registerLibrary(source: kernelSource, compileOptions: nil)
        let computeKernel = MTIComputePipelineKernel(computeFunctionDescriptor: MTIFunctionDescriptor(name: "testCompute", constantValues: nil, libraryURL: libraryURL))
        let parameters: [String: Any] = [
            "intValue": -1,
            "uintValue": 1,
            "charValue": 64,
            "ucharValue": 128,
            "shortValue": -1,
            "ushortValue": 1,
            "floatValue": 1.0,
            "halfValue": 1.0,
            "boolValue": true,
            
            "float2Value": SIMD2<Float>(x: 1, y: 1),
            "float4x4Value": simd_float4x4(1),
            "int2Value": SIMD2<Int32>(x: 1, y: 1),
            "uchar2Value": SIMD2<UInt8>(x: 1, y: 1)
        ]
        let outputImage = computeKernel.apply(toInputImages: [], parameters: parameters, dispatchOptions: nil, outputTextureDimensions: MTITextureDimensions(width: 1, height: 1), outputPixelFormat: .unspecified)
        let context = try makeContext()
        let _ = try context.makeCGImage(from: outputImage)
    }
    
    func testArgumentsEncoding_typeMismatch() throws {
        let kernelSource = """
        #include <metal_stdlib>
        using namespace metal;
        
        kernel void testCompute(
            constant int &intValue [[buffer(0)]]
        ) {}
        """
        let libraryURL = MTILibrarySourceRegistration.shared.registerLibrary(source: kernelSource, compileOptions: nil)
        let computeKernel = MTIComputePipelineKernel(computeFunctionDescriptor: MTIFunctionDescriptor(name: "testCompute", constantValues: nil, libraryURL: libraryURL))
        let parameters: [String: Any] = [
            "intValue": SIMD2<Float>(x: 0, y: 0),
        ]
        let outputImage = computeKernel.apply(toInputImages: [], parameters: parameters, dispatchOptions: nil, outputTextureDimensions: MTITextureDimensions(width: 1, height: 1), outputPixelFormat: .unspecified)
        let context = try makeContext()
        do {
            let _ = try context.makeCGImage(from: outputImage)
            XCTFail()
        } catch {
            XCTAssert((error as? MTISIMDArgumentEncoder.Error) == .argumentTypeMismatch)
        }
    }
    
    func testArgumentsEncoding_unsupportedType() throws {
        let kernelSource = """
        #include <metal_stdlib>
        using namespace metal;
        
        kernel void testCompute(
            constant float2 &float2Value [[buffer(0)]]
        ) {}
        """
        let libraryURL = MTILibrarySourceRegistration.shared.registerLibrary(source: kernelSource, compileOptions: nil)
        let computeKernel = MTIComputePipelineKernel(computeFunctionDescriptor: MTIFunctionDescriptor(name: "testCompute", constantValues: nil, libraryURL: libraryURL))
        let parameters: [String: Any] = [
            "float2Value": 2,
        ]
        let outputImage = computeKernel.apply(toInputImages: [], parameters: parameters, dispatchOptions: nil, outputTextureDimensions: MTITextureDimensions(width: 1, height: 1), outputPixelFormat: .unspecified)
        let context = try makeContext()
        do {
            let _ = try context.makeCGImage(from: outputImage)
            XCTFail()
        } catch let error as MTIError {
            XCTAssert(error.code == .parameterDataTypeMismatch)
        }
    }
}
