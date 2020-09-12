//
//  MTIImageView.h
//  Pods
//
//  Created by Yu Ao on 09/10/2017.
//

#if __has_include(<UIKit/UIKit.h>)

#import <UIKit/UIKit.h>
#import <MetalKit/MetalKit.h>
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIDrawableRendering.h>
#else
#import "MTIDrawableRendering.h"
#endif

@class MTIImage,MTIContext;

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface MTIImageView : UIView <MTKViewDelegate>

@property (nonatomic) BOOL automaticallyCreatesContext;

@property (nonatomic) MTLPixelFormat colorPixelFormat;

@property (nonatomic) MTLClearColor clearColor;

@property (nonatomic) MTIDrawableRenderingResizingMode resizingMode;

@property (nonatomic, strong, nullable) MTIContext *context;

@property (nonatomic, strong, nullable) MTIImage *image;

@property (nonatomic) BOOL drawsImmediately __attribute__((deprecated("Set `drawsImmediately` to `YES` is not recommended anymore. Please file an issue describing how you'd like to use this feature. https://github.com/MetalPetal/MetalPetal"))); //Default `NO`.

@end

NS_ASSUME_NONNULL_END

#endif
