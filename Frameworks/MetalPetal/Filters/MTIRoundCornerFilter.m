//
//  MTIRoundCornerFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 2019/12/20.
//

#import "MTIRoundCornerFilter.h"
#import "MTIFunctionDescriptor.h"
#import "MTIVector+SIMD.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIImage.h"
#import "MTIVector.h"
#import "MTIVertex.h"
#import "MTIRenderPassOutputDescriptor.h"

@implementation MTIRoundCornerFilter
@synthesize inputImage = _inputImage;
@synthesize outputPixelFormat = _outputPixelFormat;
@synthesize radius = _deprecated_radius;

+ (MTIRenderPipelineKernel *)circularCornerKernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName] fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"circularCorner"]];
    });
    return kernel;
}

+ (MTIRenderPipelineKernel *)continuousCornerKernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName] fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"continuousCorner"]];
    });
    return kernel;
}

- (void)setRadius:(simd_float4)radius {
    _cornerRadius = MTICornerRadiusMake(radius[0], radius[1], radius[2], radius[3]);
    _cornerCurve = MTICornerCurveCircular;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    simd_float4 radius = _MTICornerRadiusGetShadingParameterValue(_cornerRadius, _cornerCurve);
    if (simd_equal(radius, simd_make_float4(0))) {
        return self.inputImage;
    }
    
    MTIRenderPipelineKernel *kernel;
    switch (_cornerCurve) {
        case MTICornerCurveCircular:
            kernel = MTIRoundCornerFilter.circularCornerKernel;
            break;
        case MTICornerCurveContinuous:
            kernel = MTIRoundCornerFilter.continuousCornerKernel;
            break;
        default:
            NSAssert(NO, @"Unsupported MTICornerCurve value.");
            kernel = MTIRoundCornerFilter.circularCornerKernel;
            break;
    }
    return [kernel applyToInputImages:@[_inputImage] parameters:@{@"radius": [MTIVector vectorWithFloat4:radius]} outputTextureDimensions:_inputImage.dimensions outputPixelFormat:_outputPixelFormat];
}

@end
