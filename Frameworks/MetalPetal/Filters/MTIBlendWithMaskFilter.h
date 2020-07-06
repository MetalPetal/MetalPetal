//
//  MTIMaskBlendFilter.h
//  MetalPetal
//
//  Created by 杨乃川 on 2017/10/26.
//

#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIFilter.h>
#else
#import "MTIFilter.h"
#endif

@class MTIMask;

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface MTIBlendWithMaskFilter: NSObject <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@property (nonatomic, strong, nullable) MTIImage *inputBackgroundImage;

@property (nonatomic, strong, nullable) MTIMask *inputMask;

@end

NS_ASSUME_NONNULL_END
