//
//  MTIHighPassSkinSmoothingFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 15/01/2018.
//

#import "MTIFilter.h"
#import "MTIVector.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIHighPassSkinSmoothingFilter : NSObject <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@property (nonatomic) float amount;

@property (nonatomic) float radius;

@property (nonatomic, copy, null_resettable) NSArray<MTIVector *> *toneCurveControlPoints;

+ (BOOL)isSupportedOnDevice:(id<MTLDevice>)device;

@end

NS_ASSUME_NONNULL_END
