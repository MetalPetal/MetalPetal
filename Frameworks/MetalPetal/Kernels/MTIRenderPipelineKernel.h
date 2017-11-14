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
#import "MTITextureDimensions.h"
#import "MTIPixelFormat.h"
#import "MTIVertex.h"
#import "MTIAlphaType.h"
#import "MTIImagePromise.h"

NS_ASSUME_NONNULL_BEGIN

@class MTIRenderPipeline, MTIFunctionDescriptor, MTIContext, MTIImage;

@interface MTIRenderPipelineOutputDescriptor: NSObject <NSCopying>

@property (nonatomic,readonly) MTITextureDimensions dimensions;

@property (nonatomic,readonly) MTLPixelFormat pixelFormat;

@property (nonatomic,readonly) MTLLoadAction loadAction;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDimensions:(MTITextureDimensions)dimensions pixelFormat:(MTLPixelFormat)pixelFormat;

- (instancetype)initWithDimensions:(MTITextureDimensions)dimensions pixelFormat:(MTLPixelFormat)pixelFormat loadAction:(MTLLoadAction)loadAction NS_DESIGNATED_INITIALIZER;

- (BOOL)isEqualToOutputDescriptor:(MTIRenderPipelineOutputDescriptor *)object;

@end

@interface MTIRenderPipelineKernel : NSObject <MTIKernel>

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

- (MTIImage *)applyToInputImages:(NSArray<MTIImage *> *)images
                      parameters:(NSDictionary<NSString *,id> *)parameters
         outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions
               outputPixelFormat:(MTLPixelFormat)outputPixelFormat;

- (NSArray<MTIImage *> *)applyToInputImages:(NSArray<MTIImage *> *)images
                                 parameters:(NSDictionary<NSString *,id> *)parameters
                          outputDescriptors:(NSArray<MTIRenderPipelineOutputDescriptor *> *)outputDescriptors;

- (NSArray<MTIImage *> *)imagesByDrawingGeometry:(id<MTIGeometry>)geometry
                                    withTextures:(NSArray<MTIImage *> *)images
                                      parameters:(NSDictionary<NSString *,id> *)parameters
                               outputDescriptors:(NSArray<MTIRenderPipelineOutputDescriptor *> *)outputDescriptors;

@end

@class MTIImageRenderingDependencyGraph;

FOUNDATION_EXPORT id<MTIImagePromise> MTIColorMatrixRenderingPromiseHandleMerge(id<MTIImagePromise> promise, MTIImageRenderingDependencyGraph *dependencyGraph);

NS_ASSUME_NONNULL_END
