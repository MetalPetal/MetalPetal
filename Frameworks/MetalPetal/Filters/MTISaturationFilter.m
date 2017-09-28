//
//  MTISaturationFilter.m
//  Pods
//
//  Created by YuAo on 01/07/2017.
//
//

#import "MTISaturationFilter.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIKernel.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIFilterUtilities.h"

@implementation MTISaturationFilter

+ (MTIRenderPipelineKernel *)kernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"saturationAdjust"]
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
    return [self.class.kernel applyToInputImages:@[self.inputImage] parameters:MTIFilterGetParametersDictionary(self) outputTextureDescriptor:outputTextureDescriptor];
}

+ (NSSet *)inputParameterKeys {
    return [NSSet setWithObjects:@"saturation", nil];
}
@end
