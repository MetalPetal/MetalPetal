//
//  MTIHexagonalBokehBlurFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 13/10/2017.
//

#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIFilter.h>
#else
#import "MTIFilter.h"
#endif

@class MTIMask;

NS_ASSUME_NONNULL_BEGIN

/// An implementation of lens blur (bokeh) based on `Siggraph 2011 - Advances in Real-Time Rendering`
/// https://colinbarrebrisebois.com/2017/04/18/hexagonal-bokeh-blur-revisited/

__attribute__((objc_subclassing_restricted))
@interface MTIHexagonalBokehBlurFilter : NSObject <MTIFilter>

@property (nonatomic, strong, nullable) MTIImage *inputImage;
@property (nonatomic, strong, nullable) MTIMask *inputMask;

@property (nonatomic) float radius;
@property (nonatomic) float brightness;
@property (nonatomic) float angle;

@end

NS_ASSUME_NONNULL_END
