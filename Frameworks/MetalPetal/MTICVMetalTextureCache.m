//
//  MTICVMetalTextureCache.m
//  Pods
//
//  Created by Yu Ao on 07/01/2018.
//

#import "MTICVMetalTextureCache.h"

NSString * const MTICVMetalTextureCacheErrorDomain = @"MTICVMetalTextureCacheErrorDomain";

@interface MTICVMetalTexture ()

#if COREVIDEO_SUPPORTS_METAL

@property (nonatomic, readonly) CVMetalTextureRef textureRef;

#endif

@end

@implementation MTICVMetalTexture

#if COREVIDEO_SUPPORTS_METAL

- (instancetype)initWithCVMetalTexture:(CVMetalTextureRef)textureRef {
    if (self = [super init]) {
        NSParameterAssert(textureRef);
        _texture = CVMetalTextureGetTexture(textureRef);
        _textureRef = textureRef;
        CFRetain(_textureRef);
    }
    return self;
}

- (void)dealloc {
    CFRelease(_textureRef);
}

#endif

@end

@interface MTICVMetalTextureCache ()

#if COREVIDEO_SUPPORTS_METAL

@property (nonatomic, readonly) CVMetalTextureCacheRef cache;

#endif

@end

@implementation MTICVMetalTextureCache

- (void)dealloc {
#if COREVIDEO_SUPPORTS_METAL
    CFRelease(_cache);
#endif
}

+ (NSError *)coreVideoDoesNotSupportMetalError {
    static NSError *error;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        error = [NSError errorWithDomain:MTICVMetalTextureCacheErrorDomain code:MTICVMetalTextureCacheErrorMetalIsNotSupported userInfo:@{}];
    });
    return error;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device cacheAttributes:(NSDictionary *)cacheAttributes textureAttributes:(NSDictionary *)textureAttributes error:(NSError * _Nullable __autoreleasing *)error {
#if COREVIDEO_SUPPORTS_METAL
    if (self = [super init]) {
        _cache = NULL;
        CVReturn status = CVMetalTextureCacheCreate(kCFAllocatorDefault, (__bridge CFDictionaryRef)cacheAttributes, device, (__bridge CFDictionaryRef)textureAttributes, &_cache);
        if (status != kCVReturnSuccess || _cache == NULL) {
            if (error) {
                *error = [NSError errorWithDomain:MTICVMetalTextureCacheErrorDomain code:MTICVMetalTextureCacheErrorFailedToInitialize userInfo:@{NSUnderlyingErrorKey: [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:@{}]}];
            }
            return nil;
        }
    }
    return self;
#else
    if (error) {
        *error = [MTICVMetalTextureCache coreVideoDoesNotSupportMetalError];
    }
    return nil;
#endif
}

- (nullable MTICVMetalTexture *)newTextureWithCVImageBuffer:(CVImageBufferRef)imageBuffer attributes:(NSDictionary *)textureAttributes pixelFormat:(MTLPixelFormat)pixelFormat width:(size_t)width height:(size_t)height planeIndex:(size_t)planeIndex error:(NSError * _Nullable __autoreleasing *)error {
#if COREVIDEO_SUPPORTS_METAL
    CVMetalTextureRef textureRef = NULL;
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _cache, imageBuffer, (__bridge CFDictionaryRef)textureAttributes, pixelFormat, width, height, planeIndex, &textureRef);
    if (status != kCVReturnSuccess || textureRef == NULL) {
        if (error) {
            *error = [NSError errorWithDomain:MTICVMetalTextureCacheErrorDomain code:MTICVMetalTextureCacheErrorFailedToCreateTexture userInfo:@{NSUnderlyingErrorKey: [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:@{}]}];
        }
        return nil;
    }
    MTICVMetalTexture *texture = [[MTICVMetalTexture alloc] initWithCVMetalTexture:textureRef];
    CFRelease(textureRef);
    return texture;
#else
    if (error) {
        *error = [MTICVMetalTextureCache coreVideoDoesNotSupportMetalError];
    }
    return nil;
#endif
}

- (void)flush {
#if COREVIDEO_SUPPORTS_METAL
    CVMetalTextureCacheFlush(_cache, 0);
#endif
}

@end
