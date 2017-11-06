//
//  MTIMaskBlendFilter.h
//  MetalPetal
//
//  Created by 杨乃川 on 2017/10/26.
//

#import <Foundation/Foundation.h>
#import "MTIFilter.h"
#import "MTIColor.h"

NS_ASSUME_NONNULL_BEGIN

@interface  MTIBlendWithMaskFilter: NSObject <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@property (nonatomic, strong, nullable) MTIImage *inputMaskImage;

@property (nonatomic, strong, nullable) MTIImage *inputBackgroundImage;

@property (nonatomic, assign) MTIColorComponent maskComponent;

@end

NS_ASSUME_NONNULL_END
