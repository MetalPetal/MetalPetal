//
//  File.swift
//  
//
//  Created by YuAo on 2020/3/17.
//

import Foundation
import CoreGraphics

extension CGColor {
    static var mti_white: CGColor {
        var components: [CGFloat] = [1, 1, 1, 1]
        return CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: &components)!
    }
    static var mti_black: CGColor {
        var components: [CGFloat] = [0, 0, 0, 1]
        return CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: &components)!
    }
    static var mti_r0g128b255: CGColor {
        var components: [CGFloat] = [0, 128/255.0, 1, 1]
        return CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: &components)!
    }
}

public struct ImageGenerator {
    
    public enum Error: String, LocalizedError, Swift.Error {
        case cannotCreateCGContext
        case cannotCreateImageFromContext
        public var errorDescription: String? {
            return self.rawValue
        }
    }
    
    public static func makeCheckboardImage() throws -> CGImage {
        guard let context = CGContext(data: nil, width: 2, height: 2, bitsPerComponent: 8, bytesPerRow: 2 * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) else {
            throw Error.cannotCreateCGContext
        }
        context.setFillColor(CGColor.mti_white)
        context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        context.setFillColor(CGColor.mti_black)
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        context.fill(CGRect(x: 1, y: 1, width: 1, height: 1))
        guard let image = context.makeImage() else {
            throw Error.cannotCreateImageFromContext
        }
        return image
    }
    
    public static func makeCheckboardImageWithMonochromeColorSpace() throws -> CGImage {
        guard let context = CGContext(data: nil, width: 2, height: 2, bitsPerComponent: 8, bytesPerRow: 2, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
            throw Error.cannotCreateCGContext
        }
        context.setFillColor(CGColor.mti_white)
        context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        context.setFillColor(CGColor.mti_black)
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        context.fill(CGRect(x: 1, y: 1, width: 1, height: 1))
        guard let image = context.makeImage() else {
            throw Error.cannotCreateImageFromContext
        }
        return image
    }
    
    public static func makeCheckboardImageWith5BitPerComponent() throws -> CGImage {
        guard let context = CGContext(data: nil, width: 2, height: 2, bitsPerComponent: 5, bytesPerRow: 2 * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo.byteOrder16Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            throw Error.cannotCreateCGContext
        }
        context.setFillColor(CGColor.mti_white)
        context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        context.setFillColor(CGColor.mti_black)
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        context.fill(CGRect(x: 1, y: 1, width: 1, height: 1))
        guard let image = context.makeImage() else {
            throw Error.cannotCreateImageFromContext
        }
        return image
    }
    
    public static func makeR0G128B255CheckboardImageWithBigEndianAlphaLast() throws -> CGImage {
        guard let context = CGContext(data: nil, width: 2, height: 2, bitsPerComponent: 8, bytesPerRow: 2 * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw Error.cannotCreateCGContext
        }
        context.setFillColor(CGColor.mti_white)
        context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        context.setFillColor(CGColor.mti_r0g128b255)
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        context.fill(CGRect(x: 1, y: 1, width: 1, height: 1))
        guard let image = context.makeImage() else {
            throw Error.cannotCreateImageFromContext
        }
        return image
    }
    
    public static func makeR0G128B255CheckboardImageWithBigEndianAlphaFirst() throws -> CGImage {
        guard let context = CGContext(data: nil, width: 2, height: 2, bitsPerComponent: 8, bytesPerRow: 2 * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) else {
            throw Error.cannotCreateCGContext
        }
        context.setFillColor(CGColor.mti_white)
        context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        context.setFillColor(CGColor.mti_r0g128b255)
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        context.fill(CGRect(x: 1, y: 1, width: 1, height: 1))
        guard let image = context.makeImage() else {
            throw Error.cannotCreateImageFromContext
        }
        return image
    }
    
    public static func makeR0G128B255CheckboardImageWithDefaultEndianAlphaFirst() throws -> CGImage {
        guard let context = CGContext(data: nil, width: 2, height: 2, bitsPerComponent: 8, bytesPerRow: 2 * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) else {
            throw Error.cannotCreateCGContext
        }
        context.setFillColor(CGColor.mti_white)
        context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        context.setFillColor(CGColor.mti_r0g128b255)
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        context.fill(CGRect(x: 1, y: 1, width: 1, height: 1))
        guard let image = context.makeImage() else {
            throw Error.cannotCreateImageFromContext
        }
        return image
    }
    
    public static func makeMonochromeImage(_ data: [[UInt8]]) throws -> CGImage {
        var buffer: [UInt8] = data.flatMap { $0 }
        guard let context = CGContext(data: &buffer, width: data[0].count, height: data.count, bitsPerComponent: 8, bytesPerRow: data[0].count, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
            throw Error.cannotCreateCGContext
        }
        guard let image = context.makeImage() else {
            throw Error.cannotCreateImageFromContext
        }
        return image
    }
}
