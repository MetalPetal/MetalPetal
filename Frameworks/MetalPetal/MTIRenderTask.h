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

@interface MTIRenderTask : NSObject

@property (readonly) MTLCommandBufferStatus commandBufferStatus;

- (instancetype)initWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

/*!
 @method addCompletedHandler:block:
 @abstract Add a block to be called when this command buffer has completed execution.
 */
- (void)addCompletedHandler:(MTLCommandBufferHandler)block;

/*!
 @method waitUntilCompleted
 @abstract Synchronously wait for this command buffer to complete.
 */
- (void)waitUntilCompleted;

/*!
 @property error
 @abstract If an error occurred during execution, the NSError may contain more details about the problem.
 */
@property (nullable, readonly) NSError *error;

@end

NS_ASSUME_NONNULL_END
