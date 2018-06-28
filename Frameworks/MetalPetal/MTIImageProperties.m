//
//  MTIImageProperties.m
//  Pods
//
//  Created by YuAo on 2018/6/22.
//

#import "MTIImageProperties.h"

@implementation MTIImageProperties

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (void)dealloc {
    CGColorSpaceRelease(_colorSpace);
}

+ (NSDictionary *)imageSourceOptions {
    //Faster: @"kCGImageSourceSkipMetadata": @YES
    return @{(id)kCGImageSourceShouldCache: @NO,
             (id)kCGImageSourceShouldCacheImmediately: @NO,
             (id)kCGImageSourceShouldAllowFloat: @YES};
}

- (instancetype)initWithImageSource:(CGImageSourceRef)imageSource index:(NSUInteger)index {
    NSParameterAssert(imageSource);
    NSParameterAssert(index < CGImageSourceGetCount(imageSource));
    if (self = [super init]) {
        if (index >= CGImageSourceGetCount(imageSource)) {
            return nil;
        }
        NSDictionary *options = MTIImageProperties.imageSourceOptions;
        
        NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSource, index, (__bridge CFDictionaryRef)options);
        
        CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, index, (__bridge CFDictionaryRef)options);
        
        if (properties && image) {
            _properties = properties;
            
            CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(image);
            
            _alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
            _byteOrderInfo = bitmapInfo & kCGImageByteOrderMask;
            _floatComponents = (bitmapInfo & kCGBitmapFloatInfoMask) == kCGBitmapFloatComponents;
            _colorSpace = CGColorSpaceRetain(CGImageGetColorSpace(image));
            
            _pixelWidth = CGImageGetWidth(image);
            _pixelHeight = CGImageGetHeight(image);
            
            CGImageRelease(image);
            
            NSNumber *orientationValue = properties[(id)kCGImagePropertyOrientation];
            if ([orientationValue isKindOfClass:[NSNumber class]]) {
                _orientation = [orientationValue unsignedIntValue];
            } else {
                _orientation = kCGImagePropertyOrientationUp;
            }
            
            switch (_orientation) {
                case kCGImagePropertyOrientationUp:
                case kCGImagePropertyOrientationDown:
                case kCGImagePropertyOrientationUpMirrored:
                case kCGImagePropertyOrientationDownMirrored:
                    _displayHeight = _pixelHeight;
                    _displayWidth = _pixelWidth;
                    break;
                case kCGImagePropertyOrientationLeft:
                case kCGImagePropertyOrientationRight:
                case kCGImagePropertyOrientationLeftMirrored:
                case kCGImagePropertyOrientationRightMirrored:
                    _displayWidth = _pixelHeight;
                    _displayHeight = _pixelWidth;
                    break;
                default:
                    NSAssert(NO, @"Unknown orientation");
                    return nil;
            }
            
            return self;
        } else {
            CGImageRelease(image);
            return nil;
        }
    }
    return self;
}

- (instancetype)initWithCGImage:(CGImageRef)image {
    NSParameterAssert(image);
    if (self = [super init]) {
        CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(image);
        
        _properties = @{};
        
        _alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
        _byteOrderInfo = bitmapInfo & kCGImageByteOrderMask;
        _floatComponents = (bitmapInfo & kCGBitmapFloatInfoMask) == kCGBitmapFloatComponents;
        _colorSpace = CGColorSpaceRetain(CGImageGetColorSpace(image));
        
        _pixelWidth = CGImageGetWidth(image);
        _pixelHeight = CGImageGetHeight(image);
        
        _displayWidth = _pixelWidth;
        _displayHeight = _pixelHeight;
        
        _orientation = kCGImagePropertyOrientationUp;
    }
    return self;
}

- (instancetype)initWithImageAtURL:(NSURL *)URL {
    NSDictionary *options = MTIImageProperties.imageSourceOptions;
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)URL, (__bridge CFDictionaryRef)options);
    if (source) {
        MTIImageProperties *properties = [self initWithImageSource:source index:0];
        CFRelease(source);
        return properties;
    } else {
        return nil;
    }
}

@end
