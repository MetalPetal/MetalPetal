//
//  MTIError.h
//  Pods
//
//  Created by YuAo on 10/08/2017.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const MTIErrorDomain;

typedef NS_ERROR_ENUM(MTIErrorDomain, MTIError) {
    //Core errors
    MTIErrorDeviceNotFound = 1001,
    MTIErrorFunctionNotFound = 1002,
    MTIErrorCoreVideoDoesNotSupportMetal = 1003,
    MTIErrorCoreVideoMetalTextureCacheFailedToCreateTexture = 1004,
    
    //Texture loading errors
    MTIErrorUnsupportedCVPixelBufferFormat = 2001,
    MTIErrorFailedToLoadTexture = 2002,
    
    //Image errors
    MTIErrorUnsupportedImageCachePolicy = 3001,
    
    //Kernel errors
    MTIErrorDataBufferSizeMismatch = 4001,
    MTIErrorParameterDataTypeNotSupported = 4002,
    MTIErrorMPSKernelInputCountMismatch = 4003,
    MTIErrorMPSKernelNotSupported = 4004,
    
    //Render errors
    MTIErrorEmptyDrawable = 5001,
    MTIErrorFailedToCreateCGImageFromCVPixelBuffer = 5002,
    MTIErrorFailedToCreateCVPixelBuffer = 5003,
    MTIErrorInvalidCVPixelBufferRenderingAPI = 5004,
    MTIErrorFailedToGetRenderedBuffer = 5005,
};

NS_ASSUME_NONNULL_END
