//
//  MTIUnpremultiplyAlphaFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 30/09/2017.
//

#import "MTIFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIAlphaPremultiplicationFilter: NSObject

@property (nonatomic, strong, nullable) MTIImage *inputImage;

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image;

@end

@interface MTIUnpremultiplyAlphaFilter : MTIAlphaPremultiplicationFilter <MTIFilter>

@end

@interface MTIPremultiplyAlphaFilter : MTIAlphaPremultiplicationFilter <MTIFilter>


@end

NS_ASSUME_NONNULL_END
