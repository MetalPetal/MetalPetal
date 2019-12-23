//
//  CameraViewControllerV2.swift
//  MetalPetalDemo
//
//  Created by yinglun on 2019/12/23.
//  Copyright © 2019 MetalPetal. All rights reserved.
//

import UIKit
import MetalPetal
import VideoIO
import AVKit

class CameraViewController: UIViewController {
    
    private let folderName = "videos"
    
    private var camera: Camera?
    private let videoQueue = DispatchQueue(label: "com.metalpetal.MetalPetalDemo.videoCallback")
    
    private var recorder: MovieRecorder?
    private var isRecording = false
    
    private var pixelBufferPool: MTICVPixelBufferPool?
    
    private var renderView: MTIImageView!

    private var context = try! MTIContext(device: MTLCreateSystemDefaultDevice()!)
    
    private var currentVideoURL: URL?
    
    private var isFilterEnabled = true
    
    private let colorLookupFilter: MTIColorLookupFilter = {
        let filter = MTIColorLookupFilter()
        filter.inputColorLookupTable = MTIImage(cgImage: UIImage(named: "ColorLookup512")!.cgImage!, options: [.SRGB: false], isOpaque: true)
        return filter
    }()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let path = "\(NSTemporaryDirectory())/\(folderName)"
        let fileManager = FileManager()
        try? fileManager.removeItem(atPath: path)
        
        do {
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("\(error)")
        }
        
        renderView = MTIImageView(frame: view.bounds)
        renderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(renderView, at: 0)
        
        pixelBufferPool = try? MTICVPixelBufferPool(pixelBufferWidth: 1080, pixelBufferHeight: 1920, pixelFormatType: kCVPixelFormatType_32BGRA, minimumBufferCount: 30)
        
        camera = Camera(captureSessionPreset: .hd1920x1080)
        try? camera?.enableVideoDataOutput(on: self.videoQueue, bufferOutputCallback: { [weak self] sampleBuffer in
            guard let strongSelf = self else { return }
            guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer), CMFormatDescriptionGetMediaType(formatDescription) == kCMMediaType_Video, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }
            var outputSampleBuffer = sampleBuffer
            let inputImage = MTIImage(cvPixelBuffer: pixelBuffer, alphaType: .alphaIsOne)
            var outputImage = inputImage
            if strongSelf.isFilterEnabled {
                strongSelf.colorLookupFilter.inputImage = inputImage
                if let image = strongSelf.colorLookupFilter.outputImage?.withCachePolicy(.persistent) {
                    outputImage = image
                }
                if let pixelBuffer = try? strongSelf.pixelBufferPool?.makePixelBuffer(allocationThreshold: 30) {
                    do {
                        try strongSelf.context.render(outputImage, to: pixelBuffer)
                        if let smbf = SampleBufferUtilities.makeSampleBufferByReplacingImageBuffer(of: sampleBuffer, with: pixelBuffer) {
                            outputSampleBuffer = smbf
                        }
                    } catch {
                        print("\(error)")
                    }
                }
            }
            if strongSelf.isRecording {
                strongSelf.recorder?.append(sampleBuffer: outputSampleBuffer)
            }
            DispatchQueue.main.async {
                strongSelf.renderView.image = outputImage
            }
        })
        camera?.videoDataOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        camera?.startRunningCaptureSession()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        camera?.stopRunningCaptureSession()
    }
    
    @IBAction func rotateCamera(_ sender: Any) {
        let position: AVCaptureDevice.Position = self.camera?.videoDevice?.position == .back ? .front : .back
        try? self.camera?.switchToVideoCaptureDevice(with: position)
    }
    
    @IBAction func recordButtonTouchDown(_ sender: Any) {
        if isRecording {
            return
        }

        self.isRecording = true

        let videoSettings: [String : Any] = [
            AVVideoCodecKey : AVVideoCodecH264,
            AVVideoWidthKey : 1080,
            AVVideoHeightKey : 1920,
            AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey : 10 * 1024 * 1024
            ]
        ]

        let url = URL(fileURLWithPath: "\(NSTemporaryDirectory())/\(folderName)/\(UUID().uuidString).mp4")
        self.currentVideoURL = url
        let recorder = MovieRecorder(url: url)
        recorder.delegate = self
        recorder.audioEnabled = false
        recorder.videoSettings = videoSettings
        self.recorder = recorder
        recorder.prepareToRecord()
    }
    
    @IBAction func recordButtonTouchUp(_ sender: Any) {
        self.recorder?.finishRecording()
    }
    
    @IBAction func filterSwitchValueChanged(_ sender: UISwitch) {
        self.isFilterEnabled = sender.isOn
    }

    private func recordingStopped() {
        self.recorder = nil
        self.isRecording = false
    }
    
    private func showPlayerViewController(url: URL) {
        let playerViewController = AVPlayerViewController()
        let player = AVPlayer(url: url)
        playerViewController.player = player
        self.present(playerViewController, animated: true) {
            player.play()
        }
    }
}

@available(iOS 10.0, *)
extension CameraViewController: MovieRecorderDelegate {
    
    func movieRecorderDidFinishPreparing(_ recorder: MovieRecorder) {
        
    }
    
    func movieRecorderDidCancelRecording(_ recorder: MovieRecorder) {
        recordingStopped()
    }
    
    func movieRecorder(_ recorder: MovieRecorder, didFailWithError error: Error) {
        recordingStopped()
    }
    
    func movieRecorderDidFinishRecording(_ recorder: MovieRecorder) {
        recordingStopped()
        if let url = self.currentVideoURL {
            showPlayerViewController(url: url)
        }
    }
    
    func movieRecorder(_ recorder: MovieRecorder, didUpdateWithTotalDuration totalDuration: TimeInterval) {
        
    }
}
