//
//  MLARSCNCamera.h
//  MLARSCNCameraDemo
//
//

#if __has_include(<SceneKit/SceneKit.h>)

#import <SceneKit/SceneKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@class MTIImage;

FOUNDATION_EXPORT NSString * const MTISCNSceneRendererErrorDomain;

typedef NS_ERROR_ENUM(MTISCNSceneRendererErrorDomain, MTISCNSceneRendererError) {
    MTISCNSceneRendererErrorSceneKitDoesNotSupportMetal = 1001
};

@interface MTISCNSceneRenderer : NSObject

@property (nonatomic, strong, nullable) SCNScene *scene;

@property (nonatomic, strong, readonly) SCNRenderer *scnRenderer;

@property(nonatomic, readonly) CFTimeInterval nextFrameTime;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDevice:(id<MTLDevice>)device NS_DESIGNATED_INITIALIZER;

@end

@interface MTISCNSceneRenderer (MTIImage)

/// Create a MTImage for the scene at the specified time. The image can only be render with the MTIContext that shares the same metal device with this renderer.
- (MTIImage *)snapshotAtTime:(CFTimeInterval)time
                    viewport:(CGRect)viewport
                 pixelFormat:(MTLPixelFormat)pixelFormat
                    isOpaque:(BOOL)isOpaque;

@end

@interface MTISCNSceneRenderer (CVPixelBuffer)

/// Render the scene at the specified time to a pixel buffer. The completion block will be called on an internal queue.
- (BOOL)renderAtTime:(CFTimeInterval)time
            viewport:(CGRect)viewport
          completion:(void(^)(CVPixelBufferRef pixelBuffer))completion
               error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END

#endif
