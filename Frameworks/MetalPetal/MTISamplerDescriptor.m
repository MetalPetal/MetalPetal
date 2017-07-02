//
//  MTISamplerDescriptor.m
//  Pods
//
//  Created by YuAo on 29/06/2017.
//
//

#import "MTISamplerDescriptor.h"

@interface MTISamplerDescriptor ()

@property (nonatomic,copy) MTLSamplerDescriptor *metalSamplerDescriptor;

@end

@implementation MTISamplerDescriptor

- (instancetype)initWithMTLSamplerDescriptor:(MTLSamplerDescriptor *)samplerDescriptor {
    if (self = [super init]) {
        _metalSamplerDescriptor = [samplerDescriptor copy];
    }
    return self;
}

- (MTLSamplerDescriptor *)newMTLSamplerDescriptor {
    return [_metalSamplerDescriptor copy];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if ([object isKindOfClass:[MTISamplerDescriptor class]]) {
        return [self.metalSamplerDescriptor isEqual:((MTISamplerDescriptor *)object).metalSamplerDescriptor];
    }
    return NO;
}

- (NSUInteger)hash {
    return [_metalSamplerDescriptor hash];
}

@end

@implementation MTLSamplerDescriptor (MTISamplerDescriptor)

- (MTISamplerDescriptor *)newMTISamplerDescriptor {
    return [[MTISamplerDescriptor alloc] initWithMTLSamplerDescriptor:self];
}

@end
