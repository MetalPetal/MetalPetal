//
//  MTIComputePipeline.m
//  Pods
//
//  Created by YuAo on 27/07/2017.
//
//

#import "MTIComputePipeline.h"

@implementation MTIComputePipeline

- (instancetype)initWithState:(id<MTLComputePipelineState>)state reflection:(MTLComputePipelineReflection *)reflection {
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
