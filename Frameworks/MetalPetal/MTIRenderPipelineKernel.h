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

NS_ASSUME_NONNULL_BEGIN

@class MTIRenderPipeline, MTIFilterFunctionDescriptor, MTIContext, MTIImage;

@interface MTIRenderPipelineKernel : NSObject <MTIKernel>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithVertexFunctionDescriptor:(MTIFilterFunctionDescriptor *)vertexFunctionDescriptor
                      fragmentFunctionDescriptor:(MTIFilterFunctionDescriptor *)fragmentFunctionDescriptor
                                vertexDescriptor:(nullable MTLVertexDescriptor *)vertexDescriptor
                       colorAttachmentDescriptor:(MTLRenderPipelineColorAttachmentDescriptor *)colorAttachmentDescriptor NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithVertexFunctionDescriptor:(MTIFilterFunctionDescriptor *)vertexFunctionDescriptor
                      fragmentFunctionDescriptor:(MTIFilterFunctionDescriptor *)fragmentFunctionDescriptor
                      colorAttachmentPixelFormat:(MTLPixelFormat)colorAttachmentPixelFormat;

- (nullable MTIRenderPipeline *)newKernelStateWithContext:(MTIContext *)context error:(NSError **)error;

@property (nonatomic,readonly) MTLPixelFormat pixelFormat;

- (MTIImage *)applyToInputImages:(NSArray<MTIImage *> *)images
                      parameters:(NSDictionary<NSString *,id> *)parameters
         outputTextureDescriptor:(MTLTextureDescriptor *)outputTextureDescriptor;

@end

NS_ASSUME_NONNULL_END
