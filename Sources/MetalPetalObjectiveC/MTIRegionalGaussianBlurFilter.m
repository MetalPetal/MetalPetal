//
//  MTIRegionalGaussianBlurFilter.m
//  MetalPetal
//
//  Created by Andrew on 2024.
//

#import "MTIRegionalGaussianBlurFilter.h"
#import "MTIMPSGaussianBlurFilter.h"
#import "MTIBlendWithMaskFilter.h"
#import "MTIMPSKernel.h"
#import "MTIImage.h"

@interface MTIRegionalGaussianBlurFilter ()

@property (nonatomic, strong) MTIMPSGaussianBlurFilter *gaussianBlurFilter;
@property (nonatomic, strong) MTIBlendWithMaskFilter *blendWithMaskFilter;

@end

@implementation MTIRegionalGaussianBlurFilter
@synthesize outputPixelFormat = _outputPixelFormat;
@synthesize inputImage = _inputImage;

- (instancetype)init {
    self = [super init];
    if (self) {
        _radius = 2.0f;
        _gaussianBlurFilter = [[MTIMPSGaussianBlurFilter alloc] init];
        _blendWithMaskFilter = [[MTIBlendWithMaskFilter alloc] init];
        _gaussianBlurFilter.radius = _radius;
    }
    return self;
}

- (void)setInputImage:(MTIImage *)inputImage {
    _inputImage = inputImage;
    _gaussianBlurFilter.inputImage = inputImage;
}

- (void)setRadius:(float)radius {
    _radius = radius;
    _gaussianBlurFilter.radius = radius;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    
    // If no region mask is specified, just return the blurred image
    if (!self.regionMask) {
        return self.gaussianBlurFilter.outputImage;
    }
    
    // Get the blurred version of the input image
    MTIImage *blurredImage = self.gaussianBlurFilter.outputImage;
    
    if (!blurredImage) {
        return nil;
    }
    
    // Set up the blend filter to combine original and blurred images using the mask
    self.blendWithMaskFilter.inputImage = blurredImage;           // Image to blend in (blurred)
    self.blendWithMaskFilter.inputBackgroundImage = self.inputImage; // Base image (original)
    self.blendWithMaskFilter.inputMask = self.regionMask;
    
    return self.blendWithMaskFilter.outputImage;
}

@end