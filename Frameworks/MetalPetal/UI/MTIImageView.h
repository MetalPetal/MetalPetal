//
//  MTIImageView.h
//  Pods
//
//  Created by Yu Ao on 09/10/2017.
//

#if __has_include(<UIKit/UIKit.h>)

#import <UIKit/UIKit.h>
#import <MetalKit/MetalKit.h>
#import "MTIDrawableRendering.h"

@class MTIImage,MTIContext;

NS_ASSUME_NONNULL_BEGIN

@interface MTIImageView : UIView <MTKViewDelegate>

@property (nonatomic) MTLPixelFormat colorPixelFormat;

@property (nonatomic) MTLClearColor clearColor;

@property (nonatomic) MTIDrawableRenderingResizingMode resizingMode;

@property (nonatomic, strong) MTIContext *context;

@property (nonatomic, strong, nullable) MTIImage *image;

@property (nonatomic) BOOL drawsImmediately __attribute__((deprecated("Set `drawsImmediately` to `YES` is not recommended anymore. Please file an issue describing how you'd like to use this feature. https://github.com/MetalPetal/MetalPetal"))); //Default `NO`.

@end

NS_ASSUME_NONNULL_END

#endif
