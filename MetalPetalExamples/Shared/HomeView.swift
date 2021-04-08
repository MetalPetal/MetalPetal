//
//  ContentView.swift
//  Shared
//
//  Created by YuAo on 2021/4/3.
//

import SwiftUI
import MetalPetal

struct HomeView: View {
    
    var body: some View {
        NavigationView {
            List {
                Group {
                    NavigationLink(destination: SimpleImageFilterView()) {
                        Text("Simple Image Filter")
                    }
                    NavigationLink(destination: SimpleImageFilterViewMTKDriven()) {
                        Text("Simple Image Filter (MTKView driven)")
                    }
                }
                Group {
                    NavigationLink(destination: CameraFilterView()) {
                        Text("Camera")
                    }
                    NavigationLink(destination: VideoProcessorView()) {
                        Text("Video Processing")
                    }
                }
                Group {
                    NavigationLink(destination: BlendModesView()) {
                        Text("Blend Modes")
                    }
                    NavigationLink(destination: BokehEffectView()) {
                        Text("Bokeh")
                    }
                    NavigationLink(destination: CLAHEFilterView()) {
                        Text("CLAHE")
                    }
                    NavigationLink(destination: GaussianBlurFilterView()) {
                        Text("MPS Gaussian Blur")
                    }
                    NavigationLink(destination: MultilayerCompositingFilterView()) {
                        Text("Multilayer Compositing")
                    }
                }
                NavigationLink(destination: SketchBoardView()) {
                    Text("Sketch Board")
                }
                NavigationLink(destination: SceneKitSupportView()) {
                    Text("Working with SceneKit")
                }
                NavigationLink(destination: BouncingBallsView()) {
                    Text("Particles")
                }
            }
            .groupedListStyle()
            .inlineNavigationBarTitle("MetalPetal Examples")
            
            VStack(spacing: 6) {
                Text("Welcome to MetalPetal examples.")
                Text("Select a topic to begin.").font(Font.caption).foregroundColor(.secondary)
            }.toolbar(content: { Spacer() })
        }
        .stackNavigationViewStyle()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .previewDevice("iPad (8th generation)")
    }
}
