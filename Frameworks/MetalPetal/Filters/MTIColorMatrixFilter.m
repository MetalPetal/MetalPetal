//
//  MTIColorMatrixFilter.m
//  Pods
//
//  Created by yi chen on 2017/7/27.
//
//

#import "MTIColorMatrixFilter.h"
#import "MTIFilterUtilities.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIKernel.h"
#import "MTIRenderPipelineKernel.h"
#import "MTIVector.h"

@interface MTIColorMatrixFilter ()

@property (nonatomic,copy) NSData *colorMatrixValue;

@end

@implementation MTIColorMatrixFilter

+ (NSString *)fragmentFunctionName {
    return MTIFilterColorMatrixFragmentFunctionName;
}

- (instancetype)init {
    if (self = [super init]) {
        self.colorMatrix = MTIColorMatrixIdentity;
    }
    return self;
}

- (void)setColorMatrix:(MTIColorMatrix)colorMatrix {
    _colorMatrix = colorMatrix;
    _colorMatrixValue = [NSData dataWithBytes:&colorMatrix length:sizeof(MTIColorMatrix)];
}

+ (NSSet *)inputParameterKeys {
    return [NSSet setWithObjects:@"colorMatrixValue", nil];
}

@end

@implementation MTIExposureFilter

- (void)setExposure:(float)exposure {
    _exposure = exposure;
    [super setColorMatrix:MTIColorMatrixMakeWithExposure(exposure)];
}

@end

@implementation MTISaturationFilter

- (instancetype)init {
    if (self = [super init]) {
        self.saturation = 1;
    }
    return self;
}

- (void)setSaturation:(float)saturation {
    _saturation = saturation;
    [super setColorMatrix:MTIColorMatrixMakeWithSaturation(saturation)];
}

@end

@implementation MTIColorInvertFilter

- (instancetype)init {
    if (self = [super init]) {
        [super setColorMatrix:MTIColorMatrixRGBColorInvert];
    }
    return self;
}

@end

@implementation MTIOpacityFilter

- (instancetype)init {
    if (self = [super init]) {
        self.opacity = 1;
    }
    return self;
}

- (void)setOpacity:(float)opacity {
    _opacity = opacity;
    [super setColorMatrix:MTIColorMatrixMakeWithOpacity(opacity)];
}

@end

@implementation MTIBrightnessFilter

- (void)setBrightness:(float)brightness {
    _brightness = brightness;
    [super setColorMatrix:MTIColorMatrixMakeWithBrightness(brightness)];
}

@end

@implementation MTIContrastFilter

- (instancetype)init {
    if (self = [super init]) {
        self.contrast = 1;
    }
    return self;
}

- (void)setContrast:(float)contrast {
    _contrast = contrast;
    [super setColorMatrix:MTIColorMatrixMakeWithContrast(contrast)];
}

@end
