//
//  MTIChromaKeyBlendFilter.h
//  Pods
//
//  Created by Yu Ao on 29/12/2017.
//

#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIFilter.h>
#import <MetalPetal/MTIColor.h>
#else
#import "MTIFilter.h"
#import "MTIColor.h"
#endif

__attribute__((objc_subclassing_restricted))
@interface MTIChromaKeyBlendFilter : NSObject <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@property (nonatomic, strong, nullable) MTIImage *inputBackgroundImage;

@property (nonatomic) float thresholdSensitivity;

@property (nonatomic) float smoothing;

@property (nonatomic) MTIColor color;

@end
