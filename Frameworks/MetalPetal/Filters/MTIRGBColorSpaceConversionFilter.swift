//
//  MTIRGBColorSpaceConversionFilter.swift
//  Pods
//
//  Created by YuAo on 2021/4/13.
//

import Foundation
import Metal

#if SWIFT_PACKAGE
import MetalPetalObjectiveC.Core
#endif

extension MTIRGBColorSpaceConversionFilter {
    public static func convert(_ image: MTIImage, from inputColorSpace: MTIRGBColorSpace, to outputColorSpace: MTIRGBColorSpace, alphaType: MTIAlphaType, pixelFormat: MTLPixelFormat = .unspecified) -> MTIImage {
        return MTIRGBColorSpaceConversionFilter.__image(byConverting: image, from: inputColorSpace, to: outputColorSpace, outputAlphaType: alphaType, outputPixelFormat: pixelFormat)
    }
}
