//
//  VideoProcessorViewController.swift
//  MetalPetalDemo
//
//  Created by Yu Ao on 2019/12/19.
//  Copyright © 2019 MetalPetal. All rights reserved.
//

import UIKit
import AVKit
import MetalPetal
import MobileCoreServices
import VideoIO

@available(iOS 10.0, *)
class VideoProcessorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private var playerViewController: AVPlayerViewController? {
        return self.children.first as? AVPlayerViewController
    }
    
    private let player = AVPlayer()
    private var asset: AVAsset?
    private var videoComposition: VideoComposition<BlockBasedVideoCompositor>?
    private let context = try! MTIContext(device: MTLCreateSystemDefaultDevice()!)
    private let filter = MTIPixellateFilter()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.player.currentItem == nil {
            let imagePicker = UIImagePickerController()
            imagePicker.mediaTypes = [(kUTTypeMovie as String)]
            imagePicker.delegate = self
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.player.pause()
    }
    
    /// Preview
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let asset = AVURLAsset(url: info[.mediaURL] as! URL)
        
        let handler = MTIAsyncVideoCompositionRequestHandler(context: context, tracks: asset.tracks(withMediaType: .video)) { request in
            let scale = CGFloat(abs(sin(request.compositionTime.seconds))) * 32
            self.filter.scale = CGSize(width: scale, height: scale)
            return FilterGraph.makeImage { output in
                request.anySourceImage => self.filter => output
            }!
        }
        let composition = VideoComposition(propertiesOf: asset, compositionRequestHandler: handler.handle(request:))
        
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.videoComposition = composition.makeAVVideoComposition()
        self.player.replaceCurrentItem(with: playerItem)
        self.playerViewController?.player = self.player
        self.player.play()
        
        self.asset = asset
        self.videoComposition = composition
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /// Export
    private var exporter: AssetExportSession?
    @IBAction private func shareButtonTapped(_ sender: Any) {
        guard let asset = self.asset, let videoComposition = self.videoComposition else {
            return
        }
        self.playerViewController?.player?.pause()
        
        var textField: UITextField!
        let alertController = UIAlertController(title: NSLocalizedString("Exporting...", comment: ""), message: nil, preferredStyle: .alert)
        alertController.addTextField { tf in
            tf.isEnabled = false
            textField = tf
        }
        self.present(alertController, animated: true)
        let fileManager = FileManager()
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp.mp4")
        try? fileManager.removeItem(at: outputURL)
        
        var configuration = AssetExportSession.Configuration(videoSettings: .h264(videoSize: videoComposition.renderSize), audioSettings: .aac(channels: 2, sampleRate: 44100, bitRate: 128 * 1000))
        configuration.videoComposition = videoComposition.makeAVVideoComposition()
        let exporter = try! AssetExportSession(asset: asset, configuration: configuration, outputURL: outputURL)
        exporter.export(progress: { p in
            textField.text = p.localizedDescription
        }, completion: { error in
            self.dismiss(animated: true, completion: {
                if let error = error {
                    Alert(error: error, confirmActionTitle: "OK").show(in: self)
                } else {
                    let activityViewController = UIActivityViewController(activityItems: [outputURL], applicationActivities: nil)
                    self.present(activityViewController, animated: true, completion: nil)
                }
            })
        })
        self.exporter = exporter
    }
    
}
