//
//  MTIContext+Rendering.h
//  Pods
//
//  Created by YuAo on 23/07/2017.
//
//

#import <Foundation/Foundation.h>
#import "MTIContext.h"

NS_ASSUME_NONNULL_BEGIN

@class MTIDrawableRenderingRequest;

@interface MTIContext (Rendering)

- (BOOL)renderImage:(MTIImage *)image toCVPixelBuffer:(CVPixelBufferRef)pixelBuffer error:(NSError **)error NS_SWIFT_NAME(render(_:to:));

- (BOOL)renderImage:(MTIImage *)image toDrawableWithRequest:(MTIDrawableRenderingRequest *)request error:(NSError **)error NS_SWIFT_NAME(render(_:toDrawableWithRequest:));

- (nullable CIImage *)createCIImageFromImage:(MTIImage *)image error:(NSError **)error NS_SWIFT_NAME(makeCIImage(from:));

- (nullable CGImageRef)createCGImageFromImage:(MTIImage *)image error:(NSError **)error CF_RETURNS_RETAINED NS_SWIFT_NAME(makeCGImage(from:));

@end

NS_ASSUME_NONNULL_END
