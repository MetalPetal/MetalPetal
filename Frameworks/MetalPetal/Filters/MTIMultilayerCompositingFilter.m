//
//  MTIMultilayerCompositingFilter.m
//  Pods
//
//  Created by YuAo on 27/09/2017.
//

#import "MTIMultilayerCompositingFilter.h"
#import "MTIImage.h"

@implementation MTIMultilayerCompositingFilter

+ (MTIMultilayerCompositeKernel *)kernel {
    static MTIMultilayerCompositeKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [[MTIMultilayerCompositeKernel alloc] init];
    });
    return kernel;
}

+ (NSSet<NSString *> *)inputParameterKeys {
    return [NSSet set];
}

- (MTIImage *)outputImage {
    if (!self.inputBackgroundImage) {
        return nil;
    }
    return [self.class.kernel applyToBackgroundImage:self.inputBackgroundImage layers:self.layers outputTextureDimensions:MTITextureDimensionsMake2DFromCGSize(self.inputBackgroundImage.size)];
}

@end
