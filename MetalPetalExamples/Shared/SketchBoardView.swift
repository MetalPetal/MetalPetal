//
//  SketchBoardView.swift
//  MetalPetalDemo
//
//  Created by YuAo on 2021/4/6.
//

import Foundation
import SwiftUI
import MetalPetal

struct SketchBoardView: View {
    
    enum BrushColor: Hashable {
        struct Color: Hashable {
            var r: Float
            var g: Float
            var b: Float
            var a: Float
        }
        case `static`(Color)
        case `dynamic`
        case eraser
    }
    
    class Renderer: ObservableObject {
        
        @Published var image: CGImage?
        
        @Published var brushColor: BrushColor = .dynamic
        
        @Published var brushSize: CGFloat = 10 {
            didSet {
                self.updateBrushImage()
            }
        }
        
        private var canvasSize: CGSize
        
        private let renderContext = try! MTIContext(device: MTLCreateSystemDefaultDevice()!)
        private let imageRenderer = PixelBufferPoolBackedImageRenderer()
        
        private var backgroundImage: MTIImage
        private var previousImageBuffer: MTIImage?
        private var previousPreviousLocation: CGPoint?
        private var previousLocation: CGPoint?
        
        private var brushImage: MTIImage!
        
        private var compositingFilter = MultilayerCompositingFilter()
        
        private let bitmapScale: CGFloat = {
            #if os(macOS)
            return NSScreen.main?.backingScaleFactor ?? 1.0
            #elseif os(iOS)
            return UIScreen.main.nativeScale
            #endif
        }()
        
        private let backgroundColor: MTIColor = .white
        
        init() {
            let initialCanvasSize = CGSize(width: 1024, height: 1024)
            canvasSize = initialCanvasSize
            backgroundImage = MTIImage(color: backgroundColor, sRGB: false, size: initialCanvasSize)
            updateBrushImage()
            output(image: backgroundImage)
        }
        
        func updateCanvasSize(_ size: CGSize) {
            canvasSize = size * bitmapScale
            if let imageBuffer = previousImageBuffer, (canvasSize.width > backgroundImage.size.width || canvasSize.height > backgroundImage.size.height) {
                backgroundImage = MTIImage(color: backgroundColor, sRGB: false, size: CGSize(width: max(backgroundImage.size.width, canvasSize.width), height: max(backgroundImage.size.height, canvasSize.height)))
                let expandCanvasFilter = MultilayerCompositingFilter()
                expandCanvasFilter.inputBackgroundImage = backgroundImage
                expandCanvasFilter.layers = [MultilayerCompositingFilter.Layer(content: imageBuffer).frame(CGRect(x: 0, y: 0, width: imageBuffer.size.width, height: imageBuffer.size.height), layoutUnit: .pixel)]
                let outputImage = expandCanvasFilter.outputImage!.withCachePolicy(.persistent)
                output(image: outputImage)
            } else if let imageBuffer = previousImageBuffer {
                output(image: imageBuffer)
            } else {
                reset()
            }
            renderContext.reclaimResources()
        }
        
        private func updateBrushImage() {
            let pixelSize = brushSize * bitmapScale
            guard let context = CGContext(data: nil, width: Int(pixelSize) + 2, height: Int(pixelSize) + 2, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) else {
                fatalError()
            }
            context.setFillColor(CGColor(gray: 0, alpha: 1))
            context.fillEllipse(in: CGRect(x: 1, y: 1, width: pixelSize, height: pixelSize))
            let brushImage = MTIImage(cgImage: context.makeImage()!, isOpaque: false).premultiplyingAlpha().withCachePolicy(.persistent)
            self.brushImage = brushImage
        }
        
        func reset() {
            backgroundImage = MTIImage(color: backgroundColor, sRGB: false, size: canvasSize)
            previousImageBuffer = nil
            output(image: backgroundImage)
        }
        
        func startStoke(at location: CGPoint) {
            previousLocation = nil
            previousPreviousLocation = nil
            draw(at: location * bitmapScale)
        }
        
        func moveStroke(to location: CGPoint) {
            draw(at: location * bitmapScale)
        }
        
