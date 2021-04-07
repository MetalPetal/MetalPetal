//
//  MetalKitView.swift
//  MetalPetalDemo
//
//  Created by YuAo on 2021/4/3.
//

import Foundation
import SwiftUI
import MetalKit
import MetalPetal

#if os(iOS)
fileprivate typealias ViewRepresentable = UIViewRepresentable
#elseif os(macOS)
fileprivate typealias ViewRepresentable = NSViewRepresentable
#endif

struct MetalKitView: ViewRepresentable {
    
    typealias ViewUpdater = (MTKView) -> Void
    
    private let viewUpdater: ViewUpdater
    private let device: MTLDevice

    init(device: MTLDevice, viewUpdater: @escaping ViewUpdater) {
        self.viewUpdater = viewUpdater
        self.device = device
    }
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.delegate = context.coordinator
        mtkView.autoResizeDrawable = true
        mtkView.colorPixelFormat = .bgra8Unorm
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        
    }
    
    func makeNSView(context: Context) -> MTKView {
        makeUIView(context: context)
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        updateUIView(nsView, context: context)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewUpdater: self.viewUpdater)
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        private let viewUpdater: ViewUpdater
        
        init(viewUpdater: @escaping ViewUpdater) {
            self.viewUpdater = viewUpdater
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            
        }
        
        func draw(in view: MTKView) {
            viewUpdater(view)
        }
    }
}
