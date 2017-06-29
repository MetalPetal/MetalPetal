//
//  MTITextureDescriptor.h
//  Pods
//
//  Created by YuAo on 29/06/2017.
//
//

#import <Metal/Metal.h>

/// An immutable wrapper for MTLTextureDescriptor

@interface MTITextureDescriptor : NSObject <NSCopying>

- (instancetype)initWithMTLTextureDescriptor:(MTLTextureDescriptor *)textureDescriptor;

- (MTLTextureDescriptor *)newMTLTextureDescriptor;

@property (readonly, nonatomic) MTLTextureType textureType;

@property (readonly, nonatomic) MTLPixelFormat pixelFormat;

@property (readonly, nonatomic) NSUInteger width;

@property (readonly, nonatomic) NSUInteger height;

@property (readonly, nonatomic) NSUInteger depth;

@end

@interface MTLTextureDescriptor (MTITextureDescriptor)

- (MTITextureDescriptor *)newMTITextureDescriptor;

@end
