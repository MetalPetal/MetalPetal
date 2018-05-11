//
//  MTICropFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 28/10/2017.
//

#import "MTICropFilter.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIFunctionDescriptor.h"
#import "MTIRenderPassOutputDescriptor.h"
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

- (instancetype)init {
    if (self = [super init]) {
        _cropRegion = MTICropRegionMake((CGRect){0, 0, 1, 1}, MTICropRegionUnitPercentage);
        _scale = 1;
    }
    return self;
}

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
            cropRect = self.cropRegion.bounds;
        } break;
        case MTICropRegionUnitPercentage: {
            cropRect = CGRectMake(self.cropRegion.bounds.origin.x * self.inputImage.size.width,
                                  self.cropRegion.bounds.origin.y * self.inputImage.size.height,
                                  self.cropRegion.bounds.size.width * self.inputImage.size.width,
                                  self.cropRegion.bounds.size.height * self.inputImage.size.height);
        } break;
        default: {
            NSAssert(NO, @"Unsupported MTICropRegionUnit");
            return nil;
        } break;
    }
    
    CGRect rect = CGRectMake(-1, -1, 2, 2);
    CGFloat l = CGRectGetMinX(rect);
    CGFloat r = CGRectGetMaxX(rect);
    CGFloat t = CGRectGetMinY(rect);
    CGFloat b = CGRectGetMaxY(rect);
    
    CGFloat minX = cropRect.origin.x/self.inputImage.size.width;
    CGFloat minY = cropRect.origin.y/self.inputImage.size.height;
    CGFloat maxX = CGRectGetMaxX(cropRect)/self.inputImage.size.width;
    CGFloat maxY = CGRectGetMaxY(cropRect)/self.inputImage.size.height;
    
    MTIVertices *geometry = [[MTIVertices alloc] initWithVertices:(MTIVertex []){
        { .position = {l, t, 0, 1} , .textureCoordinate = { minX, maxY } },
        { .position = {r, t, 0, 1} , .textureCoordinate = { maxX, maxY } },
        { .position = {l, b, 0, 1} , .textureCoordinate = { minX, minY } },
        { .position = {r, b, 0, 1} , .textureCoordinate = { maxX, minY } }
    } count:4 primitiveType:MTLPrimitiveTypeTriangleStrip];
    
    double (*roundingFunction)(double);
    switch (self.roundingMode) {
        case MTICropFilterRoundingModePlain:
        roundingFunction = round;
        break;
        case MTICropFilterRoundingModeFloor:
        roundingFunction = floor;
        break;
        case MTICropFilterRoundingModeCeiling:
        roundingFunction = ceil;
        break;
        default:
        roundingFunction = round;
        break;
    }
    
    NSUInteger outputWidth = roundingFunction(cropRect.size.width * self.scale);
    NSUInteger outputHeight = roundingFunction(cropRect.size.height * self.scale);
    
    if (outputWidth == self.inputImage.size.width && outputHeight == self.inputImage.size.height && cropRect.origin.x == 0 && cropRect.origin.y == 0) {
        return self.inputImage;
    }
    
    MTIRenderPassOutputDescriptor *outputDescriptor = [[MTIRenderPassOutputDescriptor alloc] initWithDimensions:(MTITextureDimensions){.width = outputWidth, .height = outputHeight, .depth = 1} pixelFormat:self.outputPixelFormat];
    
    MTIRenderCommand *command = [[MTIRenderCommand alloc] initWithKernel:MTICropFilter.kernel geometry:geometry images:@[self.inputImage] parameters:@{}];
    return [MTIRenderCommand imagesByPerformingRenderCommands:@[command]
                                            outputDescriptors:@[outputDescriptor]].firstObject;
}

@end
