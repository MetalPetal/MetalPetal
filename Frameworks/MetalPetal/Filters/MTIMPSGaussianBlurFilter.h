//
//  MTIMPSGaussianBlurFilter.h
//  Pods
//
//  Created by YuAo on 03/08/2017.
//
//

#import "MTIFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIMPSGaussianBlurFilter : NSObject <MTIFilter>

@property (nonatomic) float radius;

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@end

NS_ASSUME_NONNULL_END
