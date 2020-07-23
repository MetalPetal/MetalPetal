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
    
    public func cropped(to region: MTICropRegion, outputPixelFormat: MTLPixelFormat = .unspecified) -> MTIImage {
        let filter = MTICropFilter()
        filter.cropRegion = region
        filter.inputImage = self
        filter.outputPixelFormat = outputPixelFormat
        return filter.outputImage!
    }
    
    public func cropped(to rect: CGRect, outputPixelFormat: MTLPixelFormat = .unspecified) -> MTIImage {
        let filter = MTICropFilter()
        filter.cropRegion = MTICropRegion(bounds: rect, unit: .pixel)
        filter.inputImage = self
        filter.outputPixelFormat = outputPixelFormat
        return filter.outputImage!
    }
    
    public func resized(to size: CGSize, outputPixelFormat: MTLPixelFormat = .unspecified) -> MTIImage {
        assert(size.width >= 1 && size.height >= 1)
        return MTIUnaryImageRenderingFilter.image(byProcessingImage: self, orientation: .up, parameters: [:], outputPixelFormat: outputPixelFormat, outputImageSize: size)
    }
    
    public func resized(to target: CGSize, resizingMode: MTIDrawableRenderingResizingMode, outputPixelFormat: MTLPixelFormat = .unspecified) -> MTIImage {
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
    @available(*, deprecated, message: "Use `MTIImage(image:colorSpace:isOpaque:)` instead")
    public func oriented(_ orientation: UIImage.Orientation, outputPixelFormat pixelFormat: MTLPixelFormat = .unspecified) -> MTIImage {
        if orientation == .up {
            return self
        }
        return self.oriented(orientation.cgImagePropertyOrientation, outputPixelFormat: pixelFormat)
    }
}

extension UIImage {
    @available(*, deprecated, message: "Use `MTIImage(image:colorSpace:isOpaque:)` instead")
    public func makeMTIImage(sRGB: Bool = false, isOpaque: Bool = false) -> MTIImage? {
        guard let cgImage = self.cgImage else {
            return nil
        }
        return MTIImage(cgImage: cgImage, options: [.SRGB: sRGB], isOpaque: isOpaque).oriented(self.imageOrientation)
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
            let format = UIGraphicsImageRendererFormat()
            format.prefersExtendedRange = false
            format.opaque = isOpaque
            format.scale = image.scale
            cgImage = UIGraphicsImageRenderer(size: image.size).image { _ in
                image.draw(at: .zero)
            }.cgImage!
            orientation = .up
        }
        let options = MTICGImageLoadingOptions(colorSpace: colorSpace)
        self.init(cgImage: cgImage, orientation: orientation, loadingOptions: options, isOpaque: isOpaque)
    }
}

#endif
