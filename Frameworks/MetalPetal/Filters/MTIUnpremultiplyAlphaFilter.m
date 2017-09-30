//
//  MTIUnpremultiplyAlphaFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 30/09/2017.
//

#import "MTIUnpremultiplyAlphaFilter.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"

@implementation MTIUnpremultiplyAlphaFilter

+ (MTIRenderPipelineKernel *)kernelWithPixelFormat:(MTLPixelFormat)pixelFormat {
    static NSMutableDictionary *kernels;
    static NSLock *kernelsLock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernels = [NSMutableDictionary dictionary];
        kernelsLock = [[NSLock alloc] init];
    });
    
    [kernelsLock lock];
    MTIRenderPipelineKernel *kernel = kernels[@(pixelFormat)];
    if (!kernel) {
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"unpremultiplyAlpha"]
                                                        colorAttachmentPixelFormat:pixelFormat];
        kernels[@(pixelFormat)] = kernel;
    }
    [kernelsLock unlock];
    return kernel;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    return [MTIUnpremultiplyAlphaFilter imageByProcessingImage:self.inputImage];
}

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image {
    MTLPixelFormat pixelFormat = MTLPixelFormatRGBA8Unorm_sRGB;
    MTLTextureDescriptor *outputTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:image.size.width height:image.size.height mipmapped:NO];
    outputTextureDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    return [[MTIUnpremultiplyAlphaFilter kernelWithPixelFormat:pixelFormat] applyToInputImages:@[image] parameters:@{} outputTextureDescriptor:outputTextureDescriptor];
}

+ (NSSet<NSString *> *)inputParameterKeys {
    return [NSSet set];
}

@end
