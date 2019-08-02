//
//  MTIFilter.m
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import "MTIFilter.h"
#import "MTIVertex.h"
#import "MTIImage.h"
#import "MTIFunctionDescriptor.h"

NSString * const MTIFilterPassthroughVertexFunctionName = @"passthroughVertex";
NSString * const MTIFilterPassthroughFragmentFunctionName = @"passthrough";

NSString * const MTIFilterUnpremultiplyAlphaFragmentFunctionName = @"unpremultiplyAlpha";
NSString * const MTIFilterUnpremultiplyAlphaWithSRGBToLinearRGBFragmentFunctionName = @"unpremultiplyAlphaWithSRGBToLinearRGB";
NSString * const MTIFilterPremultiplyAlphaFragmentFunctionName = @"premultiplyAlpha";

NSString * const MTIFilterColorMatrixFragmentFunctionName = @"colorMatrixProjection";

