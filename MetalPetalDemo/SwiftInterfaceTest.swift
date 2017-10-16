//
//  SwiftInterfaceTest.swift
//  MetalPetalDemo
//
//  Created by YuAo on 29/06/2017.
//  Copyright © 2017 MetalPetal. All rights reserved.
//

import Foundation
import MetalPetal

@objc public class MetalPetalSwiftInterfaceTest : NSObject {
    public static func test() {
        let a = MTIVertex(x: 0, y: 0, z: 0, w: 0, u: 0, v: 0)
        let b = MTIVertex(x: 1, y: 1, z: 1, w: 1, u: 1, v: 1)
        let array = [a,b]
        let vertices = MTIVertices(vertices: array)
        print(vertices)
        
        let filter = MTIExposureFilter()
        print(filter.parameters)
    }
}
