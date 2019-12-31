//
//  SceneKitViewController.swift
//  MetalPetalDemo
//
//  Created by Yu Ao on 2019/2/24.
//  Copyright © 2019 MetalPetal. All rights reserved.
//

import UIKit
import SceneKit
import MetalKit
import MetalPetal
import VideoIO

class SceneKitViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private let camera: Camera = Camera(captureSessionPreset: AVCaptureSession.Preset.hd1280x720, configurator: .portraitFrontMirroredVideoOutput)

    private weak var renderView: MTIImageView!
    
    private var context: MTIContext = try! MTIContext(device: MTLCreateSystemDefaultDevice()!)
    
    private let sceneRenderer = MTISCNSceneRenderer(device: MTLCreateSystemDefaultDevice()!)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!

        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)

        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.white
        scene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the ship node
        let ship = scene.rootNode.childNode(withName: "ship", recursively: true)!
        
        // animate the 3d object
        ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))
        
        self.sceneRenderer.scene = scene
        
        let renderView = MTIImageView(frame: self.view.bounds)
        self.view.addSubview(renderView)
        self.renderView = renderView
        
        try? self.camera.enableVideoDataOutput(delegate: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.camera.startRunningCaptureSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.camera.stopRunningCaptureSession()
    }
    
    let blendFilter = MTIBlendFilter(blendMode: .normal)
    let colorLookupFilter: MTIColorLookupFilter = {
        let filter = MTIColorLookupFilter()
        filter.inputColorLookupTable = MTIImage(cgImage: UIImage(named: "ColorLookup512")!.cgImage!, options: [.SRGB: false], isOpaque: true)
        return filter
    }()
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let backgroundImage = MTIImage(cvPixelBuffer: pixelBuffer, alphaType: .alphaIsOne)
            let sceneImage = self.sceneRenderer.snapshot(atTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds, viewport: CGRect(x: 0, y: 0, width: 720, height: 1280), pixelFormat: MTLPixelFormat.unspecified, isOpaque: false).unpremultiplyingAlpha()
            self.blendFilter.inputBackgroundImage = backgroundImage
            self.blendFilter.inputImage = sceneImage
            self.colorLookupFilter.inputImage = self.blendFilter.outputImage
            self.renderView.image = self.colorLookupFilter.outputImage
        }
    }
    
}
