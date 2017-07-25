//
//  MTIImage.m
//  Pods
//
//  Created by YuAo on 25/06/2017.
//
//

#import "MTIImage.h"
#import "MTISamplerDescriptor.h"
#import "MTITextureDescriptor.h"
#import "MTIImage+Promise.h"
#import "MTICVPixelBufferPromise.h"

@interface MTIImage ()

@property (nonatomic,copy) id<MTIImagePromise> promise;

@end

@implementation MTIImage

- (instancetype)initWithPromise:(id<MTIImagePromise>)promise {
    MTLSamplerDescriptor *samplerDescriptor = [[MTLSamplerDescriptor alloc] init];
    samplerDescriptor.minFilter = MTLSamplerMinMagFilterLinear;
    samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
    samplerDescriptor.sAddressMode = MTLSamplerAddressModeClampToZero;
    samplerDescriptor.tAddressMode = MTLSamplerAddressModeClampToZero;
    return [self initWithPromise:promise samplerDescriptor:[samplerDescriptor newMTISamplerDescriptor]];
}

- (instancetype)initWithPromise:(id<MTIImagePromise>)promise samplerDescriptor:(MTISamplerDescriptor *)samplerDescriptor {
    if (self = [super init]) {
        _promise = [promise copyWithZone:nil];
        _extent = CGRectMake(0, 0, _promise.dimensions.width, _promise.dimensions.height);
        _samplerDescriptor = [samplerDescriptor copy];
    }
    return self;
}

- (instancetype)imageWithSamplerDescriptor:(MTISamplerDescriptor *)samplerDescriptor {
    MTIImage *image = [[MTIImage alloc] initWithPromise:self.promise samplerDescriptor:self.samplerDescriptor];
    image -> _samplerDescriptor = samplerDescriptor;
    return image;
}

- (instancetype)imageWithCachePolicy:(MTIImageCachePolicy)cachePolicy {
    MTIImage *image = [[MTIImage alloc] initWithPromise:self.promise samplerDescriptor:self.samplerDescriptor];
    image -> _cachePolicy = cachePolicy;
    return image;
}

- (CGSize)size {
    return self.extent.size;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end

#import "MTIImagePromise.h"

@implementation MTIImage (Creation)

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    return [[self initWithPromise:[[MTICVPixelBufferPromise alloc] initWithCVPixelBuffer:pixelBuffer]] imageWithCachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithCGImage:(CGImageRef)cgImage {
    return [[self initWithPromise:[[MTICGImagePromise alloc] initWithCGImage:cgImage]] imageWithCachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithCIImage:(CIImage *)ciImage {
    return [[self initWithPromise:[[MTICIImagePromise alloc] initWithCIImage:ciImage]] imageWithCachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithTexture:(id<MTLTexture>)texture {
    return [self initWithPromise:[[MTITexturePromise alloc] initWithTexture:texture]];
}

- (instancetype)initWithTextureDescriptor:(MTLTextureDescriptor *)textureDescriptor {
    return [self initWithPromise:[[MTITextureDescriptorPromise alloc] initWithTextureDescriptor:textureDescriptor]];
}

@end
