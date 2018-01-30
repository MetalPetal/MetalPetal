//
//  MTIRenderCommand.h
//  Pods
//
//  Created by Yu Ao on 26/11/2017.
//

#import <Foundation/Foundation.h>
#import "MTIVertex.h"

@class MTIRenderPipelineKernel, MTIImage, MTIRenderPassOutputDescriptor;

NS_ASSUME_NONNULL_BEGIN

@interface MTIRenderCommand : NSObject <NSCopying>

@property (nonatomic, strong, readonly) MTIRenderPipelineKernel *kernel;

@property (nonatomic, copy, readonly) id<MTIGeometry> geometry;

@property (nonatomic, copy, readonly) NSArray<MTIImage *> *images;

@property (nonatomic, copy, readonly) NSDictionary<NSString *, id> *parameters;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithKernel:(MTIRenderPipelineKernel *)kernel
                      geometry:(id<MTIGeometry>)geometry
                        images:(NSArray<MTIImage *> *)images
                    parameters:(NSDictionary<NSString *,id> *)parameters NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
