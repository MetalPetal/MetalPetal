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

+ (MTIRenderPipelineKernel *)kernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName] fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"roundCorner"]];
    });
    return kernel;
}

- (MTIVertices *)verticesForRect:(CGRect)rect radius:(float)radius {
    CGFloat l = (CGRectGetMinX(rect) / self.inputImage.size.width) * 2 - 1;
    CGFloat r = (CGRectGetMaxX(rect) / self.inputImage.size.width) * 2 - 1;
    CGFloat t = (CGRectGetMinY(rect) / self.inputImage.size.height) * 2 - 1;
    CGFloat b = (CGRectGetMaxY(rect) / self.inputImage.size.height) * 2 - 1;
    MTIVertex vertices[] = {
        MTIVertexMake(l, t, 0, 1, 0, radius),
        MTIVertexMake(r, t, 0, 1, radius, radius),
        MTIVertexMake(l, b, 0, 1, 0, 0),
        MTIVertexMake(r, b, 0, 1, radius, 0)
    };
    return [[MTIVertices alloc] initWithVertices:vertices count:4 primitiveType:MTLPrimitiveTypeTriangleStrip];
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    
    simd_float4 radius = self.radius;
    
    if (simd_equal(radius, simd_make_float4(0))) {
        return self.inputImage;
    }
    
    return [MTIRoundCornerFilter.kernel applyToInputImages:@[_inputImage] parameters:@{@"radius": [MTIVector vectorWithFloat4:_radius]} outputTextureDimensions:_inputImage.dimensions outputPixelFormat:_outputPixelFormat];
}

@end
