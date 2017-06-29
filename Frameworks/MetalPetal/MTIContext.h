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

NS_ASSUME_NONNULL_BEGIN

@class MTIFilterFunctionDescriptor,MTISamplerDescriptor;

@interface MTIRenderPipelineInfo : NSObject <NSCopying>

@property (nonatomic,strong,readonly) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic,strong,readonly) MTLRenderPipelineReflection *pipelineReflection;

@end

FOUNDATION_EXPORT NSString * const MTIContextErrorDomain;

typedef NS_ENUM(NSInteger, MTIContextError) {
    MTIContextErrorFunctionNotFound = 1000
};

@interface MTIContext : NSObject

@property (nonatomic, strong, readonly) id<MTLDevice> device;

@property (nonatomic, strong, readonly) id<MTLLibrary> defaultLibrary;

@property (nonatomic, strong, readonly) id<MTLCommandQueue> commandQueue;

@property (nonatomic, strong, readonly) MTKTextureLoader *textureLoader;

@property (nonatomic, strong, readonly) CIContext *coreImageContext;

@property (nonatomic, readonly) CVMetalTextureCacheRef coreVideoTextureCache;

- (nullable instancetype)initWithDevice:(id<MTLDevice>)device error:(__autoreleasing NSError **)error;

- (nullable id<MTLLibrary>)libraryWithURL:(NSURL *)URL error:(__autoreleasing NSError **)error;

- (nullable MTIRenderPipelineInfo *)renderPipelineInfoWithColorAttachmentPixelFormats:(MTLPixelFormat)pixelFormat
                                                                       vertexFunction:(id<MTLFunction>)vertexFunction
                                                                     fragmentFunction:(id<MTLFunction>)fragmentFunction
                                                                                error:(NSError **)error;

- (nullable id<MTLFunction>)functionWithDescriptor:(MTIFilterFunctionDescriptor *)descriptor error:(__autoreleasing NSError **)error;

- (id<MTLSamplerState>)samplerStateWithDescriptor:(MTISamplerDescriptor *)descriptor;

@end

NS_ASSUME_NONNULL_END
