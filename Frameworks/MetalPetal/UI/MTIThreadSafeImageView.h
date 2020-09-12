//
//  MTIAsyncImageView.h
//  MetalPetal
//
//  Created by Yu Ao on 2019/6/12.
//

#if __has_include(<UIKit/UIKit.h>)

#import <UIKit/UIKit.h>
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIDrawableRendering.h>
#else
#import "MTIDrawableRendering.h"
#endif

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const MTIImageViewErrorDomain;

typedef NS_ERROR_ENUM(MTIImageViewErrorDomain, MTIImageViewError) {
    MTIImageViewErrorContextNotFound = 1001,
    MTIImageViewErrorSameImage = 1002
};

@class MTIImage,MTIContext;

/// An image view that immediately draws its `image` on the calling thread. Most of the custom properties can be accessed from any thread safely. It's recommanded to use the `MTIImageView` which draws it's content on the main thread instead of this view.

__attribute__((objc_subclassing_restricted))
@interface MTIThreadSafeImageView : UIView <MTIDrawableProvider>

@property (nonatomic) BOOL automaticallyCreatesContext;

@property (atomic) MTLPixelFormat colorPixelFormat;

@property (atomic) MTLClearColor clearColor;

/// This property aliases the colorspace property of the view's CAMetalLayer
@property (atomic, nullable) CGColorSpaceRef colorSpace;

@property (atomic) MTIDrawableRenderingResizingMode resizingMode;

@property (atomic, strong, nullable) MTIContext *context;

@property (atomic, nullable, strong) MTIImage *image;

/// Update the image. `renderCompletion` will be called when the rendering is finished or failed. The callback will be called on current thread or a metal internal thread.
- (void)setImage:(MTIImage * __nullable)image renderCompletion:(void (^ __nullable)(NSError * __nullable error))renderCompletion;

@end

NS_ASSUME_NONNULL_END

#endif
