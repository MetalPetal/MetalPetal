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
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIMemoryWarningObserver.h>
#else
#import "MTIMemoryWarningObserver.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@class MTICVMetalTextureCache;
@protocol MTITextureLoader, MTITexturePool, MTICVMetalTextureBridging;

FOUNDATION_EXPORT NSString * const MTIContextDefaultLabel;

/// Options for creating a MTIContext.
__attribute__((objc_subclassing_restricted))
@interface MTIContextOptions : NSObject

@property (nonatomic, copy, nullable) NSDictionary<CIContextOption,id> *coreImageContextOptions;

/// Default pixel format for intermediate textures.
@property (nonatomic) MTLPixelFormat workingPixelFormat;

/// Whether the render graph optimization is enabled. The default value for this property is NO.
@property (nonatomic) BOOL enablesRenderGraphOptimization;

/// Automatically reclaims resources on memory warning.
@property (nonatomic) BOOL automaticallyReclaimsResources;

/// Whether to enable native support for YCbCr textures. The default value for this property is YES. YCbCr textures can be used when this property is set to YES, and the device supports this feature.
@property (nonatomic) BOOL enablesYCbCrPixelFormatSupport;

/// A string to help identify this object.
@property (nonatomic, copy) NSString *label;

/// The built-in metal library URL.
@property (nonatomic, copy) NSURL *defaultLibraryURL;

/// The texture loader to use. When this property is nil, the context uses `MTIDefaultTextureLoader`.
@property (nonatomic, nullable) Class<MTITextureLoader> textureLoaderClass;

/// The core video - metal texture bridge class to use. Possible values are MTICVMetalTextureCache.class (using CVMetalTextureRef), MTICVMetalIOSurfaceBridge.class (using IOSurface to convert CVPixelBuffer to metal texture). When this property is nil, the context uses `MTICVMetalIOSurfaceBridge`.
@property (nonatomic, nullable) Class<MTICVMetalTextureBridging> coreVideoMetalTextureBridgeClass;

/// The texture pool class to use. When this property is nil, the context uses `MTIHeapTexturePool` if possible, and falls back to `MTIDeviceTexturePool`.
@property (nonatomic, nullable) Class<MTITexturePool> texturePoolClass;

@end

FOUNDATION_EXPORT NSURL * _Nullable MTIDefaultLibraryURLForBundle(NSBundle *bundle);

/// An evaluation context for rendering image processing results.
__attribute__((objc_subclassing_restricted))
@interface MTIContext : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (nullable instancetype)initWithDevice:(id<MTLDevice>)device error:(NSError **)error;

- (nullable instancetype)initWithDevice:(id<MTLDevice>)device options:(MTIContextOptions *)options error:(NSError **)error NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) MTLPixelFormat workingPixelFormat;

@property (nonatomic, readonly) BOOL isRenderGraphOptimizationEnabled;

@property (nonatomic, copy, readonly) NSString *label;

/// Whether the device supports MetalPerformanceShaders.
@property (nonatomic, readonly) BOOL isMetalPerformanceShadersSupported;

/// Whether the device supports YCbCr pixel formats.
@property (nonatomic, readonly) BOOL isYCbCrPixelFormatSupported;

/// Whether the device supports memoryless texture.
@property (nonatomic, readonly) BOOL isMemorylessTextureSupported;

/// Whether the device supports programmable blending.
@property (nonatomic, readonly) BOOL isProgrammableBlendingSupported;

/// Whether the default library is compiled with programmable blending support.
@property (nonatomic, readonly) BOOL defaultLibrarySupportsProgrammableBlending;

@property (nonatomic, strong, readonly) id<MTLDevice> device;

@property (nonatomic, strong, readonly) id<MTLLibrary> defaultLibrary;

@property (nonatomic, strong, readonly) id<MTLCommandQueue> commandQueue;

@property (nonatomic, strong, readonly) id<MTITextureLoader> textureLoader;

@property (nonatomic, strong, readonly) CIContext *coreImageContext;

@property (nonatomic, strong, readonly) id<MTICVMetalTextureBridging> coreVideoTextureBridge;

@property (nonatomic, class, readonly) BOOL defaultMetalDeviceSupportsMPS;

- (void)reclaimResources;

@property (nonatomic, readonly) NSUInteger idleResourceSize;

@property (nonatomic, readonly) NSUInteger idleResourceCount;

+ (void)enumerateAllInstances:(void (^)(MTIContext *context))enumerator;

/// Whether a device supports memoryless render targets.
+ (BOOL)deviceSupportsMemorylessTexture:(id<MTLDevice>)device;

/// Whether a device supports YCbCr pixel formats.
+ (BOOL)deviceSupportsYCbCrPixelFormat:(id<MTLDevice>)device;

/// Whether a device supports programmable blending.
/// @discussion This only indicates whether the device supports programmable blending. To use programmable blending you need to make sure the metal library is compiled with the supported metal language version. For Mac and MacCatalyst, `MTLLanguageVersion2_3` is required.
+ (BOOL)deviceSupportsProgrammableBlending:(id<MTLDevice>)device;

@end

@interface MTIContext (MemoryWarningHandling) <MTIMemoryWarningHandling>

@end

@interface MTIContext (SimulatorSupport)

/// Whether to render on iOS simulators. The default value is YES. If the value of this property is NO, the `MTIContext` initialization fails immediately with an error (MTIErrorFeatureNotAvailableOnSimulator) on Simulators. This property is relevant only during the initialization of an `MTIContext`.
@property (nonatomic, class) BOOL enablesSimulatorSupport;

@end

NS_ASSUME_NONNULL_END
