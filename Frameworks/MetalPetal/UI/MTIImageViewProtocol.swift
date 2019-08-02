//
//  MTIImageViewProtocol.swift
//  MetalPetal
//
//  Created by Yu Ao on 2019/7/5.
//

import Metal

protocol MTIImageViewProtocol {
    
    var colorPixelFormat: MTLPixelFormat { get set }
    
    var clearColor: MTLClearColor { get set }
    
    var resizingMode: MTIDrawableRenderingResizingMode { get set }
    
    var context: MTIContext { get set }
    
    var image: MTIImage? { get set }
}

#if canImport(UIKit)

extension MTIImageView: MTIImageViewProtocol {
    
}

extension MTIThreadSafeImageView: MTIImageViewProtocol {
    
}

#endif
