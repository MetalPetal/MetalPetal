//
//  MTIFilter.h
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MTIPixelFormat.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const MTIFilterPassthroughVertexFunctionName;
FOUNDATION_EXPORT NSString * const MTIFilterPassthroughFragmentFunctionName;

FOUNDATION_EXPORT NSString * const MTIFilterUnpremultiplyAlphaFragmentFunctionName;
FOUNDATION_EXPORT NSString * const MTIFilterUnpremultiplyAlphaWithSRGBToLinearRGBFragmentFunctionName;
FOUNDATION_EXPORT NSString * const MTIFilterPremultiplyAlphaFragmentFunctionName;

FOUNDATION_EXPORT NSString * const MTIFilterColorMatrixFragmentFunctionName;

@class MTIImage;

@protocol MTIFilter

@property (nonatomic) MTLPixelFormat outputPixelFormat; //Default: MTIPixelFormatUnspecified aka MTLPixelFormatInvalid

@property (nonatomic, readonly, nullable) MTIImage *outputImage;

@end

@protocol MTIUnaryFilter <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@end

NS_ASSUME_NONNULL_END
