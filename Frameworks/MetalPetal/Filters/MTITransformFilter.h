//
//  MTITransformFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 28/10/2017.
//

#import <QuartzCore/QuartzCore.h>
#import "MTIFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTITransformFilter : NSObject <MTIFilter>

@property (nonatomic) CATransform3D transform;

@property (nonatomic, strong, nullable) MTIImage *inputImage;

@end

NS_ASSUME_NONNULL_END
