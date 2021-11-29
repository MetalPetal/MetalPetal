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
    MTIErrorFailedToCreateSamplerState = 1003,
    MTIErrorFailedToCreateTexture = 1004,
    MTIErrorFailedToCreateCommandEncoder = 1005,
    MTIErrorFailedToCreateHeap = 1006,
    MTIErrorDefaultLibraryNotFound = 1007,
    MTIErrorBlendFunctionNotFound = 1008,
    
    //Texture loading errors
    MTIErrorUnsupportedCVPixelBufferFormat = 2001,
    MTIErrorTextureDimensionsMismatch = 2002,
    MTIErrorTextureLoaderFailedToCreateCGContext = 2004,
    MTIErrorTextureLoaderFailedToCreateCGImage = 2005,

    //Image errors
    MTIErrorUnsupportedImageCachePolicy = 3001,
    
    //Kernel errors
    MTIErrorParameterDataSizeMismatch = 4001,
    MTIErrorUnsupportedParameterType = 4002,
    MTIErrorMPSKernelInputCountMismatch = 4003,
    MTIErrorMPSKernelNotSupported = 4004,
    MTIErrorTextureBindingFailed = 4005,
    MTIErrorParameterDataTypeMismatch = 4006,
    
    //Render errors
    MTIErrorEmptyDrawable = 5001,
    MTIErrorEmptyDrawableTexture = 5101,
    MTIErrorFailedToCreateCGImageFromCVPixelBuffer = 5002,
    MTIErrorFailedToCreateCVPixelBuffer = 5003,
    MTIErrorInvalidCVPixelBufferRenderingAPI = 5004,
    MTIErrorFailedToGetRenderedBuffer = 5005,
    
    //For operations do not support cross device or cross context rendering, we report these errors.
    MTIErrorCrossDeviceRendering = 5006,
    MTIErrorCrossContextRendering = 5007,
    
    MTIErrorInvalidTextureDimension = 5008,
        
    //For features not available on iOS simulator.
    MTIErrorFeatureNotAvailableOnSimulator = 6001
};

/// Create a NSError with MTIErrorDomain and the specified error code and user info. Creating a symbolic breakpoint for `_MTIErrorCreate` can help you locate the source of the error.
FOUNDATION_EXPORT NSError * _MTIErrorCreate(MTIError code, NSString *defaultDescription, NSDictionary * _Nullable userInfo);

#define MTIErrorCreate(code, userInfo) _MTIErrorCreate(code, @#code, userInfo)

NS_ASSUME_NONNULL_END
