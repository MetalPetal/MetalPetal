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

- (BOOL)renderImage:(MTIImage *)image toPixelBuffer:(CVPixelBufferRef)pixelBuffer error:(NSError **)error;

- (BOOL)renderImage:(MTIImage *)image toDrawableWithRequest:(MTIDrawableRenderingRequest *)request error:(NSError **)error;

- (nullable CIImage *)createCIImage:(MTIImage *)image error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
