//
//  MTIMultilayerCompositingFilter.h
//  Pods
//
//  Created by YuAo on 27/09/2017.
//

#import "MTIFilter.h"
#import "MTILayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIMultilayerCompositingFilter : NSObject <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputBackgroundImage;

@property (nonatomic, copy) NSArray<MTILayer *> *layers;

@end

NS_ASSUME_NONNULL_END
