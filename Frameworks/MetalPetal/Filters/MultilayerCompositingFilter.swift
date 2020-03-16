//
//  MTIMultilayerCompositingFilter.swift
//  MetalPetal
//
//  Created by Yu Ao on 2019/12/4.
//

import Foundation
import CoreGraphics
import Metal

#if SWIFT_PACKAGE
@_exported import MetalPetalObjectiveC
#endif

extension MTILayer.FlipOptions: Hashable {
    
}

extension MTILayer.LayoutUnit: Hashable {
    
}

extension MTILayer.LayoutUnit: CustomDebugStringConvertible, CustomStringConvertible {
    public var debugDescription: String {
        return self.name
    }
    
    public var description: String {
        return self.name
    }
    
    private var name: String {
        switch self {
        case .fractionOfBackgroundSize:
            return "MTILayer.LayoutUnit.fractionOfBackgroundSize"
        case .pixel:
            return "MTILayer.LayoutUnit.pixel"
        }
    }
}

public class MultilayerCompositingFilter: MTIFilter {
    
    public struct Layer: Hashable, Equatable {
        
        public var content: MTIImage
        
        public var contentRegion: CGRect
        
        public var contentFlipOptions: MTILayer.FlipOptions = []
        
        public var compositingMask: MTIMask? = nil
        
        public var layoutUnit: MTILayer.LayoutUnit
        
        public var position: CGPoint
        
        public var size: CGSize
        
        public var rotation: Float = 0
        
        public var opacity: Float = 0
        
        public var blendMode: MTIBlendMode = .normal
        
        public init(content: MTIImage) {
            self.content = content
            self.contentRegion = content.extent
            self.layoutUnit = .pixel
            self.size = content.size
            self.position = CGPoint(x: content.size.width/2, y: content.size.height/2)
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(content)
            hasher.combine(contentRegion.origin.x)
            hasher.combine(contentRegion.origin.y)
            hasher.combine(contentRegion.size.width)
            hasher.combine(contentRegion.size.height)
            hasher.combine(contentFlipOptions)
            hasher.combine(compositingMask)
            hasher.combine(layoutUnit)
            hasher.combine(position.x)
            hasher.combine(position.y)
            hasher.combine(size.width)
            hasher.combine(size.height)
            hasher.combine(rotation)
            hasher.combine(opacity)
            hasher.combine(blendMode)
        }
    }
    
    public var outputPixelFormat: MTLPixelFormat {
        get {
            return internalFilter.outputPixelFormat
        }
        set {
            internalFilter.outputPixelFormat = newValue
        }
    }
    
    public var outputImage: MTIImage? {
        return internalFilter.outputImage
    }
    
    public var inputBackgroundImage: MTIImage? {
        get {
            return internalFilter.inputBackgroundImage
        }
        set {
            internalFilter.inputBackgroundImage = newValue
        }
    }
    
    private var _layers: [Layer] = []
    
    public var layers: [Layer] {
        set {
            _layers = newValue
            internalFilter.layers = newValue.map({ $0.bridgeToObjectiveC() })
        }
        get {
            return _layers
        }
    }
    
    private var internalFilter = MTIMultilayerCompositingFilter()
    
    public init() {
        
    }
}

extension MultilayerCompositingFilter {
    public static func makeLayer(content: MTIImage, configurator: (_ layer: inout Layer) -> Void) -> Layer {
        var layer = Layer(content: content)
        configurator(&layer)
        return layer
    }
}

extension MultilayerCompositingFilter.Layer {
    fileprivate func bridgeToObjectiveC() -> MTILayer {
        return MTILayer(content: self.content, contentRegion: self.contentRegion, contentFlipOptions: self.contentFlipOptions, compositingMask: self.compositingMask, layoutUnit: self.layoutUnit, position: self.position, size: self.size, rotation: self.rotation, opacity: self.opacity, blendMode: self.blendMode)
    }
}

extension MultilayerCompositingFilter.Layer: CustomDebugStringConvertible, CustomStringConvertible {
    public var debugDescription: String {
        let mirror = Mirror(reflecting: self)
        let members: String = mirror.children.reduce("", { r, c in "\(r)\(c.label ?? "(null)") = \(c.value); " })
        return "<MultilayerCompositingFilter.Layer> { \(members)}"
    }
    
    public var description: String {
        return self.debugDescription
    }
}
