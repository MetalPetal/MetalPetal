//
//  MTIImageOrientation.h
//  Pods
//
//  Created by Yu Ao on 16/10/2017.
//

#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>

// https://developer.apple.com/documentation/uikit/uiimageorientation?language=objc

typedef NS_ENUM(NSInteger, MTIImageOrientation) {
    MTIImageOrientationUnknown = 0,
    MTIImageOrientationUp = 1,
    MTIImageOrientationUpMirrored = 2,
    MTIImageOrientationDown = 3,
    MTIImageOrientationDownMirrored = 4,
    MTIImageOrientationLeftMirrored = 5,
    MTIImageOrientationRight = 6,
    MTIImageOrientationRightMirrored = 7,
    MTIImageOrientationLeft = 8
};

FOUNDATION_EXPORT MTIImageOrientation MTIImageOrientationFromCGImagePropertyOrientation(CGImagePropertyOrientation orientation) NS_SWIFT_NAME(MTIImageOrientation.init(cgImagePropertyOrientation:));
