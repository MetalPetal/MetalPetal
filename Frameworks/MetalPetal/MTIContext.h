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

NS_ASSUME_NONNULL_BEGIN

@class MTIFilterFunctionDescriptor,MTISamplerDescriptor,MTIRenderPipeline, MTITexturePool;

FOUNDATION_EXPORT NSString * const MTIContextErrorDomain;

typedef NS_ENUM(NSInteger, MTIContextError) {
    MTIContextErrorFunctionNotFound = 1000,
    MTIContextErrorCoreVideoMetalTextureCacheFailedToCreateTexture = 1001,
    MTIContextErrorCoreVideoDoesNotSupportMetal = 1002
};

@interface MTIContext : NSObject

@property (nonatomic, strong, readonly) id<MTLDevice> device;

@property (nonatomic, strong, readonly) id<MTLLibrary> defaultLibrary;

@property (nonatomic, strong, readonly) id<MTLCommandQueue> commandQueue;

@property (nonatomic, strong, readonly) id<MTLComputePipelineState> computePipelineState;

@property (nonatomic, strong, readonly) MTKTextureLoader *textureLoader;

@property (nonatomic, strong, readonly) CIContext *coreImageContext;

#if COREVIDEO_SUPPORTS_METAL

@property (nonatomic, readonly) CVMetalTextureCacheRef coreVideoTextureCache;

#endif

@property (nonatomic, strong, readonly) MTITexturePool *texturePool;

- (nullable instancetype)initWithDevice:(id<MTLDevice>)device error:(NSError **)error;

#pragma mark - Cache

- (nullable id<MTLLibrary>)libraryWithURL:(NSURL *)URL error:(NSError **)error;

- (nullable id<MTLFunction>)functionWithDescriptor:(MTIFilterFunctionDescriptor *)descriptor error:(NSError **)error;

- (id<MTLSamplerState>)samplerStateWithDescriptor:(MTISamplerDescriptor *)descriptor;

- (nullable MTIRenderPipeline *)renderPipelineWithDescriptor:(MTLRenderPipelineDescriptor *)descriptor error:(NSError **)error;

- (nullable id)kernelStateForKernel:(id<MTIKernel>)kernel error:(NSError **)error;

@end


NS_ASSUME_NONNULL_END
