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

- (instancetype)initWithPromise:(id<MTIImagePromise>)promise {
    return [self initWithPromise:promise samplerDescriptor:MTIImage.defaultSamplerDescriptor];
}

- (instancetype)initWithPromise:(id<MTIImagePromise>)promise samplerDescriptor:(MTISamplerDescriptor *)samplerDescriptor cachePolicy:(MTIImageCachePolicy)cachePolicy {
    if (self = [super init]) {
        _promise = [promise copyWithZone:nil];
        _extent = CGRectMake(0, 0, _promise.dimensions.width, _promise.dimensions.height);
        _samplerDescriptor = [samplerDescriptor copy];
        _cachePolicy = cachePolicy;
    }
    return self;
}

- (instancetype)initWithPromise:(id<MTIImagePromise>)promise samplerDescriptor:(MTISamplerDescriptor *)samplerDescriptor {
    return [self initWithPromise:promise samplerDescriptor:samplerDescriptor cachePolicy:MTIImageCachePolicyTransient];
}

- (instancetype)imageWithSamplerDescriptor:(MTISamplerDescriptor *)samplerDescriptor {
    return [[MTIImage alloc] initWithPromise:self.promise samplerDescriptor:samplerDescriptor cachePolicy:self.cachePolicy];
}

- (instancetype)imageWithCachePolicy:(MTIImageCachePolicy)cachePolicy {
    return [[MTIImage alloc] initWithPromise:self.promise samplerDescriptor:self.samplerDescriptor cachePolicy:cachePolicy];
}

- (CGSize)size {
    return _extent.size;
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

- (instancetype)initWithCGImage:(CGImageRef)cgImage options:(NSDictionary<NSString *,id> *)options {
    return [self initWithPromise:[[MTICGImagePromise alloc] initWithCGImage:cgImage options:options] samplerDescriptor:MTIImage.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithCIImage:(CIImage *)ciImage {
    return [self initWithPromise:[[MTICIImagePromise alloc] initWithCIImage:ciImage] samplerDescriptor:MTIImage.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithTexture:(id<MTLTexture>)texture {
    return [self initWithPromise:[[MTITexturePromise alloc] initWithTexture:texture] samplerDescriptor:MTIImage.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

- (instancetype)initWithTextureDescriptor:(MTLTextureDescriptor *)textureDescriptor {
    return [self initWithPromise:[[MTITextureDescriptorPromise alloc] initWithTextureDescriptor:textureDescriptor]];
}

- (instancetype)initWithContentsOfURL:(NSURL *)URL options:(NSDictionary<NSString *, id> *)options {
    id<MTIImagePromise> urlPromise = [[MTIImageURLPromise alloc] initWithContentsOfURL:URL options:options];
    if (!urlPromise) {
        return nil;
    }
    return [self initWithPromise:urlPromise samplerDescriptor:MTIImage.defaultSamplerDescriptor cachePolicy:MTIImageCachePolicyPersistent];
}

@end
