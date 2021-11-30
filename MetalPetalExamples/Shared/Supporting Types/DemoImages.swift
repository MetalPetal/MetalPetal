//
//  DemoImages.swift
//  MetalPetalDemo
//
//  Created by YuAo on 2021/4/3.
//

import Foundation
import MetalPetal

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

struct DemoImages {
    
    private static let namedCGImageCache = NSCache<NSString, CGImage>()
    
    static func cgImage(named name: String) -> CGImage! {
        if let image = namedCGImageCache.object(forKey: name as NSString) {
            return image
        }
        let url = Bundle.main.url(forResource: name, withExtension: nil)!
        if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil), let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) {
            namedCGImageCache.setObject(image, forKey: name as NSString)
            return image
        }
        return nil
    }
    
    static let p1040808 = MTIImage(contentsOf: Bundle.main.url(forResource: "P1040808", withExtension: "jpg")!, isOpaque: true)!
    
    static let p1 = MTIImage(contentsOf: Bundle.main.url(forResource: "P1", withExtension: "jpg")!, isOpaque: true)!
    static let p1DepthMask = MTIImage(contentsOf: Bundle.main.url(forResource: "P1_depth", withExtension: "jpg")!, isOpaque: true)!
    
    static let colorLookupTable = MTIImage(contentsOf: Bundle.main.url(forResource: "ColorLookupTable", withExtension: "png")!, isOpaque: true)!
    
    static func makeSymbolImage(named name: String, aspectFitIn size: CGSize, padding: CGFloat = 0) -> MTIImage {
        #if os(iOS)
        guard let cgImage = UIImage(systemName: name, withConfiguration: UIImage.SymbolConfiguration(pointSize:  min(size.width, size.height), weight: .medium))?.cgImage else {
            fatalError()
        }
        #elseif os(macOS)
        guard let cgImage = NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: min(size.width, size.height), weight: .medium))?.cgImage(forProposedRect: nil, context: nil, hints: [:]) else {
            fatalError()
        }
        #else
        #error("Unsupported Platform")
        #endif
        
        guard let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) else {
            fatalError()
        }
        context.draw(cgImage, in: MTIMakeRect(aspectRatio: CGSize(width: cgImage.width, height: cgImage.height), insideRect: CGRect(origin: .zero, size: size).insetBy(dx: padding, dy: padding)))
        guard let image = context.makeImage() else {
            fatalError()
        }
        return MTIImage(cgImage: image, isOpaque: false)
    }
    
    static func makeSymbolAlphaMaskImage(named name: String, aspectFitIn size: CGSize, padding: CGFloat = 0) -> MTIImage {
        #if os(iOS)
        guard let cgImage = UIImage(systemName: name, withConfiguration: UIImage.SymbolConfiguration(pointSize:  min(size.width, size.height), weight: .medium))?.cgImage else {
            fatalError()
        }
        #elseif os(macOS)
        guard let cgImage = NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: min(size.width, size.height), weight: .medium))?.cgImage(forProposedRect: nil, context: nil, hints: [:]) else {
            fatalError()
        }
        #else
        #error("Unsupported Platform")
        #endif
        
        guard let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) else {
            fatalError()
        }
        context.draw(cgImage, in: MTIMakeRect(aspectRatio: CGSize(width: cgImage.width, height: cgImage.height), insideRect: CGRect(origin: .zero, size: size).insetBy(dx: padding, dy: padding)))
        guard let maskImage = context.makeImage() else {
            fatalError()
        }
        context.setFillColor(CGColor(gray: 0, alpha: 1))
        context.fill(CGRect(origin: .zero, size: size))
        context.clip(to: CGRect(origin: .zero, size: size), mask: maskImage)
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(origin: .zero, size: size))

        guard let image = context.makeImage() else {
            fatalError()
        }
        return MTIImage(cgImage: image, isOpaque: true)
    }
}

struct RGUVGradientImage {
    private static let kernel = MTIRenderPipelineKernel(vertexFunctionDescriptor: .passthroughVertex, fragmentFunctionDescriptor: MTIFunctionDescriptor(name: "rgUVGradient", in: Bundle.main))
    static func makeImage(size: CGSize) -> MTIImage {
        kernel.makeImage(dimensions: MTITextureDimensions(cgSize: size))
    }
}

struct RGUVB1GradientImage {
    private static let kernel = MTIRenderPipelineKernel(vertexFunctionDescriptor: .passthroughVertex, fragmentFunctionDescriptor: MTIFunctionDescriptor(name: "rgUVB1Gradient", in: Bundle.main))
    static func makeImage(size: CGSize) -> MTIImage {
        kernel.makeImage(dimensions: MTITextureDimensions(cgSize: size))
    }
    static func makeCGImage(size: CGSize) -> CGImage {
        let context = try! MTIContext(device: MTLCreateSystemDefaultDevice()!)
        return try! context.makeCGImage(from: self.makeImage(size: size))
    }
}

struct RadialGradientImage {
    private static let kernel = MTIRenderPipelineKernel(vertexFunctionDescriptor: .passthroughVertex, fragmentFunctionDescriptor: MTIFunctionDescriptor(name: "radialGradient", in: Bundle.main))
    static func makeImage(size: CGSize) -> MTIImage {
        kernel.makeImage(dimensions: MTITextureDimensions(cgSize: size))
    }
}

struct ImageUtilities {
    static func loadUserPickedImage(from url: URL, requiresUnpremultipliedAlpha: Bool) -> MTIImage? {
        if var image = MTIImage(contentsOf: url, isOpaque: false) {
            if image.size.width > 2160 || image.size.height > 2160 {
                image = image.resized(to: CGSize(width: 2160, height: 2160), resizingMode: .aspect) ?? image
            }
            if requiresUnpremultipliedAlpha {
                image = image.unpremultiplyingAlpha()
            }
            image = image.withCachePolicy(.persistent)
            return image
        }
        return nil
    }
}
