//
//  MTIMPSGaussianBlurFilter.h
//  Pods
//
//  Created by YuAo on 03/08/2017.
//
//

#import "MTIFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIMPSGaussianBlurFilter : NSObject <MTIUnaryFilter>

@property (nonatomic) float radius;

@end

NS_ASSUME_NONNULL_END
