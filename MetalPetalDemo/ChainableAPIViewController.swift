//
//  ChainableAPIViewController.swift
//  MetalPetalDemo
//
//  Created by Yu Ao on 2019/12/6.
//  Copyright © 2019 MetalPetal. All rights reserved.
//

import Foundation
import UIKit
import MetalPetal
import VideoIO
import Combine

@available(iOS 13.0, *)
class ChainableAPIViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet private weak var imageView: MTIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageView.clearColor = MTLClearColorMake(0, 0, 0, 0)
        self.imageView.isOpaque = false
        
        guard let inputImage = UIImage(named: "P1040808.jpg").map({ MTIImage(image: $0, isOpaque: true) }) else {
            fatalError()
        }
        
        let saturationFilter = MTISaturationFilter()
        saturationFilter.saturation = 0.2
        
        let exposureFilter = MTIExposureFilter()
        exposureFilter.exposure = 1
        
        let contrastFilter = MTIContrastFilter()
        contrastFilter.contrast = 0
        
        let overlayBlendFilter = MTIBlendFilter(blendMode: .overlay)
        
        let enableSaturationAdjustment = Bool.random()
        
        let image = FilterGraph.makeImage { output in
            inputImage => (enableSaturationAdjustment ? AnyIOPort(saturationFilter) : AnyIOPort(ImagePassthroughPort())) => exposureFilter => contrastFilter => overlayBlendFilter.inputPorts.inputImage
            exposureFilter => overlayBlendFilter.inputPorts.inputBackgroundImage
            overlayBlendFilter => output
        }
        
        self.imageView.image = image
    }
    
    private var camera = Camera(captureSessionPreset: .hd1920x1080, configurator: .portraitFrontMirroredVideoOutput)
    
    @Published var cameraImage: MTIImage?
    
    private var cameraImageSubscriber: Any?

    @IBAction func driveWithCameraFeedButtonTapped(_ sender: UIButton) {
        sender.isHidden = true
        
        let colorLookupTable = UIImage(named: "ColorLookup512").map({ MTIImage(image: $0, isOpaque: true) })
        try? self.camera.enableVideoDataOutput(delegate: self)
        
        let colorLookupFilter = MTIColorLookupFilter()
        colorLookupFilter.inputColorLookupTable = colorLookupTable
        let saturationFilter = MTISaturationFilter()
        saturationFilter.saturation = 0
        
        self.cameraImageSubscriber = FilterGraph.makePublisher(upstream: $cameraImage) { input, output in
            if let image = input {
                image => colorLookupFilter.inputPorts.inputImage
            }
            colorLookupFilter => saturationFilter => output
        }.receive(on: DispatchQueue.main).assign(to: \.image, on: self.imageView)
        
        self.camera.startRunningCaptureSession()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.cameraImage = MTIImage(cvPixelBuffer: CMSampleBufferGetImageBuffer(sampleBuffer)!, alphaType: .alphaIsOne)
    }
}
