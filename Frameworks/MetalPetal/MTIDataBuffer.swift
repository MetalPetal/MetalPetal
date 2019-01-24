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
}
