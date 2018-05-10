//
//  MTIImage.h
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <CoreImage/CoreImage.h>
#import <MetalKit/MetalKit.h>
#import "MTICVPixelBufferRendering.h"
#import "MTIColor.h"
#import "MTIAlphaType.h"

NS_ASSUME_NONNULL_BEGIN

@class MTISamplerDescriptor, MTICIImageRenderingOptions, MTICVPixelBufferRenderingOptions;

typedef NS_ENUM(NSInteger, MTIImageCachePolicy) {
    MTIImageCachePolicyTransient,
    MTIImageCachePolicyPersistent
};

@interface MTIImage : NSObject <NSCopying>

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

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer options:(MTICVPixelBufferRenderingOptions *)options alphaType:(MTIAlphaType)alphaType;


- (instancetype)initWithCGImage:(CGImageRef)cgImage options:(nullable NSDictionary<MTKTextureLoaderOption,id> *)options;

- (instancetype)initWithCGImage:(CGImageRef)cgImage options:(nullable NSDictionary<MTKTextureLoaderOption,id> *)options alphaType:(MTIAlphaType)alphaType;


- (instancetype)initWithTexture:(id<MTLTexture>)texture alphaType:(MTIAlphaType)alphaType;


- (instancetype)initWithCIImage:(CIImage *)ciImage;

- (instancetype)initWithCIImage:(CIImage *)ciImage isOpaque:(BOOL)isOpaque;

- (instancetype)initWithCIImage:(CIImage *)ciImage isOpaque:(BOOL)isOpaque options:(MTICIImageRenderingOptions *)options;


- (nullable instancetype)initWithContentsOfURL:(NSURL *)URL options:(nullable NSDictionary<MTKTextureLoaderOption,id> *)options;

- (nullable instancetype)initWithContentsOfURL:(NSURL *)URL options:(nullable NSDictionary<MTKTextureLoaderOption,id> *)options alphaType:(MTIAlphaType)alphaType;

//MTIAlphaTypeNonPremultiplied
- (instancetype)initWithColor:(MTIColor)color sRGB:(BOOL)sRGB size:(CGSize)size;

- (instancetype)initWithBitmapData:(NSData *)data width:(NSUInteger)width height:(NSUInteger)height bytesPerRow:(NSUInteger)bytesPerRow pixelFormat:(MTLPixelFormat)pixelFormat alphaType:(MTIAlphaType)alphaType;

- (instancetype)initWithName:(NSString *)name
                      bundle:(nullable NSBundle *)bundle
                        size:(CGSize)size
                 scaleFactor:(CGFloat)scaleFactor
                     options:(nullable NSDictionary<MTKTextureLoaderOption, id> *)options
                   alphaType:(MTIAlphaType)alphaType NS_AVAILABLE(10_12, 10_0);

/// A 1x1 white image
@property (class, readonly) MTIImage *whiteImage;

/// A 1x1 black image
@property (class, readonly) MTIImage *blackImage;

/// A 1x1 transparent image
@property (class, readonly) MTIImage *transparentImage;

@end


NS_ASSUME_NONNULL_END
