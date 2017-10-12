//
//  MTIUnaryImageFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 10/10/2017.
//

#import "MTIFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIUnaryImageFilter : NSObject <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputImage;

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image withInputParameters:(NSDictionary<NSString *,id> *)parameters outputPixelFormat:(MTIPixelFormat)outputPixelFormat;

@end

@interface MTIUnaryImageFilter (SubclassingHooks)

+ (NSString *)fragmentFunctionName;

@end

NS_ASSUME_NONNULL_END
