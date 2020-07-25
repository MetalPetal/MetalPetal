//
//  File.swift
//  
//
//  Created by YuAo on 2020/3/17.
//

import Foundation
import CoreGraphics

public struct PixelEnumerator {

    public struct Coordinates: Hashable {
        public var x: Int
        public var y: Int
        public init(x: Int, y: Int) {
            self.x = x
            self.y = y
        }
    }
    
    public struct Pixel: Hashable {
        public var b: UInt8
        public var g: UInt8
        public var r: UInt8
        public var a: UInt8
        public init(b: UInt8, g: UInt8, r: UInt8, a: UInt8) {
            self.b = b
            self.g = g
            self.r = r
            self.a = a
        }
    }

    public static func enumeratePixels(in cgImage: CGImage, with block:(Pixel, Coordinates) -> Void) {
        var buffer = [Pixel](repeating: Pixel(b: 0, g: 0, r: 0, a: 0), count: cgImage.width * cgImage.height)
        let context = CGContext(data: &buffer, width: cgImage.width, height: cgImage.height, bitsPerComponent: 8, bytesPerRow: cgImage.width * 4, space: cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        for x in 0..<cgImage.width {
            for y in 0..<cgImage.height {
                block(buffer[y * cgImage.width + x], Coordinates(x: x, y: y))
            }
        }
    }
}

extension PixelEnumerator {
    public static func monochromeImageEqual(image: CGImage, target: [[UInt8]]) -> Bool {
        var allEqual = true
        self.enumeratePixels(in: image) { (pixel, coordinate) in
            if pixel.r == pixel.g && pixel.g == pixel.b && pixel.a == 255 {
                if pixel.r != target[coordinate.y][coordinate.x] {
                    allEqual = false
                }
            }
        }
        return allEqual
    }
}
