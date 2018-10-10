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

NS_ASSUME_NONNULL_BEGIN

@class MTICVMetalTextureCache;

FOUNDATION_EXPORT NSString * const MTIContextDefaultLabel;

@interface MTIContextOptions : NSObject <NSCopying>

@property (nonatomic,copy,nullable) NSDictionary<NSString *,id> *coreImageContextOptions;

@property (nonatomic) MTLPixelFormat workingPixelFormat;

@property (nonatomic) BOOL enablesRenderGraphOptimization;

/*! @brief Automatically reclaim resources on memory warning. */
@property (nonatomic) BOOL automaticallyReclaimResources;

/*! @brief A string to help identify this object */
@property (nonatomic, copy) NSString *label;

@end

FOUNDATION_EXPORT NSURL * _Nullable MTIDefaultLibraryURLForBundle(NSBundle *bundle);

@interface MTIContext : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (nullable instancetype)initWithDevice:(id<MTLDevice>)device error:(NSError **)error;

- (nullable instancetype)initWithDevice:(id<MTLDevice>)device options:(MTIContextOptions *)options error:(NSError **)error NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) MTLPixelFormat workingPixelFormat;

@property (nonatomic, readonly) BOOL isRenderGraphOptimizationEnabled;

@property (nonatomic, copy, readonly) NSString *label;

@property (nonatomic, readonly) BOOL isMetalPerformanceShadersSupported;

@property (nonatomic, strong, readonly) id<MTLDevice> device;

@property (nonatomic, strong, readonly) id<MTLLibrary> defaultLibrary;

@property (nonatomic, strong, readonly) id<MTLCommandQueue> commandQueue;

@property (nonatomic, strong, readonly) MTKTextureLoader *textureLoader;

@property (nonatomic, strong, readonly) CIContext *coreImageContext;

@property (nonatomic, strong, readonly) id<MTICVMetalTextureBridging> coreVideoTextureBridge;

@property (nonatomic, class, readonly) BOOL defaultMetalDeviceSupportsMPS;

- (void)reclaimResources;

@property (nonatomic, readonly) NSUInteger idleResourceSize NS_AVAILABLE(10_13, 11_0);

@property (nonatomic, readonly) NSUInteger idleResourceCount;

@end

@interface MTIContext (MemoryWarningHandling) <MTIMemoryWarningHandling>

@end

NS_ASSUME_NONNULL_END
