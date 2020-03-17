//
//  MTIColorMatrix.swift
//  MetalPetal
//
//  Created by Yu Ao on 25/10/2017.
//

import Foundation

#if SWIFT_PACKAGE
import MetalPetalObjectiveC.Core
#endif

extension MTIColorMatrix : Equatable {
    public static func == (lhs: MTIColorMatrix, rhs: MTIColorMatrix) -> Bool {
        return lhs.isEqual(to: rhs)
    }
}
