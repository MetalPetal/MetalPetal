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
    MTLTextureDescriptor *outputTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm_sRGB width:self.inputImage.size.width height:self.inputImage.size.height mipmapped:NO];
    outputTextureDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;
    return [self.class.kernel applyToInputImages:@[self.inputImage] parameters:MTIFilterGetParametersDictionary(self) outputTextureDescriptor:outputTextureDescriptor];
}

+ (NSSet *)inputParameterKeys {
    return [NSSet setWithObjects:@"exposure", nil];
}

@end
