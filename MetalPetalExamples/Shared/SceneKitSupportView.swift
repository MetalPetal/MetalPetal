//
//  SceneKitSupportView.swift
//  MetalPetalDemo
//
//  Created by YuAo on 2021/4/5.
//

import Foundation
import SwiftUI
import MetalPetal

struct SceneKitSupportView: View {
    
    private class Renderer: ObservableObject {
        
        enum Effect: String, Identifiable, CaseIterable {
            case none = "No Filter"
            case grayscale = "Gray Scale"
            case colorHalftone = "Color Halftone"
            
            var id: String { rawValue }
            
            typealias Filter = (MTIImage) -> MTIImage
            
            func makeFilter() -> Filter {
                switch self {
                case .none:
                    return { image in image }
                case .grayscale:
                    return { image in image.adjusting(saturation: 0) }
                case .colorHalftone:
                    let filter = MTIColorHalftoneFilter()
                    filter.scale = 8
                    return { image in
                        filter.inputImage = image
                        return filter.outputImage!
                    }
                }
            }
        }
        
        private var filter: Effect.Filter = Effect.colorHalftone.makeFilter()

        @Published var effect: Effect = .colorHalftone {
            didSet {
                self.filter = effect.makeFilter()
            }
        }
        
        private let sceneRenderer: MTISCNSceneRenderer
        let renderContext: MTIContext
        
        init() {
            let device = MTLCreateSystemDefaultDevice()!
            renderContext = try! MTIContext(device: device)
            sceneRenderer = MTISCNSceneRenderer(device: device)
            
            // create a new scene
            let scene = SCNScene(named: "art.scnassets/ship.scn")!
            
            // create and add a camera to the scene
            let cameraNode = SCNNode()
            cameraNode.camera = SCNCamera()
            scene.rootNode.addChildNode(cameraNode)
            cameraNode.position = SCNVector3(x: 0, y: 2, z: 15)
            
            // create and add a light to the scene
            let lightNode = SCNNode()
            lightNode.light = SCNLight()
            lightNode.light!.type = .omni
            lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
            scene.rootNode.addChildNode(lightNode)
            
            // create and add an ambient light to the scene
            let ambientLightNode = SCNNode()
            ambientLightNode.light = SCNLight()
            ambientLightNode.light!.type = .ambient
            #if os(iOS)
            ambientLightNode.light!.color = UIColor.white
            #elseif os(macOS)
            ambientLightNode.light!.color = NSColor.white
            #endif
            scene.rootNode.addChildNode(ambientLightNode)
            
            // retrieve the ship node
            let ship = scene.rootNode.childNode(withName: "ship", recursively: true)!
            
            // animate the 3d object
            ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))
            
            // enable antialiasing
            self.sceneRenderer.antialiasingMode = .multisampling4X
            
            self.sceneRenderer.scene = scene
        }
        
        func snapshot(at time: TimeInterval, viewport: CGRect, convertsToSRGB: Bool) -> MTIImage {
            let sceneImage = sceneRenderer.snapshot(atTime: time, viewport: viewport, pixelFormat: .rgba8Unorm, isOpaque: false)
            if convertsToSRGB {
                return filter(MTIRGBColorSpaceConversionFilter.convert(sceneImage, from: .linear, to: .sRGB, alphaType: .nonPremultiplied))
            } else {
                return filter(sceneImage.unpremultiplyingAlpha())
            }
        }
    }
    
    @StateObject private var renderer: Renderer = Renderer()
    
    var body: some View {
        MetalKitView(device: renderer.renderContext.device) { view in
            let sceneImage = self.renderer.snapshot(at: CFAbsoluteTimeGetCurrent(), viewport: view.bounds, convertsToSRGB: true)
            let request = MTIDrawableRenderingRequest(drawableProvider: view, resizingMode: .aspect)
            do {
                try self.renderer.renderContext.render(sceneImage, toDrawableWithRequest: request)
            } catch {
                print(error)
            }
        }
        .overlay(VStack(alignment: .leading) {
            HStack(alignment: .top) {
                NoteView { noteContent }
                
                Picker(selection: $renderer.effect, label: Text(effectPickerLabel), content: {
                    ForEach(Renderer.Effect.allCases) { effect in
                        Text(effect.rawValue).tag(effect)
                    }
                })
                .pickerWidthLimit(180)
                .roundedRectangleButtonStyle()
                .largeControlSize()
                .pickerStyle(MenuPickerStyle())
                .animation(.none)
                Spacer()
            }
            Spacer()
        }.padding())
        .toolbar(content: { Spacer() })
        .inlineNavigationBarTitle("Working with SceneKit")
    }
    
    private var noteContent: Text = Text("This is an example of using ") + Text("MTISCNSceneRenderer").bold() + Text(" to create ") + Text("MTIImage").bold() + Text("s from a ") + Text("SCNScene").bold() + Text(" , then apply filters to the scene image. You can also render the scene image to a ") + Text("CVPixelBuffer").bold() + Text(" and record the scene using a ") + Text("MovieRecorder").bold() + Text(", similar to what the \"Camera\" demo does.")
    
    private var effectPickerLabel: String {
        #if os(iOS)
        return renderer.effect.rawValue
        #else
        return ""
        #endif
    }
}
