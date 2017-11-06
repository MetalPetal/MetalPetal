//
//  MTIMultilayerCompositingFilter.m
//  Pods
//
//  Created by YuAo on 27/09/2017.
//

#import "MTIMultilayerCompositingFilter.h"
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

- (MTIImage *)outputImage {
    if (!_inputBackgroundImage) {
        return nil;
    }
    return [self.class.kernel applyToBackgroundImage:_inputBackgroundImage
                                              layers:_layers
                             outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(_inputBackgroundImage.size)
                                   outputPixelFormat:_outputPixelFormat];
}

@end
