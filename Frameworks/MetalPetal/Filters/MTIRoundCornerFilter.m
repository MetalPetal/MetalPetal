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
    
#define MTI_TARGET_SUPPORT_READ_FROM_COLOR_ATTACHMENTS (TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR)

#if MTI_TARGET_SUPPORT_READ_FROM_COLOR_ATTACHMENTS
    MTIRenderCommand *command = [[MTIRenderCommand alloc] initWithKernel: MTIRenderPipelineKernel.passthroughRenderPipelineKernel geometry:MTIVertices.fullViewportSquareVertices images:@[self.inputImage] parameters:@{}];
    NSMutableArray<MTIRenderCommand *> *commands = [NSMutableArray array];
    [commands addObject:command];
    
    if (radius[3] > 0) {
        [commands addObject:[[MTIRenderCommand alloc] initWithKernel:MTIRoundCornerFilter.kernel geometry:[self verticesForRect:CGRectMake(0, 0, radius[3], radius[3]) radius:radius[3]] images:@[] parameters:@{
            @"center": [MTIVector vectorWithX:radius[3] Y:0],
            @"radius": @(radius[3])
        }]];
    }
    if (radius[2] > 0) {
        [commands addObject:[[MTIRenderCommand alloc] initWithKernel:MTIRoundCornerFilter.kernel geometry:[self verticesForRect:CGRectMake(self.inputImage.size.width - radius[2], 0, radius[2], radius[2]) radius:radius[2]] images:@[] parameters:@{
            @"center": [MTIVector vectorWithX:0 Y:0],
            @"radius": @(radius[2])
        }]];
    }
    if (radius[1] > 0) {
        [commands addObject:[[MTIRenderCommand alloc] initWithKernel:MTIRoundCornerFilter.kernel geometry:[self verticesForRect:CGRectMake(self.inputImage.size.width - radius[1], self.inputImage.size.height - radius[1], radius[1], radius[1]) radius:radius[1]] images:@[] parameters:@{
            @"center": [MTIVector vectorWithX:0 Y:radius[1]],
            @"radius": @(radius[1])
        }]];
    }
    if (radius[0] > 0) {
        [commands addObject:[[MTIRenderCommand alloc] initWithKernel:MTIRoundCornerFilter.kernel geometry:[self verticesForRect:CGRectMake(0, self.inputImage.size.height - radius[0], radius[0], radius[0]) radius:radius[0]] images:@[] parameters:@{
            @"center": [MTIVector vectorWithX:radius[0] Y:radius[0]],
            @"radius": @(radius[0])
        }]];
    }
    MTIRenderPassOutputDescriptor *outputDescriptor = [[MTIRenderPassOutputDescriptor alloc] initWithDimensions:self.inputImage.dimensions pixelFormat:self.outputPixelFormat];
    return [MTIRenderCommand imagesByPerformingRenderCommands:commands outputDescriptors:@[outputDescriptor]].firstObject;
#else
    return [MTIRoundCornerFilter.kernel applyToInputImages:@[_inputImage] parameters:@{@"radius": [MTIVector vectorWithFloat4:_radius]} outputTextureDimensions:_inputImage.dimensions outputPixelFormat:_outputPixelFormat];
#endif
}

@end
