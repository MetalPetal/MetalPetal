//
//  MTIMaskBlendFilter.h
//  MetalPetal
//
//  Created by 杨乃川 on 2017/10/26.
//

#import <Foundation/Foundation.h>
#import "MTIFilter.h"
#import "MTIColor.h"
#import "MTIMask.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIBlendWithMaskFilter: NSObject <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@property (nonatomic, strong, nullable) MTIImage *inputBackgroundImage;

@property (nonatomic, strong, nullable) MTIMask *inputMask;

@end

NS_ASSUME_NONNULL_END
