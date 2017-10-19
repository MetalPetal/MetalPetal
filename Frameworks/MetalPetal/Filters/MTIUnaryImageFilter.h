//
//  MTIUnaryImageFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 10/10/2017.
//

#import "MTIFilter.h"
#import "MTIImageOrientation.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIUnaryImageFilter : NSObject <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@property (nonatomic) MTIImageOrientation inputRotation; //Rotate the input image to that orientation.

+ (MTIImage *)imageByProcessingImage:(MTIImage *)image withInputParameters:(NSDictionary<NSString *,id> *)parameters outputPixelFormat:(MTLPixelFormat)outputPixelFormat;

@end

@interface MTIUnaryImageFilter (SubclassingHooks)

+ (NSString *)fragmentFunctionName;

@end

NS_ASSUME_NONNULL_END
