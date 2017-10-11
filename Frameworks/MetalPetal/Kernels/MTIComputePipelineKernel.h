//
//  MTIComputePipelineKernel.h
//  Pods
//
//  Created by yi chen on 2017/7/27.
//
//
#import <Metal/Metal.h>
#import "MTIKernel.h"
#import "MTITextureDimensions.h"

NS_ASSUME_NONNULL_BEGIN

@class MTIComputePipeline, MTIFunctionDescriptor, MTIImage;

@interface MTIComputePipelineKernel : NSObject <MTIKernel>

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithComputeFunctionDescriptor:(MTIFunctionDescriptor *)computeFunctionDescriptor NS_DESIGNATED_INITIALIZER;

- (nullable MTIComputePipeline *)newKernelStateWithContext:(MTIContext *)context error:(NSError **)error;

- (MTIImage *)applyToInputImages:(NSArray<MTIImage *> *)images
                      parameters:(NSDictionary<NSString *,id> *)parameters
         outputTextureDimensions:(MTITextureDimensions)outputTextureDimensions;

@end

NS_ASSUME_NONNULL_END
