//
//  MTILookUpTableFilter.m
//  MetalPetal
//
//  Created by 杨乃川 on 2017/10/12.
//

#import "MTIColorLookupFilter.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIFunctionDescriptor.h"
#import "MTIFilterUtilities.h"
#import "MTIImage.h"

@implementation MTIColorLookupFilter

@synthesize outputPixelFormat = _outputPixelFormat;

+ (MTIRenderPipelineKernel *)kernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"colorLookUp512x512"]];
    });
    return kernel;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    return [self.class.kernel applyToInputImages:@[self.inputImage, self.inputColorLookupTable]
                                      parameters:@{}
                         outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(_inputImage.size)
                               outputPixelFormat:_outputPixelFormat];
}

+ (nonnull NSSet<NSString *> *)inputParameterKeys {
    return [NSSet set];
}

@end

