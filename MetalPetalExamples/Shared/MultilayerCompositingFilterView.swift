//
//  MultilayerCompositingFilterView.swift
//  MetalPetalDemo
//
//  Created by YuAo on 2021/4/6.
//

import Foundation
import SwiftUI
import MetalPetal

struct MultilayerCompositingFilterView: View {
    static let grayScaleBlendMode: MTIBlendMode = {
        let mode = MTIBlendMode(String(#fileID) + String("\(#line)"))
        MTIBlendModes.registerBlendMode(mode, with: MTIBlendFunctionDescriptors(blendFormula: """
            float4 blend(float4 backdrop, float4 source) {
                return float4(
                    mix(backdrop.rgb, dot(backdrop.rgb, float3(0.299, 0.587, 0.114)), source.a),
                    backdrop.a
                );
            }
            """))
        return mode
    }()
    
    var body: some View {
        ImageFilterView(filter: { () -> MultilayerCompositingFilter in
            let filter = MultilayerCompositingFilter()
            filter.layers = [
                // layers with tint color
                MultilayerCompositingFilter.Layer(content: DemoImages.makeSymbolImage(named: "triangle.circle", aspectFitIn: CGSize(width: 120, height: 120)))
                    .tintColor(MTIColor(red: 54/255.0, green: 207/255.0, blue: 150/255.0, alpha: 1))
                    .frame(CGRect(x: 16 + (120 + 16) * 0, y: 16, width: 120, height: 120), layoutUnit: .pixel),
                MultilayerCompositingFilter.Layer(content: DemoImages.makeSymbolImage(named: "circle.circle", aspectFitIn: CGSize(width: 120, height: 120)))
                    .tintColor(MTIColor(red: 213/255.0, green: 50/255.0, blue: 50/255.0, alpha: 1))
                    .frame(CGRect(x: 16 + (120 + 16) * 1, y: 16, width: 120, height: 120), layoutUnit: .pixel),
                MultilayerCompositingFilter.Layer(content: DemoImages.makeSymbolImage(named: "xmark.circle", aspectFitIn: CGSize(width: 120, height: 120)))
                    .tintColor(MTIColor(red: 105/255.0, green: 133/255.0, blue: 197/255.0, alpha: 1))
                    .frame(CGRect(x: 16 + (120 + 16) * 2, y: 16, width: 120, height: 120), layoutUnit: .pixel),
                MultilayerCompositingFilter.Layer(content: DemoImages.makeSymbolImage(named: "square.circle", aspectFitIn: CGSize(width: 120, height: 120)))
                    .tintColor(MTIColor(red: 212/255.0, green: 104/255.0, blue: 190/255.0, alpha: 1))
                    .frame(CGRect(x: 16 + (120 + 16) * 3, y: 16, width: 120, height: 120), layoutUnit: .pixel),
                
                //layer with blend mode
                // index 4
                MultilayerCompositingFilter.Layer(content: DemoImages.makeSymbolImage(named: "sparkles", aspectFitIn: CGSize(width: 120, height: 120)))
                    .tintColor(MTIColor(red: 210/255.0, green: 180/255.0, blue: 40/255.0, alpha: 1))
                    .frame(CGRect(x: 56, y: 1080 - 16 - 120, width: 120, height: 120), layoutUnit: .pixel)
                    .blendMode(.hardLight),
                
                // index 5
                // layer with compositing mask and color lookup blend mode
                MultilayerCompositingFilter.Layer(content: DemoImages.colorLookupTable)
                    .frame(CGRect(x: 0, y: 0, width: 1, height: 1), layoutUnit: .fractionOfBackgroundSize)
                    .compositingMask(MTIMask(content: DemoImages.makeSymbolImage(named: "diamond.fill", aspectFitIn: CGSize(width: 1080, height: 1920), padding: 96), component: .alpha, mode: .normal))
                    .blendMode(.colorLookup512x512),
                
                // index 6
                //layer with custom blend mode
                MultilayerCompositingFilter.Layer(content: DemoImages.makeSymbolImage(named: "drop.fill", aspectFitIn: CGSize(width: 180, height: 180)))
                    .frame(center: CGPoint(x: 0.5, y: 0.5), size: CGSize(width: 0.18, height: 0.32), layoutUnit: .fractionOfBackgroundSize)
                    .blendMode(MultilayerCompositingFilterView.grayScaleBlendMode),
                
                //layer with content region and mask
                MultilayerCompositingFilter.Layer(content: DemoImages.p1DepthMask)
                    .contentRegion(MTIMakeRect(aspectRatio: CGSize(width: 1, height: 1), insideRect: DemoImages.p1DepthMask.extent))
                    .frame(CGRect(x: 1920 - 240 - 16, y: 16, width: 240, height: 240), layoutUnit: .pixel)
                    .mask(MTIMask(content: DemoImages.makeSymbolImage(named: "hexagon.fill", aspectFitIn: CGSize(width: 240, height: 240)), component: .alpha, mode: .normal)),
                
                //bottom right layers
                MultilayerCompositingFilter.Layer(content: DemoImages.makeSymbolImage(named: "capsule.fill", aspectFitIn: CGSize(width: 180, height: 120)))
                    .frame(CGRect(x: 1920 - 180 - 16, y: 1080 - 120 - 16, width: 180, height: 120), layoutUnit: .pixel)
                    .tintColor(.white),
                MultilayerCompositingFilter.Layer(content: DemoImages.makeSymbolImage(named: "leaf.fill", aspectFitIn: CGSize(width: 180, height: 120), padding: 32))
                    .frame(CGRect(x: 1920 - 180 - 16, y: 1080 - 120 - 16, width: 180, height: 120), layoutUnit: .pixel)
                    .tintColor(MTIColor(red: 0.1, green: 0.9, blue: 0.1, alpha: 0.5))
            ]
            return filter
        }(),
        filterInputKeyPath: \.inputBackgroundImage,
        parameters: [
            FilterParameter(name: "Sparkles Rotation", defaultValue: 0, sliderRange: 0...(.pi * 2), updater: { filter, rotation in
                filter.layers[4] = filter.layers[4].rotation(rotation)
            }),
            FilterParameter(name: "Color Lookup Intensity", defaultValue: 1, sliderRange: 0...1, updater: { filter, intensity in
                filter.layers[5] = filter.layers[5].opacity(intensity)
            }),
            FilterParameter(name: "Gray Scale Blend Intensity", defaultValue: 1, sliderRange: 0...1, updater: { filter, intensity in
                filter.layers[6] = filter.layers[6].opacity(intensity)
            })
        ],
        isChangingImageAllowed: false)
        .inlineNavigationBarTitle("Multilayer Compositing")
    }
}
