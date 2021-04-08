//
//  GaussianBlurFilterView.swift
//  MetalPetalDemo
//
//  Created by YuAo on 2021/4/6.
//

import Foundation
import SwiftUI
import MetalPetal

struct GaussianBlurFilterView: View {
    var body: some View {
        ImageFilterView(filter: MTIMPSGaussianBlurFilter(),
                        filterInputKeyPath: \.inputImage,
                        parameters: [
                            FilterParameter(name: "Radius", defaultValue: 20, sliderRange: 0...100, updater: { filter, radius in
                                filter.radius = radius
                            })
                        ])
            .inlineNavigationBarTitle("MPS Gaussian Blur")
    }
}
