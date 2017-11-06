//
//  MTIMaskBlendFilter.m
//  MetalPetal
//
//  Created by 杨乃川 on 2017/10/26.
//

#import "MTIBlendWithMaskFilter.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIFunctionDescriptor.h"
#import "MTIFilterUtilities.h"
#import "MTIImage.h"


@implementation MTIBlendWithMaskFilter
@synthesize outputPixelFormat = _outputPixelFormat;

+ (MTIRenderPipelineKernel *)kernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"maskBlend"]];
    });
    return kernel;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    return [self.class.kernel applyToInputImages:@[self.inputImage, self.inputMaskImage, self.inputBackgroundImage]
                                      parameters:@{@"maskComponent": @(self.maskComponent)}
                         outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(_inputImage.size)
                               outputPixelFormat:_outputPixelFormat];
}

+ (nonnull NSSet<NSString *> *)inputParameterKeys {
    return [NSSet set];
}

@end
