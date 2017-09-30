//
//  MTIImage+Filters.m
//  Pods
//
//  Created by Yu Ao on 30/09/2017.
//

#import "MTIImage+Filters.h"
#import "MTIUnpremultiplyAlphaFilter.h"

@implementation MTIImage (Filters)

- (MTIImage *)imageByUnpremultiplyingAlpha {
    return [MTIUnpremultiplyAlphaFilter imageByProcessingImage:self];
}

@end
