//
//  MTILensBlurFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 13/10/2017.
//

#import "MTILensBlurFilter.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIVector.h"

@implementation MTILensBlurFilter
@synthesize outputPixelFormat = _outputPixelFormat;

+ (MTIRenderPipelineKernel *)prepassKernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"lensBlurPre"]];
    });
    return kernel;
}

+ (MTIRenderPipelineKernel *)alphaPassKernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"lensBlurAlpha"]
                                                                  vertexDescriptor:nil
                                                              colorAttachmentCount:2];
    });
    return kernel;
}

+ (MTIRenderPipelineKernel *)bravoCharliePassKernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"lensBlurBravoCharlie"]];
    });
    return kernel;
}

+ (NSSet<NSString *> *)inputParameterKeys {
    return [NSSet setWithArray:@[@"radius", @"brightness", @"angle"]];
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    if (self.radius == 0) {
        return self.inputImage;
    }
    
    MTIImage *maskImage = self.inputMaskImage;
    if (!maskImage) {
        maskImage = [[MTIImage alloc] initWithColor:MTIColorMake(1, 1, 1, 1) sRGB:NO size:CGSizeMake(1, 1)];
    }
    
    NSMutableArray *deltas = [NSMutableArray array];
    for (NSInteger i = 0; i < 3; ++i) {
        float a = self.angle + i * M_PI * 2.0 / 3.0;
        MTIVector *delta = [[MTIVector alloc] initWithCGSize:CGSizeMake(self.radius * sin(a)/self.inputImage.size.width, self.radius * cos(a)/self.inputImage.size.height)];
        [deltas addObject:delta];
    }
    
    float power = pow(10, MIN(MAX(self.brightness, -1), 1));
    
    MTIImage *prepassOutputImage = [[MTILensBlurFilter prepassKernel] applyToInputImages:@[self.inputImage]
                                                                              parameters:@{@"power": @(power)}
                                                                 outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(self.inputImage.size)
                                                                       outputPixelFormat:MTLPixelFormatRGBA16Float];
    NSArray<MTIImage *> *alphaOutputs = [[MTILensBlurFilter alphaPassKernel] applyToInputImages:@[prepassOutputImage, maskImage]
                                                                                     parameters:@{@"delta0": deltas[0],
                                                                                                  @"delta1": deltas[1],
                                                                                                  }
                                                                              outputDescriptors:@[[[MTIRenderPipelineOutputDescriptor alloc] initWithDimensions:MTITextureDimensionsMake2DFromCGSize(self.inputImage.size)],[[MTIRenderPipelineOutputDescriptor alloc] initWithDimensions:MTITextureDimensionsMake2DFromCGSize(self.inputImage.size)]]
                                                                              outputPixelFormat:MTLPixelFormatRGBA16Float];
    MTIImage *outputImage = [[MTILensBlurFilter bravoCharliePassKernel] applyToInputImages:@[alphaOutputs[0],alphaOutputs[1],maskImage,self.inputImage]
                                                                                parameters:@{@"delta0": deltas[1],
                                                                                             @"delta1": deltas[2],
                                                                                             @"power": @((float)1.0/power)
                                                                                             }
                                                                   outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(self.inputImage.size)
                                                                         outputPixelFormat:_outputPixelFormat];
    return outputImage;
}

@end
