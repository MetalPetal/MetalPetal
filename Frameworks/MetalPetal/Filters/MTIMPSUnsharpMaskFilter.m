//
//  MTIUSMSharpenFilter.m
//  MetalPetal
//
//  Created by yi chen on 2018/2/7.
//

#import "MTIMPSUnsharpMaskFilter.h"
#import "MTIMPSGaussianBlurFilter.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"

@interface MTIMPSUnsharpMaskFilter ()

@property (nonatomic,strong) MTIMPSGaussianBlurFilter *gaussianBlurFilter;

@end

@implementation MTIMPSUnsharpMaskFilter
@synthesize outputPixelFormat = _outputPixelFormat;
@synthesize inputImage = _inputImage;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _scale = 0.5;
        _threshold = 0;
        _radius = 2.0;
        _gaussianBlurFilter = [[MTIMPSGaussianBlurFilter alloc] init];
        _gaussianBlurFilter.radius = _radius;
    }
    return self;
}

+ (MTIRenderPipelineKernel *)kernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"usmSecondPass"]];
    });
    return kernel;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    self.gaussianBlurFilter.outputPixelFormat = self.outputPixelFormat;
    self.gaussianBlurFilter.inputImage = self.inputImage;
    self.gaussianBlurFilter.radius = self.radius;
    MTIImage *blurImage = self.gaussianBlurFilter.outputImage;
    if (!blurImage) {
        return nil;
    }
    return [[[self class] kernel] applyToInputImages:@[self.inputImage, blurImage]
                                          parameters:@{@"scale": @(self.scale), @"threshold": @(self.threshold)}
                             outputTextureDimensions: MTITextureDimensionsMake2DFromCGSize(self.inputImage.size)
                                   outputPixelFormat:_outputPixelFormat];
    
    return nil;
}

@end
