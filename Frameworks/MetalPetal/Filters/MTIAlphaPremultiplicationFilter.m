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
#import "MTIFilterUtilities.h"

@interface MTIAlphaPremultiplicationFilter () <MTIFilter>

@end

@implementation MTIAlphaPremultiplicationFilter

+ (NSString *)fragmentFunctionName {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"" userInfo:nil];
}

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
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:[self fragmentFunctionName]]
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
    return [self.class imageByProcessingImage:self.inputImage];
}

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image {
    MTLPixelFormat pixelFormat = MTLPixelFormatBGRA8Unorm;
    MTLTextureDescriptor *outputTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:image.size.width height:image.size.height mipmapped:NO];
    outputTextureDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    return [[self.class kernelWithPixelFormat:pixelFormat] applyToInputImages:@[image] parameters:@{} outputTextureDescriptor:outputTextureDescriptor];
}

+ (NSSet<NSString *> *)inputParameterKeys {
    return [NSSet set];
}

@end

@implementation MTIPremultiplyAlphaFilter

+ (NSString *)fragmentFunctionName {
    return @"premultiplyAlpha";
}

@end

@implementation MTIUnpremultiplyAlphaFilter

+ (NSString *)fragmentFunctionName {
    return @"unpremultiplyAlpha";
}

@end
