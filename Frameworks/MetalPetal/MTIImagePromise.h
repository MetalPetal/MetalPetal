//
//  MTIImagePromise.h
//  Pods
//
//  Created by YuAo on 27/06/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <simd/simd.h>
#import <CoreImage/CoreImage.h>
#import <ModelIO/ModelIO.h>
#import "MTIColor.h"
#import "MTITextureDimensions.h"
#import "MTIAlphaType.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT BOOL MTIMTKTextureLoaderCanDecodeImage(CGImageRef image);

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

@interface MTIImageURLPromise : NSObject <MTIImagePromise>

- (nullable instancetype)initWithContentsOfURL:(NSURL *)URL
                                    properties:(MTIImageProperties *)properties
                                       options:(nullable NSDictionary<MTKTextureLoaderOption, id> *)options
                                     alphaType:(MTIAlphaType)alphaType;

@end

@interface MTICGImagePromise : NSObject <MTIImagePromise>

- (instancetype)initWithCGImage:(CGImageRef)cgImage options:(nullable NSDictionary<MTKTextureLoaderOption, id> *)options alphaType:(MTIAlphaType)alphaType;

@end

@interface MTITexturePromise : NSObject <MTIImagePromise>

- (instancetype)initWithTexture:(id<MTLTexture>)texture alphaType:(MTIAlphaType)alphaType;

@end

@interface MTICIImagePromise : NSObject <MTIImagePromise>

- (instancetype)initWithCIImage:(CIImage *)ciImage bounds:(CGRect)bounds isOpaque:(BOOL)isOpaque options:(MTICIImageRenderingOptions *)options;

@end

@interface MTIColorImagePromise: NSObject <MTIImagePromise>

@property (nonatomic, readonly) MTIColor color;

- (instancetype)initWithColor:(MTIColor)color sRGB:(BOOL)sRGB size:(CGSize)size;

@end

@interface MTIBitmapDataImagePromise: NSObject <MTIImagePromise>

- (instancetype)initWithBitmapData:(NSData *)data width:(NSUInteger)width height:(NSUInteger)height bytesPerRow:(NSUInteger)bytesPerRow pixelFormat:(MTLPixelFormat)pixelFormat alphaType:(MTIAlphaType)alphaType;

@end

NS_AVAILABLE(10_12, 10_0)
@interface MTINamedImagePromise: NSObject <MTIImagePromise>

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong, readonly, nullable) NSBundle *bundle;
@property (nonatomic, readonly) CGFloat scaleFactor;

- (instancetype)initWithName:(NSString *)name
                      bundle:(nullable NSBundle *)bundle
                        size:(CGSize)size
                 scaleFactor:(CGFloat)scaleFactor
                     options:(nullable NSDictionary<MTKTextureLoaderOption, id> *)options
                   alphaType:(MTIAlphaType)alphaType;

@end

NS_AVAILABLE(10_12, 10_0)
@interface MTIMDLTexturePromise: NSObject <MTIImagePromise>

- (instancetype)initWithMDLTexture:(MDLTexture *)texture
                           options:(nullable NSDictionary<MTKTextureLoaderOption, id> *)options
                         alphaType:(MTIAlphaType)alphaType;

@end

NS_ASSUME_NONNULL_END

