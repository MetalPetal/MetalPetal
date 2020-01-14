//
//  MTIGeometryUtilities.m
//  MetalPetal
//
//  Created by Yu Ao on 2019/11/8.
//

#import "MTIGeometryUtilities.h"
#import <AVFoundation/AVFoundation.h>

CGRect MTIMakeRectWithAspectRatioFillRect(CGSize aspectRatio, CGRect boundingRect) {
    CGFloat horizontalRatio = boundingRect.size.width / aspectRatio.width;
    CGFloat verticalRatio = boundingRect.size.height / aspectRatio.height;
    CGFloat ratio = MAX(horizontalRatio, verticalRatio);
    CGSize newSize = CGSizeMake(aspectRatio.width * ratio, aspectRatio.height * ratio);
    CGRect rect = CGRectMake(boundingRect.origin.x + (boundingRect.size.width - newSize.width)/2, boundingRect.origin.y + (boundingRect.size.height - newSize.height)/2, newSize.width, newSize.height);
    return rect;
}

CGRect MTIMakeRectWithAspectRatioInsideRect(CGSize aspectRatio, CGRect boundingRect) {
    return AVMakeRectWithAspectRatioInsideRect(aspectRatio, boundingRect);
}
