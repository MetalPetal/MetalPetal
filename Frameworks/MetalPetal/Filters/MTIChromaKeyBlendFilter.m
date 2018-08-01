//
//  MTIChromaKeyBlendFilter.m
//  Pods
//
//  Created by Yu Ao on 29/12/2017.
//

#import "MTIChromaKeyBlendFilter.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIVector+SIMD.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"

@implementation MTIChromaKeyBlendFilter
@synthesize outputPixelFormat = _outputPixelFormat;

+ (MTIRenderPipelineKernel *)kernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"chromaKeyBlend"]];
    });
    return kernel;
}

- (instancetype)init {
    if (self = [super init]) {
        _thresholdSensitivity = 0.4;
        _smoothing = 0.1;
        _color = MTIColorMake(0.0, 1.0, 0.0, 1.0);
    }
    return self;
}

- (MTIImage *)outputImage {
    if (!self.inputImage || !self.inputBackgroundImage) {
        return nil;
    }
    return [self.class.kernel applyToInputImages:@[self.inputImage, self.inputBackgroundImage]
                                      parameters:@{@"color": [MTIVector vectorWithFloat4:MTIColorToFloat4(self.color)],
                                                   @"thresholdSensitivity": @(self.thresholdSensitivity),
                                                   @"smoothing": @(self.smoothing)}
                         outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(self.inputImage.size)
                               outputPixelFormat:self.outputPixelFormat];
}

@end
