//
//  MTIVibranceFilter.h
//  MetalPetal
//
//  Created by 杨乃川 on 2017/11/6.
//

#import "MTIUnaryImageRenderingFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIVibranceFilter : MTIUnaryImageRenderingFilter

@property (nonatomic) float amount;

@property (nonatomic) BOOL avoidSaturatingSkinTones;

@end

NS_ASSUME_NONNULL_END
