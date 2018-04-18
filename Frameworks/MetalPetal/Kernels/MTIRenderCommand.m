//
//  MTIRenderCommand.m
//  Pods
//
//  Created by Yu Ao on 26/11/2017.
//

#import "MTIRenderCommand.h"

@implementation MTIRenderCommand

- (instancetype)initWithKernel:(MTIRenderPipelineKernel *)kernel geometry:(id<MTIGeometry>)geometry images:(NSArray<MTIImage *> *)images parameters:(NSDictionary<NSString *,id> *)parameters {
    if (self = [super init]) {
        NSParameterAssert(kernel);
        NSParameterAssert(images);
        NSParameterAssert(parameters);
        NSParameterAssert(geometry);
        _kernel = kernel;
        _geometry = [geometry copyWithZone:nil];
        _images = [images copy];
        _parameters = [parameters copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end
