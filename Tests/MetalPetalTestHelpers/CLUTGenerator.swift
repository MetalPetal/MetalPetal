import CoreGraphics

public struct CLUTImageLayout {
    public var horizontalTileCount: UInt
    public var verticalTileCount: UInt
    public init(horizontalTileCount: UInt, verticalTileCount: UInt) {
        self.verticalTileCount = verticalTileCount
        self.horizontalTileCount = horizontalTileCount
    }
}

public struct CLUTImageDescriptor {
    public var dimension: UInt
    public var layout: CLUTImageLayout
    
    public var isValid: Bool {
        return dimension > 0 && dimension <= 256 && (layout.horizontalTileCount * layout.verticalTileCount == dimension)
    }
    
    public var title: String {
        return "CLUT_D\(self.dimension)_\(self.layout.horizontalTileCount * self.dimension)x\(self.layout.verticalTileCount * self.dimension)"
    }
    
    public static let squareD16: CLUTImageDescriptor = CLUTImageDescriptor(dimension: 16, layout: CLUTImageLayout(horizontalTileCount: 4, verticalTileCount: 4))

    public static let squareD64: CLUTImageDescriptor = CLUTImageDescriptor(dimension: 64, layout: CLUTImageLayout(horizontalTileCount: 8, verticalTileCount: 8))
    
    public static let squareD256: CLUTImageDescriptor = CLUTImageDescriptor(dimension: 256, layout: CLUTImageLayout(horizontalTileCount: 16, verticalTileCount: 16))
    
    public init(dimension: UInt, layout: CLUTImageLayout) {
        self.dimension = dimension
        self.layout = layout
    }
}

public struct IdentityCLUTImageGenerator {
    public static func generateIdentityCLUTImage(with descriptor: CLUTImageDescriptor) -> CGImage? {
        assert(descriptor.isValid)
        guard descriptor.isValid else {
            return nil
        }
        
        let imageWidth = Int(descriptor.dimension * descriptor.layout.horizontalTileCount)
        let imageHeight = Int(descriptor.dimension * descriptor.layout.verticalTileCount)
        
        let bytesPerPixel = 4
        let bytesPerRow = imageWidth * bytesPerPixel
        
        guard let buffer = malloc(imageHeight * bytesPerRow) else {
            return nil
        }
        
        struct Pixel {
            var b: UInt8
            var g: UInt8
            var r: UInt8
            var a: UInt8
        }
        
        precondition(MemoryLayout<Pixel>.size == 4)
        
        let pixels = buffer.assumingMemoryBound(to: Pixel.self)
        for y in 0..<imageHeight {
            let lineOffset = y * imageWidth
            for x in 0..<imageWidth {
                var pixel = pixels.advanced(by: lineOffset + x).pointee
                let tileX = x / Int(descriptor.dimension)
                let tileY = y / Int(descriptor.dimension)
                let tile = tileY * Int(descriptor.layout.horizontalTileCount) + tileX
                let innerX = x - tileX * Int(descriptor.dimension)
                let innerY = y - tileY * Int(descriptor.dimension)
                pixel.b = UInt8(round(Double(tile) / Double(descriptor.dimension - 1) * 255))
                pixel.r = UInt8(round(Double(innerX) / Double(descriptor.dimension - 1) * 255))
                pixel.g = UInt8(round(Double(innerY) / Double(descriptor.dimension - 1) * 255))
                pixel.a = 255
                pixels.advanced(by: lineOffset + x).pointee = pixel
            }
        }
        guard let dataProvider = CGDataProvider(data: CFDataCreate(kCFAllocatorDefault, buffer.assumingMemoryBound(to: UInt8.self), imageHeight * bytesPerRow)) else {
            return nil
        }
        return CGImage(width: imageWidth,
                       height: imageHeight,
                       bitsPerComponent: 8,
                       bitsPerPixel: bytesPerPixel * 8,
                       bytesPerRow: bytesPerRow,
                       space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue),
                       provider: dataProvider,
                       decode: nil,
                       shouldInterpolate: false,
                       intent: .defaultIntent)
    }
}
