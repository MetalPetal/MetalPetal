//
//  MTIMaskBlendFilter.h
//  MetalPetal
//
//  Created by 杨乃川 on 2017/10/26.
//

#import <MTIFilter.h>

@class MTIMask;

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface MTIBlendWithMaskFilter: NSObject <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@property (nonatomic, strong, nullable) MTIImage *inputBackgroundImage;

@property (nonatomic, strong, nullable) MTIMask *inputMask;

@end

NS_ASSUME_NONNULL_END
