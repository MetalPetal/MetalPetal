//
//  MTIColorMatrixFilter.h
//  Pods
//
//  Created by yi chen on 2017/7/27.
//
//

#import <UIKit/UIKit.h>
#import "MTIFilter.h"
@import simd;

NS_ASSUME_NONNULL_BEGIN

@interface MTIColorMatrixFilter : NSObject <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@property (nonatomic) matrix_float4x4 colorMatrix;

@end

NS_ASSUME_NONNULL_END
