//
//  MTITextureDescriptor.m
//  Pods
//
//  Created by YuAo on 29/06/2017.
//
//

#import "MTITextureDescriptor.h"

@interface MTITextureDescriptor ()

@property (nonatomic,copy) MTLTextureDescriptor *metalTextureDescriptor;

@end

@implementation MTITextureDescriptor

- (instancetype)initWithMTLTextureDescriptor:(MTLTextureDescriptor *)textureDescriptor {
    if (self = [super init]) {
        _metalTextureDescriptor = [textureDescriptor copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (MTLTextureDescriptor *)newMTLTextureDescriptor {
    return [_metalTextureDescriptor copy];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if ([object isKindOfClass:[MTITextureDescriptor class]]) {
        return [_metalTextureDescriptor isEqual:((MTITextureDescriptor *)object).metalTextureDescriptor];
    }
    return NO;
}

- (NSUInteger)hash {
    return [_metalTextureDescriptor hash];
}

- (MTLTextureType)textureType {
    return _metalTextureDescriptor.textureType;
}

- (MTLPixelFormat)pixelFormat {
    return _metalTextureDescriptor.pixelFormat;
}

- (NSUInteger)width {
    return _metalTextureDescriptor.width;
}

- (NSUInteger)height {
    return _metalTextureDescriptor.height;
}

- (NSUInteger)depth {
    return _metalTextureDescriptor.depth;
}

@end

@implementation MTLTextureDescriptor (MTITextureDescriptor)

- (MTITextureDescriptor *)newMTITextureDescriptor {
    return [[MTITextureDescriptor alloc] initWithMTLTextureDescriptor:self];
}

@end
