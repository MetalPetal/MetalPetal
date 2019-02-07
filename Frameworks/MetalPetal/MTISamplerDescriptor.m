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

@property (nonatomic, readonly) NSUInteger cachedHashValue;

@end

@implementation MTISamplerDescriptor

- (instancetype)initWithMTLSamplerDescriptor:(MTLSamplerDescriptor *)samplerDescriptor {
    if (self = [super init]) {
        _metalSamplerDescriptor = [samplerDescriptor copy];
        _cachedHashValue = [samplerDescriptor hash];
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
        return [_metalSamplerDescriptor isEqual:((MTISamplerDescriptor *)object) -> _metalSamplerDescriptor];
    }
    return NO;
}

- (NSUInteger)hash {
    return _cachedHashValue;
}

+ (MTISamplerDescriptor *)defaultSamplerDescriptor {
    static MTISamplerDescriptor *defaultSamplerDescriptor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MTLSamplerDescriptor *samplerDescriptor = [[MTLSamplerDescriptor alloc] init];
        samplerDescriptor.minFilter = MTLSamplerMinMagFilterLinear;
        samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
        samplerDescriptor.sAddressMode = MTLSamplerAddressModeClampToZero;
        samplerDescriptor.tAddressMode = MTLSamplerAddressModeClampToZero;
        defaultSamplerDescriptor = [samplerDescriptor newMTISamplerDescriptor];
    });
    return defaultSamplerDescriptor;
}

+ (instancetype)defaultSamplerDescriptorWithAddressMode:(MTLSamplerAddressMode)addressMode {
    static MTISamplerDescriptor *defaultSamplerDescriptorClampToEdge;
    static MTISamplerDescriptor *defaultSamplerDescriptorRepeat;
    static MTISamplerDescriptor *defaultSamplerDescriptorMirrorRepeat;
    static MTISamplerDescriptor *defaultSamplerDescriptorClampToZero;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MTLSamplerDescriptor *samplerDescriptor = [[MTLSamplerDescriptor alloc] init];
        samplerDescriptor.minFilter = MTLSamplerMinMagFilterLinear;
        samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
        
        samplerDescriptor.sAddressMode = MTLSamplerAddressModeClampToZero;
        samplerDescriptor.tAddressMode = MTLSamplerAddressModeClampToZero;
        samplerDescriptor.rAddressMode = MTLSamplerAddressModeClampToZero;
        defaultSamplerDescriptorClampToZero = [samplerDescriptor newMTISamplerDescriptor];
        
        samplerDescriptor.sAddressMode = MTLSamplerAddressModeClampToEdge;
        samplerDescriptor.tAddressMode = MTLSamplerAddressModeClampToEdge;
        samplerDescriptor.rAddressMode = MTLSamplerAddressModeClampToEdge;
        defaultSamplerDescriptorClampToEdge = [samplerDescriptor newMTISamplerDescriptor];
        
        samplerDescriptor.sAddressMode = MTLSamplerAddressModeRepeat;
        samplerDescriptor.tAddressMode = MTLSamplerAddressModeRepeat;
        samplerDescriptor.rAddressMode = MTLSamplerAddressModeRepeat;
        defaultSamplerDescriptorRepeat = [samplerDescriptor newMTISamplerDescriptor];
        
        samplerDescriptor.sAddressMode = MTLSamplerAddressModeMirrorRepeat;
        samplerDescriptor.tAddressMode = MTLSamplerAddressModeMirrorRepeat;
        samplerDescriptor.rAddressMode = MTLSamplerAddressModeMirrorRepeat;
        defaultSamplerDescriptorMirrorRepeat = [samplerDescriptor newMTISamplerDescriptor];
    });
    
    switch (addressMode) {
        case MTLSamplerAddressModeMirrorRepeat:
            return defaultSamplerDescriptorMirrorRepeat;
        case MTLSamplerAddressModeClampToEdge:
            return defaultSamplerDescriptorClampToEdge;
        case MTLSamplerAddressModeRepeat:
            return defaultSamplerDescriptorRepeat;
        case MTLSamplerAddressModeClampToZero:
            return defaultSamplerDescriptorClampToZero;
        default:
            NSAssert(NO, @"Unsupported address mode.");
            return defaultSamplerDescriptorClampToZero;
    }
}

@end

@implementation MTLSamplerDescriptor (MTISamplerDescriptor)

- (MTISamplerDescriptor *)newMTISamplerDescriptor {
    return [[MTISamplerDescriptor alloc] initWithMTLSamplerDescriptor:self];
}

@end
