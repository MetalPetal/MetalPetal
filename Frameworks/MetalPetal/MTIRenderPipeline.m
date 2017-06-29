//
//  MTIRenderPipelineInfo.m
//  Pods
//
//  Created by YuAo on 30/06/2017.
//
//

#import "MTIRenderPipeline.h"

@implementation MTIRenderPipeline

- (instancetype)initWithState:(id<MTLRenderPipelineState>)state reflection:(MTLRenderPipelineReflection *)reflection {
    if (self = [super init]) {
        _state = state;
        _reflection = reflection;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end
