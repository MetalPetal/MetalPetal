//
//  MTIImage.h
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MTICVPixelBufferPromise.h"

NS_ASSUME_NONNULL_BEGIN

@class MTISamplerDescriptor;

typedef NS_ENUM(NSInteger, MTIImageCachePolicy) {
    MTIImageCachePolicyTransient,
    MTIImageCachePolicyPersistent
};

@interface MTIImage : NSObject <NSCopying>

@property (nonatomic,readonly,class) MTISamplerDescriptor *defaultSamplerDescriptor;

@property (nonatomic,readonly) MTIImageCachePolicy cachePolicy;

@property (nonatomic,readonly) CGRect extent;

@property (nonatomic,readonly) CGSize size;

@property (nonatomic,copy, readonly) MTISamplerDescriptor *samplerDescriptor;

@property (nonatomic, readonly) MTIAlphaType alphaType; //relay to underlying promise

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)imageWithSamplerDescriptor:(MTISamplerDescriptor *)samplerDescriptor;

- (instancetype)imageWithCachePolicy:(MTIImageCachePolicy)cachePolicy;

@end

@interface MTIImage (Creation)

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer alphaType:(MTIAlphaType)alphaType;

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer renderingAPI:(MTICVPixelBufferRenderingAPI)renderingAPI alphaType:(MTIAlphaType)alphaType;


- (instancetype)initWithCGImage:(CGImageRef)cgImage options:(nullable NSDictionary<NSString *,id> *)options;

- (instancetype)initWithCGImage:(CGImageRef)cgImage options:(nullable NSDictionary<NSString *,id> *)options alphaType:(MTIAlphaType)alphaType;


- (instancetype)initWithTexture:(id<MTLTexture>)texture alphaType:(MTIAlphaType)alphaType;


- (instancetype)initWithCIImage:(CIImage *)ciImage;

- (instancetype)initWithCIImage:(CIImage *)ciImage isOpaque:(BOOL)isOpaque;


- (nullable instancetype)initWithContentsOfURL:(NSURL *)URL options:(nullable NSDictionary<NSString *,id> *)options;

- (nullable instancetype)initWithContentsOfURL:(NSURL *)URL options:(nullable NSDictionary<NSString *,id> *)options alphaType:(MTIAlphaType)alphaType;

//MTIAlphaTypeNonPremultiplied
- (instancetype)initWithColor:(MTIColor)color sRGB:(BOOL)sRGB size:(CGSize)size;

/// Return a 1x1 white image
+ (instancetype)whiteImage;

/// Return a 1x1 black image
+ (instancetype)blackImage;

/// Return a 1x1 transparent image
+ (instancetype)transparentImage;

@end


NS_ASSUME_NONNULL_END
