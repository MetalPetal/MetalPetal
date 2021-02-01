//
//  MTICropRegion.swift
//  MetalPetal
//
//  Created by YuAo on 2021/2/1.
//

import Foundation

#if SWIFT_PACKAGE
import MetalPetalObjectiveC.Core
#endif

extension MTICropRegion {
    public static func pixel(_ rect: CGRect) -> MTICropRegion {
        MTICropRegion(bounds: rect, unit: .pixel)
    }
    
    public static func fractional(_ rect: CGRect) -> MTICropRegion {
        MTICropRegion(bounds: rect, unit: .percentage)
    }
}
