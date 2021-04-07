//
//  CLAHEFilterView.swift
//  MetalPetalDemo
//
//  Created by YuAo on 2021/4/6.
//

import Foundation
import SwiftUI
import MetalPetal

struct CLAHEFilterView: View {
    @Environment(\.openURL) var openURL: OpenURLAction
    var body: some View {
        ImageFilterView(filter: MTICLAHEFilter(),
                        filterInputKeyPath: \.inputImage,
                        parameters: [
                            FilterParameter(name: "Clip Limit", defaultValue: 2, sliderRange: 0...4, updater: { filter, limit in
                                filter.clipLimit = limit
                            }),
                            FilterParameter(name: "Tile Grid Size", defaultValue: 8, sliderRange: 4...32, step: 1, updater: { filter, size in
                                filter.tileGridSize = MTICLAHESize(width: UInt(size), height: UInt(size))
                            })
                        ])
            .noteOverlay(NoteView({
                VStack(alignment: .leading, spacing: 6) {
                    Text("This is an example of \"Contrast Limited Adaptive Histogram Equalization\" filter.")
                    Button("More Information") { [openURL] in
                        openURL(URL(string: "https://github.com/YuAo/Accelerated-CLAHE")!)
                    }.linkButtonStyle()
                }
            }))
            .inlineNavigationBarTitle("CLAHE")
    }
}
