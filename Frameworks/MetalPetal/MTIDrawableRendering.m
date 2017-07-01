//
//  MTIDrawableRendering.m
//  Pods
//
//  Created by YuAo on 01/07/2017.
//
//

#import "MTIDrawableRendering.h"

@implementation MTIDrawableRenderingRequest

- (instancetype)init {
    if (self = [super init]) {
        _identifier = [NSUUID UUID];
    }
    return self;
}

@end

@implementation MTKView (MTIDrawableProvider)

- (id<MTLDrawable>)drawableForRequest:(MTIDrawableRenderingRequest *)request {
    return self.currentDrawable;
}

- (MTLRenderPassDescriptor *)renderPassDescriptorForRequest:(MTIDrawableRenderingRequest *)request {
    return self.currentRenderPassDescriptor;
}

@end
