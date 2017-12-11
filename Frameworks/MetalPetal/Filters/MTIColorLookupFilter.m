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

@implementation MTIColorLookupTableInfo

- (instancetype)initWithType:(MTIColorLookupTableType)type dimension:(NSInteger)dimension {
    if (self = [super init]) {
        _type = type;
        _dimension = dimension;
    }
    return self;
}

- (instancetype)initWithColorLookupTableImageSize:(CGSize)colorLookupTableImageSize {
    MTIColorLookupTableType type = MTIColorLookupTableTypeUnknown;
    NSInteger dimension = 0;
    NSInteger width = colorLookupTableImageSize.width;
    NSInteger height = colorLookupTableImageSize.height;
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
        }
    }
    return [self initWithType:type dimension:dimension];
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

- (instancetype)init {
    if (self = [super init]) {
        _intensity = 1.0;
    }
    return self;
}

- (void)setInputColorLookupTable:(MTIImage *)inputColorLookupTable {
    _inputColorLookupTable = inputColorLookupTable;
    _inputColorLookupTableInfo = [[MTIColorLookupTableInfo alloc] initWithColorLookupTableImageSize:inputColorLookupTable.size];
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
        default:
            break;
    }
    return [kernel applyToInputImages:@[self.inputImage, self.inputColorLookupTable]
                           parameters:@{@"intensity": @(self.intensity),
                                        @"dimension": @((int)info.dimension)}
              outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(_inputImage.size)
                 outputPixelFormat:_outputPixelFormat];
}

@end

