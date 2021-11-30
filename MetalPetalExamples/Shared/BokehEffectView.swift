//
//  BokehEffectView.swift
//  MetalPetalDemo
//
//  Created by YuAo on 2021/4/5.
//

import Foundation
import SwiftUI
import MetalPetal
import VideoToolbox

struct BokehEffectView: View {
    private let inputImage: MTIImage = DemoImages.p1
    private let inputDepthMask: MTIImage = DemoImages.p1DepthMask
    
    @State private var radius: Float = 10

    // For hexagonal filter
    @State private var brightness: Float = 0.5
    
    // For custom shape
    @State private var power: Float = 4.0
    @State private var backgroundBrightness: Float = 2.0
    
    enum BokehShape: Hashable, Identifiable {
        case hexagon
        case custom(String, MTIImage)
        
        var id: String {
            switch self {
            case .hexagon:
                return "Hexagon"
            case .custom(let name, _):
                return name
            }
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static let all: [BokehShape] = [
            .hexagon,
            .custom("Heart", DemoImages.makeSymbolAlphaMaskImage(named: "suit.heart.fill", aspectFitIn: CGSize(width: 64, height: 64))),
            .custom("Star", DemoImages.makeSymbolAlphaMaskImage(named: "star.fill", aspectFitIn: CGSize(width: 64, height: 64))),
            .custom("Circle", DemoImages.makeSymbolAlphaMaskImage(named: "circle.fill", aspectFitIn: CGSize(width: 64, height: 64))),
        ]
    }
    
    @State private var bokehShape: BokehShape = .hexagon
    
    @State private var showsNote: Bool = false

    @StateObject private var renderContext = try! MTIContext(device: MTLCreateSystemDefaultDevice()!)
    
    @Environment(\.openURL) var openURL: OpenURLAction
    
    private let imageRenderer = PixelBufferPoolBackedImageRenderer()
    
    private func applyFilter() throws -> CGImage {
        let outputImage: MTIImage
        switch self.bokehShape {
        case .hexagon:
            let bokeh = MTIHexagonalBokehBlurFilter()
            bokeh.inputImage = inputImage.withSamplerDescriptor(.defaultSamplerDescriptor(with: .clampToEdge))
            bokeh.inputMask = MTIMask(content: inputDepthMask, component: .red, mode: .oneMinusMaskValue)
            bokeh.brightness = brightness
            bokeh.radius = radius
            outputImage = bokeh.outputImage!
        case .custom(_, let kernelImage):
            outputImage = CustomShapeBokehWithMask.bokeh(image: inputImage, mask: inputDepthMask, kernelImage: kernelImage, kernelSize: Int(radius * 2), power: power, brightness: backgroundBrightness)
        }
        return try self.imageRenderer.render(outputImage, using: renderContext).cgImage
    }
    
    var body: some View {
        Group {
            switch Result(catching: {
                try applyFilter()
            }) {
            case .success(let image):
                VStack {
                    Image(cgImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    Picker(selection: $bokehShape, label: EmptyView(), content: {
                        ForEach(BokehShape.all) { shape in
                            Text(shape.id).tag(shape)
                        }
                    }).pickerStyle(SegmentedPickerStyle()).largeControlSize().padding([.leading, .trailing, .top])
                    switch bokehShape {
                    case .hexagon:
                        VStack {
                            VStack(alignment: .leading) {
                                Text("Radius \(radius, specifier: "%.2f")")
                                Slider(value: $radius, in: 0...20)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10)
                                            .foregroundColor(Color.secondarySystemBackground))
                            VStack(alignment: .leading) {
                                Text("Brightness \(brightness, specifier: "%.2f")")
                                Slider(value: $brightness, in: 0...1)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10)
                                            .foregroundColor(Color.secondarySystemBackground))
                        }.padding()
                    case .custom:
                        VStack {
                            VStack(alignment: .leading) {
                                Text("Radius \(radius, specifier: "%.2f")")
                                Slider(value: $radius, in: 0...20)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10)
                                            .foregroundColor(Color.secondarySystemBackground))
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Brightness \(backgroundBrightness, specifier: "%.2f")")
                                    Slider(value: $backgroundBrightness, in: 1...5)
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 10)
                                                .foregroundColor(Color.secondarySystemBackground))
                                VStack(alignment: .leading) {
                                    Text("Power \(power, specifier: "%.2f")")
                                    Slider(value: $power, in: 1...10)
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 10)
                                                .foregroundColor(Color.secondarySystemBackground))
                            }
                        }.padding()
                    }
                }
            case .failure(let error):
                Text(error.localizedDescription)
            }
        }
        .noteOverlay(NoteView {
            VStack(alignment: .leading, spacing: 6) {
                Text("This is an example of applying various bokeh effects to the input image with a depth mask.")
                HStack {
                    VStack {
                        Image(cgImage: DemoImages.cgImage(named: "P1.jpg")).resizable().aspectRatio(contentMode: .fit)
                        Text("Image").font(Font.caption).foregroundColor(.secondary)
                    }
                    VStack {
                        Image(cgImage: DemoImages.cgImage(named: "P1_depth.jpg")).resizable().aspectRatio(contentMode: .fit)
                        Text("Depth Mask").font(Font.caption).foregroundColor(.secondary)
                    }
                }.frame(height: 128)
                Text("The hexagon shape bokeh blur effect comes from a bulit-in filter - MTIHexagonalBokehBlurFilter.")
                Button("Hexagonal Bokeh Blur") { [openURL] in
                    openURL(URL(string: "https://github.com/YuAo/HexagonalBokehBlur")!)
                }.linkButtonStyle()
                Text("Other bokeh effects are implemented in the example project using straight forward image convolution.")
                Button("Close") { [$showsNote] in
                    $showsNote.wrappedValue.toggle()
                }.linkButtonStyle()
            }
        }, isHidden: !showsNote)
        .toolbar(content: {
            Button(action: { [$showsNote] in
                $showsNote.wrappedValue.toggle()
            }, label: {
                Image(systemName: "info.circle")
            })
        })
        .inlineNavigationBarTitle("Bokeh")
    }
}


struct CustomShapeBokehWithMask {
    private static let powKernel = MTIRenderPipelineKernel(vertexFunctionDescriptor: .passthroughVertex, fragmentFunctionDescriptor: MTIFunctionDescriptor(name: "imagePow", in: .main))
    private static func pow(_ image: MTIImage, _ value: Float) -> MTIImage {
        powKernel.apply(to: [image], parameters: ["value": value], outputDimensions: image.dimensions, outputPixelFormat: .rgba32Float)
    }
    private static let convolutionKernel = MTIRenderPipelineKernel(vertexFunctionDescriptor: .passthroughVertex, fragmentFunctionDescriptor: MTIFunctionDescriptor(name: "imageConvolution", in: .main))
    private static func applyImageConvolution(to image: MTIImage, mask: MTIImage, kernelSize: Int, kernelImage: MTIImage, brightness: Float = 1.0) -> MTIImage {
        return convolutionKernel.apply(to: [image, mask, kernelImage], parameters: ["radius": kernelSize/2, "brightness": brightness], outputDimensions: image.dimensions, outputPixelFormat: .rgba32Float)
    }
    static func bokeh(image: MTIImage, mask: MTIImage, kernelImage: MTIImage, kernelSize: Int, power: Float, brightness: Float) -> MTIImage {
        let powered = pow(image, power)
        let bokehImage = applyImageConvolution(to: powered, mask: mask, kernelSize: kernelSize, kernelImage: kernelImage, brightness: brightness)
        let outputImage = pow(bokehImage, 1.0/power)
        return outputImage
    }
}
