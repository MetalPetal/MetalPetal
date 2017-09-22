//
//  MTIRenderPipelineInfo.h
//  Pods
//
//  Created by YuAo on 30/06/2017.
//
//

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTIRenderPipeline : NSObject <NSCopying>

@property (nonatomic,strong,readonly) id<MTLRenderPipelineState> state;

@property (nonatomic,strong,readonly) MTLRenderPipelineReflection *reflection;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithState:(id<MTLRenderPipelineState>)state reflection:(MTLRenderPipelineReflection *)reflection NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
