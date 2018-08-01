//
//  MTIRenderTask.m
//  MetalPetal
//
//  Created by Yu Ao on 2018/5/22.
//

#import "MTIRenderTask.h"
#import "MTIImageRenderingContext.h"

@interface MTIRenderTask ()

@property (nonatomic, readonly, strong) id<MTLCommandBuffer> commandBuffer;

@end

@implementation MTIRenderTask

- (instancetype)initWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer {
    if (self = [super init]) {
        _commandBuffer = commandBuffer;
    }
    return self;
}

- (NSError *)error {
    return _commandBuffer.error;
}

- (void)waitUntilCompleted {
    [_commandBuffer waitUntilCompleted];
}

- (MTLCommandBufferStatus)commandBufferStatus {
    return _commandBuffer.status;
}

@end
