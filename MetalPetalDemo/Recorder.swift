//
//  Recorder.swift
//  MetalPetalDemo
//
//  Created by Yu Ao on 10/01/2018.
//  Copyright © 2018 MetalPetal. All rights reserved.
//

import Foundation
import AVFoundation

@objcMembers class Recorder: NSObject {
    
    private let assetWriter: AVAssetWriter
    private var assetWriterInput: AVAssetWriterInput!
    
    private let queue = DispatchQueue(label: "com.metalpetal.MetalPetalDemo.videoRecording")
    
    init(outputURL: URL) {
        self.assetWriter = try! AVAssetWriter(url: outputURL, fileType: AVFileType.mp4)
        super.init()
    }
    
    private var recording: Bool = false
    
    @objc(appendSampleBuffer:) func append(sampleBuffer: CMSampleBuffer) {
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            return
        }
        guard CMFormatDescriptionGetMediaType(formatDescription) == kCMMediaType_Video else {
           return
        }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        self.queue.async {
            if self.recording {
                if self.assetWriterInput == nil {
                    self.assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings:
                        [AVVideoCodecKey: AVVideoCodecH264,
                         AVVideoWidthKey: CVPixelBufferGetWidth(pixelBuffer),
                         AVVideoHeightKey: CVPixelBufferGetHeight(pixelBuffer),
                         AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                         AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey : 10 * 1024 * 1024]]
                    )
                    self.assetWriterInput.expectsMediaDataInRealTime = true
                    self.assetWriter.add(self.assetWriterInput)
                    
                    self.assetWriter.startWriting()
                    self.assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                }
                if self.assetWriterInput.isReadyForMoreMediaData {
                    self.assetWriterInput.append(sampleBuffer)
                }
            }
        }
    }
    
    func startRecording() {
        self.queue.sync {
            self.recording = true
        }
    }
    
    func stopRecording(completion: @escaping (() -> Void)) {
        self.queue.sync {
            self.recording = false
            self.assetWriter.finishWriting {
                self.queue.async {
                    completion()
                }
            }
        }
    }
}
