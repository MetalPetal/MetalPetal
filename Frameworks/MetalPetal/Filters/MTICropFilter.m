//
//  MTICropFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 28/10/2017.
//

#import "MTICropFilter.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIFunctionDescriptor.h"
#import "MTIRenderPipelineOutputDescriptor.h"
#import "MTIImage.h"

MTICropRegion MTICropRegionMake(CGRect rect, MTICropRegionUnit unit) {
    return (MTICropRegion) {
        .bounds = rect,
        .unit = unit
    };
}

@implementation MTICropFilter
@synthesize outputPixelFormat = _outputPixelFormat;
@synthesize inputImage = _inputImage;

+ (MTIRenderPipelineKernel *)kernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughFragmentFunctionName]
                                                                  vertexDescriptor:nil
                                                              colorAttachmentCount:1
                                                             alphaTypeHandlingRule:MTIAlphaTypeHandlingRule.passthroughAlphaTypeHandlingRule];
    });
    return kernel;
}

- (MTIImage *)outputImage {
    if (!self.inputImage || (self.cropRegion.bounds.size.width <= 0 || self.cropRegion.bounds.size.height <= 0)) {
        return nil;
    }
    
    CGRect cropRect = CGRectZero;
    switch (self.cropRegion.unit) {
        case MTICropRegionUnitPixel: {
            cropRect = CGRectMake(self.cropRegion.bounds.origin.x / self.inputImage.size.width,
                                  self.cropRegion.bounds.origin.y / self.inputImage.size.height,
                                  self.cropRegion.bounds.size.width / self.inputImage.size.width,
                                  self.cropRegion.bounds.size.height / self.inputImage.size.height);
        } break;
        case MTICropRegionUnitPercentage: {
            cropRect = self.cropRegion.bounds;
        } break;
        default: {
            NSAssert(NO, @"Unsupported MTICropRegionUnit");
        } break;
    }
    
    CGRect rect = CGRectMake(-1, -1, 2, 2);
    CGFloat l = CGRectGetMinX(rect);
    CGFloat r = CGRectGetMaxX(rect);
    CGFloat t = CGRectGetMinY(rect);
    CGFloat b = CGRectGetMaxY(rect);
    
    CGFloat minX = cropRect.origin.x;
    CGFloat minY = cropRect.origin.y;
    CGFloat maxX = CGRectGetMaxX(cropRect);
    CGFloat maxY = CGRectGetMaxY(cropRect);
    
    MTIVertices *geometry = [[MTIVertices alloc] initWithVertices:(MTIVertex []){
        { .position = {l, t, 0, 1} , .textureCoordinate = { minX, maxY } },
        { .position = {r, t, 0, 1} , .textureCoordinate = { maxX, maxY } },
        { .position = {l, b, 0, 1} , .textureCoordinate = { minX, minY } },
        { .position = {r, b, 0, 1} , .textureCoordinate = { maxX, minY } }
    } count:4 primitiveType:MTLPrimitiveTypeTriangleStrip];
    
    MTIRenderPipelineOutputDescriptor *outputDescriptor = [[MTIRenderPipelineOutputDescriptor alloc] initWithDimensions:(MTITextureDimensions){.width = self.inputImage.size.width * cropRect.size.width, .height = self.inputImage.size.height * cropRect.size.height, .depth = 1} pixelFormat:self.outputPixelFormat];
    
    MTIRenderCommand *command = [[MTIRenderCommand alloc] initWithKernel:MTICropFilter.kernel geometry:geometry images:@[self.inputImage] parameters:@{}];
    return [MTIRenderCommand imagesByPerformingRenderCommands:@[command]
                                            outputDescriptors:@[outputDescriptor]].firstObject;
}

@end
