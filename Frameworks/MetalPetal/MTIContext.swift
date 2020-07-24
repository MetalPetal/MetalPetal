//
//  MTIContext.swift
//  MetalPetal
//
//  Created by YuAo on 2020/7/24.
//

import Foundation

#if SWIFT_PACKAGE
import MetalPetalObjectiveC.Core
#endif

extension MTIContext {
    public func startTaskToCreateCGImage(from image: MTIImage, colorSpace: CGColorSpace? = nil, completion: ((MTIRenderTask) -> Void)? = nil) throws -> (image: CGImage, task: MTIRenderTask) {
        var outputCGImage: CGImage?
        let task = try self.startTask(toCreate: &outputCGImage, from: image, colorSpace: colorSpace, completion: completion)
        return (outputCGImage!, task)
    }
}
