//
//  MTIRenderPipelineKernel.h
//  Pods
//
//  Created by YuAo on 02/07/2017.
//
//

#import <Metal/Metal.h>
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIKernel.h>
#import <MetalPetal/MTITextureDimensions.h>
#import <MetalPetal/MTIRenderCommand.h>
#else
#import "MTIKernel.h"
#import "MTITextureDimensions.h"
#import "MTIRenderCommand.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@class MTIRenderPipeline, MTIFunctionDescriptor, MTIContext, MTIImage, MTIRenderPassOutputDescriptor, MTIAlphaTypeHandlingRule;

FOUNDATION_EXPORT NSUInteger const MTIRenderPipelineMaximumColorAttachmentCount;

__attribute__((objc_subclassing_restricted))
@interface MTIRenderPipelineKernelConfiguration: NSObject <MTIKernelConfiguration>

@property (nonatomic, readonly) const MTLPixelFormat *colorAttachmentPixelFormats;

@property (nonatomic, readonly) NSUInteger colorAttachmentCount;

@property (nonatomic, readonly) MTLPixelFormat depthAttachmentPixelFormat;

@property (nonatomic, readonly) MTLPixelFormat stencilAttachmentPixelFormat;

@property (nonatomic, readonly) NSUInteger rasterSampleCount;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithColorAttachmentPixelFormats:(MTLPixelFormat[_Nonnull])colorAttachmentPixelFormats count:(NSUInteger)count;

- (instancetype)initWithColorAttachmentPixelFormat:(MTLPixelFormat)colorAttachmentPixelFormat;

- (instancetype)initWithColorAttachmentPixelFormats:(MTLPixelFormat[_Nonnull])colorAttachmentPixelFormats count:(NSUInteger)count depthAttachmentPixelFormat:(MTLPixelFormat)depthAttachmentPixelFormat stencilAttachmentPixelFormat:(MTLPixelFormat)stencilAttachmentPixelFormat rasterSampleCount:(NSUInteger)rasterSampleCount NS_DESIGNATED_INITIALIZER;

@end

__attribute__((objc_subclassing_restricted))
@interface MTIRenderPipelineKernel : NSObject <MTIKernel>

@property (nonatomic,copy,readonly) MTIFunctionDescriptor *vertexFunctionDescriptor;

@property (nonatomic,copy,readonly) MTIFunctionDescriptor *fragmentFunctionDescriptor;

@property (nonatomic,copy,readonly,nullable) MTLVertexDescriptor *vertexDescriptor;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic,readonly) NSUInteger colorAttachmentCount;

@property (nonatomic,copy,readonly) MTIAlphaTypeHandlingRule *alphaTypeHandlingRule;

- (instancetype)initWithVertexFunctionDescriptor:(MTIFunctionDescriptor *)vertexFunctionDescriptor
                      fragmentFunctionDescriptor:(MTIFunctionDescriptor *)fragmentFunctionDescriptor
                                vertexDescriptor:(nullable MTLVertexDescriptor *)vertexDescriptor
                            colorAttachmentCount:(NSUInteger)colorAttachmentCount
                           alphaTypeHandlingRule:(MTIAlphaTypeHandlingRule *)alphaTypeHandlingRule NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithVertexFunctionDescriptor:(MTIFunctionDescriptor *)vertexFunctionDescriptor
                      fragmentFunctionDescriptor:(MTIFunctionDescriptor *)fragmentFunctionDescriptor;

@end

@interface MTIRenderPipelineKernel (ImageCreation)

- (MTIImage *)applyToInputImages:(NSArray<MTIImage *> *)images
                      parameters:(NSDictionary<NSString *,id> *)parameters
         outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions
               outputPixelFormat:(MTLPixelFormat)outputPixelFormat NS_REFINED_FOR_SWIFT;

- (NSArray<MTIImage *> *)applyToInputImages:(NSArray<MTIImage *> *)images
                                 parameters:(NSDictionary<NSString *,id> *)parameters
                          outputDescriptors:(NSArray<MTIRenderPassOutputDescriptor *> *)outputDescriptors NS_REFINED_FOR_SWIFT;

@end

@interface MTIRenderPipelineKernel (PassthroughKernel)

@property (nonatomic, class, strong, readonly) MTIRenderPipelineKernel *passthroughRenderPipelineKernel;

@end

@interface MTIRenderCommand (ImageCreation)

+ (NSArray<MTIImage *> *)imagesByPerformingRenderCommands:(NSArray<MTIRenderCommand *> *)renderCommands
                                        outputDescriptors:(NSArray<MTIRenderPassOutputDescriptor *> *)outputDescriptors;


+ (NSArray<MTIImage *> *)imagesByPerformingRenderCommands:(NSArray<MTIRenderCommand *> *)renderCommands
                                        rasterSampleCount:(NSUInteger)rasterSampleCount
                                        outputDescriptors:(NSArray<MTIRenderPassOutputDescriptor *> *)outputDescriptors;

@end

@class MTIRenderGraphNode;

FOUNDATION_EXPORT void MTIColorMatrixRenderGraphNodeOptimize(MTIRenderGraphNode *node);

NS_ASSUME_NONNULL_END
