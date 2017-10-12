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
@synthesize outputPixelFormat = _outputPixelFormat;

+ (MTIRenderPipelineKernel *)kernel {
    static NSMutableDictionary *kernels;
    static NSLock *kernelsLock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernels = [NSMutableDictionary dictionary];
        kernelsLock = [[NSLock alloc] init];
    });
    
    NSString *fragmentFunctionName = [self fragmentFunctionName];
    
    [kernelsLock lock];
    MTIRenderPipelineKernel *kernel = kernels[fragmentFunctionName];
    if (!kernel) {
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:fragmentFunctionName]];
        kernels[fragmentFunctionName] = kernel;
    }
    [kernelsLock unlock];
    
    return kernel;
}

- (MTIImage *)outputImage {
    if (!_inputImage) {
        return nil;
    }
    return [self.class imageByProcessingImage:_inputImage withInputParameters:MTIFilterGetParametersDictionary(self) outputPixelFormat:_outputPixelFormat];
}

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image withInputParameters:(NSDictionary<NSString *,id> *)parameters outputPixelFormat:(MTLPixelFormat)outputPixelFormat {
    return [[self kernel] applyToInputImages:@[image] parameters:parameters outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(image.size) outputPixelFormat:outputPixelFormat];
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
