//
//  MTIPixelFormat.swift
//  Pods
//
//  Created by Yu Ao on 2018/11/8.
//

import Metal

#if SWIFT_PACKAGE
import MetalPetalObjectiveC.Core
#endif

extension MTLPixelFormat {
    public static let unspecified = MTLPixelFormat.invalid
    public static let yCbCr8_420_2p = __MTIPixelFormatYCBCR8_420_2P
    public static let yCbCr8_420_2p_srgb = __MTIPixelFormatYCBCR8_420_2P_sRGB
}
