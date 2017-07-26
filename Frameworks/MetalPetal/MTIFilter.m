//
//  MTIFilter.m
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import "MTIFilter.h"
#import "MTIVertex.h"
#import "MTIImageRenderingContext.h"
#import "MTIImage.h"
#import "MTIFilterFunctionDescriptor.h"
#import "MTIFilter+Property.h"


NSString * const MTIFilterPassthroughVertexFunctionName = @"passthroughVertexShader";
NSString * const MTIFilterPassthroughFragmentFunctionName = @"passthroughFragmentShader";

@interface MTIFilter ()

@end

@implementation MTIFilter

- (MTIImage *)outputImage {
    return nil;
}

@end
