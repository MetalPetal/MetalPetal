//
//  MTIImagePromise.h
//  Pods
//
//  Created by YuAo on 27/06/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <simd/simd.h>
#import "MTIColor.h"
#import "MTITextureDimensions.h"
#import "MTIAlphaType.h"

NS_ASSUME_NONNULL_BEGIN

@class MTIImage, MTIImageRenderingContext, MTIFunctionDescriptor, MTITextureDescriptor, MTIImagePromiseRenderTarget, MTIImagePromiseDebugInfo;

@protocol MTIImagePromise <NSObject, NSCopying>

@property (nonatomic, readonly) MTITextureDimensions dimensions;

@property (nonatomic, readonly, copy) NSArray<MTIImage *> *dependencies;

@property (nonatomic, readonly) MTIAlphaType alphaType;

- (nullable MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError **)error;

- (instancetype)promiseByUpdatingDependencies:(NSArray<MTIImage *> *)dependencies;

@property (nonatomic, strong, readonly) MTIImagePromiseDebugInfo *debugInfo;

@end

#pragma mark - Promises

@interface MTIImageURLPromise : NSObject <MTIImagePromise>

- (nullable instancetype)initWithContentsOfURL:(NSURL *)URL options:(nullable NSDictionary <NSString *, id> *)options alphaType:(MTIAlphaType)alphaType;

@end

@interface MTICGImagePromise : NSObject <MTIImagePromise>

- (instancetype)initWithCGImage:(CGImageRef)cgImage options:(nullable NSDictionary <NSString *, id> *)options alphaType:(MTIAlphaType)alphaType;

@end

@interface MTITexturePromise : NSObject <MTIImagePromise>

- (instancetype)initWithTexture:(id<MTLTexture>)texture alphaType:(MTIAlphaType)alphaType;

@end

@interface MTICIImagePromise : NSObject <MTIImagePromise>

- (instancetype)initWithCIImage:(CIImage *)ciImage isOpaque:(BOOL)isOpaque;

@end

@interface MTIColorImagePromise: NSObject <MTIImagePromise>

@property (nonatomic,readonly) MTIColor color;

- (instancetype)initWithColor:(MTIColor)color sRGB:(BOOL)sRGB size:(CGSize)size;

@end

@interface MTIBitmapDataImagePromise: NSObject <MTIImagePromise>

- (instancetype)initWithBitmapData:(NSData *)data width:(NSUInteger)width height:(NSUInteger)height bytesPerRow:(NSUInteger)bytesPerRow pixelFormat:(MTLPixelFormat)pixelFormat alphaType:(MTIAlphaType)alphaType;

@end

NS_ASSUME_NONNULL_END

