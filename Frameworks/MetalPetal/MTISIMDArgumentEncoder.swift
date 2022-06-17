//
//  MTISIMDArgumentEncoder.swift
//  MetalPetal
//
//  Auto-generated.
//

import Foundation
import Metal

#if SWIFT_PACKAGE
import MetalPetalObjectiveC.Core
#endif

@objc(MTISIMDArgumentEncoder) public class MTISIMDArgumentEncoder: NSObject, MTIFunctionArgumentEncoding {
    
    public enum Error: String, Swift.Error, LocalizedError {
        case argumentTypeMismatch
        public var errorDescription: String? {
            return self.rawValue
        }
    }
    
    public static func encodeValue(_ value: Any, argument: MTLArgument, proxy: MTIFunctionArgumentEncodingProxy) throws {
        switch value {
        case let v as SIMD2<Float>:
            guard argument.bufferDataType == .float2 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as SIMD3<Float>:
            guard argument.bufferDataType == .float3 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as SIMD4<Float>:
            guard argument.bufferDataType == .float4 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as float2x2:
            guard argument.bufferDataType == .float2x2 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as float2x3:
            guard argument.bufferDataType == .float2x3 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as float2x4:
            guard argument.bufferDataType == .float2x4 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as float3x2:
            guard argument.bufferDataType == .float3x2 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as float3x3:
            guard argument.bufferDataType == .float3x3 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as float3x4:
            guard argument.bufferDataType == .float3x4 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as float4x2:
            guard argument.bufferDataType == .float4x2 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as float4x3:
            guard argument.bufferDataType == .float4x3 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as float4x4:
            guard argument.bufferDataType == .float4x4 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as SIMD2<Int32>:
            guard argument.bufferDataType == .int2 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as SIMD3<Int32>:
            guard argument.bufferDataType == .int3 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as SIMD4<Int32>:
            guard argument.bufferDataType == .int4 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as SIMD2<UInt32>:
            guard argument.bufferDataType == .uint2 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as SIMD3<UInt32>:
            guard argument.bufferDataType == .uint3 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as SIMD4<UInt32>:
            guard argument.bufferDataType == .uint4 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as SIMD2<Int16>:
            guard argument.bufferDataType == .short2 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as SIMD3<Int16>:
            guard argument.bufferDataType == .short3 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as SIMD4<Int16>:
            guard argument.bufferDataType == .short4 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as SIMD2<UInt16>:
            guard argument.bufferDataType == .ushort2 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as SIMD3<UInt16>:
            guard argument.bufferDataType == .ushort3 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as SIMD4<UInt16>:
            guard argument.bufferDataType == .ushort4 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as SIMD2<Int8>:
            guard argument.bufferDataType == .char2 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as SIMD3<Int8>:
            guard argument.bufferDataType == .char3 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as SIMD4<Int8>:
            guard argument.bufferDataType == .char4 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as SIMD2<UInt8>:
            guard argument.bufferDataType == .uchar2 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as SIMD3<UInt8>:
            guard argument.bufferDataType == .uchar3 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
        case let v as SIMD4<UInt8>:
            guard argument.bufferDataType == .uchar4 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
#if !os(tvOS)
        case let v as MTLPackedFloat3:
            guard argument.bufferDataType == .float3 else {
                throw Error.argumentTypeMismatch
            }
            encode(v, proxy: proxy)
#endif
        default:
            break
        }
    }

    private static func encode<T>(_ value: T, proxy: MTIFunctionArgumentEncodingProxy) {
        withUnsafePointer(to: value) { ptr in
            proxy.encodeBytes(ptr, length: UInt(MemoryLayout.size(ofValue: value)))
        }
    }
}
