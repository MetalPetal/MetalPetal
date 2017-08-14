//
//  MTISamplerDescriptor.h
//  Pods
//
//  Created by YuAo on 29/06/2017.
//
//

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

/// An immutable wrapper for MTLSamplerDescriptor.

@interface MTISamplerDescriptor : NSObject <NSCopying>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithMTLSamplerDescriptor:(MTLSamplerDescriptor *)samplerDescriptor NS_DESIGNATED_INITIALIZER;

- (MTLSamplerDescriptor *)newMTLSamplerDescriptor NS_SWIFT_NAME(makeMTLSamplerDescriptor());

@end

@interface MTLSamplerDescriptor (MTISamplerDescriptor)

- (MTISamplerDescriptor *)newMTISamplerDescriptor NS_SWIFT_NAME(makeMTISamplerDescriptor());

@end

NS_ASSUME_NONNULL_END
