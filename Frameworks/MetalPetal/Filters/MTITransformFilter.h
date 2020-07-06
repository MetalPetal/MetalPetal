//
//  MTITransformFilter.h
//  MetalPetal
//
//  Created by Yu Ao on 28/10/2017.
//

#import <QuartzCore/QuartzCore.h>
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIFilter.h>
#else
#import "MTIFilter.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/*
           ^  y+
           |
           |
     +--+--+--+--+
     |/////|/////|
 ----|-----|-----|---> x+
     |/////|/////|
     +--+--+--+--+
           |
           |
*/

typedef CGRect MTITransformFilterViewport NS_SWIFT_NAME(MTITransformFilter.Viewport);

__attribute__((objc_subclassing_restricted))
@interface MTITransformFilter : NSObject <MTIUnaryFilter>

@property (nonatomic) CATransform3D transform;

/*!
 @property fov
 @abstract Determines the receiver's field of view on the X And Y axis (in radian).
 @discussion When fov is zero the orthographic matrix will be applied . Otherwise, use the perspective matrix. Value in [0, M_PI) is valid. Defaults to 0.
 */
@property (nonatomic) float fieldOfView;

@property (nonatomic) MTITransformFilterViewport viewport;

@property (nonatomic, readonly) MTITransformFilterViewport minimumEnclosingViewport;

@property (nonatomic, readonly) MTITransformFilterViewport defaultViewport;

@property (nonatomic) NSUInteger rasterSampleCount;

@end

NS_ASSUME_NONNULL_END
