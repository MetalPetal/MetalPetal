//
//  VideoProcessorView.swift
//  MetalPetalDemo
//
//  Created by YuAo on 2021/4/4.
//

import Foundation
import SwiftUI
import AVFoundation
import AVKit
import MetalPetal

struct VideoProcessorView: View {
    @State private var videoURL: URL?
    @State private var videoPlayer: AVPlayer?

    @StateObject private var renderContext = try! MTIContext(device: MTLCreateSystemDefaultDevice()!)

    var body: some View {
        Group {
            if let videoPlayer = videoPlayer {
                VideoPlayer(player: videoPlayer).toolbar(content: {
                    videoPicker
                })
            } else {
                videoPicker
                    .roundedRectangleButtonStyle()
                    .largeControlSize()
                    .toolbar(content: { Spacer() })
            }
        }
        .inlineNavigationBarTitle("Video Processing")
    }
    
    private func renderVideo(at url: URL) {
        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        let presentationSize = asset.presentationVideoSize ?? CGSize(width: 720, height: 720)
        
        let pixellateFilter = MTIPixellateFilter()
        let grayScaleFilter = MTISaturationFilter()
        grayScaleFilter.saturation = 0
        let dotScreenFilter = MTIDotScreenFilter()
        let blendWithMaskFilter = MTIBlendWithMaskFilter()
        blendWithMaskFilter.inputMask = MTIMask(content: RadialGradientImage.makeImage(size: presentationSize))
        
        let watermarkFilter = MultilayerCompositingFilter()
        let whiteSquare = MTIImage.white.resized(to: CGSize(width: presentationSize.width/10, height: presentationSize.width/10))!
        let roundCornerFilter = MTIRoundCornerFilter()
        roundCornerFilter.cornerRadius = MTICornerRadius(all: Float(whiteSquare.size.width/4))
        roundCornerFilter.cornerCurve = .continuous
        roundCornerFilter.inputImage = whiteSquare
        let watermarkImage = roundCornerFilter.outputImage!.withCachePolicy(.persistent)
        let mask = DemoImages.makeSymbolImage(named: "seal.fill", aspectFitIn: whiteSquare.size, padding: whiteSquare.size.width/10)
        let watermarkMaskImage = mask
        let watermarkMaskTransformFilter = MTITransformFilter()
        watermarkMaskTransformFilter.inputImage = watermarkMaskImage
        
        let videoComposition = MTIVideoComposition(asset: asset, context: renderContext, queue: DispatchQueue.main, filter: { request in
            watermarkMaskTransformFilter.transform = CATransform3DMakeRotation(CGFloat(request.compositionTime.seconds), 0, 0, 1)
            let pixellateScale = mix(SIMD2<Float>(50,50), SIMD2<Float>(1,1), t: min(Float(request.compositionTime.seconds), 1))
            pixellateFilter.scale.width = CGFloat(pixellateScale.x)
            pixellateFilter.scale.height = CGFloat(pixellateScale.y)
            watermarkFilter.layers = [MultilayerCompositingFilter.Layer(content: watermarkImage)
                                        .blendMode(.normal)
                                        .frame(CGRect(x: request.anySourceImage.size.width - watermarkImage.size.width - 16,
                                                      y: request.anySourceImage.size.height - watermarkImage.size.height - 16,
                                                      width: watermarkImage.size.width,
                                                      height: watermarkImage.size.height),
                                               layoutUnit: .pixel)
                                        .mask(MTIMask(content: watermarkMaskTransformFilter.outputImage!, component: .alpha, mode: .oneMinusMaskValue))]
            
            return FilterGraph.makeImage(builder: { output in
                request.anySourceImage => blendWithMaskFilter.inputPorts.inputImage
                request.anySourceImage => grayScaleFilter => dotScreenFilter => blendWithMaskFilter.inputPorts.inputBackgroundImage
                blendWithMaskFilter => pixellateFilter => watermarkFilter.inputPorts.inputBackgroundImage
                watermarkFilter => output
            })!
        })
        let playerItem = AVPlayerItem(url: url)
        playerItem.videoComposition = videoComposition.makeAVVideoComposition()
        self.videoPlayer = AVPlayer(playerItem: playerItem)
        self.videoPlayer?.play()
    }
    
    private var videoPicker: some View {
        VideoPicker(title: "Choose Video") { url in
            self.videoURL = url
            self.renderVideo(at: url)
        }
    }
}
