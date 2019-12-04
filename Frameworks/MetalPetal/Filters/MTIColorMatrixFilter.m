//
//  MTIColorMatrixFilter.m
//  Pods
//
//  Created by yi chen on 2017/7/27.
//
//

#import "MTIColorMatrixFilter.h"
#import "MTIFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIKernel.h"
#import "MTIRenderPipelineKernel.h"

NSString * const MTIColorMatrixFilterColorMatrixParameterKey = @"colorMatrix";

@implementation MTIColorMatrixFilter

+ (MTIFunctionDescriptor *)fragmentFunctionDescriptor {
    return [[MTIFunctionDescriptor alloc] initWithName:MTIFilterColorMatrixFragmentFunctionName];
}

- (instancetype)init {
    if (self = [super init]) {
        self.colorMatrix = MTIColorMatrixIdentity;
    }
    return self;
}

- (NSDictionary<NSString *,id> *)parameters {
    return @{MTIColorMatrixFilterColorMatrixParameterKey: [NSData dataWithBytes:&_colorMatrix length:sizeof(MTIColorMatrix)]};
}

+ (MTIAlphaTypeHandlingRule *)alphaTypeHandlingRule {
    return MTIAlphaTypeHandlingRule.generalAlphaTypeHandlingRule;
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
        self.grayColorTransform = MTIGrayColorTransformDefault;
        self.saturation = 1;
    }
    return self;
}

- (void)setSaturation:(float)saturation {
    _saturation = saturation;
    [super setColorMatrix:MTIColorMatrixMakeWithSaturation(self.saturation,self.grayColorTransform)];
}

- (void)setGrayColorTransform:(simd_float3)grayColorTransform {
    _grayColorTransform = grayColorTransform;
    [super setColorMatrix:MTIColorMatrixMakeWithSaturation(self.saturation,self.grayColorTransform)];
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
