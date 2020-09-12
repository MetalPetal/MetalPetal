//
//  SketchViewController.swift
//  MetalPetalDemo
//
//  Created by YuAo on 2020/7/10.
//  Copyright © 2020 MetalPetal. All rights reserved.
//

import UIKit
import MetalPetal

class SketchViewController: UIViewController {

    @IBOutlet private weak var imageView: MTIImageView!
    @IBOutlet private weak var toolsView: UIView!
    @IBOutlet private weak var brushSizeSlider: UISlider!
    @IBOutlet private weak var brushSizeIndicatorView: UIView!
    @IBOutlet private weak var brushSizeIndicatorViewSize: NSLayoutConstraint!
    
    @IBOutlet var colorButtons: [ColorButton]!
    
    private var brushColor: UIColor = .black
    
    private var backgroundImage: MTIImage!
    
    private var previousImageBuffer: MTIImage?
    private var previousLocationInView: CGPoint?
    
    private var brushImage: MTIImage!
    
    private var compositingFilter = MultilayerCompositingFilter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.brushColor = self.colorButtons.first(where: {$0.isSelected})?.color ?? .clear
        self.brushSizeIndicatorViewSize.constant = CGFloat(self.brushSizeSlider.value)
        self.brushSizeIndicatorView.layer.cornerRadius = CGFloat(self.brushSizeSlider.value) / 2
        self.updateBrushImage(radius: CGFloat(self.brushSizeSlider.value))
        //warm up
        do {
            let background = MTIImage(color: .white, sRGB: false, size: self.brushImage.size)
            compositingFilter.inputBackgroundImage = background
            compositingFilter.layers = [MultilayerCompositingFilter.Layer(content: self.brushImage)]
            let _ = try? self.imageView.context!.startTask(toRender: compositingFilter.outputImage!)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.backgroundImage == nil {
            self.reset()
        }
        toolsView.layer.shadowPath = UIBezierPath(roundedRect: toolsView.bounds, cornerRadius: 16).cgPath
        toolsView.layer.shadowRadius = 10
        toolsView.layer.shadowColor = UIColor.black.cgColor
        toolsView.layer.shadowOpacity = 0.2
        toolsView.layer.shadowOffset = .zero
    }
    
