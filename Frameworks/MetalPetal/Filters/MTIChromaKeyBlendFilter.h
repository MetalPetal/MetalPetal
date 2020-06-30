//
//  MTIChromaKeyBlendFilter.h
//  Pods
//
//  Created by Yu Ao on 29/12/2017.
//

#import <MTIFilter.h>
#import <MTIColor.h>

__attribute__((objc_subclassing_restricted))
@interface MTIChromaKeyBlendFilter : NSObject <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@property (nonatomic, strong, nullable) MTIImage *inputBackgroundImage;

@property (nonatomic) float thresholdSensitivity;

@property (nonatomic) float smoothing;

@property (nonatomic) MTIColor color;

@end
