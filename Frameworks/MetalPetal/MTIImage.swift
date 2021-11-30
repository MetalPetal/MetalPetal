//
//  MTIImage.swift
//  MetalPetal
//
//  Created by Yu Ao on 2019/12/4.
//

import Foundation
import MetalKit

#if SWIFT_PACKAGE
import MetalPetalObjectiveC.Core
#endif

extension MTIImage {
    
    public convenience init(cgImage: CGImage, orientation: CGImagePropertyOrientation = .up, options: MTICGImageLoadingOptions = .default, isOpaque: Bool = false) {
        self.init(__cgImage: cgImage, orientation: orientation, loadingOptions: options, isOpaque: isOpaque)
    }
    
    public convenience init?(contentsOf url: URL, options: MTICGImageLoadingOptions = .default, isOpaque: Bool = false) {
        self.init(__contentsOf: url, loadingOptions: options, isOpaque: isOpaque)
    }
    
    @available(*, deprecated, message: "Use init?(contentsOf:options:isOpaque:) instead.")
    public convenience init?(contentsOf url: URL, options: MTICGImageLoadingOptions = .default, alphaType: MTIAlphaType? = nil) {
        self.init(__contentsOf: url, loadingOptions: options, isOpaque: alphaType == .alphaIsOne ? true : false)
    }
    
    public convenience init(cgImage: CGImage, options: [MTKTextureLoader.Option: Any], isOpaque: Bool = false) {
        self.init(__cgImage: cgImage, options: options, isOpaque: isOpaque)
    }
    
    public convenience init?(contentsOf url: URL, options: [MTKTextureLoader.Option: Any], alphaType: MTIAlphaType? = nil) {
        if let alphaType = alphaType {
            self.init(__contentsOf: url, options: options, alphaType: alphaType)
        } else {
            self.init(__contentsOf: url, options: options)
        }
    }
    
    public convenience init?(contentsOf url: URL, size: CGSize, options: [MTKTextureLoader.Option: Any], alphaType: MTIAlphaType) {
        self.init(__contentsOf: url, size: size, options: options, alphaType: alphaType)
    }
    
    public convenience init(bitmapData data: Data, width: Int, height: Int, bytesPerRow: Int, pixelFormat: MTLPixelFormat, alphaType: MTIAlphaType) {
        self.init(bitmapData: data, width: UInt(width), height: UInt(height), bytesPerRow: UInt(bytesPerRow), pixelFormat: pixelFormat, alphaType: alphaType)
    }
    
    public convenience init(cvPixelBuffer pixelBuffer: CVPixelBuffer, planeIndex: Int, textureDescriptor: MTLTextureDescriptor, alphaType: MTIAlphaType) {
        self.init(cvPixelBuffer: pixelBuffer, planeIndex: UInt(planeIndex), textureDescriptor: textureDescriptor, alphaType: alphaType)
    }
}

extension MTIImage {
    
    public func adjusting(saturation: Float, outputPixelFormat: MTLPixelFormat = .unspecified) -> MTIImage {
        let filter = MTISaturationFilter()
        filter.saturation = saturation
        filter.inputImage = self
        filter.outputPixelFormat = outputPixelFormat
        return filter.outputImage!
    }
    
    public func adjusting(exposure: Float, outputPixelFormat: MTLPixelFormat = .unspecified) -> MTIImage {
        let filter = MTIExposureFilter()
        filter.exposure = exposure
        filter.inputImage = self
        filter.outputPixelFormat = outputPixelFormat
        return filter.outputImage!
    }
    
    public func adjusting(brightness: Float, outputPixelFormat: MTLPixelFormat = .unspecified) -> MTIImage {
        let filter = MTIBrightnessFilter()
        filter.brightness = brightness
        filter.inputImage = self
        filter.outputPixelFormat = outputPixelFormat
        return filter.outputImage!
    }
    
    public func adjusting(contrast: Float, outputPixelFormat: MTLPixelFormat = .unspecified) -> MTIImage {
        let filter = MTIContrastFilter()
        filter.contrast = contrast
        filter.inputImage = self
        filter.outputPixelFormat = outputPixelFormat
        return filter.outputImage!
    }
    
    public func adjusting(vibrance: Float, outputPixelFormat: MTLPixelFormat = .unspecified) -> MTIImage {
        let filter = MTIVibranceFilter()
        filter.amount = vibrance
        filter.inputImage = self
        filter.outputPixelFormat = outputPixelFormat
        return filter.outputImage!
    }
    
