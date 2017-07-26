//
//  MTIColorInvertFilter.h
//  Pods
//
//  Created by YuAo on 27/06/2017.
//
//

#import "MTIFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIColorInvertFilter : NSObject <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@end

NS_ASSUME_NONNULL_END
