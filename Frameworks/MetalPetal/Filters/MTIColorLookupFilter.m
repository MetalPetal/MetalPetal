//
//  MTILookUpTableFilter.m
//  MetalPetal
//
//  Created by 杨乃川 on 2017/10/12.
//

#import "MTIColorLookupFilter.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIComputePipelineKernel.h"

@implementation MTIColorLookupTableInfo

- (instancetype)initWithType:(MTIColorLookupTableType)type dimension:(NSInteger)dimension {
    if (self = [super init]) {
        _type = type;
        _dimension = dimension;
    }
    return self;
}

- (instancetype)initWithColorLookupTableImageDimensions:(MTITextureDimensions)colorLookupTableImageDimensions {
    if (colorLookupTableImageDimensions.depth == 1) {
        MTIColorLookupTableType type = MTIColorLookupTableTypeUnknown;
        NSInteger dimension = 0;
        NSInteger width = colorLookupTableImageDimensions.width;
        NSInteger height = colorLookupTableImageDimensions.height;
        if (width == height) {
            //may be a 2d squre
            NSInteger possibleDimension = round(pow(width * height, 1.0/3.0));
            if (possibleDimension * possibleDimension * possibleDimension == width * height) {
                dimension = possibleDimension;
                type = MTIColorLookupTableType2DSquare;
            }
        } else {
            //may be a 2d strip
            if (height * height == width) {
                type = MTIColorLookupTableType2DHorizontalStrip;
                dimension = height;
            } else if (width * width == height) {
                type = MTIColorLookupTableType2DVerticalStrip;
                dimension = width;
            }
        }
        return [self initWithType:type dimension:dimension];
    } else {
        if (colorLookupTableImageDimensions.width == colorLookupTableImageDimensions.height &&
            colorLookupTableImageDimensions.width == colorLookupTableImageDimensions.depth) {
            return [self initWithType:MTIColorLookupTableType3D dimension:colorLookupTableImageDimensions.width];
        } else {
            return [self initWithType:MTIColorLookupTableTypeUnknown dimension:0];
        }
    }
    
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end

@implementation MTIColorLookupFilter

@synthesize outputPixelFormat = _outputPixelFormat;

+ (MTIRenderPipelineKernel *)squareLookupKernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"colorLookup2DSquare"]];
    });
    return kernel;
}

+ (MTIRenderPipelineKernel *)horizontalStripLookupKernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"colorLookup2DHorizontalStrip"]];
    });
    return kernel;
}

+ (MTIRenderPipelineKernel *)verticalStripLookupKernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"colorLookup2DVerticalStrip"]];
    });
    return kernel;
}


+ (MTIRenderPipelineKernel *)lookup3DKernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"colorLookup3D"]];
    });
    return kernel;
}

- (instancetype)init {
    if (self = [super init]) {
        _intensity = 1.0;
    }
    return self;
}

- (void)setInputColorLookupTable:(MTIImage *)inputColorLookupTable {
    _inputColorLookupTable = inputColorLookupTable;
    _inputColorLookupTableInfo = [[MTIColorLookupTableInfo alloc] initWithColorLookupTableImageDimensions:inputColorLookupTable.dimensions];
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    MTIColorLookupTableInfo *info = self.inputColorLookupTableInfo;
    if (info.type == MTIColorLookupTableTypeUnknown || info.dimension == 0) {
        return nil;
    }
    MTIRenderPipelineKernel *kernel;
    switch (info.type) {
        case MTIColorLookupTableType2DSquare:
            kernel = MTIColorLookupFilter.squareLookupKernel;
            break;
        case MTIColorLookupTableType2DHorizontalStrip:
            kernel = MTIColorLookupFilter.horizontalStripLookupKernel;
            break;
        case MTIColorLookupTableType2DVerticalStrip:
            kernel = MTIColorLookupFilter.verticalStripLookupKernel;
            break;
        case MTIColorLookupTableType3D:
            kernel = MTIColorLookupFilter.lookup3DKernel;
            break;
        default:
            NSAssert(NO, @"");
            break;
    }
    return [kernel applyToInputImages:@[self.inputImage, self.inputColorLookupTable]
                           parameters:@{@"intensity": @(self.intensity),
                                        @"dimension": @((int)info.dimension)}
              outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(_inputImage.size)
                    outputPixelFormat:_outputPixelFormat];
}

+ (MTIImage *)create3DColorLookupTableFrom2DColorLookupTable:(MTIImage *)image pixelFormat:(MTLPixelFormat)pixelFormat {
    MTIColorLookupTableInfo *info = [[MTIColorLookupTableInfo alloc] initWithColorLookupTableImageDimensions:image.dimensions];
    if (info.type == MTIColorLookupTableTypeUnknown || info.dimension == 0) {
        return nil;
    }
    static MTIComputePipelineKernel *kernel2DSquare = nil;
    static MTIComputePipelineKernel *kernel2DStripVertical = nil;
    static MTIComputePipelineKernel *kernel2DStripHorizontal = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel2DSquare = [[MTIComputePipelineKernel alloc] initWithComputeFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"colorLookupTable2DSquareTo3D"] alphaTypeHandlingRule:MTIAlphaTypeHandlingRule.passthroughAlphaTypeHandlingRule];
        kernel2DStripVertical = [[MTIComputePipelineKernel alloc] initWithComputeFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"colorLookupTable2DStripVerticalTo3D"] alphaTypeHandlingRule:MTIAlphaTypeHandlingRule.passthroughAlphaTypeHandlingRule];
        kernel2DStripHorizontal = [[MTIComputePipelineKernel alloc] initWithComputeFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"colorLookupTable2DStripHorizontalTo3D"] alphaTypeHandlingRule:MTIAlphaTypeHandlingRule.passthroughAlphaTypeHandlingRule];
    });
    MTIComputePipelineKernel *kernel;
    switch (info.type) {
        case MTIColorLookupTableType3D:
            return image;
        case MTIColorLookupTableType2DSquare:
            kernel = kernel2DSquare;
            break;
        case MTIColorLookupTableType2DVerticalStrip:
            kernel = kernel2DStripVertical;
            break;
        case MTIColorLookupTableType2DHorizontalStrip:
            kernel = kernel2DStripHorizontal;
            break;
        default:
            NSAssert(NO, @"");
            break;
    }
    return [kernel applyToInputImages:@[image] parameters:@{@"dimension": @((int)(info.dimension))} outputTextureDimensions:(MTITextureDimensions){info.dimension,info.dimension,info.dimension} outputPixelFormat:pixelFormat];
}

@end

