//
//  MTIMPSGaussianBlurFilter.h
//  Pods
//
//  Created by YuAo on 03/08/2017.
//
//

#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIFilter.h>
#else
#import "MTIFilter.h"
#endif

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface MTIMPSGaussianBlurFilter : NSObject <MTIUnaryFilter>

@property (nonatomic) float radius;

@end

NS_ASSUME_NONNULL_END
