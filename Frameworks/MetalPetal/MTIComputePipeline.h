//
//  MTIComputePipeline.h
//  Pods
//
//  Created by YuAo on 27/07/2017.
//
//

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTIComputePipeline : NSObject <NSCopying>

@property (nonatomic,strong,readonly) id<MTLComputePipelineState> state;

@property (nonatomic,strong,readonly) MTLComputePipelineReflection *reflection;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithState:(id<MTLComputePipelineState>)state reflection:(MTLComputePipelineReflection *)reflection NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
