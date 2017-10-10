//
//  MTIUnaryImageFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 10/10/2017.
//

#import "MTIUnaryImageFilter.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIFilterUtilities.h"

@implementation MTIUnaryImageFilter

+ (MTIRenderPipelineKernel *)kernelWithPixelFormat:(MTLPixelFormat)pixelFormat {
    static NSMutableDictionary *kernels;
    static NSLock *kernelsLock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernels = [NSMutableDictionary dictionary];
        kernelsLock = [[NSLock alloc] init];
    });
    
    NSString *fragmentFunctionName = [self fragmentFunctionName];
    NSString *kernelKey = [fragmentFunctionName stringByAppendingFormat:@"-%@",@(pixelFormat)];
    
    [kernelsLock lock];
    MTIRenderPipelineKernel *kernel = kernels[kernelKey];
    if (!kernel) {
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:fragmentFunctionName]
                                                        colorAttachmentPixelFormat:pixelFormat];
        kernels[kernelKey] = kernel;
    }
    [kernelsLock unlock];
    
    return kernel;
}

- (MTIImage *)outputImage {
    if (!_inputImage) {
        return nil;
    }
    return [self.class imageByProcessingImage:_inputImage withInputParameters:MTIFilterGetParametersDictionary(self)];
}

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image withInputParameters:(NSDictionary<NSString *,id> *)parameters {
    MTLPixelFormat pixelFormat = MTLPixelFormatBGRA8Unorm;
    MTLTextureDescriptor *outputTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:image.size.width height:image.size.height mipmapped:NO];
    outputTextureDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    return [[self kernelWithPixelFormat:pixelFormat] applyToInputImages:@[image] parameters:parameters outputTextureDescriptor:outputTextureDescriptor];
}

+ (NSSet<NSString *> *)inputParameterKeys {
    return [NSSet set];
}

@end

@implementation MTIUnaryImageFilter (SubclassingHooks)

+ (NSString *)fragmentFunctionName {
    return MTIFilterPassthroughFragmentFunctionName;
}

@end
