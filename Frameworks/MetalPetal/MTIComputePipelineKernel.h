//
//  MTIComputePipelineKernel.h
//  Pods
//
//  Created by yi chen on 2017/7/27.
//
//

#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import "MTIKernel.h"

NS_ASSUME_NONNULL_BEGIN

@class MTIComputePipeline, MTIFunctionDescriptor, MTIImage;
@interface MTIComputePipelineKernel : NSObject <MTIKernel>

@property (nonatomic, readonly) MTLPixelFormat pixelFormat;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithComputeFunctionDescriptor:(MTIFunctionDescriptor *)computeFunctionDescriptor pixelFormat:(MTLPixelFormat)pixelFormat NS_DESIGNATED_INITIALIZER;

- (nullable MTIComputePipeline *)newKernelStateWithContext:(MTIContext *)context error:(NSError **)error;

- (MTIImage *)applyToInputImages:(NSArray<MTIImage *> *)images
                      parameters:(NSDictionary<NSString *,id> *)parameters
         outputTextureDescriptor:(MTLTextureDescriptor *)outputTextureDescriptor;

@end

NS_ASSUME_NONNULL_END
