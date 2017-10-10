//
//  MTISaturationFilter.h
//  Pods
//
//  Created by YuAo on 01/07/2017.
//
//

#import "MTIFilter.h"
#import "MTIUnaryImageFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTISaturationFilter : MTIUnaryImageFilter

@property (nonatomic) float saturation;

@end

NS_ASSUME_NONNULL_END
