//
//  MTIRenderPipelineKernel.h
//  Pods
//
//  Created by YuAo on 02/07/2017.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MTIKernel.h"
#import "MTIVertex.h"
#import "MTIAlphaType.h"
#import "MTIImagePromise.h"
#import "MTIRenderCommand.h"

NS_ASSUME_NONNULL_BEGIN

@class MTIRenderPipeline, MTIFunctionDescriptor, MTIContext, MTIImage, MTIRenderPassOutputDescriptor;

@interface MTIRenderPipelineKernelConfiguration: NSObject <MTIKernelConfiguration>

@property (nonatomic,copy,readonly) NSArray<NSNumber *> *colorAttachmentPixelFormats;

- (instancetype)initWithColorAttachmentPixelFormats:(NSArray<NSNumber *> *)colorAttachmentPixelFormats;

@end

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
               outputPixelFormat:(MTLPixelFormat)outputPixelFormat;

- (NSArray<MTIImage *> *)applyToInputImages:(NSArray<MTIImage *> *)images
                                 parameters:(NSDictionary<NSString *,id> *)parameters
                          outputDescriptors:(NSArray<MTIRenderPassOutputDescriptor *> *)outputDescriptors;

@end

@interface MTIRenderCommand (ImageCreation)

+ (NSArray<MTIImage *> *)imagesByPerformingRenderCommands:(NSArray<MTIRenderCommand *> *)renderCommands
                                        outputDescriptors:(NSArray<MTIRenderPassOutputDescriptor *> *)outputDescriptors;

@end

@class MTIImageRenderingDependencyGraph, MTIRenderGraphNode;

FOUNDATION_EXPORT void MTIColorMatrixRenderGraphNodeOptimize(MTIRenderGraphNode *node);

NS_ASSUME_NONNULL_END
