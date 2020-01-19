//
//  MTIImage+Filters.m
//  Pods
//
//  Created by Yu Ao on 30/09/2017.
//

#import "MTIImage+Filters.h"
#import "MTIAlphaPremultiplicationFilter.h"
#import "MTIUnaryImageRenderingFilter.h"

@implementation MTIImage (Filters)

- (MTIImage *)imageByUnpremultiplyingAlpha {
    return [[MTIUnpremultiplyAlphaFilter imageByProcessingImage:[self imageWithCachePolicy:MTIImageCachePolicyTransient]] imageWithCachePolicy:self.cachePolicy];
}

- (MTIImage *)imageByPremultiplyingAlpha {
    return [[MTIPremultiplyAlphaFilter imageByProcessingImage:[self imageWithCachePolicy:MTIImageCachePolicyTransient]] imageWithCachePolicy:self.cachePolicy];
}

- (MTIImage *)imageByApplyingCGOrientation:(CGImagePropertyOrientation)orientation {
    return [self imageByApplyingCGOrientation:orientation outputPixelFormat:MTIPixelFormatUnspecified];
}

- (MTIImage *)imageByApplyingCGOrientation:(CGImagePropertyOrientation)orientation outputPixelFormat:(MTLPixelFormat)pixelFormat {
    if (orientation == kCGImagePropertyOrientationUp) {
        return self;
    }
    MTIImageOrientation imageOrientation;
    switch (orientation) {
        case kCGImagePropertyOrientationUp:
            imageOrientation = MTIImageOrientationUp;
            break;
        case kCGImagePropertyOrientationDown:
            imageOrientation = MTIImageOrientationDown;
            break;
        case kCGImagePropertyOrientationLeft:
            imageOrientation = MTIImageOrientationRight;
            break;
        case kCGImagePropertyOrientationRight:
            imageOrientation = MTIImageOrientationLeft;
            break;
        case kCGImagePropertyOrientationUpMirrored:
            imageOrientation = MTIImageOrientationUpMirrored;
            break;
        case kCGImagePropertyOrientationDownMirrored:
            imageOrientation = MTIImageOrientationDownMirrored;
            break;
        case kCGImagePropertyOrientationLeftMirrored:
            imageOrientation = MTIImageOrientationRightMirrored;
            break;
        case kCGImagePropertyOrientationRightMirrored:
            imageOrientation = MTIImageOrientationLeftMirrored;
            break;
        default:
            imageOrientation = MTIImageOrientationUnknown;
            break;
    }
    return [[MTIUnaryImageRenderingFilter imageByProcessingImage:[self imageWithCachePolicy:MTIImageCachePolicyTransient] orientation:imageOrientation parameters:@{} outputPixelFormat:pixelFormat] imageWithCachePolicy:self.cachePolicy];
}

@end
