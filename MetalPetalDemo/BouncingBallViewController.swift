//
//  BouncingBallViewController.swift
//  MetalPetalDemo
//
//  Created by YuAo on 2020/8/16.
//  Copyright © 2020 MetalPetal. All rights reserved.
//

import Foundation
import UIKit
import MetalPetal

class BouncingBallViewController: UIViewController {
    @IBOutlet private weak var imageView: MTIImageView!
    
    private weak var displayLink: CADisplayLink?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.displayLink?.invalidate()
        let displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.displayLink?.invalidate()
        self.displayLink = nil
    }
    
    private var frameDataBuffer: MTIDataBuffer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.clearColor = MTLClearColorMake(1, 1, 1, 1)
        let numberOfParticles = 512
        var particles: [ParticleData] = []
        for _ in 0..<numberOfParticles {
            particles.append(ParticleData(position: SIMD2<Float>(Float.random(in: 24...1000), Float.random(in: 24...400)), speed: .zero, size: Float.random(in: 12...36)))
        }
        self.frameDataBuffer = MTIDataBuffer(bytes: particles, length: UInt(MemoryLayout<ParticleData>.size * numberOfParticles))

    }
    
    class PointVertices: NSObject, MTIGeometry {
        func copy(with zone: NSZone? = nil) -> Any {
            return self
        }
        func encodeDrawCall(with commandEncoder: MTLRenderCommandEncoder, context: MTIGeometryRenderingContext) {
            commandEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: 1, instanceCount: 512)
        }
    }
    
    private let computeKernel = MTIComputePipelineKernel(computeFunctionDescriptor: MTIFunctionDescriptor(name: "bouncingBallCompute", libraryURL: URL.defaultMetalLibraryURL(for: .main)))
    private let renderKernel = MTIRenderPipelineKernel(vertexFunctionDescriptor: MTIFunctionDescriptor(name: "bouncingBallVertex", libraryURL: URL.defaultMetalLibraryURL(for: .main)), fragmentFunctionDescriptor: MTIFunctionDescriptor(name: "bouncingBallFragment", libraryURL: URL.defaultMetalLibraryURL(for: .main)))
    
    @objc private func tick(_ sender: CADisplayLink) {
        let computeOutput = computeKernel.apply(toInputImages: [],
                                                parameters: ["data": frameDataBuffer!],
                                                dispatchOptions: .init(threads: MTLSize(width: 512, height: 1, depth: 1), threadgroups: MTLSize(width: 16, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: 32, height: 1, depth: 1)),
                                                outputTextureDimensions: MTITextureDimensions(width: 1, height: 1, depth: 1),
                                                outputPixelFormat: .unspecified)
        //There's no actual image data in computeOutput. It is used to build the dependency between the compute command and the render command.
        let renderCommand = MTIRenderCommand(kernel: renderKernel, geometry: PointVertices(), images: [computeOutput], parameters: ["data": frameDataBuffer!])
        let output = MTIRenderCommand.images(byPerforming: [renderCommand], outputDescriptors: [MTIRenderPassOutputDescriptor(dimensions: MTITextureDimensions(width: 1024, height: 1024, depth: 1), pixelFormat: .unspecified, clearColor: MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1), loadAction: .clear, storeAction: .store)])
        self.imageView.image = output.first
    }
    
}
