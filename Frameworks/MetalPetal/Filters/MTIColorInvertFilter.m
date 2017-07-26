//
//  MTIColorInvertFilter.m
//  Pods
//
//  Created by YuAo on 27/06/2017.
//
//

#import "MTIColorInvertFilter.h"
#import "MTIFilterFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIKernel.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIFilter+Property.h"

@implementation MTIColorInvertFilter

+ (MTIRenderPipelineKernel *)kernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFilterFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFilterFunctionDescriptor alloc] initWithName:@"colorInvert"]
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
    return [self.class.kernel applyToInputImages:@[self.inputImage] parameters:parametersDictionaryFor(self) outputTextureDescriptor:outputTextureDescriptor];
}

@end
