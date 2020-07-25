//
//  MTISKSceneRenderer.h
//  MetalPetal
//
//  Created by YuAo on 2020/7/24.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>
#import <Metal/Metal.h>
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIImage.h>
#else
#import "MTIImage.h"
#endif

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
NS_CLASS_AVAILABLE(10_13, 11_0)
@interface MTISKSceneRenderer : NSObject

@property (nonatomic, strong, nullable) SKScene *scene;

@property (nonatomic, strong, readonly) SKRenderer *skRenderer;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDevice:(id<MTLDevice>)device NS_DESIGNATED_INITIALIZER;

@end

@interface MTISKSceneRenderer (MTIImage)

/// Create a `MTImage` for the scene at the specified time. The image can only be render with the MTIContext that shares the same metal device with this renderer.
- (MTIImage *)snapshotAtTime:(NSTimeInterval)time
                    viewport:(CGRect)viewport
                 pixelFormat:(MTLPixelFormat)pixelFormat
                    isOpaque:(BOOL)isOpaque;

@end

@interface MTIImage (MTISKSceneRenderer)

/// Create a `MTIImage` object from a static `SKScene`. The scene will be copied. If you want to update the scene, use `MTISKSceneRenderer`.
- (instancetype)initWithSKScene:(SKScene *)scene
                           time:(NSTimeInterval)time
                       viewport:(CGRect)viewport
                    pixelFormat:(MTLPixelFormat)pixelFormat
                       isOpaque:(BOOL)isOpaque NS_AVAILABLE(10_13, 11_0);

- (instancetype)initWithSKScene:(SKScene *)scene NS_AVAILABLE(10_13, 11_0);

@end


NS_ASSUME_NONNULL_END
