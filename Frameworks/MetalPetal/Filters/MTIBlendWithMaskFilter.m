//
//  MTIMaskBlendFilter.m
//  MetalPetal
//
//  Created by 杨乃川 on 2017/10/26.
//

#import "MTIBlendWithMaskFilter.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"

@implementation MTIBlendWithMaskFilter
@synthesize outputPixelFormat = _outputPixelFormat;

+ (MTIRenderPipelineKernel *)kernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"blendWithMask"]];
    });
    return kernel;
}

- (MTIImage *)outputImage {
    if (!self.inputImage || !self.inputMask || !self.inputBackgroundImage) {
        return nil;
    }
    BOOL usesOneMinusMaskValue = self.inputMask.mode == MTIMaskModeOneMinusMaskValue;
    return [self.class.kernel applyToInputImages:@[self.inputImage, self.inputMask.content, self.inputBackgroundImage]
                                      parameters:@{@"maskComponent": @((int)self.inputMask.component),
                                                   @"usesOneMinusMaskValue": @(usesOneMinusMaskValue)}
                         outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(_inputBackgroundImage.size)
                               outputPixelFormat:_outputPixelFormat];
}

@end
