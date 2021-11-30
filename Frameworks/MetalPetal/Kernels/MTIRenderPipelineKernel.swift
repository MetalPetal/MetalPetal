//
//  MTIRenderPipelineKernel.swift
//  Pods
//
//  Created by YuAo on 2021/11/30.
//

import Foundation
import Metal

#if SWIFT_PACKAGE
import MetalPetalObjectiveC.Core
#endif

extension MTIRenderPipelineKernel {
    
    public func makeImage(parameters: [String: Any] = [:], dimensions: MTITextureDimensions, pixelFormat: MTLPixelFormat = .unspecified) -> MTIImage {
        apply(to: [], parameters: parameters, outputDimensions: dimensions, outputPixelFormat: pixelFormat)
    }
    
    public func apply(to image: MTIImage, parameters: [String: Any] = [:], outputPixelFormat: MTLPixelFormat = .unspecified) -> MTIImage {
        __apply(toInputImages: [image], parameters: parameters, outputTextureDimensions: image.dimensions, outputPixelFormat: outputPixelFormat)
    }
    
    public func apply(to image: MTIImage, parameters: [String: Any] = [:], outputDimensions: MTITextureDimensions, outputPixelFormat: MTLPixelFormat = .unspecified) -> MTIImage {
        __apply(toInputImages: [image], parameters: parameters, outputTextureDimensions: outputDimensions, outputPixelFormat: outputPixelFormat)
    }
    
    public func apply(to images: [MTIImage], parameters: [String: Any] = [:], outputDimensions: MTITextureDimensions, outputPixelFormat: MTLPixelFormat = .unspecified) -> MTIImage {
        __apply(toInputImages: images, parameters: parameters, outputTextureDimensions: outputDimensions, outputPixelFormat: outputPixelFormat)
    }
    
    public func apply(to images: [MTIImage], parameters: [String: Any] = [:], outputDescriptors: [MTIRenderPassOutputDescriptor]) -> [MTIImage] {
        __apply(toInputImages: images, parameters: parameters, outputDescriptors: outputDescriptors)
    }
    
    @available(*, deprecated, renamed: "apply(to:parameters:outputDescriptors:)")
    public func apply(toInputImages: [MTIImage], parameters: [String: Any], outputDescriptors: [MTIRenderPassOutputDescriptor]) -> [MTIImage] {
        __apply(toInputImages: toInputImages, parameters: parameters, outputDescriptors: outputDescriptors)
    }
    
    @available(*, deprecated, renamed: "apply(to:parameters:outputDimensions:outputPixelFormat:)")
    public func apply(toInputImages: [MTIImage], parameters: [String: Any], outputTextureDimensions: MTITextureDimensions, outputPixelFormat: MTLPixelFormat) -> MTIImage {
        __apply(toInputImages: toInputImages, parameters: parameters, outputTextureDimensions: outputTextureDimensions, outputPixelFormat: outputPixelFormat)
    }
}

extension Array where Element == MTIRenderCommand {
    
    public func makeImage(rasterSampleCount: Int = 1, dimension: MTITextureDimensions, pixelFormat: MTLPixelFormat = .unspecified) -> MTIImage {
        MTIRenderCommand.images(byPerforming: self, rasterSampleCount: UInt(rasterSampleCount), outputDescriptors: [MTIRenderPassOutputDescriptor(dimensions: dimension, pixelFormat: pixelFormat)]).first!
    }
    
    public func makeImages(rasterSampleCount: Int = 1, outputDescriptors: [MTIRenderPassOutputDescriptor]) -> [MTIImage] {
        MTIRenderCommand.images(byPerforming: self, rasterSampleCount: UInt(rasterSampleCount), outputDescriptors: outputDescriptors)
    }
}
