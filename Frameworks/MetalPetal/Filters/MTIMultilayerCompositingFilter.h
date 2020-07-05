//
//  MTIMultilayerCompositingFilter.h
//  Pods
//
//  Created by YuAo on 27/09/2017.
//

#import <MTIFilter.h>

@class MTILayer;

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface MTIMultilayerCompositingFilter : NSObject <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputBackgroundImage;

@property (nonatomic, copy) NSArray<MTILayer *> *layers;

@property (nonatomic) NSUInteger rasterSampleCount;

@end

NS_ASSUME_NONNULL_END
