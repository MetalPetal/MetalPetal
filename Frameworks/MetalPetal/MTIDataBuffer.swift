//
//  MTIDataBuffer.swift
//  MetalPetal
//
//  Created by Yu Ao on 2019/1/24.
//

import Foundation

extension MTIDataBuffer {
    
    public convenience init?<T>(values: [T], options: MTLResourceOptions = []) {
        self.init(bytes: values, length: UInt(MemoryLayout<T>.size * values.count), options: options)
    }
    
    public func unsafeAccess<ReturnType, BufferContentType>(_ block: (UnsafeMutableBufferPointer<BufferContentType>) throws -> ReturnType) rethrows -> ReturnType {
        var result: (pointer: UnsafeMutableRawPointer, length: UInt)!
        self.unsafeAccess { (pointer: UnsafeMutableRawPointer, length: UInt) -> Void in
            result = (pointer, length)
        }
        precondition(Int(result.length) % MemoryLayout<BufferContentType>.size == 0)
        return try block(UnsafeMutableBufferPointer<BufferContentType>(start: result.pointer.assumingMemoryBound(to: BufferContentType.self), count: Int(result.length)/MemoryLayout<BufferContentType>.size))
    }
}
