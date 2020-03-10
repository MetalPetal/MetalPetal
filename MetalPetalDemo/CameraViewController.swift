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

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private let folderName = "videos"
    
    private var camera: Camera?
    private let videoQueue = DispatchQueue(label: "com.metalpetal.MetalPetalDemo.videoCallback")
    
    private var recorder: MovieRecorder?
    
    private var isRecording = false
    
    private var pixelBufferPool: MTICVPixelBufferPool?
    
    @IBOutlet private var renderView: MTIImageView!

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
        
        self.renderView.contentMode = .scaleAspectFit
        self.renderView.context = self.context
        
        pixelBufferPool = try? MTICVPixelBufferPool(pixelBufferWidth: 1080, pixelBufferHeight: 1920, pixelFormatType: kCVPixelFormatType_32BGRA, minimumBufferCount: 30)
        
        camera = Camera(captureSessionPreset: .hd1920x1080, configurator: .portraitFrontMirroredVideoOutput)
        try? camera?.enableVideoDataOutput(on: self.videoQueue, delegate: self)
        camera?.videoDataOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        camera?.startRunningCaptureSession()
    }
   
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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

        let url = URL(fileURLWithPath: "\(NSTemporaryDirectory())/\(folderName)/\(UUID().uuidString).mp4")
        self.currentVideoURL = url
        
        var configuration = MovieRecorder.Configuration()
        configuration.isAudioEnabled = false
        let recorder = MovieRecorder(url: url, configuration: configuration, delegate: self)
        self.recorder = recorder
        recorder.prepareToRecord()
        
        self.isRecording = true
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
        }
        DispatchQueue.main.async {
            if self.isRecording {
                if let pixelBuffer = try? self.pixelBufferPool?.makePixelBuffer(allocationThreshold: 30) {
                    do {
                        try self.context.render(outputImage, to: pixelBuffer)
                        if let smbf = SampleBufferUtilities.makeSampleBufferByReplacingImageBuffer(of: sampleBuffer, with: pixelBuffer) {
                            outputSampleBuffer = smbf
                        }
                    } catch {
                        print("\(error)")
                    }
                }
                self.recorder?.append(sampleBuffer: outputSampleBuffer)
            }
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
        print(totalDuration)
    }
}
