//
//  MTIMaskBlendFilter.h
//  MetalPetal
//
//  Created by 杨乃川 on 2017/10/26.
//

#import <Foundation/Foundation.h>
#import "MTIFilter.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int, MTIMaskBlendComponent) {
    MTIMaskBlendComponentAlpha = 0,
    MTIMaskBlendComponentRed
};

@interface  MTIBlendWithMaskFilter: NSObject<MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@property (nonatomic, strong, nullable) MTIImage *inputMaskImage;

@property (nonatomic, strong, nullable) MTIImage *inputBackgroundImage;

@property (nonatomic, assign) MTIMaskBlendComponent maskComponent;

@end

NS_ASSUME_NONNULL_END
