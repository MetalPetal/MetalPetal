//
//  MTIPerspectiveTransformFilter.m
//  GPUImageBeauty
//
//  Created by apple on 2018/8/16.
//  Copyright © 2018年 erpapa. All rights reserved.
//

#import "MTIPerspectiveTransformFilter.h"

@implementation MTIPerspectiveTransformFilter
@synthesize outputPixelFormat = _outputPixelFormat;
@synthesize inputImage = _inputImage;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.verticeRegion = MTIVerticeRegionMakeFromCGRect(CGRectMake(0, 0, 1, 1));
        self.backgroundSize = CGSizeZero;
        self.outputImageSize = CGSizeMake(1, 1);
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

- (MTIVertices *)vertices {
    CGSize backgroundSize = CGSizeEqualToSize(self.backgroundSize, CGSizeZero) ? self.outputImageSize : self.backgroundSize;
    CGPoint tl = CGPointMake(-1 + self.verticeRegion.bl.x / backgroundSize.width * 2, 1 - self.verticeRegion.bl.y / backgroundSize.height * 2);
    CGPoint tr = CGPointMake(-1 + self.verticeRegion.br.x / backgroundSize.width * 2, 1 - self.verticeRegion.br.y / backgroundSize.height * 2);
    CGPoint bl = CGPointMake(-1 + self.verticeRegion.tl.x / backgroundSize.width * 2, 1 - self.verticeRegion.tl.y / backgroundSize.height * 2);
    CGPoint br = CGPointMake(-1 + self.verticeRegion.tr.x / backgroundSize.width * 2, 1 - self.verticeRegion.tr.y / backgroundSize.height * 2);
    
    MTIVertices *vertices = [[MTIVertices alloc] initWithVertices:(MTIVertex []){
        { .position = {tl.x, tl.y, 0, 1} , .textureCoordinate = { 0, 1 } },
        { .position = {tr.x, tr.y, 0, 1} , .textureCoordinate = { 1, 1 } },
        { .position = {bl.x, bl.y, 0, 1} , .textureCoordinate = { 0, 0 } },
        { .position = {br.x, br.y, 0, 1} , .textureCoordinate = { 1, 0 } }
    } count:4 primitiveType:MTLPrimitiveTypeTriangleStrip];
    return vertices;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    if (self.verticeRegion.bl.y - self.verticeRegion.tl.y == 0 && self.verticeRegion.br.y - self.verticeRegion.tr.y == 0 && self.verticeRegion.tr.x - self.verticeRegion.tl.x == 0 && self.verticeRegion.br.x - self.verticeRegion.bl.x == 0) {
        return MTIImage.transparentImage;
    }
    MTIRenderPassOutputDescriptor *outputDescriptor = [[MTIRenderPassOutputDescriptor alloc] initWithDimensions:MTITextureDimensionsMake2DFromCGSize(self.outputImageSize) pixelFormat:self.outputPixelFormat loadAction:MTLLoadActionClear];
    MTIRenderCommand *command = [[MTIRenderCommand alloc] initWithKernel:MTIPerspectiveTransformFilter.kernel geometry:self.vertices images:@[self.inputImage] parameters:@{}];
    return [MTIRenderCommand imagesByPerformingRenderCommands:@[command]
                                            outputDescriptors:@[outputDescriptor]].firstObject;
}

@end
