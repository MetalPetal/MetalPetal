//
//  MTIFunctionDescriptor.swift
//  MetalPetal
//
//  Created by Yu Ao on 2019/12/26.
//

import Foundation

extension MTIFunctionDescriptor {
    public static let passthroughFragment: MTIFunctionDescriptor = MTIFunctionDescriptor(name: MTIFilterPassthroughFragmentFunctionName)
    
    public static let passthroughVertex: MTIFunctionDescriptor = MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName)
}

extension URL {
    public static func defaultMetalLibraryURL(for bundleForClass: AnyClass) -> URL! {
        return MTIDefaultLibraryURLForBundle(Bundle(for: bundleForClass))
    }
    
    public static func defaultMetalLibraryURL(for bundle: Bundle) -> URL! {
        return MTIDefaultLibraryURLForBundle(bundle)
    }
}
