//
//  MTIContext.h
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <CoreImage/CoreImage.h>
#import <CoreVideo/CoreVideo.h>
#import "MTIKernel.h"
#import "MTIImagePromise.h"
#import "MTIMemoryWarningObserver.h"
#import "MTICVMetalTextureBridging.h"
#import "MTITextureLoader.h"
#import "MTITexturePool.h"

NS_ASSUME_NONNULL_BEGIN

@class MTICVMetalTextureCache;

FOUNDATION_EXPORT NSString * const MTIContextDefaultLabel;

/// Options for creating a MTIContext.
@interface MTIContextOptions : NSObject <NSCopying>

@property (nonatomic, copy, nullable) NSDictionary<CIContextOption,id> *coreImageContextOptions;

/// Default pixel format for intermediate textures.
@property (nonatomic) MTLPixelFormat workingPixelFormat;

/// Whether the render graph optimization is enabled. The default value for this property is NO.
@property (nonatomic) BOOL enablesRenderGraphOptimization;

/// Automatically reclaim resources on memory warning.
@property (nonatomic) BOOL automaticallyReclaimResources;

/// Whether to enable native support for YCbCr textures. The default value for this property is YES. YCbCr textures can be used when this property is set to YES, and the device supports this feature.
@property (nonatomic) BOOL enablesYCbCrPixelFormatSupport;

/// A string to help identify this object.
@property (nonatomic, copy) NSString *label;

/// The built-in metal library URL.
@property (nonatomic, copy) NSURL *defaultLibraryURL;

/// The texture loader to use. Possible values are MTKTextureLoader.class, MTITextureLoaderForiOS9WithImageOrientationFix.class
@property (nonatomic) Class<MTITextureLoader> textureLoaderClass;

/// The core video - metal texture bridge class to use. Possible values are MTICVMetalTextureCache.class (using CVMetalTextureRef), MTICVMetalIOSurfaceBridge.class (using IOSurface to convert CVPixelBuffer to metal texture).
@property (nonatomic) Class<MTICVMetalTextureBridging> coreVideoMetalTextureBridgeClass;

/// The texture pool class to use.
@property (nonatomic) Class<MTITexturePool> texturePoolClass;

/// The default value for this property is MTKTextureLoader.class
@property (nonatomic, class) Class<MTITextureLoader> defaultTextureLoaderClass;

/// On iOS 11/macOS 10.11 or later, the default value is MTICVMetalIOSurfaceBridge.class. Before iOS 11/macOS 10.11, the defualt value is MTICVMetalTextureCache.class.
@property (nonatomic, class) Class<MTICVMetalTextureBridging> defaultCoreVideoMetalTextureBridgeClass;

/// The default value for this property is MTIDeviceTexturePool.class
@property (nonatomic, class) Class<MTITexturePool> defaultTexturePoolClass;

@end

FOUNDATION_EXPORT NSURL * _Nullable MTIDefaultLibraryURLForBundle(NSBundle *bundle);

/// An evaluation context for rendering image processing results.
@interface MTIContext : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (nullable instancetype)initWithDevice:(id<MTLDevice>)device error:(NSError **)error;

- (nullable instancetype)initWithDevice:(id<MTLDevice>)device options:(MTIContextOptions *)options error:(NSError **)error NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) MTLPixelFormat workingPixelFormat;

@property (nonatomic, readonly) BOOL isRenderGraphOptimizationEnabled;

@property (nonatomic, copy, readonly) NSString *label;

@property (nonatomic, readonly) BOOL isMetalPerformanceShadersSupported;

@property (nonatomic, readonly) BOOL isYCbCrPixelFormatSupported;

@property (nonatomic, strong, readonly) id<MTLDevice> device;

@property (nonatomic, strong, readonly) id<MTLLibrary> defaultLibrary;

@property (nonatomic, strong, readonly) id<MTLCommandQueue> commandQueue;

@property (nonatomic, strong, readonly) id<MTITextureLoader> textureLoader;

@property (nonatomic, strong, readonly) CIContext *coreImageContext;

@property (nonatomic, strong, readonly) id<MTICVMetalTextureBridging> coreVideoTextureBridge;

@property (nonatomic, class, readonly) BOOL defaultMetalDeviceSupportsMPS;

- (void)reclaimResources;

@property (nonatomic, readonly) NSUInteger idleResourceSize NS_AVAILABLE(10_13, 11_0);

@property (nonatomic, readonly) NSUInteger idleResourceCount;

+ (void)enumerateAllInstances:(void (^)(MTIContext *context))enumerator;

@end

@interface MTIContext (MemoryWarningHandling) <MTIMemoryWarningHandling>

@end

@interface MTIContext (SimulatorSupport)

/// Whether to render on iOS simulators. The default value is YES. If the value of this property is NO, the `MTIContext` initialization fails immediately with an error (MTIErrorFeatureNotAvailableOnSimulator) on Simulators. This property is relevant only during the initialization of an `MTIContext`.
@property (nonatomic, class) BOOL enablesSimulatorSupport;

@end

NS_ASSUME_NONNULL_END
