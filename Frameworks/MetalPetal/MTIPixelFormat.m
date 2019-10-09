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

BOOL MTIDeviceSupportsYCBCRPixelFormat(id<MTLDevice> device) {
    #if TARGET_OS_SIMULATOR
    return NO;
    #elif TARGET_OS_IPHONE
    return [device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily3_v1];
    #else
    return NO;
    #endif
}
