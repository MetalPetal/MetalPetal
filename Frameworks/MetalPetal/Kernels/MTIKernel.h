//
//  MTIKernel.h
//  Pods
//
//  Created by YuAo on 02/07/2017.
//
//

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@class MTIContext;

@protocol MTIKernelConfiguration <NSObject, NSCopying>

@property (nonatomic, copy, readonly) id<NSCopying> identifier;

@end

/// A kernel must be stateless.

@protocol MTIKernel <NSObject>

- (nullable id)newKernelStateWithContext:(MTIContext *)context configuration:(nullable id<MTIKernelConfiguration>)configuration error:(NSError **)error NS_SWIFT_NAME(makeKernelState(context:configuration:));

@end

NS_ASSUME_NONNULL_END
