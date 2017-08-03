//
//  MTIMPSGaussianBlurFilter.h
//  Pods
//
//  Created by YuAo on 03/08/2017.
//
//

#import <Foundation/Foundation.h>
#import "MTIFilter.h"

@interface MTIMPSGaussianBlurFilter : NSObject <MTIFilter>

@property (nonatomic) float radius;

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@end
