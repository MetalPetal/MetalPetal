//
//  MTIVector.swift
//  MetalPetal
//
//  Created by Yu Ao on 2018/7/2.
//

import Foundation

#if SWIFT_PACKAGE
import MetalPetalObjectiveC.Core
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
    
    public convenience init(values: [Int16]) {
        self.init(shortValues: values, count: UInt(values.count))
    }
    
    public convenience init(values: [UInt16]) {
        self.init(ushortValues: values, count: UInt(values.count))
    }
    
    public convenience init(values: [Int8]) {
        self.init(charValues: values, count: UInt(values.count))
    }
    
    public convenience init(values: [UInt8]) {
        self.init(ucharValues: values, count: UInt(values.count))
    }
}
