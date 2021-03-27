//
//  MTIMultilayerCompositingFilter.h
//  Pods
//
//  Created by YuAo on 27/09/2017.
//

#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIFilter.h>
#import <MetalPetal/MTIAlphaType.h>
#else
#import "MTIFilter.h"
#import "MTIAlphaType.h"
#endif

@class MTILayer;

NS_ASSUME_NONNULL_BEGIN

/// A filter that allows you to compose multiple `MTILayer` objects onto a background image. A `MTIMultilayerCompositingFilter` object skips the actual rendering when its `layers.count` is zero.
__attribute__((objc_subclassing_restricted))
@interface MTIMultilayerCompositingFilter : NSObject <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputBackgroundImage;

@property (nonatomic, copy) NSArray<MTILayer *> *layers;

@property (nonatomic) NSUInteger rasterSampleCount;

/// Specifies the alpha type of output image. If `.alphaIsOne` is assigned, the alpha channel of the output image will be set to 1. The default value for this property is `.nonPremultiplied`.
@property (nonatomic) MTIAlphaType outputAlphaType;

@end

NS_ASSUME_NONNULL_END
