//
//  MTISaturationFilter.m
//  Pods
//
//  Created by YuAo on 01/07/2017.
//
//

#import "MTISaturationFilter.h"
#import "MTIFilterFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIKernel.h"
#import "MTIRenderPipelineKernel.h"

@implementation MTISaturationFilter

+ (MTIRenderPipelineKernel *)kernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFilterFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFilterFunctionDescriptor alloc] initWithName:@"saturationAdjust"]
                                                        colorAttachmentPixelFormat:MTLPixelFormatBGRA8Unorm_sRGB];
    });
    return kernel;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    MTLTextureDescriptor *outputTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:self.class.kernel.pixelFormat width:self.inputImage.size.width height:self.inputImage.size.height mipmapped:NO];
    outputTextureDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    return [self.class.kernel applyToInputImages:@[self.inputImage] parameters:self.parametersDictionary outputTextureDescriptor:outputTextureDescriptor];
}

@end
