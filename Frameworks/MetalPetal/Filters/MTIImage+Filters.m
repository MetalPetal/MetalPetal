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
    return [[MTIUnpremultiplyAlphaFilter imageByProcessingImage:self] imageWithCachePolicy:self.cachePolicy];
}

- (MTIImage *)imageByPremultiplyingAlpha {
    return [[MTIPremultiplyAlphaFilter imageByProcessingImage:self] imageWithCachePolicy:self.cachePolicy];
}

- (MTIImage *)imageByApplyingCGOrientation:(CGImagePropertyOrientation)orientation {
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
    return [[MTIUnaryImageRenderingFilter imageByProcessingImage:self orientation:imageOrientation parameters:@{} outputPixelFormat:MTIPixelFormatUnspecified] imageWithCachePolicy:self.cachePolicy];
}

@end
