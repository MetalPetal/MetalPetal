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
import VideoIO

struct VideoProcessorView: View {
    
    class VideoProcessor: ObservableObject {
        @Published var videoPlayer: AVPlayer?
     
        private var videoComposition: MTIVideoComposition?
        private var videoAsset: AVAsset?
        
        private let renderContext = try! MTIContext(device: MTLCreateSystemDefaultDevice()!)
        
        private var exportSession: AssetExportSession?
        
        @Published var exportProgress: Progress?
        
        func updateVideoURL(_ url: URL) {
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
            roundCornerFilter.cornerRadius = MTICornerRadius(Float(whiteSquare.size.width/4))
            roundCornerFilter.cornerCurve = .continuous
            roundCornerFilter.inputImage = whiteSquare
            let watermarkImage = roundCornerFilter.outputImage!.withCachePolicy(.persistent)
            let mask = DemoImages.makeSymbolImage(named: "seal.fill", aspectFitIn: whiteSquare.size, padding: whiteSquare.size.width/10)
            let watermarkMaskImage = mask
            let watermarkMaskTransformFilter = MTITransformFilter()
            watermarkMaskTransformFilter.inputImage = watermarkMaskImage
            
            let videoComposition = MTIVideoComposition(asset: asset, context: renderContext, queue: DispatchQueue.main, filter: { request in
                guard let sourceImage = request.anySourceImage else {
                    return MTIImage.black
                }
                watermarkMaskTransformFilter.transform = CATransform3DMakeRotation(CGFloat(request.compositionTime.seconds), 0, 0, 1)
                let pixellateScale = mix(SIMD2<Float>(50,50), SIMD2<Float>(1,1), t: min(Float(request.compositionTime.seconds), 1))
                pixellateFilter.scale.width = CGFloat(pixellateScale.x)
                pixellateFilter.scale.height = CGFloat(pixellateScale.y)
                watermarkFilter.layers = [MultilayerCompositingFilter.Layer(content: watermarkImage)
                                            .blendMode(.normal)
                                            .frame(CGRect(x: sourceImage.size.width - watermarkImage.size.width - 16,
                                                          y: sourceImage.size.height - watermarkImage.size.height - 16,
                                                          width: watermarkImage.size.width,
                                                          height: watermarkImage.size.height),
                                                   layoutUnit: .pixel)
                                            .mask(MTIMask(content: watermarkMaskTransformFilter.outputImage!, component: .alpha, mode: .oneMinusMaskValue))]
                
                return FilterGraph.makeImage(builder: { output in
                    sourceImage => blendWithMaskFilter.inputPorts.inputImage
                    sourceImage => grayScaleFilter => dotScreenFilter => blendWithMaskFilter.inputPorts.inputBackgroundImage
                    blendWithMaskFilter => pixellateFilter => watermarkFilter.inputPorts.inputBackgroundImage
                    watermarkFilter => output
                })!
            })
            let playerItem = AVPlayerItem(asset: asset)
            playerItem.videoComposition = videoComposition.makeAVVideoComposition()
            self.videoComposition = videoComposition
            videoAsset = asset
            videoPlayer = AVPlayer(playerItem: playerItem)
            videoPlayer?.play()
        }
        
        func export(completion: @escaping (Result<URL, Error>) -> Void) {
            guard let asset = self.videoAsset, let videoComposition = self.videoComposition else {
                return
            }
            exportProgress = nil
            exportSession?.cancel()
            exportSession = nil
            
            var configuration = AssetExportSession.Configuration(fileType: .mp4, videoSettings: .h264(videoSize: videoComposition.renderSize), audioSettings: .aac(channels: 2, sampleRate: 44100, bitRate: 128 * 1000))
            configuration.videoComposition = videoComposition.makeAVVideoComposition()
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
            do {
                let exportSession = try AssetExportSession(asset: asset, outputURL: outputURL, configuration: configuration)
                exportSession.export(progress: { [weak self] progress in
                    self?.exportProgress = progress
                }, completion: { [weak self] error in
                    self?.exportProgress = nil
                    self?.exportSession = nil
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(outputURL))
                    }
                })
                self.exportSession = exportSession
            } catch {
                completion(.failure(error))
            }
        }
        
        deinit {
            exportSession?.cancel()
        }
    }
    
    @StateObject private var videoProcessor = VideoProcessor()

    var body: some View {
        Group {
            if let videoPlayer = videoProcessor.videoPlayer {
                VideoPlayer(player: videoPlayer).toolbar(content: {
                    if let progress = self.videoProcessor.exportProgress {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Exporting...").font(.footnote).foregroundColor(.secondary)
                            ProgressView(value: progress.fractionCompleted).progressViewStyle(LinearProgressViewStyle()).frame(width: 72).smallControlSize()
                        }
                    } else {
                        Button("Export", action: { [videoProcessor] in
                            videoProcessor.export { result in
                                switch result {
                                case .success(let outputURL):
                                    #if os(macOS)
                                    let savePanel = NSSavePanel()
                                    savePanel.nameFieldStringValue = "video." + outputURL.pathExtension
                                    if savePanel.runModal() == .OK, let url = savePanel.url {
                                        do {
                                            try? FileManager.default.removeItem(at: url)
                                            try FileManager.default.moveItem(at: outputURL, to: url)
                                        } catch {
                                            VideoProcessorView.showErrorAlert(error: error)
                                        }
                                    } else {
                                        try? FileManager.default.removeItem(at: outputURL)
                                    }
                                    #else
                                    //For demo purpose only. This is not the best practice of presenting an UIActivityViewController in SwiftUI.
                                    let activityViewController = UIActivityViewController(activityItems: [outputURL], applicationActivities: nil)
                                    activityViewController.completionWithItemsHandler = { _,_,_,_ in
                                        try? FileManager.default.removeItem(at: outputURL)
                                    }
                                    UIApplication.shared.topMostViewController?.present(activityViewController, animated: true, completion: nil)
                                    #endif
                                case .failure(let error):
                                    VideoProcessorView.showErrorAlert(error: error)
                                }
                            }
                        })
                    }
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
    
    private var videoPicker: some View {
        VideoPicker(title: "Choose Video") { url in
            self.videoProcessor.updateVideoURL(url)
        }
    }
    
    private static func showErrorAlert(error: Error) {
        #if os(macOS)
        NSAlert(error: error).runModal()
        #elseif os(iOS)
        //For demo purpose only. This is not the best practice of presenting an alert in SwiftUI.
        let alertController = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        UIApplication.shared.topMostViewController?.present(alertController, animated: true, completion: nil)
        #endif
    }
}
