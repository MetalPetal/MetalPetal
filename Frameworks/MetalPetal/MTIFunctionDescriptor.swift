//
//  MTIFunctionDescriptor.swift
//  MetalPetal
//
//  Created by Yu Ao on 2019/12/26.
//

import Foundation

#if SWIFT_PACKAGE
import MetalPetalObjectiveC.Core
#endif

extension MTIFunctionDescriptor {
    public static let passthroughFragment: MTIFunctionDescriptor = MTIFunctionDescriptor(name: MTIFilterPassthroughFragmentFunctionName)
    
    public static let passthroughVertex: MTIFunctionDescriptor = MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName)
}

extension MTIFunctionDescriptor {
    public convenience init(name: String, constantValues: MTLFunctionConstantValues? = nil, in bundle: Bundle) {
        self.init(name: name, constantValues: constantValues, libraryURL: MTIDefaultLibraryURLForBundle(bundle))
    }
}

extension URL {
    public static func defaultMetalLibraryURL(for bundleForClass: AnyClass) -> URL! {
        return MTIDefaultLibraryURLForBundle(Bundle(for: bundleForClass))
    }
    
    public static func defaultMetalLibraryURL(for bundle: Bundle) -> URL! {
        return MTIDefaultLibraryURLForBundle(bundle)
    }
}
