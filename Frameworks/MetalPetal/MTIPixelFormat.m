//
//  MTIPixelFormat.m
//  MetalPetal
//
//  Created by Yu Ao on 11/10/2017.
//

#import "MTIPixelFormat.h"
#import <AssertMacros.h>

MTLPixelFormat const MTIPixelFormatUnspecified = MTLPixelFormatInvalid;

MTLPixelFormat const MTIPixelFormatYCBCR8_420_2P = 500;
MTLPixelFormat const MTIPixelFormatYCBCR8_420_2P_sRGB = 520;

MTLPixelFormat const MTIPixelFormatYCBCR10_420_2P = 505;
MTLPixelFormat const MTIPixelFormatYCBCR10_420_2P_sRGB = 525;

BOOL MTIDeviceSupportsYCBCRPixelFormat(id<MTLDevice> device) {
    if (@available(iOS 13.0, tvOS 13.0, macCatalyst 14.0, macOS 11.0, *)) {
        if ([device supportsFamily:MTLGPUFamilyApple3]) {
            return YES;
        } else {
            return NO;
        }
    } else {
        #if TARGET_OS_TV
        return [device supportsFeatureSet:MTLFeatureSet_tvOS_GPUFamily2_v1];
        #elif TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR && !TARGET_OS_MACCATALYST
        return [device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily3_v1];
        #else
        return NO;
        #endif
    }
}
