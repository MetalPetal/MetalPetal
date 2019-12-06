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

class ChainableAPIViewController: UIViewController {
    
    @IBOutlet private weak var imageView: MTIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
}
