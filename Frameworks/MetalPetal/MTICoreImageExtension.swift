//
//  MTICoreImageProcessing.swift
//  MetalPetal
//
//  Created by YuAo on 2020/1/27.
//

import Foundation
import CoreImage

#if SWIFT_PACKAGE
@_implementationOnly import MetalPetalObjectiveC.Extension
#else
@_implementationOnly import MetalPetal.Extension
#endif

/// `MTICoreImageKernel` provides the ability to use CoreImage filters with MetalPetal with little or no overhead.
public struct MTICoreImageKernel {
    
    public enum Error: Swift.Error {
        case failedToCreateCIImage
        case nilOutput
    }
    
    private final class Promise: NSObject, NSCopying, MTIImagePromise {
        
        let dimensions: MTITextureDimensions
        
        let dependencies: [MTIImage]
        
        let alphaType: MTIAlphaType
        
        private let pixelFormat: MTLPixelFormat
        
        private let filter: ([CIImage]) throws -> CIImage
        
        private let colorSpace: CGColorSpace?
        
        init(inputs: [MTIImage], filter: @escaping ([CIImage]) throws -> CIImage, dimensions: MTITextureDimensions, pixelFormat: MTLPixelFormat, colorSpace: CGColorSpace?, alphaType: MTIAlphaType) {
            assert(dimensions.depth == 1)
            self.dependencies = inputs
            self.filter = filter
            self.dimensions = dimensions
            self.pixelFormat = pixelFormat
            self.colorSpace = colorSpace
            self.alphaType = alphaType
        }
        
        func copy(with zone: NSZone? = nil) -> Any {
            return self
        }
        
        private func ciImage(for mtiImage: MTIImage, from texture: MTLTexture) throws -> CIImage {
            let options: [CIImageOption: Any] = [.colorSpace: colorSpace ?? NSNull()]
            if let image = CIImage(mtlTexture: texture, options: options) {
                if mtiImage.alphaType == .nonPremultiplied {
                    return image.premultiplyingAlpha().oriented(.downMirrored)
                } else {
                    return image.oriented(.downMirrored)
                }
            } else {
                throw Error.failedToCreateCIImage
            }
        }
        
