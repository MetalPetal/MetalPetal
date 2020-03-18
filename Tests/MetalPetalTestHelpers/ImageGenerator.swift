//
//  File.swift
//  
//
//  Created by YuAo on 2020/3/17.
//

import Foundation
import CoreGraphics

#if canImport(UIKit)
import UIKit
#endif

extension CGColor {
    static var mti_white: CGColor {
        #if canImport(UIKit)
        return UIColor.white.cgColor
        #else
        return .white
        #endif
    }
    static var mti_black: CGColor {
        #if canImport(UIKit)
        return UIColor.black.cgColor
        #else
        return .black
        #endif
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
}
