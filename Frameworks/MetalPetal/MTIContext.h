//
//  MTIContext.h
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <CoreImage/CoreImage.h>
#import <CoreVideo/CoreVideo.h>
#import "MTIKernel.h"
#import "MTIImagePromise.h"

NS_ASSUME_NONNULL_BEGIN

@class MTIFunctionDescriptor, MTISamplerDescriptor, MTIRenderPipeline, MTIComputePipeline, MTITextureDescriptor;

@interface MTIImagePromiseRenderTarget : NSObject

@property (nonatomic,strong,readonly,nullable) id<MTLTexture> texture;

- (BOOL)retainTexture;

- (void)releaseTexture;

@end

FOUNDATION_EXPORT NSString * const MTIContextErrorDomain;

typedef NS_ENUM(NSInteger, MTIContextError) {
    MTIContextErrorFunctionNotFound = 1000,
    MTIContextErrorCoreVideoMetalTextureCacheFailedToCreateTexture = 1001,
    MTIContextErrorCoreVideoDoesNotSupportMetal = 1002,
    MTIContextErrorUnsupportedCVPixelBufferFormat = 1003,
    MTIContextErrorUnsupportedImageCachePolicy = 1004,
    MTIContextErrorDataBufferSizeMismatch = 1005,
    MTIContextErrorDeviceNotFound = 1006,
    MTIContextErrorEmptyDrawable = 1007
};

@interface MTIContextOptions : NSObject <NSCopying>

@property (nonatomic,copy,nullable) NSDictionary<NSString *,id> *coreImageContextOptions;

@end

@interface MTIContext : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (nullable instancetype)initWithDevice:(id<MTLDevice>)device error:(NSError **)error;

- (nullable instancetype)initWithDevice:(id<MTLDevice>)device options:(nullable MTIContextOptions *)options error:(NSError **)error NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, readonly) id<MTLDevice> device;

@property (nonatomic, strong, readonly) id<MTLLibrary> defaultLibrary;

@property (nonatomic, strong, readonly) id<MTLCommandQueue> commandQueue;

@property (nonatomic, strong, readonly) MTKTextureLoader *textureLoader;

@property (nonatomic, strong, readonly) CIContext *coreImageContext;

#pragma mark - Pool

#if COREVIDEO_SUPPORTS_METAL

@property (nonatomic, readonly) CVMetalTextureCacheRef coreVideoTextureCache;

#endif

#pragma mark - Cache

- (nullable id<MTLLibrary>)libraryWithURL:(NSURL *)URL error:(NSError **)error;

- (nullable id<MTLFunction>)functionWithDescriptor:(MTIFunctionDescriptor *)descriptor error:(NSError **)error;

- (id<MTLSamplerState>)samplerStateWithDescriptor:(MTISamplerDescriptor *)descriptor;

- (nullable MTIRenderPipeline *)renderPipelineWithDescriptor:(MTLRenderPipelineDescriptor *)descriptor error:(NSError **)error;

- (nullable MTIComputePipeline *)computePipelineWithDescriptor:(MTLComputePipelineDescriptor *)descriptor error:(NSError **)error;

- (nullable id)kernelStateForKernel:(id<MTIKernel>)kernel error:(NSError **)error;


- (MTIImagePromiseRenderTarget *)newRenderTargetWithResuableTextureDescriptor:(MTITextureDescriptor *)textureDescriptor;
- (MTIImagePromiseRenderTarget *)newRenderTargetWithTexture:(id<MTLTexture>)texture;


- (nullable id)valueForPromise:(id<MTIImagePromise>)promise inTable:(NSString *)tableName;

- (void)setValue:(id)value forPromise:(id<MTIImagePromise>)promise inTable:(NSString *)tableName;

- (nullable id)valueForImage:(MTIImage *)image inTable:(NSString *)tableName;

- (void)setValue:(id)value forImage:(MTIImage *)image inTable:(NSString *)tableName;

@end


NS_ASSUME_NONNULL_END
