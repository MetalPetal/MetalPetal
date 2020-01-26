//
//  TripleBufferingViewController.swift
//  MetalPetalDemo
//
//  Created by Yu Ao on 2019/1/26.
//  Copyright © 2019 MetalPetal. All rights reserved.
//

import UIKit
import MetalPetal
import simd

struct ColoredVertex {
    var position: SIMD4<Float>
    var color: SIMD4<Float>
}

class ColoredVertices: NSObject, MTIGeometry {
    
    class BufferState {
        private(set) var isInflight: Bool = true
        
        func reclaimBuffer() {
            assert(isInflight == true)
            isInflight = false
            reclaimHandler()
        }
        
        private let reclaimHandler: () -> Void
        
        init(reclaimHandler: @escaping () -> Void) {
            self.reclaimHandler = reclaimHandler
        }
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    static let maximumInflightBuffers: Int = 3
    
    private let dataBuffers: [MTIDataBuffer]
    
    private let semaphore = DispatchSemaphore(value: ColoredVertices.maximumInflightBuffers)
    
    private var currentFrameIndex: Int = 0
    
    override init() {
        let vertex = ColoredVertex(position: .init(0, 0, 0, 1), color: .init(0, 0, 0, 0))
        var dataBuffers: [MTIDataBuffer] = []
        for _ in 0..<ColoredVertices.maximumInflightBuffers {
            dataBuffers.append(MTIDataBuffer(values: [ColoredVertex](repeating: vertex, count: 3))!)
        }
        self.dataBuffers = dataBuffers
        super.init()
    }
    
    func takeBuffer(_ block: (UnsafeMutableBufferPointer<ColoredVertex>) -> Void) -> BufferState {
        self.semaphore.wait()
        self.currentFrameIndex = (self.currentFrameIndex + 1) % ColoredVertices.maximumInflightBuffers;
        self.dataBuffers[self.currentFrameIndex].unsafeAccess { buffer in
            return block(buffer)
        }
        return BufferState(reclaimHandler: {
            self.semaphore.signal()
        })
    }
    
    func encodeDrawCall(with commandEncoder: MTLRenderCommandEncoder, context: MTIGeometryRenderingContext) {
        commandEncoder.setVertexBuffer(self.dataBuffers[self.currentFrameIndex].buffer(for: context.device)!, offset: 0, index: 0)
        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 36)
    }
}

class TripleBufferingViewController: UIViewController, MTKViewDelegate {
    
    private let context = try! MTIContext(device: MTLCreateSystemDefaultDevice()!)

    private weak var renderView: MTKView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let renderView = MTKView(frame: self.view.bounds, device: self.context.device)
        renderView.delegate = self
        renderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(renderView)
        self.renderView = renderView
    }
    
    private let geometry: ColoredVertices = ColoredVertices()
    
    private let kernel = MTIRenderPipelineKernel(
        vertexFunctionDescriptor: MTIFunctionDescriptor(name: "demoColoredVertex", libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main)),
        fragmentFunctionDescriptor: MTIFunctionDescriptor(name: "demoColoredFragment", libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main))
    )
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        let bufferState = self.geometry.takeBuffer { buffer in
            let ft = Float(abs(sin(CFAbsoluteTimeGetCurrent())))
            buffer[0].position = SIMD4<Float>(-ft, -ft, 0, 1)
            buffer[1].position = SIMD4<Float>(ft, -ft, 0, 1)
            buffer[2].position = SIMD4<Float>(0, ft, 0, 1)
            buffer[0].color = SIMD4<Float>(0, ft, ft, 1)
            buffer[1].color = SIMD4<Float>(ft, 0, ft, 1)
            buffer[2].color = SIMD4<Float>(ft, ft, 0, 1)
        }
        let renderCommand = MTIRenderCommand(kernel: self.kernel, geometry: self.geometry, images: [], parameters: [:])
        let outputDescriptor = MTIRenderPassOutputDescriptor(dimensions: MTITextureDimensions(width: 750, height: 750, depth: 1), pixelFormat: .bgra8Unorm, loadAction: .clear, storeAction: .store)
        let image = MTIRenderCommand.images(byPerforming: [renderCommand], outputDescriptors: [outputDescriptor]).first!
        do {
            let request = MTIDrawableRenderingRequest(drawableProvider: view, resizingMode: .aspect)
            try self.context.startTask(toRender: image, toDrawableWithRequest: request) { (task) in
                bufferState.reclaimBuffer()
            }
        } catch {
            bufferState.reclaimBuffer()
        }
    }
    
}
