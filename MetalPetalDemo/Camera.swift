//
//  Camera.swift
//  MomoCV
//
//  Created by YuAo on 5/6/16.
//  Copyright © 2016 Momo. All rights reserved.
//

import Foundation
import AVFoundation

@objcMembers class Camera: NSObject {
    
    private(set) var videoCaptureDevice: AVCaptureDevice?
    private(set) var videoCaptureDeviceInput: AVCaptureDeviceInput?
    private(set) var videoDataOuput: AVCaptureVideoDataOutput?
    
    private let captureSession = AVCaptureSession()
    
    init(sessionPreset: AVCaptureSession.Preset, cameraPosition: AVCaptureDevice.Position = .front) {
        super.init()
        self.captureSession.beginConfiguration()
        if self.captureSession.canSetSessionPreset(sessionPreset) {
            self.captureSession.sessionPreset = sessionPreset
        }
        self.useVideoCaptureDeviceAtPosition(cameraPosition)
        self.captureSession.commitConfiguration()
    }
    
    private var sampleBufferReceiver: Any?
    
    func enableVideoDataOutputWithSampleBufferDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue) {
        self.captureSession.beginConfiguration()
        if let videoDataOuput = self.videoDataOuput {
            self.captureSession.removeOutput(videoDataOuput)
            self.videoDataOuput = nil
        }
        let videoDataOuput = AVCaptureVideoDataOutput()
        videoDataOuput.alwaysDiscardsLateVideoFrames = true
        videoDataOuput.setSampleBufferDelegate(delegate, queue: queue)
        if self.captureSession.canAddOutput(videoDataOuput) {
            self.captureSession.addOutput(videoDataOuput)
            self.videoDataOuput = videoDataOuput
        }
        self.captureSession.commitConfiguration()
        self.configureVideoConnection()
    }
    
    func startRunningCaptureSession() {
        if !self.captureSession.isRunning {
            self.captureSession.startRunning()
        }
    }
    
    func stopRunningCaptureSession() {
        if self.captureSession.isRunning {
            self.captureSession.stopRunning()
        }
    }
    
    private func configureVideoConnection() {
        if let videoConnection = self.videoDataOuput?.connection(with: .video) {
            videoConnection.videoOrientation = .portrait
//            if videoConnection.isVideoStabilizationSupported {
//                videoConnection.preferredVideoStabilizationMode = .standard
//            }
            if self.videoCaptureDevice?.position == .front {
                videoConnection.isVideoMirrored = true
            }
        }
    }
    
    func useVideoCaptureDeviceAtPosition(_ position: AVCaptureDevice.Position) {
        for device in AVCaptureDevice.devices() {
            if device.hasMediaType(AVMediaType.video) && device.position == position {
                do {
                    try device.lockForConfiguration()
                    if device.isFocusModeSupported(.continuousAutoFocus) {
                        device.focusMode = .continuousAutoFocus
                    }
                    if device.isLowLightBoostSupported {
                        device.automaticallyEnablesLowLightBoostWhenAvailable = true
                    }
                    device.automaticallyAdjustsVideoHDREnabled = true
                    device.unlockForConfiguration()
                    self.videoCaptureDevice = device
                    
                    self.captureSession.beginConfiguration()
                    let videoInput = try AVCaptureDeviceInput(device: device)
                    if let currentVideoCaptureDeviceInput = self.videoCaptureDeviceInput {
                        self.captureSession.removeInput(currentVideoCaptureDeviceInput)
                    }
                    if self.captureSession.canAddInput(videoInput) {
                        self.captureSession.addInput(videoInput)
                        self.videoCaptureDeviceInput = videoInput
                    }
                    self.captureSession.commitConfiguration()
                    self.configureVideoConnection()
                } catch {
                    fatalError("Cannot configure video device: \(device)")
                }
                break
            }
        }
    }
}

import Combine
import MetalPetal

@available(iOS 13.0, *)
extension Camera {
    
    private class SampleBufferReceiver:NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        @Published var image: MTIImage?
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                self.image = MTIImage(cvPixelBuffer: pixelBuffer, alphaType: .alphaIsOne)
            }
        }
    }
    
    func subscribeVideoDataOutput(queue: DispatchQueue) -> AnyPublisher<MTIImage?, Never> {
        assert(self.sampleBufferReceiver == nil)
        let sampleBufferReceiver = SampleBufferReceiver()
        self.enableVideoDataOutputWithSampleBufferDelegate(sampleBufferReceiver, queue: queue)
        self.sampleBufferReceiver = sampleBufferReceiver
        return sampleBufferReceiver.$image.eraseToAnyPublisher()
    }
}
