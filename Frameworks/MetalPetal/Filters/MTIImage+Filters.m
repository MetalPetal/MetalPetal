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
    return [MTIUnpremultiplyAlphaFilter imageByProcessingImage:self];
}

- (MTIImage *)imageByPremultiplyingAlpha {
    return [MTIPremultiplyAlphaFilter imageByProcessingImage:self];
}

- (MTIImage *)imageByApplyingCGOrientation:(CGImagePropertyOrientation)orientation {
    MTIImageOrientation imageOrientation = MTIImageOrientationFromCGImagePropertyOrientation(orientation);
    return [MTIUnaryImageRenderingFilter imageByProcessingImage:self orientation:imageOrientation parameters:@{} outputPixelFormat:MTIPixelFormatUnspecified];
}

@end
