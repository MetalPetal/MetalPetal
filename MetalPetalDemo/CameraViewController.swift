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
    
    private var pixelBufferPool: CVPixelBufferPool?
    
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
        
        CVPixelBufferPoolCreate(kCFAllocatorDefault, [kCVPixelBufferPoolMinimumBufferCountKey:30] as CFDictionary, [kCVPixelBufferPixelFormatTypeKey:kCVPixelFormatType_32BGRA, kCVPixelBufferWidthKey:1080,kCVPixelBufferHeightKey:1920,kCVPixelBufferIOSurfacePropertiesKey:[:]] as CFDictionary, &self.pixelBufferPool)
        
        camera = Camera(sessionPreset: .hd1920x1080, cameraPosition: .back)
        camera?.enableVideoDataOutputWithSampleBufferDelegate(self, queue: self.videoQueue)
        camera?.videoDataOuput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
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
        let position: AVCaptureDevice.Position = self.camera?.videoCaptureDevice?.position == .back ? .front : .back
        self.camera?.useVideoCaptureDeviceAtPosition(position)
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
                AVVideoAverageBitRateKey : 1 * 1024 * 1024,
                AVVideoMaxKeyFrameIntervalKey : 30
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

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer), CMFormatDescriptionGetMediaType(formatDescription) == kCMMediaType_Video, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var outputSampleBuffer = sampleBuffer
        
        let inputImage = MTIImage(cvPixelBuffer: pixelBuffer, alphaType: .alphaIsOne)
        
        var outputImage = inputImage
        
        if self.isFilterEnabled {
            self.colorLookupFilter.inputImage = inputImage
            if let image = self.colorLookupFilter.outputImage?.withCachePolicy(.persistent) {
                outputImage = image
            }
            
            var outputPixelBuffer: CVPixelBuffer?
            
            CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, self.pixelBufferPool!, &outputPixelBuffer)
            
            if let pixelBuffer = outputPixelBuffer {
                do {
                    try self.context.render(outputImage, to: pixelBuffer)
                    
                    if let smbf = outputSampleBuffer.replacing(imageBuffer: pixelBuffer) {
                        outputSampleBuffer = smbf
                    }
                    
                } catch {
                    print("\(error)")
                }
            }
            
        }
        
        if self.isRecording {
            self.recorder?.append(sampleBuffer: outputSampleBuffer)
        }
        
        DispatchQueue.main.async {
            self.renderView.image = outputImage
        }
        
    }
    
}

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

extension CMSampleBuffer {
    
    func replacing(imageBuffer: CVPixelBuffer) -> CMSampleBuffer? {
        var timingInfo: CMSampleTimingInfo = .invalid
        CMSampleBufferGetSampleTimingInfo(self, at: 0, timingInfoOut: &timingInfo)
        var result: CMSampleBuffer?
        var formatDescription: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: imageBuffer, formatDescriptionOut: &formatDescription)
        CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: imageBuffer, formatDescription: formatDescription!, sampleTiming: &timingInfo, sampleBufferOut: &result)
        return result
    }
    
}
