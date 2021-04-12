//
//  MTIUnpremultiplyAlphaFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 30/09/2017.
//

#import "MTIAlphaPremultiplicationFilter.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIPixelFormat.h"

@implementation MTIUnpremultiplyAlphaFilter
@synthesize inputImage = _inputImage;
@synthesize outputPixelFormat = _outputPixelFormat;

+ (MTIRenderPipelineKernel *)kernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterUnpremultiplyAlphaFragmentFunctionName]
                                                                  vertexDescriptor:nil
                                                              colorAttachmentCount:1
                                                             alphaTypeHandlingRule:[[MTIAlphaTypeHandlingRule alloc] initWithAcceptableAlphaTypes:@[@(MTIAlphaTypePremultiplied)] outputAlphaType:MTIAlphaTypeNonPremultiplied]];
    });
    return kernel;
}

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image outputPixelFormat:(MTLPixelFormat)pixelFormat {
    if (image.alphaType == MTIAlphaTypeAlphaIsOne || image.alphaType == MTIAlphaTypeNonPremultiplied) {
        return image;
    }
    return [MTIUnpremultiplyAlphaFilter.kernel applyToInputImages:@[image] parameters:@{} outputTextureDimensions:image.dimensions outputPixelFormat:pixelFormat];
}

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image {
    return [MTIUnpremultiplyAlphaFilter imageByProcessingImage:image outputPixelFormat:MTIPixelFormatUnspecified];
}

- (MTIImage *)outputImage {
    if (!_inputImage) {
        return nil;
    }
    return [MTIUnpremultiplyAlphaFilter imageByProcessingImage:_inputImage outputPixelFormat:_outputPixelFormat];
}

@end

@implementation MTIPremultiplyAlphaFilter
@synthesize inputImage = _inputImage;
@synthesize outputPixelFormat = _outputPixelFormat;

+ (MTIRenderPipelineKernel *)kernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPremultiplyAlphaFragmentFunctionName]
                                                                  vertexDescriptor:nil
                                                              colorAttachmentCount:1
                                                             alphaTypeHandlingRule:[[MTIAlphaTypeHandlingRule alloc] initWithAcceptableAlphaTypes:@[@(MTIAlphaTypeNonPremultiplied)] outputAlphaType:MTIAlphaTypePremultiplied]];
    });
    return kernel;
}

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image outputPixelFormat:(MTLPixelFormat)pixelFormat {
    if (image.alphaType == MTIAlphaTypeAlphaIsOne || image.alphaType == MTIAlphaTypePremultiplied) {
        return image;
    }
    return [MTIPremultiplyAlphaFilter.kernel applyToInputImages:@[image] parameters:@{} outputTextureDimensions:image.dimensions outputPixelFormat:pixelFormat];
}

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image {
    return [MTIPremultiplyAlphaFilter imageByProcessingImage:image outputPixelFormat:MTIPixelFormatUnspecified];
}

- (MTIImage *)outputImage {
    if (!_inputImage) {
        return nil;
    }
    return [MTIPremultiplyAlphaFilter imageByProcessingImage:_inputImage outputPixelFormat:_outputPixelFormat];
}

@end
