//
//  MTICVPixelBufferPromise.h
//  Pods
//
//  Created by YuAo on 21/07/2017.
//
//

#import <Foundation/Foundation.h>
#import "MTIImagePromise.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MTICVPixelBufferRenderingAPI) {
    MTICVPixelBufferRenderingAPIDefault = 1,
    MTICVPixelBufferRenderingAPIMetalPetal = 1,
    MTICVPixelBufferRenderingAPICoreImage = 2
};

@interface MTICVPixelBufferPromise : NSObject <MTIImagePromise>

@property (nonatomic, readonly) MTICVPixelBufferRenderingAPI renderingAPI;

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer renderingAPI:(MTICVPixelBufferRenderingAPI)renderingAPI alphaType:(MTIAlphaType)alphaType;

@end

NS_ASSUME_NONNULL_END
