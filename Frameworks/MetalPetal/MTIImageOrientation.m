//
//  MTIImageOrientation.m
//  Pods
//
//  Created by Yu Ao on 16/10/2017.
//

#import "MTIImageOrientation.h"

MTIImageOrientation MTIImageOrientationFromCGImagePropertyOrientation(CGImagePropertyOrientation orientation) {
    MTIImageOrientation imageOrientation;
    switch (orientation) {
        case kCGImagePropertyOrientationUp:
            imageOrientation = MTIImageOrientationUp;
            break;
        case kCGImagePropertyOrientationDown:
            imageOrientation = MTIImageOrientationDown;
            break;
        case kCGImagePropertyOrientationLeft:
            imageOrientation = MTIImageOrientationLeft;
            break;
        case kCGImagePropertyOrientationRight:
            imageOrientation = MTIImageOrientationRight;
            break;
        case kCGImagePropertyOrientationUpMirrored:
            imageOrientation = MTIImageOrientationUpMirrored;
            break;
        case kCGImagePropertyOrientationDownMirrored:
            imageOrientation = MTIImageOrientationDownMirrored;
            break;
        case kCGImagePropertyOrientationLeftMirrored:
            imageOrientation = MTIImageOrientationLeftMirrored;
            break;
        case kCGImagePropertyOrientationRightMirrored:
            imageOrientation = MTIImageOrientationRightMirrored;
            break;
        default:
            imageOrientation = MTIImageOrientationUnknown;
            break;
    }
    return imageOrientation;
}