    private func updateBrushImage(radius: CGFloat) {
        // +2 to avoid pixels on geometry boundary so we do not need to enable MSAA.
        let image = UIGraphicsImageRenderer(size: CGSize(width: radius + 2, height: radius + 2)).image { _ in
            UIColor.black.setFill()
            UIBezierPath(ovalIn: CGRect(x: 1, y: 1, width: radius, height: radius)).fill()
        }
        let brushImage = MTIImage(cgImage: image.cgImage!, options: [.SRGB: false], isOpaque: false).unpremultiplyingAlpha().withCachePolicy(.persistent)
        self.brushImage = brushImage
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
    
    @IBAction func brushSliderValueChanged(_ sender: UISlider) {
        self.brushSizeIndicatorViewSize.constant = CGFloat(self.brushSizeSlider.value)
        self.brushSizeIndicatorView.layer.cornerRadius = CGFloat(self.brushSizeSlider.value) / 2
        self.updateBrushImage(radius: CGFloat(sender.value))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        previousLocationInView = nil
        self.draw(with: touches.randomElement()!)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.draw(with: touches.randomElement()!)
    }
    
    private func draw(with touch: UITouch) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        self.brushColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let enableTint: Bool
        let brush: MTIImage
        if alpha == 0 {
            brush = BrushTinter.image(byProcessingImage: self.brushImage, withInputParameters: ["color": SIMD4<Float>(0,0,0,1)], outputPixelFormat: .unspecified).premultiplyingAlpha()
            enableTint = true
        } else {
            brush = BrushTinter.image(byProcessingImage: self.brushImage, withInputParameters: ["color": SIMD4<Float>(Float(red),Float(green),Float(blue),Float(alpha))], outputPixelFormat: .unspecified).premultiplyingAlpha()
            enableTint = false
        }
        
        let context: MTIContext = imageView.context!
        let background: MTIImage = previousImageBuffer ?? backgroundImage
        
        var brushLayers = [MultilayerCompositingFilter.Layer]()
        
        let currentLocation: CGPoint = touch.location(in: view) * UIScreen.main.nativeScale
        let previousPreviousLocation = self.previousLocationInView ?? currentLocation
        let previousLocation = touch.previousLocation(in: view) * UIScreen.main.nativeScale
        self.previousLocationInView = previousLocation
        
        let mid1 = (previousLocation + previousPreviousLocation) * 0.5
        let mid2 = (currentLocation + previousLocation) * 0.5
        
        func quadBezierPoint(t: CGFloat, start: CGPoint, c1: CGPoint, end: CGPoint) -> CGPoint {
            let x = quadBezier(t: t, start: start.x, c1: c1.x, end: end.x)
            let y = quadBezier(t: t, start: start.y, c1: c1.y, end: end.y)
            return CGPoint(x: x, y: y)
        }
        
        func quadBezier(t: CGFloat, start: CGFloat, c1: CGFloat, end: CGFloat) -> CGFloat {
            let t_ = (1.0 - t)
            let tt_ = t_ * t_
            let tt = t * t
            return start * tt_ + 2.0 *  c1 * t_ * t + end * tt
        }
        
        let pl = SIMD2<Float>(Float(previousLocation.x), Float(previousLocation.y))
        let cl = SIMD2<Float>(Float(currentLocation.x), Float(currentLocation.y))
        let d = distance(pl, cl)
        if d > 1 {
            for i in 1..<Int(d) {
                let p = quadBezierPoint(t: CGFloat(i)/CGFloat(d), start: mid1, c1: previousLocation, end: mid2)
                var brushLayer = MultilayerCompositingFilter.Layer(content: brush)
                brushLayer.position = p
                brushLayer.opacity = 1
                brushLayer.blendMode = .normal
                if enableTint {
                    brushLayer.tintColor = MTIColor(red: Float(p.x)/Float(backgroundImage.size.width), green: Float(p.y)/Float(backgroundImage.size.height), blue: 1, alpha: 1)
                }
                brushLayers.append(brushLayer)
            }
        } else {
            var brushLayer = MultilayerCompositingFilter.Layer(content: brush)
            brushLayer.position = currentLocation
            brushLayer.opacity = 1
            brushLayer.blendMode = .normal
            if enableTint {
                brushLayer.tintColor = MTIColor(red: Float(currentLocation.x)/Float(backgroundImage.size.width), green: Float(currentLocation.y)/Float(backgroundImage.size.height), blue: 1, alpha: 1)
            }
            brushLayers.append(brushLayer)
        }
        
        compositingFilter.inputBackgroundImage = background
        compositingFilter.layers = brushLayers
        if let output = compositingFilter.outputImage?.withCachePolicy(.persistent) {
            do {
                // Render the output image
                try context.startTask(toRender: output)
                // Save the rendered buffer so we can use it in the next frame.
                previousImageBuffer = context.renderedBuffer(for: output)
                // Display the output
                imageView.image = output
            } catch {
                print(error)
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: nil) { context in
            self.reset()
        }
    }
}

// MARK: -

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

fileprivate extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}

@IBDesignable
class ColorButton: UIButton {
    @IBInspectable var color: UIColor? {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    private let context = try! MTIContext(device: MTLCreateSystemDefaultDevice()!)
    
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
        if color == .clear {
            struct Kernels {
                static let iconGenerator = MTIRenderPipelineKernel(vertexFunctionDescriptor: .passthroughVertex, fragmentFunctionDescriptor: MTIFunctionDescriptor(name: "magicTintBrushIconGenerator", libraryURL: URL.defaultMetalLibraryURL(for: ColorButton.self)))
            }
            let icon = MTIRenderCommand.images(byPerforming: [
                MTIRenderCommand(kernel: Kernels.iconGenerator, geometry: MTIVertices.fullViewportSquare, images: [], parameters: [:])
                ], outputDescriptors: [
                    MTIRenderPassOutputDescriptor(dimensions: MTITextureDimensions(cgSize: bounds.size), pixelFormat: .unspecified)
            ]).first
            let cgImage = try! context.makeCGImage(from: icon!)
            backgroundColor = UIColor(patternImage: UIImage(cgImage: cgImage))
        } else {
            backgroundColor = color
        }
    }
}

class BrushTinter: MTIUnaryImageRenderingFilter {
    override class func fragmentFunctionDescriptor() -> MTIFunctionDescriptor {
        struct Static {
            static let descriptor = MTIFunctionDescriptor(name: "tintBrush", libraryURL: URL.defaultMetalLibraryURL(for: .main))
        }
        return Static.descriptor
    }
}
