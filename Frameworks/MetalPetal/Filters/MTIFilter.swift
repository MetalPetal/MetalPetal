//
//  MTIFilter.swift
//  Pods
//
//  Created by YuAo on 22/09/2017.
//

import Foundation

extension MTIFilter {
    
}

extension MTIImage {
    
    public func adjusting(saturation: Float) -> MTIImage {
        let filter = MTISaturationFilter()
        filter.saturation = saturation
        filter.inputImage = self
        return filter.outputImage!
    }
    
    public func adjusting(exposure: Float) -> MTIImage {
        let filter = MTIExposureFilter()
        filter.exposure = exposure
        filter.inputImage = self
        return filter.outputImage!
    }
    
    public func adjusting(brightness: Float) -> MTIImage {
        let filter = MTIBrightnessFilter()
        filter.brightness = brightness
        filter.inputImage = self
        return filter.outputImage!
    }
    
    public func adjusting(contrast: Float) -> MTIImage {
        let filter = MTIContrastFilter()
        filter.contrast = contrast
        filter.inputImage = self
        return filter.outputImage!
    }
    
    public func adjusting(vibrance: Float) -> MTIImage {
        let filter = MTIVibranceFilter()
        filter.amount = vibrance
        filter.inputImage = self
        return filter.outputImage!
    }
    
    public func cropped(to region: MTICropRegion) -> MTIImage {
        let filter = MTICropFilter()
        filter.cropRegion = region
        filter.inputImage = self
        return filter.outputImage!
    }
    
    public func cropped(to rect: CGRect) -> MTIImage {
        let filter = MTICropFilter()
        filter.cropRegion = MTICropRegion(bounds: rect, unit: .pixel)
        filter.inputImage = self
        return filter.outputImage!
    }
}