        func resolve(with renderingContext: MTIImageRenderingContext) throws -> MTIImagePromiseRenderTarget {
            let inputCIImages: [CIImage] = try dependencies.map({
                let texture = renderingContext.resolvedTexture(for: $0)
                // CoreImage does not support yCbCr8_420_2p, yCbCr8_420_2p_srgb pixel format. We have to convert.
                if texture.pixelFormat == .yCbCr8_420_2p || texture.pixelFormat == .yCbCr8_420_2p_srgb {
                    let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: texture.width, height: texture.height, mipmapped: false)
                    textureDescriptor.usage = [.shaderRead, .renderTarget]
                    textureDescriptor.resourceOptions = .storageModePrivate
                    guard let tempTexture = renderingContext.context.device.makeTexture(descriptor: textureDescriptor) else {
                        throw _MTIErrorCreate(.failedToCreateTexture, "MTIErrorFailedToCreateTexture", nil)
                    }
                    let renderPassDescriptor = MTLRenderPassDescriptor()
                    renderPassDescriptor.colorAttachments[0].texture = tempTexture
                    renderPassDescriptor.colorAttachments[0].loadAction = .dontCare
                    renderPassDescriptor.colorAttachments[0].storeAction = .store
                    guard let commandEncoder = renderingContext.commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                        throw _MTIErrorCreate(.failedToCreateCommandEncoder, "MTIErrorFailedToCreateCommandEncoder", nil)
                    }
                    let pipeline = (try renderingContext.context.kernelState(for: MTIRenderPipelineKernel.passthrough, configuration: MTIRenderPipelineKernelConfiguration(colorAttachmentPixelFormat: .bgra8Unorm))) as! MTIRenderPipeline
                    commandEncoder.setRenderPipelineState(pipeline.state)
                    commandEncoder.setFragmentTexture(texture, index: 0)
                    commandEncoder.setFragmentSamplerState(try renderingContext.context.samplerState(with: MTISamplerDescriptor.default), index: 0)
                    MTIVertices.fullViewportSquare.encodeDrawCall(with: commandEncoder, context: pipeline)
                    commandEncoder.endEncoding()
                    return try ciImage(for: $0, from: tempTexture)
                } else {
                    return try ciImage(for: $0, from: texture)
                }
            })
            let renderTarget = try renderingContext.context.makeRenderTarget(reusableTextureDescriptor: MTITextureDescriptor(pixelFormat: pixelFormat == .invalid ? renderingContext.context.workingPixelFormat : pixelFormat, width: dimensions.width, height: dimensions.height, mipmapped: false, usage: [.shaderRead,.shaderWrite], resourceOptions: .storageModePrivate))
            let outputCIImage = try filter(inputCIImages)
            let renderDestination = CIRenderDestination(mtlTexture: renderTarget.texture!, commandBuffer: renderingContext.commandBuffer)
            renderDestination.isFlipped = true
            switch alphaType {
            case .alphaIsOne:
                renderDestination.alphaMode = .none
            case .nonPremultiplied:
                renderDestination.alphaMode = .unpremultiplied
            case .premultiplied:
                renderDestination.alphaMode = .premultiplied
            case .unknown:
                assertionFailure()
                renderDestination.alphaMode = .none
            }
            renderDestination.colorSpace = colorSpace
            try renderingContext.context.coreImageContext.startTask(toRender: outputCIImage, to: renderDestination)
            return renderTarget
        }
        
        func updatingDependencies(_ dependencies: [MTIImage]) -> Promise {
            assert(dependencies.count == self.dependencies.count)
            return Promise(inputs: dependencies, filter: filter, dimensions: dimensions, pixelFormat: pixelFormat, colorSpace: colorSpace, alphaType: alphaType)
        }
        
        private(set) lazy var debugInfo: MTIImagePromiseDebugInfo = MTIImagePromiseDebugInfo(promise: self, type: .processor, content: "")
    }
    
    /// Process `MTIImage`s using `CIFilter`s. The filter block is called when the image is rendered.
    public static func image(byProcessing images:[MTIImage],
                             using filter: @escaping ([CIImage]) throws -> CIImage,
                             colorSpace: CGColorSpace? = CGColorSpaceCreateDeviceRGB(),
                             outputDimensions: MTITextureDimensions,
                             outputPixelFormat: MTLPixelFormat = .unspecified,
                             outputAlphaType: MTIAlphaType = .nonPremultiplied) -> MTIImage {
        let promise = Promise(inputs: images,
                              filter: filter,
                              dimensions: outputDimensions,
                              pixelFormat: outputPixelFormat,
                              colorSpace: colorSpace,
                              alphaType: outputAlphaType)
        return MTIImage(promise: promise)
    }
    
    /// Process a `MTIImage` using a `CIFilter`. The filter is copied. If there are multiple filters you'd like to apply, do not call this method multiple times, instead you should subclass `CIFilter` and combine the filters to one `CIFilter` (https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_filer_recipes/ci_filter_recipes.html#//apple_ref/doc/uid/TP30001185-CH4-SW1). This gives `CoreImage` a chance to optimize the render graph thus improves performance.
    public static func image(byProcessing inputImage: MTIImage,
                             using filter: CIFilter,
                             colorSpace: CGColorSpace? = CGColorSpaceCreateDeviceRGB(),
                             outputDimensions: MTITextureDimensions,
                             outputPixelFormat: MTLPixelFormat = .unspecified,
                             outputAlphaType: MTIAlphaType = .nonPremultiplied) -> MTIImage {
        let copiedFilter = filter.copy() as! CIFilter
        return image(byProcessing: [inputImage], using: { inputImages in
            copiedFilter.setValue(inputImages[0], forKey: kCIInputImageKey)
            if let image = copiedFilter.outputImage {
                return image
            } else {
                throw Error.nilOutput
            }
        }, colorSpace: colorSpace,
           outputDimensions: outputDimensions,
           outputPixelFormat: outputPixelFormat,
           outputAlphaType: outputAlphaType)
    }
}


/// Process a `MTIImage` using a `CIFilter`. If there are multiple filters you'd like to apply, do not create multiple instances, instead you should subclass `CIFilter` and combine the filters to one `CIFilter` (https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_filer_recipes/ci_filter_recipes.html#//apple_ref/doc/uid/TP30001185-CH4-SW1). This gives `CoreImage` a chance to optimize the render graph thus improves performance.
public final class MTICoreImageUnaryFilter: MTIUnaryFilter {
    
    public init() {
        
    }
    
    public var outputPixelFormat: MTLPixelFormat = .unspecified
    
    public var colorSpace: CGColorSpace? = CGColorSpaceCreateDeviceRGB()
    
    public var filter: CIFilter?
    
    public var inputImage: MTIImage?
    
    public var outputImageSize: CGSize?
    
    /// Specifies the alpha type of the output image.
    public var outputAlphaType: MTIAlphaType = .nonPremultiplied
    
    public var outputImage: MTIImage? {
        guard let inputImage = self.inputImage, let filter = filter?.copy() as? CIFilter else {
            return self.inputImage
        }
        let dimensions: MTITextureDimensions
        if let outputImageSize = self.outputImageSize {
            dimensions = MTITextureDimensions(cgSize: outputImageSize)
        } else {
            let placeholder = CIImage(color: CIColor()).cropped(to: inputImage.extent)
            filter.setValue(placeholder, forKey: kCIInputImageKey)
            if let output = filter.outputImage {
                dimensions = MTITextureDimensions(cgSize: output.extent.size)
            } else {
                assertionFailure()
                dimensions = inputImage.dimensions
            }
        }
        return MTICoreImageKernel.image(byProcessing: inputImage, using: filter, colorSpace: colorSpace, outputDimensions: dimensions, outputPixelFormat: outputPixelFormat, outputAlphaType: outputAlphaType)
    }
}
