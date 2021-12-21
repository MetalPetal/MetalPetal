//
//  BouncingBallsView.swift
//  MetalPetalDemo
//
//  Created by YuAo on 2021/4/4.
//

import Foundation
import SwiftUI
import MetalPetal

struct BouncingBallsView: View {
    
    static let numberOfParticles = 1024
    
    private class PointVertices: NSObject, MTIGeometry {
        func copy(with zone: NSZone? = nil) -> Any {
            return self
        }
        func encodeDrawCall(with commandEncoder: MTLRenderCommandEncoder, context: MTIGeometryRenderingContext) {
            commandEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: 1, instanceCount: BouncingBallsView.numberOfParticles)
        }
    }
    
    private static let computeKernel = MTIComputePipelineKernel(computeFunctionDescriptor: MTIFunctionDescriptor(name: "bouncingBallCompute", in: .main))
    private static let renderKernel = MTIRenderPipelineKernel(vertexFunctionDescriptor: MTIFunctionDescriptor(name: "bouncingBallVertex", in: .main), fragmentFunctionDescriptor: MTIFunctionDescriptor(name: "bouncingBallFragment", in: .main))

    @StateObject private var renderContext = try! MTIContext(device: MTLCreateSystemDefaultDevice()!)

    private class FrameDataBuffer: ObservableObject {
        @Published var buffer: MTIDataBuffer = FrameDataBuffer.makeBuffer()
        
        func reset() {
            self.buffer = FrameDataBuffer.makeBuffer()
        }
        
        private static func makeBuffer() -> MTIDataBuffer {
            var particles: [ParticleData] = []
            for _ in 0..<BouncingBallsView.numberOfParticles {
                particles.append(ParticleData(position: SIMD2<Float>(Float.random(in: 24...1000), Float.random(in: 24...400)), speed: .zero, size: Float.random(in: 8...36)))
            }
            return MTIDataBuffer(bytes: particles, length: UInt(MemoryLayout<ParticleData>.size * BouncingBallsView.numberOfParticles))!
        }
    }
    
    @StateObject private var frameDataBuffer: FrameDataBuffer = FrameDataBuffer()
    
    var body: some View {
        MetalKitView(device: renderContext.device) { view in
            let computeOutput = BouncingBallsView.computeKernel.apply(toInputImages: [],
                                                                      parameters: ["data": frameDataBuffer.buffer],
                                                    dispatchOptions: .init(threads: MTLSize(width: 1024, height: 1, depth: 1), threadgroups: MTLSize(width: 32, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: 32, height: 1, depth: 1)),
                                                    outputTextureDimensions: MTITextureDimensions(width: 1, height: 1, depth: 1),
                                                    outputPixelFormat: .unspecified)
            //There's no actual image data in computeOutput. It is used to build the dependency between the compute command and the render command.
            let renderCommand = MTIRenderCommand(kernel: BouncingBallsView.renderKernel, geometry: PointVertices(), images: [computeOutput], parameters: ["data": frameDataBuffer.buffer])
            let output = MTIRenderCommand.images(byPerforming: [renderCommand], outputDescriptors: [MTIRenderPassOutputDescriptor(dimensions: MTITextureDimensions(width: 1024, height: 1024, depth: 1), pixelFormat: .unspecified, clearColor: MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1), loadAction: .clear, storeAction: .store)])
            let request = MTIDrawableRenderingRequest(drawableProvider: view, resizingMode: .aspect)
            do {
                try self.renderContext.render(output[0], toDrawableWithRequest: request)
            } catch {
                print(error)
            }
        }.toolbar(content: {
            Button("Reset") { [frameDataBuffer] in
                frameDataBuffer.reset()
            }
        })
        .inlineNavigationBarTitle("Particles")
    }
}
