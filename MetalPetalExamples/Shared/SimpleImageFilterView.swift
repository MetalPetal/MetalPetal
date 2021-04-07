//
//  SimpleImageFilterView.swift
//  MetalPetalDemo
//
//  Created by YuAo on 2021/4/3.
//

import Foundation
import SwiftUI
import MetalPetal

struct SimpleImageFilterView: View {
    
    @State private var inputImage: MTIImage = DemoImages.p1040808
    @State private var saturation: Float = 1
    
    @StateObject private var renderContext = try! MTIContext(device: MTLCreateSystemDefaultDevice()!)

    private func filter(_ image: MTIImage) throws -> CGImage {
        let filteredImage = image.adjusting(saturation: saturation)
        let cgImage = try self.renderContext.makeCGImage(from: filteredImage)
        return cgImage
    }
    
    var body: some View {
        Group {
            switch Result(catching: {
                try filter(inputImage)
            }) {
            case .success(let image):
                VStack {
                    Image(cgImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    VStack(alignment: .leading) {
                        Text("Saturation \(saturation, specifier: "%.2f")")
                        Slider(value: $saturation, in: 0...2)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10)
                                            .foregroundColor(Color.secondarySystemBackground))
                    .padding()
                }
            case .failure(let error):
                Text(error.localizedDescription)
            }
        }
        .toolbar(content: {
            ImagePicker(title: "Choose Image", handler: { url in
                if let image = ImageUtilities.loadUserPickedImage(from: url, requiresUnpremultipliedAlpha: true) {
                    self.inputImage = image
                }
            })
        })
        .inlineNavigationBarTitle("Simple Filter")
    }
}

struct SimpleImageFilterViewMTKDriven: View {
    private let image: MTIImage = DemoImages.p1040808
    @StateObject private var renderContext: MTIContext = try! MTIContext(device: MTLCreateSystemDefaultDevice()!)

    var body: some View {
        MetalKitView(device: renderContext.device) { view in
            let filteredImage = image.adjusting(saturation: 1.0 + Float(sin(CFAbsoluteTimeGetCurrent() * 2.0)))
            let request = MTIDrawableRenderingRequest(drawableProvider: view, resizingMode: .aspect)
            do {
                try self.renderContext.render(filteredImage, toDrawableWithRequest: request)
            } catch {
                print(error)
            }
        }
        .toolbar(content: { Spacer() })
        .inlineNavigationBarTitle("Simple Filter")
    }
}
