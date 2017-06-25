//
//  MTIImage.m
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import "MTIImage.h"
#import "MTIImagePrivate.h"

@implementation MTIImageResolveResult

@end

@interface MTIImage ()

@end

@implementation MTIImage

- (instancetype)init {
    if (self = [super init]) {
        MTLSamplerDescriptor *samplerDescriptor = [[MTLSamplerDescriptor alloc] init];
        samplerDescriptor.minFilter = MTLSamplerMipFilterLinear;
        samplerDescriptor.magFilter = MTLSamplerMipFilterLinear;
        samplerDescriptor.sAddressMode = MTLSamplerAddressModeClampToZero;
        samplerDescriptor.tAddressMode = MTLSamplerAddressModeClampToZero;
        _samplerDescriptor = samplerDescriptor;
    }
    return self;
}

- (instancetype)imageWithSamplerDescriptor:(MTLSamplerDescriptor *)samplerDescriptor {
    return nil;
}

@end
