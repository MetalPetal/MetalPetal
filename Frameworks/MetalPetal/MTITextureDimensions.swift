//
//  MTITextureDimensions.swift
//  Pods
//
//  Created by Yu Ao on 11/10/2017.
//

#if SWIFT_PACKAGE
import MetalPetalObjectiveC.Core
#endif

extension MTITextureDimensions : Equatable {
    public static func == (lhs: MTITextureDimensions, rhs: MTITextureDimensions) -> Bool {
        return lhs.isEqual(to: rhs)
    }
    
    public init(width: Int, height: Int, depth: Int = 1) {
        self.init(width: UInt(width), height: UInt(height), depth: UInt(depth))
    }
}
