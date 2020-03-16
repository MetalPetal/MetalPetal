//
//  MTIVector.swift
//  MetalPetal
//
//  Created by Yu Ao on 2018/7/2.
//

import Foundation

#if SWIFT_PACKAGE
@_exported import MetalPetalObjectiveC
#endif

extension MTIVector {
    
    public convenience init(values: [Float]) {
        self.init(floatValues: values, count: UInt(values.count))
    }
    
    public convenience init(values: [Int32]) {
        self.init(intValues: values, count: UInt(values.count))
    }
    
    public convenience init(values: [UInt32]) {
        self.init(uintValues: values, count: UInt(values.count))
    }
}
