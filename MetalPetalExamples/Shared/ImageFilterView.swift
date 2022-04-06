//
//  ImageFilterView.swift
//  MetalPetalDemo
//
//  Created by YuAo on 2021/4/5.
//

import Foundation
import MetalPetal
import SwiftUI
import VideoToolbox

struct FilterParameter<Filter> {
    var name: String
    var defaultValue: Float
    var sliderRange: ClosedRange<Float>
    var step: Float.Stride? = nil
    let updater: (Filter, Float) -> Void
}

extension FilterParameter: Identifiable {
    var id: String { name }
}

struct ImageFilterView<Filter>: View where Filter: MTIFilter {
    @State private var inputImage: MTIImage = DemoImages.p1040808
    @State private var values: [String: Float]
    @StateObject private var renderContext = try! MTIContext(device: MTLCreateSystemDefaultDevice()!)
        
    private let filter: Filter
    private let parameters: [FilterParameter<Filter>]
    private let filterInputKeyPath: ReferenceWritableKeyPath<Filter, MTIImage?>
    private let isChangingImageAllowed: Bool
    
    private let imageRenderer = PixelBufferPoolBackedImageRenderer()
    
    init(filter: Filter, filterInputKeyPath: ReferenceWritableKeyPath<Filter, MTIImage?>, parameters: [FilterParameter<Filter>], isChangingImageAllowed: Bool = true) {
        self.isChangingImageAllowed = isChangingImageAllowed
        self.filterInputKeyPath = filterInputKeyPath
        self.parameters = parameters
        self.filter = filter
        self.values = [:]
    }
    
    private func valueBinding<T>(for parameter: FilterParameter<T>) -> Binding<Float> {
        Binding<Float>(get: {
            values[parameter.name, default: parameter.defaultValue]
        }, set: {
            values[parameter.name] = $0
        })
    }
    
    private func filter(_ image: MTIImage?) throws -> CGImage {
        filter[keyPath: filterInputKeyPath] = image
        for parameter in parameters {
            parameter.updater(filter, values[parameter.name, default: parameter.defaultValue])
        }
        guard let outputImage = filter.outputImage else {
            throw DescriptiveError("Filter outputs nil image.")
        }
        return try self.imageRenderer.render(outputImage, using: renderContext).cgImage
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
                    VStack {
                        ForEach(parameters) { parameter in
                            VStack(alignment: .leading) {
                                Text("\(parameter.name) \(values[parameter.name, default: parameter.defaultValue], specifier: "%.2f")")
                                if let step = parameter.step {
                                    Slider(value: valueBinding(for: parameter), in: parameter.sliderRange, step: step, onEditingChanged: { _ in })
                                } else {
                                    Slider(value: valueBinding(for: parameter), in: parameter.sliderRange)
                                }
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10)
                                            .foregroundColor(Color.secondarySystemBackground))
                        }
                    }.padding()
                }
            case .failure(let error):
                Text(error.localizedDescription)
            }
        }
        .toolbar(content: {
            if isChangingImageAllowed {
                ImagePicker(title: "Choose Image", handler: { url in
                    if let image = ImageUtilities.loadUserPickedImage(from: url, requiresUnpremultipliedAlpha: true) {
                        self.inputImage = image
                    }
                })
            } else {
                Spacer()
            }
        })
    }
}
