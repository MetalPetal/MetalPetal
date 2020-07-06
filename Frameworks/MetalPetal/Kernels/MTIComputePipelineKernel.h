//
//  MTIComputePipelineKernel.h
//  Pods
//
//  Created by yi chen on 2017/7/27.
//
//
#import <Metal/Metal.h>
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIKernel.h>
#import <MetalPetal/MTITextureDimensions.h>
#else
#import "MTIKernel.h"
#import "MTITextureDimensions.h"
#endif

@class MTIAlphaTypeHandlingRule;

NS_ASSUME_NONNULL_BEGIN

@class MTIComputePipeline, MTIFunctionDescriptor, MTIImage;

__attribute__((objc_subclassing_restricted))
@interface MTIComputeFunctionDispatchOptions : NSObject <NSCopying>

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithThreads:(MTLSize)threads threadgroups:(MTLSize)threadgroups threadsPerThreadgroup:(MTLSize)threadsPerThreadgroup;

- (instancetype)initWithGenerator:(void (^)(id<MTLComputePipelineState> pipelineState, MTLSize *threads, MTLSize *threadgroups, MTLSize *threadsPerThreadgroup))block NS_REFINED_FOR_SWIFT;

@end

__attribute__((objc_subclassing_restricted))
@interface MTIComputePipelineKernel : NSObject <MTIKernel>

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic,copy,readonly) MTIAlphaTypeHandlingRule *alphaTypeHandlingRule;

@property (nonatomic, copy, readonly) MTIFunctionDescriptor *computeFunctionDescriptor;

- (instancetype)initWithComputeFunctionDescriptor:(MTIFunctionDescriptor *)computeFunctionDescriptor;

- (instancetype)initWithComputeFunctionDescriptor:(MTIFunctionDescriptor *)computeFunctionDescriptor alphaTypeHandlingRule:(MTIAlphaTypeHandlingRule *)alphaTypeHandlingRule NS_DESIGNATED_INITIALIZER;

- (MTIImage *)applyToInputImages:(NSArray<MTIImage *> *)images
                      parameters:(NSDictionary<NSString *,id> *)parameters
         outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions
               outputPixelFormat:(MTLPixelFormat)outputPixelFormat;

- (MTIImage *)applyToInputImages:(NSArray<MTIImage *> *)images
                      parameters:(NSDictionary<NSString *,id> *)parameters
                 dispatchOptions:(nullable MTIComputeFunctionDispatchOptions *)dispatchOptions
         outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions
               outputPixelFormat:(MTLPixelFormat)outputPixelFormat;

@end

NS_ASSUME_NONNULL_END
