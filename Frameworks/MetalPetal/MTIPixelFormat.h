//
//  MTIPixelFormat.h
//  MetalPetal
//
//  Created by Yu Ao on 11/10/2017.
//


#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT MTLPixelFormat const MTIPixelFormatUnspecified;   //aliased to MTLPixelFormatInvalid

FOUNDATION_EXPORT MTLPixelFormat const MTIPixelFormatYCBCR8_420_2P;
FOUNDATION_EXPORT MTLPixelFormat const MTIPixelFormatYCBCR8_420_2P_sRGB;

FOUNDATION_EXPORT BOOL MTIDeviceSupportsYCBCRPixelFormat(id<MTLDevice> device);

NS_ASSUME_NONNULL_END

