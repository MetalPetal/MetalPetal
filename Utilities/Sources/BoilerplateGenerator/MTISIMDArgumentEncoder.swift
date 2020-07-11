//
//  File.swift
//  
//
//  Created by YuAo on 2020/7/11.
//

import Foundation
import SIMDType

fileprivate let template: String = """
//
//  MTISIMDArgumentEncoder.swift
//  MetalPetal
//
//  Auto-generated.
//

import Foundation

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
{MTI_SIMD_SHADER_ARGUMENT_ENCODER_GENERATED}
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

"""

public struct MTISIMDShaderArgumentEncoderGenerator {
    public static func generate() -> [String: String] {
        var content: String = ""
        for simdType in SIMDType.metalSupportedSIMDTypes {
            switch simdType.dimension {
            case .vector(let count):
                content.append(
                """
                        case let v as SIMD\(count)<\(simdType.scalarType.swiftTypeName)>:
                            guard argument.bufferDataType == .\(simdType.scalarType.description(capitalized: false))\(count) else {
                                throw Error.argumentTypeMismatch
                            }
                            encode(v, proxy: proxy)
                
                """)
            case .matrix(let c, let r):
                content.append(
                """
                        case let v as \(simdType.scalarType.description(capitalized: false))\(c)x\(r):
                            guard argument.bufferDataType == .\(simdType.scalarType.description(capitalized: false))\(c)x\(r) else {
                                throw Error.argumentTypeMismatch
                            }
                            encode(v, proxy: proxy)
                
                """)
            }
        }
        return ["MTISIMDArgumentEncoder.swift": template.replacingOccurrences(of: "{MTI_SIMD_SHADER_ARGUMENT_ENCODER_GENERATED}", with: content)]
    }
}
