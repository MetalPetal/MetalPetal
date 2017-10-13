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
@import MetalKit;


@implementation MTIColorLookupFilter
{
    MTIImage *_mtiLutImage;
}
@synthesize outputPixelFormat = _outputPixelFormat;

+ (MTIRenderPipelineKernel *)kernel {
    static MTIRenderPipelineKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                        fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"lookUpTable"]];
    });
    return kernel;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    if (_mtiLutImage == nil ) return nil;
    return [self.class.kernel applyToInputImages:@[self.inputImage, _mtiLutImage]
                                      parameters:@{}
                         outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(_inputImage.size)
                               outputPixelFormat:_outputPixelFormat];
}
- (void)setInputColorLookupTable:(UIImage *)inputColorLookupTable
{
    _inputColorLookupTable = inputColorLookupTable;
    _mtiLutImage = [self mtiLutImageWithImage:inputColorLookupTable];
}


+ (nonnull NSSet<NSString *> *)inputParameterKeys {
    return [NSSet set];
}

- (MTIImage *)mtiLutImageWithImage:(UIImage *)lutImage
{
    MTIImage *img = [[MTIImage alloc] initWithCGImage:lutImage.CGImage options:@{MTKTextureLoaderOptionSRGB: @(YES)}];
    return img;
}
@end

