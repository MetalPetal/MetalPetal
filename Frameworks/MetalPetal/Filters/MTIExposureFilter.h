//
//  MTIExposureFilter.h
//  Pods
//
//  Created by yi chen on 2017/7/27.
//
//

#import <UIKit/UIKit.h>
#import "MTIFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIExposureFilter : NSObject <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@property (nonatomic) float exposure;

@end

NS_ASSUME_NONNULL_END