    /// Returns a MTIImage object that specifies a subimage of the image. If the `region` parameter defines an empty area, returns nil.
    public func cropped(to region: MTICropRegion, outputPixelFormat: MTLPixelFormat = .unspecified) -> MTIImage? {
        let filter = MTICropFilter()
        filter.cropRegion = region
        filter.inputImage = self
        filter.outputPixelFormat = outputPixelFormat
        return filter.outputImage
    }
    
    /// Returns a MTIImage object that specifies a subimage of the image. If the `rect` parameter defines an empty area, returns nil.
    public func cropped(to rect: CGRect, outputPixelFormat: MTLPixelFormat = .unspecified) -> MTIImage? {
        let filter = MTICropFilter()
        filter.cropRegion = MTICropRegion(bounds: rect, unit: .pixel)
        filter.inputImage = self
        filter.outputPixelFormat = outputPixelFormat
        return filter.outputImage
    }
    
    /// Returns a MTIImage object that is resized to a specified size. If the `size` parameter has zero/negative width or height, returns nil.
    public func resized(to size: CGSize, outputPixelFormat: MTLPixelFormat = .unspecified) -> MTIImage? {
        assert(size.width >= 1 && size.height >= 1)
        guard size.width >= 1 && size.height >= 1 else { return nil }
        return MTIUnaryImageRenderingFilter.image(byProcessingImage: self, orientation: .up, parameters: [:], outputPixelFormat: outputPixelFormat, outputImageSize: size)
    }
    
    /// Returns a MTIImage object that is resized to a specified size. If the `size` parameter has zero/negative width or height, returns nil.
    public func resized(to target: CGSize, resizingMode: MTIDrawableRenderingResizingMode, outputPixelFormat: MTLPixelFormat = .unspecified) -> MTIImage? {
        let size: CGSize
        switch resizingMode {
        case .aspect:
            size = MTIMakeRect(aspectRatio: self.size, insideRect: CGRect(origin: .zero, size: target)).size
        case .aspectFill:
            size = MTIMakeRect(aspectRatio: self.size, fillRect: CGRect(origin: .zero, size: target)).size
        case .scale:
            size = target
        @unknown default:
            fatalError()
        }
        assert(size.width >= 1 && size.height >= 1)
        guard size.width >= 1 && size.height >= 1 else { return nil }
        return MTIUnaryImageRenderingFilter.image(byProcessingImage: self, orientation: .up, parameters: [:], outputPixelFormat: outputPixelFormat, outputImageSize: size)
    }
}

#if canImport(UIKit)

import UIKit

extension UIImage.Orientation {
    fileprivate var cgImagePropertyOrientation: CGImagePropertyOrientation {
        let cgImagePropertyOrientation: CGImagePropertyOrientation
        switch self {
        case .up:
            cgImagePropertyOrientation = .up
        case .upMirrored:
            cgImagePropertyOrientation = .upMirrored
        case .left:
            cgImagePropertyOrientation = .left
        case .leftMirrored:
            cgImagePropertyOrientation = .leftMirrored
        case .right:
            cgImagePropertyOrientation = .right
        case .rightMirrored:
            cgImagePropertyOrientation = .rightMirrored
        case .down:
            cgImagePropertyOrientation = .down
        case .downMirrored:
            cgImagePropertyOrientation = .downMirrored
        @unknown default:
            fatalError("Unknown UIImage.Orientation: \(self.rawValue)")
        }
        return cgImagePropertyOrientation
    }
}

extension MTIImage {
    public convenience init(image: UIImage, colorSpace: CGColorSpace? = nil, isOpaque: Bool = false) {
        let cgImage: CGImage
        let orientation: CGImagePropertyOrientation
        if let cg = image.cgImage {
            cgImage = cg
            orientation = image.imageOrientation.cgImagePropertyOrientation
        } else {
            let format = UIGraphicsImageRendererFormat.preferred()
            format.opaque = isOpaque
            format.scale = image.scale
            cgImage = UIGraphicsImageRenderer(size: image.size).image { _ in
                image.draw(at: .zero)
            }.cgImage!
            orientation = .up
        }
        let options = MTICGImageLoadingOptions(colorSpace: colorSpace)
        self.init(cgImage: cgImage, orientation: orientation, options: options, isOpaque: isOpaque)
    }
}

#endif

#if canImport(AppKit)

import AppKit

extension MTIImage {
    @available(macCatalyst, unavailable)
    public convenience init?(image: NSImage, colorSpace: CGColorSpace? = nil, isOpaque: Bool = false) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        let options = MTICGImageLoadingOptions(colorSpace: colorSpace)
        self.init(cgImage: cgImage, orientation: .up, options: options, isOpaque: isOpaque)
    }
}

#endif

