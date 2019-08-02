//
//  MTIRenderTask.h
//  MetalPetal
//
//  Created by Yu Ao on 2018/5/22.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@class MTIImageRenderingContext;

/// Represents a GPU render task - i.e., commands in a command buffer.
@interface MTIRenderTask : NSObject

/// Status of the underlaying command buffer.
@property (readonly) MTLCommandBufferStatus commandBufferStatus;

- (instancetype)initWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

/// Synchronously blocks execution until the task either completes or fails (with error).
- (void)waitUntilCompleted;

/// If an error occurred during execution, the NSError may contain more details about the problem.
@property (nullable, readonly) NSError *error;

@end

NS_ASSUME_NONNULL_END
