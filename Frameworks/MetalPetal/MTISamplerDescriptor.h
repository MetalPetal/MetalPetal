//
//  MTISamplerDescriptor.h
//  Pods
//
//  Created by YuAo on 29/06/2017.
//
//

#import <Metal/Metal.h>

/// An immutable wrapper for MTLSamplerDescriptor.

@interface MTISamplerDescriptor : NSObject <NSCopying>

- (instancetype)initWithMTLSamplerDescriptor:(MTLSamplerDescriptor *)samplerDescriptor;

- (MTLSamplerDescriptor *)newMTLSamplerDescriptor;

@end

@interface MTLSamplerDescriptor (MTISamplerDescriptor)

- (MTISamplerDescriptor *)newMTISamplerDescriptor;

@end
