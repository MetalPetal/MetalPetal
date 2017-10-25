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
#import "MTIFilterUtilities.h"

@implementation MTIPremultiplyAlphaFilter

+ (NSString *)fragmentFunctionName {
    return MTIFilterPremultiplyAlphaFragmentFunctionName;
}

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image {
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

+ (NSString *)fragmentFunctionName {
    return MTIFilterUnpremultiplyAlphaFragmentFunctionName;
}

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image {
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
