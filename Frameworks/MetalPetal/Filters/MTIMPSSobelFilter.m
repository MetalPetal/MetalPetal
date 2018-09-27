//
//  MTIMPSSobelFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 11/12/2017.
//

#import "MTIMPSSobelFilter.h"
#import "MTIMPSKernel.h"
#import "MTIImage.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIFunctionDescriptor.h"

@interface MTIMPSSobelFilter ()

@property (nonatomic, strong, readonly) MTIMPSKernel *kernel;

@end

@implementation MTIMPSSobelFilter
@synthesize outputPixelFormat = _outputPixelFormat;
@synthesize inputImage = _inputImage;

- (instancetype)init {
    return [self initWithGrayColorTransform:MTIGrayColorTransformDefault];
}

- (instancetype)initWithGrayColorTransform:(simd_float3)grayColorTransform {
    if (self = [super init]) {
        _grayColorTransform = grayColorTransform;
        _kernel = [[MTIMPSKernel alloc] initWithMPSKernelBuilder:^MPSKernel * _Nonnull(id<MTLDevice>  _Nonnull device) {
            const float values[3] = {grayColorTransform.r, grayColorTransform.g, grayColorTransform.b};
            MPSImageSobel *k = [[MPSImageSobel alloc] initWithDevice:device linearGrayColorTransform:values];
            k.edgeMode = MPSImageEdgeModeClamp;
            return k;
        }];
    }
    return self;
}

+ (MTIRenderPipelineKernel *)rToMonochromeKernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"rToMonochrome"]
                                                                  vertexDescriptor:nil
                                                              colorAttachmentCount:1
                                                             alphaTypeHandlingRule:MTIAlphaTypeHandlingRule.generalAlphaTypeHandlingRule];
    });
    return kernel;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    switch (self.colorMode) {
        case MTIMPSSobelColorModeAuto:
            return [self.kernel applyToInputImages:@[_inputImage] parameters:@{} outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(_inputImage.size) outputPixelFormat:_outputPixelFormat];
        case MTIMPSSobelColorModeGrayscale: {
            MTIImage *sobelImage = [self.kernel applyToInputImages:@[_inputImage] parameters:@{} outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(_inputImage.size) outputPixelFormat:MTLPixelFormatR8Unorm];
            return [[self.class rToMonochromeKernel] applyToInputImages:@[sobelImage] parameters:@{@"invert": @NO,
                                                                                                   @"convertSRGBToLinear": @((bool)false)
                                                                                                   } outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(_inputImage.size) outputPixelFormat:_outputPixelFormat];
        }
        case MTIMPSSobelColorModeGrayscaleInverted: {
            MTIImage *sobelImage = [self.kernel applyToInputImages:@[_inputImage] parameters:@{} outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(_inputImage.size) outputPixelFormat:MTLPixelFormatR8Unorm];
            return [[self.class rToMonochromeKernel] applyToInputImages:@[sobelImage] parameters:@{@"invert": @YES,
                                                                                                   @"convertSRGBToLinear": @((bool)false)
                                                                                                   } outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(_inputImage.size) outputPixelFormat:_outputPixelFormat];
        }
        default:
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Unknown MTIMPSSobelOutputMode" userInfo:@{}];
    }
}

@end

