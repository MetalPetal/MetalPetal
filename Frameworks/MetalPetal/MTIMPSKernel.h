//
//  MTIMPSKernel.h
//  Pods
//
//  Created by YuAo on 03/08/2017.
//
//

#import <Foundation/Foundation.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#import "MTIKernel.h"

NS_ASSUME_NONNULL_BEGIN

@class MTIContext, MTIImage;

typedef MPSKernel * _Nonnull (^MTIMPSKernelBuilder)(id<MTLDevice> device);

@interface MTIMPSKernel : NSObject <MTIKernel>

- (instancetype)initWithMPSKernelBuilder:(MTIMPSKernelBuilder)builder NS_SWIFT_NAME(init(builder:));

- (MTIImage *)applyToInputImages:(NSArray<MTIImage *> *)images
                      parameters:(NSDictionary<NSString *,id> *)parameters
         outputTextureDescriptor:(MTLTextureDescriptor *)outputTextureDescriptor;

@end

NS_ASSUME_NONNULL_END
