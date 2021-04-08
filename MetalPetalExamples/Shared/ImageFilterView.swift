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

struct ImageFilterView<Filter>: View where Filter: MTIFilter {
    @State private var inputImage: MTIImage = DemoImages.p1040808
    @State private var values: [Float]
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
        var values: [Float] = []
        for parameter in parameters {
            values.append(parameter.defaultValue)
        }
        self._values = State<[Float]>(initialValue: values)
    }
    
    private func filter(_ image: MTIImage?) throws -> CGImage {
        filter[keyPath: filterInputKeyPath] = image
        for (index, value) in values.enumerated() {
            parameters[index].updater(filter, value)
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
                        ForEach(0..<parameters.count) { index in
                            VStack(alignment: .leading) {
                                Text("\(parameters[index].name) \(values[index], specifier: "%.2f")")
                                if let step = parameters[index].step {
                                    Slider(value: $values[index], in: parameters[index].sliderRange, step: step, onEditingChanged: { _ in })
                                } else {
                                    Slider(value: $values[index], in: parameters[index].sliderRange)
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
