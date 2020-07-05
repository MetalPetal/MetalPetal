//
//  MTIMultilayerCompositingFilter.m
//  Pods
//
//  Created by YuAo on 27/09/2017.
//

#import "MTIMultilayerCompositingFilter.h"
#import "MTIMultilayerCompositeKernel.h"
#import "MTIImage.h"

@implementation MTIMultilayerCompositingFilter

@synthesize outputPixelFormat = _outputPixelFormat;

+ (MTIMultilayerCompositeKernel *)kernel {
    static MTIMultilayerCompositeKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIMultilayerCompositeKernel alloc] init];
    });
    return kernel;
}

- (instancetype)init {
    if (self = [super init]) {
        _rasterSampleCount = 1;
    }
    return self;
}

- (MTIImage *)outputImage {
    if (!_inputBackgroundImage) {
        return nil;
    }
    if (_layers.count == 0) {
        return _inputBackgroundImage;
    }
    return [self.class.kernel applyToBackgroundImage:_inputBackgroundImage
                                              layers:_layers
                                   rasterSampleCount:_rasterSampleCount
                             outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(_inputBackgroundImage.size)
                                   outputPixelFormat:_outputPixelFormat];
}

@end
