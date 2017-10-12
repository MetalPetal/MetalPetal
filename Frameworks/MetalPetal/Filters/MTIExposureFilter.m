//
//  MTIExposureFilter.m
//  Pods
//
//  Created by yi chen on 2017/7/27.
//
//

#import "MTIExposureFilter.h"
#import "MTIComputePipelineKernel.h"
#import "MTIFunctionDescriptor.h"
#import "MTIFilterUtilities.h"
#import "MTIImage.h"

@implementation MTIExposureFilter

@synthesize outputPixelFormat = _outputPixelFormat;

+ (MTIComputePipelineKernel *)kernel {
    static MTIComputePipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIComputePipelineKernel alloc] initWithComputeFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"adjustExposure"]];
    });
    return kernel;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    return [self.class.kernel applyToInputImages:@[self.inputImage] parameters:MTIFilterGetParametersDictionary(self) outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(self.inputImage.size) outputPixelFormat:_outputPixelFormat];
}

+ (NSSet *)inputParameterKeys {
    return [NSSet setWithObjects:@"exposure", nil];
}

@end
