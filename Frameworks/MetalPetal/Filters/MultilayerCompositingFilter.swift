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
import MetalPetalObjectiveC.Core
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
        
        public var mask: MTIMask? = nil
        
        public var compositingMask: MTIMask? = nil
        
        public var layoutUnit: MTILayer.LayoutUnit
        
        public var position: CGPoint
        
        public var size: CGSize
        
        public var rotation: Float = 0
        
        public var opacity: Float = 1
        
        public var cornerRadius: MTICornerRadius = MTICornerRadius(0)
        
        public var cornerCurve: MTICornerCurve = .circular
        
        public var tintColor: MTIColor = .clear
        
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
            hasher.combine(mask)
            hasher.combine(compositingMask)
            hasher.combine(layoutUnit)
            hasher.combine(position.x)
            hasher.combine(position.y)
            hasher.combine(size.width)
            hasher.combine(size.height)
            hasher.combine(rotation)
            hasher.combine(opacity)
            hasher.combine(cornerRadius)
            hasher.combine(cornerCurve)
            hasher.combine(tintColor)
            hasher.combine(blendMode)
        }
        
        private func mutating(_ block: (inout Layer) -> Void) -> Layer {
            var layer = self
            block(&layer)
            return layer
        }
        
        public static func content(_ image: MTIImage) -> Layer {
            Layer(content: image)
        }
        
        public static func content(_ image: MTIImage, modifier: (inout Layer) -> Void) -> Layer {
            Layer(content: image).mutating(modifier)
        }
        
        public func opacity(_ value: Float) -> Layer {
            self.mutating({ $0.opacity = value })
        }
        
        public func contentRegion(_ contentRegion: CGRect) -> Layer {
            self.mutating({ $0.contentRegion = contentRegion })
        }
        
        public func contentFlipOptions(_ contentFlipOptions: MTILayer.FlipOptions) -> Layer {
            self.mutating({ $0.contentFlipOptions = contentFlipOptions })
        }
        
        public func mask(_ mask: MTIMask?) -> Layer {
            self.mutating({ $0.mask = mask })
        }
        
        public func compositingMask(_ mask: MTIMask?) -> Layer {
            self.mutating({ $0.compositingMask = mask })
        }
        
        public func frame(_ rect: CGRect, layoutUnit: MTILayer.LayoutUnit) -> Layer {
            self.mutating({
                $0.size = rect.size
                $0.position = CGPoint(x: rect.midX, y: rect.midY)
                $0.layoutUnit = layoutUnit
            })
        }
        
        public func frame(center: CGPoint, size: CGSize, layoutUnit: MTILayer.LayoutUnit) -> Layer {
            self.mutating({
                $0.size = size
                $0.position = center
                $0.layoutUnit = layoutUnit
            })
        }
        
        public func rotation(_ rotation: Float) -> Layer {
            self.mutating({ $0.rotation = rotation })
        }
        
        public func tintColor(_ color: MTIColor?) -> Layer {
            self.mutating({ $0.tintColor = color ?? .clear })
        }
        
        public func blendMode(_ blendMode: MTIBlendMode) -> Layer {
            self.mutating({ $0.blendMode = blendMode })
        }
        
        public func corner(radius: MTICornerRadius, curve: MTICornerCurve) -> Layer {
            self.mutating({
                $0.cornerRadius = radius
                $0.cornerCurve = curve
            })
        }
        
        public func cornerRadius(_ radius: MTICornerRadius) -> Layer {
            self.mutating({ $0.cornerRadius = radius })
        }
        
        public func cornerRadius(_ radius: Float) -> Layer {
            self.mutating({ $0.cornerRadius = MTICornerRadius(radius) })
        }
        
        public func cornerCurve(_ curve: MTICornerCurve) -> Layer {
            self.mutating({ $0.cornerCurve = curve })
        }
    }
    
    public var outputPixelFormat: MTLPixelFormat {
        get { internalFilter.outputPixelFormat }
        set { internalFilter.outputPixelFormat = newValue }
    }
    
    public var outputImage: MTIImage? {
        return internalFilter.outputImage
    }
    
    public var inputBackgroundImage: MTIImage? {
        get { internalFilter.inputBackgroundImage }
        set { internalFilter.inputBackgroundImage = newValue }
    }
    
    public var outputAlphaType: MTIAlphaType {
        get { internalFilter.outputAlphaType }
        set { internalFilter.outputAlphaType = newValue }
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
    
    public var rasterSampleCount: Int {
        set { internalFilter.rasterSampleCount = UInt(newValue) }
        get { Int(internalFilter.rasterSampleCount) }
    }
    
    private var internalFilter = MTIMultilayerCompositingFilter()
    
    public init() {
        
    }
}

extension MultilayerCompositingFilter {
    @available(*, deprecated, message: "Use MultilayerCompositingFilter.Layer(content:).frame(...).opacity(...)... instead.")
    public static func makeLayer(content: MTIImage, configurator: (_ layer: inout Layer) -> Void) -> Layer {
        var layer = Layer(content: content)
        configurator(&layer)
        return layer
    }
}

extension MultilayerCompositingFilter.Layer {
    fileprivate func bridgeToObjectiveC() -> MTILayer {
        return MTILayer(content: self.content, contentRegion: self.contentRegion, contentFlipOptions: self.contentFlipOptions, mask: self.mask, compositingMask: self.compositingMask, layoutUnit: self.layoutUnit, position: self.position, size: self.size, rotation: self.rotation, opacity: self.opacity, cornerRadius: self.cornerRadius, cornerCurve: self.cornerCurve, tintColor: self.tintColor, blendMode: self.blendMode)
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
