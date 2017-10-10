//
//  MTIColorMatrixFilter.h
//  Pods
//
//  Created by yi chen on 2017/7/27.
//
//

#import "MTIFilter.h"
#import "MTIUnaryImageFilter.h"
#import <simd/simd.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTIColorMatrixFilter : MTIUnaryImageFilter

@property (nonatomic) simd_float4x4 colorMatrix;

@end

NS_ASSUME_NONNULL_END
