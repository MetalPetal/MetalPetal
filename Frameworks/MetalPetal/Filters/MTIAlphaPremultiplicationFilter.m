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

@implementation MTIPremultiplyAlphaFilter

+ (MTIFunctionDescriptor *)fragmentFunctionDescriptor {
    return [[MTIFunctionDescriptor alloc] initWithName:MTIFilterPremultiplyAlphaFragmentFunctionName];
}

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image {
    if (image.alphaType == MTIAlphaTypeAlphaIsOne || image.alphaType == MTIAlphaTypePremultiplied) {
        return image;
    }
    return [self imageByProcessingImage:image withInputParameters:@{} outputPixelFormat:MTIPixelFormatUnspecified];
}

+ (MTIAlphaTypeHandlingRule *)alphaTypeHandlingRule {
    return [[MTIAlphaTypeHandlingRule alloc] initWithAcceptableAlphaTypes:@[@(MTIAlphaTypeNonPremultiplied)] outputAlphaType:MTIAlphaTypePremultiplied];
}

- (MTIImage *)outputImage {
    if (self.inputImage.alphaType == MTIAlphaTypeAlphaIsOne || self.inputImage.alphaType == MTIAlphaTypePremultiplied) {
        return self.inputImage;
    }
    return [super outputImage];
}

@end

@implementation MTIUnpremultiplyAlphaFilter

+ (MTIFunctionDescriptor *)fragmentFunctionDescriptor {
    return [[MTIFunctionDescriptor alloc] initWithName:MTIFilterUnpremultiplyAlphaFragmentFunctionName];
}

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image {
    if (image.alphaType == MTIAlphaTypeAlphaIsOne || image.alphaType == MTIAlphaTypeNonPremultiplied) {
        return image;
    }
    return [self imageByProcessingImage:image withInputParameters:@{} outputPixelFormat:MTIPixelFormatUnspecified];
}

+ (MTIAlphaTypeHandlingRule *)alphaTypeHandlingRule {
    return [[MTIAlphaTypeHandlingRule alloc] initWithAcceptableAlphaTypes:@[@(MTIAlphaTypePremultiplied)] outputAlphaType:MTIAlphaTypeNonPremultiplied];
}

- (MTIImage *)outputImage {
    if (self.inputImage.alphaType == MTIAlphaTypeAlphaIsOne || self.inputImage.alphaType == MTIAlphaTypeNonPremultiplied) {
        return self.inputImage;
    }
    return [super outputImage];
}

@end

@implementation MTIUnpremultiplyAlphaWithSRGBToLinearRGBFilter

+ (MTIFunctionDescriptor *)fragmentFunctionDescriptor {
    return [[MTIFunctionDescriptor alloc] initWithName:MTIFilterUnpremultiplyAlphaWithSRGBToLinearRGBFragmentFunctionName];
}

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image {
    if (image.alphaType == MTIAlphaTypeAlphaIsOne || image.alphaType == MTIAlphaTypeNonPremultiplied) {
        return image;
    }
    return [self imageByProcessingImage:image withInputParameters:@{} outputPixelFormat:MTIPixelFormatUnspecified];
}

+ (MTIAlphaTypeHandlingRule *)alphaTypeHandlingRule {
    return [[MTIAlphaTypeHandlingRule alloc] initWithAcceptableAlphaTypes:@[@(MTIAlphaTypePremultiplied)] outputAlphaType:MTIAlphaTypeNonPremultiplied];
}

- (MTIImage *)outputImage {
    if (self.inputImage.alphaType == MTIAlphaTypeAlphaIsOne || self.inputImage.alphaType == MTIAlphaTypeNonPremultiplied) {
        return self.inputImage;
    }
    return [super outputImage];
}

@end
