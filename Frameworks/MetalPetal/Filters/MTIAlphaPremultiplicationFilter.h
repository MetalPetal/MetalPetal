//
//  MTIUnpremultiplyAlphaFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 30/09/2017.
//

#import "MTIFilter.h"
#import "MTIUnaryImageFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIUnpremultiplyAlphaFilter : MTIUnaryImageFilter

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image;

@end

@interface MTIPremultiplyAlphaFilter : MTIUnaryImageFilter

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image;

@end

NS_ASSUME_NONNULL_END
