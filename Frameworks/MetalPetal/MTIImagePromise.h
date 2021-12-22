//
//  MTIImagePromise.h
//  Pods
//
//  Created by YuAo on 27/06/2017.
//
//

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <simd/simd.h>
#import <CoreImage/CoreImage.h>
#import <ModelIO/ModelIO.h>
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIColor.h>
#import <MetalPetal/MTITextureDimensions.h>
#import <MetalPetal/MTIAlphaType.h>
#else
#import "MTIColor.h"
#import "MTITextureDimensions.h"
#import "MTIAlphaType.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@class MTIImage, MTIImageRenderingContext, MTIFunctionDescriptor, MTITextureDescriptor, MTIImagePromiseRenderTarget, MTIImagePromiseDebugInfo, MTICIImageRenderingOptions, MTIImageProperties;

@protocol MTIImagePromise <NSObject, NSCopying>

@property (nonatomic, readonly) MTITextureDimensions dimensions;

@property (nonatomic, readonly, copy) NSArray<MTIImage *> *dependencies;

@property (nonatomic, readonly) MTIAlphaType alphaType;

- (nullable MTIImagePromiseRenderTarget *)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError **)error;

- (instancetype)promiseByUpdatingDependencies:(NSArray<MTIImage *> *)dependencies;

@property (nonatomic, strong, readonly) MTIImagePromiseDebugInfo *debugInfo;

@end

#pragma mark - Promises

__attribute__((objc_subclassing_restricted))
@interface MTIImageURLPromise : NSObject <MTIImagePromise>

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (nullable instancetype)initWithContentsOfURL:(NSURL *)URL
                                    dimensions:(MTITextureDimensions)dimensions
                                       options:(nullable NSDictionary<MTKTextureLoaderOption, id> *)options
                                     alphaType:(MTIAlphaType)alphaType;

@end

__attribute__((objc_subclassing_restricted))
@interface MTILegacyCGImagePromise : NSObject <MTIImagePromise>

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithCGImage:(CGImageRef)cgImage options:(nullable NSDictionary<MTKTextureLoaderOption, id> *)options alphaType:(MTIAlphaType)alphaType;

@end


__attribute__((objc_subclassing_restricted))
@interface MTICGImageLoadingOptions : NSObject <NSCopying>

@property (nonatomic, readonly, nullable) CGColorSpaceRef colorSpace;

@property (nonatomic, readonly) BOOL flipsVertically;

@property (nonatomic, readonly) MTLStorageMode storageMode;
@property (nonatomic, readonly) MTLCPUCacheMode cpuCacheMode;

@property (nonatomic, class, readonly) MTICGImageLoadingOptions *defaultOptions;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithColorSpace:(nullable CGColorSpaceRef)colorSpace;

- (instancetype)initWithColorSpace:(nullable CGColorSpaceRef)colorSpace
                   flipsVertically:(BOOL)flipsVertically;

/// Create a `MTICGImageLoadingOptions` object. If `colorSpace` is nil, the "Device RGB" color space will be used. The image's color values will be transfered to `colorSpace` when the image is loaded.
- (instancetype)initWithColorSpace:(nullable CGColorSpaceRef)colorSpace
                   flipsVertically:(BOOL)flipsVertically
                       storageMode:(MTLStorageMode)storageMode
                      cpuCacheMode:(MTLCPUCacheMode)cpuCacheMode NS_DESIGNATED_INITIALIZER;

@end


__attribute__((objc_subclassing_restricted))
@interface MTICGImagePromise : NSObject <MTIImagePromise>

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithCGImage:(CGImageRef)cgImage orientation:(CGImagePropertyOrientation)orientation options:(nullable MTICGImageLoadingOptions *)options isOpaque:(BOOL)isOpaque;

@end

__attribute__((objc_subclassing_restricted))
@interface MTITexturePromise : NSObject <MTIImagePromise>

@property (nonatomic, strong, readonly) id<MTLTexture> texture;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithTexture:(id<MTLTexture>)texture alphaType:(MTIAlphaType)alphaType;

@end

__attribute__((objc_subclassing_restricted))
@interface MTICIImagePromise : NSObject <MTIImagePromise>

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithCIImage:(CIImage *)ciImage bounds:(CGRect)bounds isOpaque:(BOOL)isOpaque options:(MTICIImageRenderingOptions *)options;

@end

__attribute__((objc_subclassing_restricted))
@interface MTIColorImagePromise: NSObject <MTIImagePromise>

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, readonly) MTIColor color;

- (instancetype)initWithColor:(MTIColor)color sRGB:(BOOL)sRGB size:(CGSize)size;

@end

__attribute__((objc_subclassing_restricted))
@interface MTIBitmapDataImagePromise: NSObject <MTIImagePromise>

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithBitmapData:(NSData *)data width:(NSUInteger)width height:(NSUInteger)height bytesPerRow:(NSUInteger)bytesPerRow pixelFormat:(MTLPixelFormat)pixelFormat alphaType:(MTIAlphaType)alphaType;

@end

__attribute__((objc_subclassing_restricted))
@interface MTINamedImagePromise: NSObject <MTIImagePromise>

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong, readonly, nullable) NSBundle *bundle;
@property (nonatomic, readonly) CGFloat scaleFactor;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithName:(NSString *)name
                      bundle:(nullable NSBundle *)bundle
                        size:(CGSize)size
                 scaleFactor:(CGFloat)scaleFactor
                     options:(nullable NSDictionary<MTKTextureLoaderOption, id> *)options
                   alphaType:(MTIAlphaType)alphaType;

@end

__attribute__((objc_subclassing_restricted))
@interface MTIMDLTexturePromise: NSObject <MTIImagePromise>

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithMDLTexture:(MDLTexture *)texture
                           options:(nullable NSDictionary<MTKTextureLoaderOption, id> *)options
                         alphaType:(MTIAlphaType)alphaType;

@end

NS_ASSUME_NONNULL_END