        private func draw(at point: CGPoint) {
            let background: MTIImage = previousImageBuffer ?? backgroundImage
            
            var brushLayers = [MultilayerCompositingFilter.Layer]()
            
            let previousPreviousLocation = self.previousPreviousLocation ?? point
            let previousLocation = self.previousLocation ?? point
            self.previousPreviousLocation = self.previousLocation
            self.previousLocation = point
            
            let mid1 = (previousLocation + previousPreviousLocation) * 0.5
            let mid2 = (point + previousLocation) * 0.5
            
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
            let cl = SIMD2<Float>(Float(point.x), Float(point.y))
            let d = distance(pl, cl)
            if d > 1 {
                for i in 1..<Int(d) {
                    let p = quadBezierPoint(t: CGFloat(i)/CGFloat(d), start: mid1, c1: previousLocation, end: mid2)
                    
                    let tintColor: MTIColor
                    switch self.brushColor {
                    case .dynamic:
                        tintColor = MTIColor(red: Float(p.x)/Float(backgroundImage.size.width), green: Float(p.y)/Float(backgroundImage.size.height), blue: 1, alpha: 1)
                    case .static(let color):
                        tintColor = MTIColor(red: color.r, green: color.g, blue: color.b, alpha: color.a)
                    case .eraser:
                        tintColor = backgroundColor
                    }
                    var brushLayer = MultilayerCompositingFilter.Layer(content: brushImage)
                    brushLayer.position = p
                    brushLayer.opacity = 1
                    brushLayer.blendMode = .normal
                    brushLayer.tintColor = tintColor
                    brushLayers.append(brushLayer)
                }
            } else {
                let tintColor: MTIColor
                switch self.brushColor {
                case .dynamic:
                    tintColor = MTIColor(red: Float(point.x)/Float(backgroundImage.size.width), green: Float(point.y)/Float(backgroundImage.size.height), blue: 1, alpha: 1)
                case .static(let color):
                    tintColor = MTIColor(red: color.r, green: color.g, blue: color.b, alpha: color.a)
                case .eraser:
                    tintColor = backgroundColor
                }
                var brushLayer = MultilayerCompositingFilter.Layer(content: brushImage)
                brushLayer.position = point
                brushLayer.opacity = 1
                brushLayer.blendMode = .normal
                brushLayer.tintColor = tintColor
                brushLayers.append(brushLayer)
            }
            
            compositingFilter.inputBackgroundImage = background
            compositingFilter.layers = brushLayers
            
            let output = compositingFilter.outputImage!.withCachePolicy(.persistent)
            self.output(image: output)
        }
        
        private func output(image: MTIImage) {
            do {
                // Render the output image
                try renderContext.startTask(toRender: image, completion: nil)
                // Save the rendered buffer so we can use it in the next frame.
                previousImageBuffer = renderContext.renderedBuffer(for: image)
                //Crop the output
                let croppedImage = image.cropped(to: CGRect(origin: .zero, size: canvasSize))!
                
                self.image = try self.imageRenderer.render(croppedImage, using: renderContext).cgImage
            } catch {
                print(error)
            }
        }
    }
    
    @StateObject private var renderer = Renderer()
    
    var body: some View {
        ZStack {
            if let image = renderer.image {
                Image(cgImage: image).resizable()
            }
            
            TouchTrackingView(touchBeganHandler: { [renderer] point in
                renderer.startStoke(at: point)
            }, touchMovedHandler: { [renderer] point in
                renderer.moveStroke(to: point)
            }, boundsChangedHandler: { [renderer] bounds in
                renderer.updateCanvasSize(bounds.size)
            }).frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        BrushColorButton($renderer.brushColor, color: .dynamic)
                        BrushColorButton($renderer.brushColor, color: .static(BrushColor.Color(r: 1, g: 203/255.0, b: 0, a: 1)))
                        BrushColorButton($renderer.brushColor, color: .static(BrushColor.Color(r: 0, g: 203/255.0, b: 71/255.0, a: 1)))
                        BrushColorButton($renderer.brushColor, color: .static(BrushColor.Color(r: 0, g: 203/255.0, b: 1, a: 1)))
                        BrushColorButton($renderer.brushColor, color: .static(BrushColor.Color(r: 1, g: 0, b: 79/255.0, a: 1)))
                        BrushColorButton($renderer.brushColor, color: .static(BrushColor.Color(r: 0, g: 0, b: 0, a: 1)))
                        BrushColorButton($renderer.brushColor, color: .eraser)
                    }
                    HStack {
                        Group {
                            Circle().frame(width: renderer.brushSize, height: renderer.brushSize).foregroundColor(Color.secondary.opacity(0.5))
                        }.frame(width: BrushColorButton.preferredSize, height: BrushColorButton.preferredSize)
                        Slider(value: $renderer.brushSize, in: 6...BrushColorButton.preferredSize)
                            .accentColor(Color.secondary.opacity(0.5))
                    }
                }
                .scaledToFit()
                .padding()
                .blurBackgroundEffect(cornerRadius: 16)
                .padding()
            }
        }
        .toolbar(content: {
            Button("Reset", action: { [renderer] in
                renderer.reset()
            })
        })
        .inlineNavigationBarTitle("Sketch Board")
    }
    
    struct BrushColorButton: View {
        
        static let preferredSize: CGFloat = 36
        static let dynamicBrushIcon: CGImage = RGUVB1GradientImage.makeCGImage(size: CGSize(width: BrushColorButton.preferredSize * 2, height: BrushColorButton.preferredSize * 2))
        
        private let value: Binding<BrushColor>
        private let color: BrushColor
        private let isSelected: Bool
        @State var isHovering: Bool = false
        
        init(_ value: Binding<BrushColor>, color: BrushColor) {
            self.value = value
            self.color = color
            self.isSelected = value.wrappedValue == color
        }
        
        var body: some View {
            Group {
                switch color {
                case .static(let c):
                    Circle().foregroundColor(Color(Color.RGBColorSpace.sRGB,
                                                   red: Double(c.r),
                                                   green: Double(c.g),
                                                   blue: Double(c.b),
                                                   opacity: Double(c.a)))
                case .dynamic:
                    Image(cgImage: BrushColorButton.dynamicBrushIcon).resizable()
                case .eraser:
                    Image(systemName: "square.tophalf.fill").resizable().padding(10).background(Color(.sRGB, white: 1, opacity: 1))
                }
            }
            .frame(width: BrushColorButton.preferredSize, height: BrushColorButton.preferredSize)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity((isSelected || isHovering) ? 0.25 : 0), radius: 4, x: 0, y: 2)
            .overlay(Circle().stroke(Color.white, lineWidth: isSelected ? 2 : 0))
            .onTapGesture { [value, color] in
                value.wrappedValue = color
            }
            .onHover(perform: { [$isHovering] hovering in
                withAnimation {
                    $isHovering.wrappedValue = hovering
                }
            })
        }
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

