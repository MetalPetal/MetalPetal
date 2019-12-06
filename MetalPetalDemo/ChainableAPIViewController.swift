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
import Combine

class ChainableAPIViewController: UIViewController {
    
    @IBOutlet private weak var imageView: MTIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageView.clearColor = MTLClearColorMake(0, 0, 0, 0)
        self.imageView.isOpaque = false
        
        guard let inputImage = UIImage(named: "P1040808.jpg")?.makeMTIImage() else {
            fatalError()
        }
        
        let saturationFilter = MTISaturationFilter()
        saturationFilter.saturation = 0.5
        
        let exposureFilter = MTIExposureFilter()
        exposureFilter.exposure = 1
        
        let contrastFilter = MTIContrastFilter()
        contrastFilter.contrast = 0
        
        let overlayBlendFilter = MTIBlendFilter(blendMode: .overlay)
        
        let image = try! FilterGraph.makeImage { output in
            inputImage => saturationFilter => exposureFilter => contrastFilter => overlayBlendFilter.inputPorts.inputImage
            exposureFilter => overlayBlendFilter.inputPorts.inputBackgroundImage
            overlayBlendFilter => output
        }
        
        self.imageView.image = image
    }
    
    private var camera = Camera(sessionPreset: .hd1920x1080, cameraPosition: .back)
    
    private var cameraImageSubscriber: Any?

    @IBAction func driveWithCameraFeedButtonTapped(_ sender: UIButton) {
        if #available(iOS 13.0, *) {
            sender.isHidden = true
            
            let colorLookupTable = UIImage(named: "ColorLookup512")?.makeMTIImage(sRGB: false, isOpaque: true)
            let cameraImagePublisher = self.camera.subscribeVideoDataOutput(queue: DispatchQueue.main)
            
            let colorLookupFilter = MTIColorLookupFilter()
            colorLookupFilter.inputColorLookupTable = colorLookupTable
            let saturationFilter = MTISaturationFilter()
            saturationFilter.saturation = 0

            self.cameraImageSubscriber = FilterGraph.makePublisher(upstream: cameraImagePublisher) { input, output in
                if let image = input {
                    image => colorLookupFilter.inputPorts.inputImage
                    colorLookupFilter => saturationFilter => output
                }
            }.receive(on: DispatchQueue.main).assign(to: \.image, on: self.imageView)
            
            self.camera.startRunningCaptureSession()
        } else {
            assertionFailure()
        }
    }
}
