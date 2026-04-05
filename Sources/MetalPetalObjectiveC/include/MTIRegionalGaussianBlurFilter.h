//
//  MTIRegionalGaussianBlurFilter.h
//  MetalPetal
//
//  Created by Andrew on 2024.
//

#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIFilter.h>
#else
#import "MTIFilter.h"
#endif

@class MTIMask;

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface MTIRegionalGaussianBlurFilter : NSObject <MTIUnaryFilter>

@property (nonatomic) float radius;

@property (nonatomic, strong, nullable) MTIMask *regionMask;

@end

NS_ASSUME_NONNULL_END