fileprivate extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}

#if os(iOS)
fileprivate typealias ViewRepresentable = UIViewRepresentable
#elseif os(macOS)
fileprivate typealias ViewRepresentable = NSViewRepresentable
#endif

struct TouchTrackingView: ViewRepresentable {
    
    #if os(iOS)
    class TouchTrackingNativeView: UIView {
        var touchBeginHandler: TouchHandler?
        var touchMovedHandler: TouchHandler?
        var boundsChangedHandler: BoundsChangeHandler?
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            touchBeginHandler?(touches.randomElement()!.location(in: self))
        }
        
        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            touchMovedHandler?(touches.randomElement()!.location(in: self))
        }
        
        private var previousBounds: CGRect?

        override func layoutSubviews() {
            super.layoutSubviews()
            if previousBounds != bounds {
                previousBounds = bounds
                boundsChangedHandler?(bounds)
            }
        }
    }
    #elseif os(macOS)
    class TouchTrackingNativeView: NSView {
        var touchBeginHandler: TouchHandler?
        var touchMovedHandler: TouchHandler?
        var boundsChangedHandler: BoundsChangeHandler?
        
        private var isMouseUp: Bool = true
        
        override func mouseDown(with event: NSEvent) {
            var location = convert(event.locationInWindow, from: nil)
            location.y = bounds.height - location.y
            if isMouseUp {
                isMouseUp = false
                touchBeginHandler?(location)
            }
        }
        
        override func mouseDragged(with event: NSEvent) {
            var location = convert(event.locationInWindow, from: nil)
            location.y = bounds.height - location.y
            touchMovedHandler?(location)
        }
        
        override func mouseUp(with event: NSEvent) {
            isMouseUp = true
        }
        
        private var previousBounds: CGRect?
        
        override func layout() {
            super.layout()
            if previousBounds != bounds {
                previousBounds = bounds
                boundsChangedHandler?(bounds)
            }
        }
    }
    #endif
    
    typealias TouchHandler = (CGPoint) -> Void
    typealias BoundsChangeHandler = (CGRect) -> Void
    private let touchBeginHandler: TouchHandler
    private let touchMovedHandler: TouchHandler
    private let boundsChangedHandler: BoundsChangeHandler
    
    init(touchBeganHandler: @escaping TouchHandler, touchMovedHandler: @escaping TouchHandler, boundsChangedHandler: @escaping BoundsChangeHandler) {
        self.touchBeginHandler = touchBeganHandler
        self.touchMovedHandler = touchMovedHandler
        self.boundsChangedHandler = boundsChangedHandler
    }
    
    func makeUIView(context: Context) -> TouchTrackingNativeView {
        let view = TouchTrackingNativeView(frame: .zero)
        view.touchBeginHandler = self.touchBeginHandler
        view.touchMovedHandler = self.touchMovedHandler
        view.boundsChangedHandler = self.boundsChangedHandler
        return view
    }
    
    func updateUIView(_ uiView: TouchTrackingNativeView, context: Context) {
        
    }
    
    func makeNSView(context: Context) -> TouchTrackingNativeView {
        makeUIView(context: context)
    }
    
    func updateNSView(_ nsView: TouchTrackingNativeView, context: Context) {
        updateUIView(nsView, context: context)
    }
}

struct SketchBoardView_Previews: PreviewProvider {
    static var previews: some View {
        SketchBoardView()
    }
}
