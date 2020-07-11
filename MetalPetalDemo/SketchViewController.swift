//
//  SketchViewController.swift
//  MetalPetalDemo
//
//  Created by YuAo on 2020/7/10.
//  Copyright © 2020 MetalPetal. All rights reserved.
//

import UIKit
import MetalPetal

@IBDesignable
class ColorButton: UIButton {
    @IBInspectable var color: UIColor? {
        didSet {
            self.backgroundColor = color
        }
    }
    
    override var isSelected: Bool {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height/2
        if isSelected {
            layer.borderWidth = 2
            layer.borderColor = UIColor.white.cgColor
            layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.height/2).cgPath
            layer.shadowRadius = 4
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.2
            layer.shadowOffset = CGSize(width: 0, height: 2)
            layer.mask = nil
        } else {
            layer.borderWidth = 2
            layer.borderColor = UIColor.clear.cgColor
            layer.shadowPath = nil
            layer.shadowRadius = 0
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0
            layer.shadowOffset = .zero
            let mask = CAShapeLayer()
            mask.path = UIBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), cornerRadius: bounds.insetBy(dx: 2, dy: 2).height/2).cgPath
            mask.fillColor = UIColor.white.cgColor
            layer.mask = mask
        }
    }
}

class BrushTinter: MTIUnaryImageRenderingFilter {
    override class func fragmentFunctionDescriptor() -> MTIFunctionDescriptor {
        MTIFunctionDescriptor(name: "tintBrush", libraryURL: URL.defaultMetalLibraryURL(for: .main))
    }
}

fileprivate extension CGSize {
    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        return CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
}

fileprivate extension CGPoint {
    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}

class SketchViewController: UIViewController {

    @IBOutlet private weak var imageView: MTIImageView!
    @IBOutlet private weak var toolsView: UIView!
    
    @IBOutlet var colorButtons: [ColorButton]!
    
    private var brushColor: UIColor = .black
    
    private var backgroundImage: MTIImage!
    
    private var previousImageBuffer: MTIImage?
    private var previousLocationInView: CGPoint?
    
    private var brushImage: MTIImage!
    
    private var compositingFilter = MultilayerCompositingFilter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let brushRadius: CGFloat = 28
        let brushBlur: CGFloat = 4
        let brushGenerator: CIFilter = CIFilter(name: "CIRadialGradient", parameters: [
            "inputColor1": CIColor(red: 0, green: 0, blue: 0, alpha: 0),
            "inputColor0": CIColor(red: 0, green: 0, blue: 0, alpha: 1),
            "inputRadius0": brushRadius - brushBlur,
            "inputRadius1": brushRadius,
            "inputCenter": CIVector(x: brushRadius, y: brushRadius)
        ])!
        let brushImage = MTIImage(ciImage: brushGenerator.outputImage!.cropped(to: CGRect(origin: .zero, size: CGSize(width: brushRadius * 2, height: brushRadius * 2))), isOpaque: true).unpremultiplyingAlpha().withCachePolicy(.persistent)
        self.brushImage = brushImage
        //warm up
        let _ = try? self.imageView.context.startTask(toRender: self.brushImage)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.backgroundImage == nil {
            self.reset()
        }
        toolsView.layer.shadowPath = UIBezierPath(roundedRect: toolsView.bounds, cornerRadius: toolsView.bounds.height/2).cgPath
        toolsView.layer.shadowRadius = 10
        toolsView.layer.shadowColor = UIColor.black.cgColor
        toolsView.layer.shadowOpacity = 0.2
        toolsView.layer.shadowOffset = .zero
    }
    
    private func reset() {
        backgroundImage = MTIImage(color: MTIColor.white, sRGB: false, size: view.bounds.size * UIScreen.main.nativeScale)
        imageView.image = backgroundImage
        previousImageBuffer = nil
    }
    
    @IBAction func colorButtonTapped(_ sender: ColorButton) {
        colorButtons.forEach { button in
            if button == sender {
                button.isSelected = true
            } else {
                button.isSelected = false
            }
        }
        brushColor = sender.color!
    }
    
    @IBAction func clearButtonTapped(_ sender: UIButton) {
        self.reset()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        previousLocationInView = nil
        self.draw(to: touches.randomElement()!.location(in: view) * UIScreen.main.nativeScale)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.draw(to: touches.randomElement()!.location(in: view) * UIScreen.main.nativeScale)
    }
    
    private func draw(to point: CGPoint) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        self.brushColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let brush = BrushTinter.image(byProcessingImage: self.brushImage, withInputParameters: ["color": SIMD4<Float>(Float(red),Float(green),Float(blue),Float(alpha))], outputPixelFormat: .unspecified)
        
        let context = imageView.context
        let background: MTIImage = previousImageBuffer ?? backgroundImage
        
        let currentLocation: CGPoint = point
        
        var brushLayers = [MultilayerCompositingFilter.Layer]()
        
        let blendMode: MTIBlendMode = .normal
        
        if let previousLocation = self.previousLocationInView {
            let pl = SIMD2<Float>(Float(previousLocation.x), Float(previousLocation.y))
            let cl = SIMD2<Float>(Float(currentLocation.x), Float(currentLocation.y))
            let d = distance(pl, cl)
            let flow: Float = 2
            if d > flow {
                for i in 1..<Int(d/flow) {
                    let v = normalize(cl - pl)
                    let t = pl + v * Float(i) * flow
                    var brushLayer = MultilayerCompositingFilter.Layer(content: brush)
                    brushLayer.position = CGPoint(x: Double(t.x), y: Double(t.y))
                    brushLayer.opacity = 1
                    brushLayer.blendMode = blendMode
                    brushLayers.append(brushLayer)
                }
            }
        }
        
        previousLocationInView = currentLocation
        
        var brushLayer = MultilayerCompositingFilter.Layer(content: brush)
        brushLayer.position = currentLocation
        brushLayer.opacity = 1
        brushLayer.blendMode = blendMode
        brushLayers.append(brushLayer)
        
        compositingFilter.inputBackgroundImage = background
        compositingFilter.layers = brushLayers
        if let output = compositingFilter.outputImage?.withCachePolicy(.persistent) {
            do {
                try context.startTask(toRender: output)
                previousImageBuffer = context.renderedBuffer(for: output)
                imageView.image = output
            } catch {
                print(error)
            }
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
