//
//  MTICVPixelBufferPromise.h
//  Pods
//
//  Created by YuAo on 21/07/2017.
//
//

#import <Foundation/Foundation.h>
#import "MTIImagePromise.h"
#import "MTICVPixelBufferRendering.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTICVPixelBufferPromise : NSObject <MTIImagePromise>

@property (nonatomic, readonly) MTICVPixelBufferRenderingAPI renderingAPI;

@property (nonatomic, readonly) BOOL sRGB;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer options:(MTICVPixelBufferRenderingOptions *)options alphaType:(MTIAlphaType)alphaType;

@end

NS_ASSUME_NONNULL_END
