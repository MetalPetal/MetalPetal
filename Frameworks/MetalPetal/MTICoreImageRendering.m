//
//  MTICoreImageRendering.m
//  Pods
//
//  Created by Yu Ao on 04/04/2018.
//

#import "MTICoreImageRendering.h"

@implementation MTICIImageRenderingOptions

- (void)dealloc {
    CGColorSpaceRelease(_colorSpace);
}

- (instancetype)initWithDestinationPixelFormat:(MTLPixelFormat)pixelFormat colorSpace:(CGColorSpaceRef)colorSpace flipped:(BOOL)flipped {
    if (self = [super init]) {
        _destinationPixelFormat = pixelFormat;
        _alphaMode = CIRenderDestinationAlphaPremultiplied;
        _colorSpace = CGColorSpaceRetain(colorSpace);
        _flipped = flipped;
    }
    return self;
}

- (instancetype)initWithDestinationPixelFormat:(MTLPixelFormat)pixelFormat alphaMode:(CIRenderDestinationAlphaMode)alphaMode colorSpace:(CGColorSpaceRef)colorSpace flipped:(BOOL)flipped {
    if (self = [super init]) {
        _destinationPixelFormat = pixelFormat;
        _alphaMode = alphaMode;
        _colorSpace = CGColorSpaceRetain(colorSpace);
        _flipped = flipped;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

+ (MTICIImageRenderingOptions *)defaultOptions {
    static MTICIImageRenderingOptions *defaultOptions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
        defaultOptions = [[MTICIImageRenderingOptions alloc] initWithDestinationPixelFormat:MTLPixelFormatBGRA8Unorm colorSpace:colorspace flipped:YES];
        CGColorSpaceRelease(colorspace);
    });
    return defaultOptions;
}

@end

@implementation MTICIImageCreationOptions

- (void)dealloc {
    CGColorSpaceRelease(_colorSpace);
}

- (instancetype)initWithColorSpace:(CGColorSpaceRef)colorSpace flipped:(BOOL)flipped {
    if (self = [super init]) {
        _colorSpace = CGColorSpaceRetain(colorSpace);
        _flipped = flipped;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

+ (MTICIImageCreationOptions *)defaultOptions {
    static MTICIImageCreationOptions *defaultOptions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
        defaultOptions = [[MTICIImageCreationOptions alloc] initWithColorSpace:colorspace flipped:YES];
        CGColorSpaceRelease(colorspace);
    });
    return defaultOptions;
}

@end
