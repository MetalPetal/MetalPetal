//
//  MTIRGBColorSpaceConversionFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 2019/2/11.
//

#import "MTIRGBColorSpaceConversionFilter.h"
#import "MTIFunctionDescriptor.h"
#import "MTIPixelFormat.h"
#import "MTILock.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIImage.h"

@implementation MTILinearToSRGBToneCurveFilter

+ (MTIFunctionDescriptor *)fragmentFunctionDescriptor {
    return [[MTIFunctionDescriptor alloc] initWithName:@"convertLinearRGBToSRGB"];
}

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image {
    return [self imageByProcessingImage:image withInputParameters:@{} outputPixelFormat:MTIPixelFormatUnspecified];
}

@end

@implementation MTISRGBToneCurveToLinearFilter

+ (MTIFunctionDescriptor *)fragmentFunctionDescriptor {
    return [[MTIFunctionDescriptor alloc] initWithName:@"convertSRGBToLinearRGB"];
}

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image {
    return [self imageByProcessingImage:image withInputParameters:@{} outputPixelFormat:MTIPixelFormatUnspecified];
}

@end

@implementation MTIITUR709RGBToLinearRGBFilter

+ (MTIFunctionDescriptor *)fragmentFunctionDescriptor {
    return [[MTIFunctionDescriptor alloc] initWithName:@"convertITUR709RGBToLinearRGB"];
}

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image {
    return [self imageByProcessingImage:image withInputParameters:@{} outputPixelFormat:MTIPixelFormatUnspecified];
}

@end

@implementation MTIITUR709RGBToSRGBFilter

+ (MTIFunctionDescriptor *)fragmentFunctionDescriptor {
    return [[MTIFunctionDescriptor alloc] initWithName:@"convertITUR709RGBToSRGB"];
}

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image {
    return [self imageByProcessingImage:image withInputParameters:@{} outputPixelFormat:MTIPixelFormatUnspecified];
}

@end

@implementation MTIRGBColorSpaceConversionFilter
@synthesize inputImage = _inputImage;
@synthesize outputPixelFormat = _outputPixelFormat;

+ (MTIRenderPipelineKernel *)kernelWithInputColorSpace:(MTIRGBColorSpace)inputColorSpace
                                      outputColorSpace:(MTIRGBColorSpace)outputColorSpace
                                        inputAlphaType:(MTIAlphaType)inputAlphaType
                                       outputAlphaType:(MTIAlphaType)outputAlphaType
{
    MTLFunctionConstantValues *constantValues = [[MTLFunctionConstantValues alloc] init];
    short inputColorSpaceValue = (short)inputColorSpace;
    short outputColorSpaceValue = (short)outputColorSpace;
    bool inputHasPremultipliedAlpha = inputAlphaType == MTIAlphaTypePremultiplied;
    bool outputsPremultipliedAlpha = outputAlphaType == MTIAlphaTypePremultiplied;
    bool outputsOpaqueImage = outputAlphaType == MTIAlphaTypeAlphaIsOne;
    [constantValues setConstantValue:&inputHasPremultipliedAlpha type:MTLDataTypeBool withName:@"metalpetal::rgb_color_space_conversion_input_has_premultiplied_alpha"];
    [constantValues setConstantValue:&inputColorSpaceValue type:MTLDataTypeShort withName:@"metalpetal::rgb_color_space_conversion_input_color_space"];
    [constantValues setConstantValue:&outputColorSpaceValue type:MTLDataTypeShort withName:@"metalpetal::rgb_color_space_conversion_output_color_space"];
    [constantValues setConstantValue:&outputsPremultipliedAlpha type:MTLDataTypeBool withName:@"metalpetal::rgb_color_space_conversion_outputs_premultiplied_alpha"];
    [constantValues setConstantValue:&outputsOpaqueImage type:MTLDataTypeBool withName:@"metalpetal::rgb_color_space_conversion_outputs_opaque_image"];

    static NSMutableDictionary *kernels;
    static id<MTILocking> kernelsLock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernels = [NSMutableDictionary dictionary];
        kernelsLock = MTILockCreate();
    });
    
    [kernelsLock lock];
    MTIRenderPipelineKernel *kernel = kernels[constantValues];
    if (!kernel) {
        MTIFunctionDescriptor *fragmentFunctionDescriptor = [[MTIFunctionDescriptor alloc] initWithName:@"rgbColorSpaceConvert" constantValues:constantValues libraryURL:nil];
        MTIAlphaTypeHandlingRule *rule = [[MTIAlphaTypeHandlingRule alloc] initWithAcceptableAlphaTypes:@[@(MTIAlphaTypePremultiplied), @(MTIAlphaTypeNonPremultiplied),@(MTIAlphaTypeAlphaIsOne)] outputAlphaType:outputAlphaType];
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:fragmentFunctionDescriptor
                                                                  vertexDescriptor:nil
                                                              colorAttachmentCount:1
                                                             alphaTypeHandlingRule:rule];
        kernels[constantValues] = kernel;
    }
    [kernelsLock unlock];
    
    return kernel;
}

- (instancetype)init {
    if (self = [super init]) {
        _inputColorSpace = MTIRGBColorSpaceLinearSRGB;
        _outputColorSpace = MTIRGBColorSpaceLinearSRGB;
        _outputAlphaType = MTIAlphaTypeNonPremultiplied;
    }
    return self;
}

- (MTIImage *)outputImage {
    if (!_inputImage) {
        return nil;
    }
    return [MTIRGBColorSpaceConversionFilter imageByConvertingImage:_inputImage fromColorSpace:_inputColorSpace toColorSpace:_outputColorSpace outputAlphaType:_outputAlphaType outputPixelFormat:_outputPixelFormat];
}

+ (MTIImage *)imageByConvertingImage:(MTIImage *)image fromColorSpace:(MTIRGBColorSpace)inputColorSpace toColorSpace:(MTIRGBColorSpace)outputColorSpace outputAlphaType:(MTIAlphaType)outputAlphaType outputPixelFormat:(MTLPixelFormat)pixelFormat {
    return [[self kernelWithInputColorSpace:inputColorSpace outputColorSpace:outputColorSpace inputAlphaType:image.alphaType outputAlphaType:outputAlphaType] applyToInputImages:@[image] parameters:@{} outputTextureDimensions:image.dimensions outputPixelFormat:pixelFormat];
}

@end
