//
//  MTIUnpremultiplyAlphaFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 30/09/2017.
//

#import <Foundation/Foundation.h>
#import "MTIFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIUnpremultiplyAlphaFilter : NSObject <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputImage;

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image;

@end

NS_ASSUME_NONNULL_END
