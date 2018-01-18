//
//  MTIMPSBoxBlurFilter.m
//  MetalPetal
//
//  Created by Yu Ao on 18/01/2018.
//

#import "MTIMPSBoxBlurFilter.h"
#import "MTIMPSKernel.h"
#import "MTIImage.h"
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

@implementation MTIMPSBoxBlurFilter
@synthesize outputPixelFormat = _outputPixelFormat;
@synthesize inputImage = _inputImage;

+ (MTIMPSKernel *)kernelWithSize:(simd_int2)size {
    static NSMutableDictionary *kernels;
    static NSLock *kernelsLock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernels = [NSMutableDictionary dictionary];
        kernelsLock = [[NSLock alloc] init];
    });
    
    [kernelsLock lock];
    id<NSCopying> key = @[@(size.x),@(size.y)];
    MTIMPSKernel *kernel = kernels[key];
    if (!kernel) {
        kernel = [[MTIMPSKernel alloc] initWithMPSKernelBuilder:^MPSKernel * _Nonnull(id<MTLDevice>  _Nonnull device) {
            MPSImageBox *k = [[MPSImageBox alloc] initWithDevice:device kernelWidth:size.x kernelHeight:size.y];
            k.edgeMode = MPSImageEdgeModeClamp;
            return k;
        }];
        kernels[key] = kernel;
    }
    [kernelsLock unlock];
    
    return kernel;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    if (self.size.x <= 1 || self.size.y <= 1) {
        return self.inputImage;
    }
    simd_int2 size = self.size;
    size.x = size.x + (size.x + 1) % 2;
    size.y = size.y + (size.y + 1) % 2;
    return [[self.class kernelWithSize:size] applyToInputImages:@[self.inputImage] parameters:@{} outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(self.inputImage.size) outputPixelFormat:_outputPixelFormat];
}
@end
