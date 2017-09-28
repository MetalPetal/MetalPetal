//
//  MTISaturationFilter.h
//  Pods
//
//  Created by YuAo on 01/07/2017.
//
//

#import "MTIFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTISaturationFilter : NSObject <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@property (nonatomic) float saturation;

@end

NS_ASSUME_NONNULL_END
