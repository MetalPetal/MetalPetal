//
//  MTIContext+Internal.h
//  MetalPetal
//
//  Created by Yu Ao on 07/01/2018.
//

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <CoreImage/CoreImage.h>
#import <CoreVideo/CoreVideo.h>
#import "MTIContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTIImagePromiseRenderTarget : NSObject

@property (nonatomic,strong,readonly,nullable) id<MTLTexture> texture;

- (BOOL)retainTexture;

- (void)releaseTexture;

@end

typedef NSString * MTIContextPromiseAssociatedValueTableName NS_EXTENSIBLE_STRING_ENUM;
typedef NSString * MTIContextImageAssociatedValueTableName NS_EXTENSIBLE_STRING_ENUM;

@class MTIFunctionDescriptor, MTISamplerDescriptor, MTIRenderPipeline, MTIComputePipeline, MTITextureDescriptor;

@interface MTIContext (Internal)

#pragma mark - Render Target

- (nullable MTIImagePromiseRenderTarget *)newRenderTargetWithResuableTextureDescriptor:(MTITextureDescriptor *)textureDescriptor error:(NSError **)error NS_SWIFT_NAME(makeRenderTarget(resuableTextureDescriptor:));

- (MTIImagePromiseRenderTarget *)newRenderTargetWithTexture:(id<MTLTexture>)texture NS_SWIFT_NAME(makeRenderTarget(texture:));

#pragma mark - Lock

- (void)lockForRendering;

- (void)unlockForRendering;

#pragma mark - Cache

- (nullable id<MTLLibrary>)libraryWithURL:(NSURL *)URL error:(NSError **)error;

- (nullable id<MTLFunction>)functionWithDescriptor:(MTIFunctionDescriptor *)descriptor error:(NSError **)error;

- (nullable id<MTLSamplerState>)samplerStateWithDescriptor:(MTISamplerDescriptor *)descriptor error:(NSError **)error;

- (nullable MTIRenderPipeline *)renderPipelineWithDescriptor:(MTLRenderPipelineDescriptor *)descriptor error:(NSError **)error;

- (nullable MTIComputePipeline *)computePipelineWithDescriptor:(MTLComputePipelineDescriptor *)descriptor error:(NSError **)error;

- (nullable id)kernelStateForKernel:(id<MTIKernel>)kernel configuration:(nullable id<MTIKernelConfiguration>)configuration error:(NSError **)error;

#pragma mark - Privately Used Caches

/* Weak to strong tables */

- (nullable id)valueForPromise:(id<MTIImagePromise>)promise inTable:(MTIContextPromiseAssociatedValueTableName)tableName;

- (void)setValue:(nullable id)value forPromise:(id<MTIImagePromise>)promise inTable:(MTIContextPromiseAssociatedValueTableName)tableName;

- (nullable id)valueForImage:(MTIImage *)image inTable:(MTIContextImageAssociatedValueTableName)tableName;

- (void)setValue:(nullable id)value forImage:(MTIImage *)image inTable:(MTIContextImageAssociatedValueTableName)tableName;

/* MTIImagePromise (weak) to MTIImagePromiseRenderTarget (weak) table. */

- (void)setRenderTarget:(MTIImagePromiseRenderTarget *)renderTarget forPromise:(id<MTIImagePromise>)promise;

- (nullable MTIImagePromiseRenderTarget *)renderTargetForPromise:(id<MTIImagePromise>)promise;

@end

NS_ASSUME_NONNULL_END
