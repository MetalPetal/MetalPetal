//
//  MTICVMetalTextureCache.m
//  Pods
//
//  Created by Yu Ao on 07/01/2018.
//

#import "MTICVMetalTextureCache.h"
#import "MTILock.h"

NSString * const MTICVMetalTextureCacheErrorDomain = @"MTICVMetalTextureCacheErrorDomain";

__attribute__((objc_subclassing_restricted))
@interface MTICVMetalTextureCacheTexture: NSObject <MTICVMetalTexture>

#if COREVIDEO_SUPPORTS_METAL

@property (nonatomic, readonly) CVMetalTextureRef textureRef;

#endif

@end

@implementation MTICVMetalTextureCacheTexture
@synthesize texture = _texture;

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

@property (nonatomic, strong, readonly) id<NSLocking> lock;

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

+ (instancetype)newCoreVideoMetalTextureBridgeWithDevice:(id<MTLDevice>)device error:(NSError * __autoreleasing *)error {
    return [[self alloc] initWithDevice:device cacheAttributes:nil textureAttributes:nil error:error];
}

- (instancetype)initWithDevice:(id<MTLDevice>)device cacheAttributes:(NSDictionary *)cacheAttributes textureAttributes:(NSDictionary *)textureAttributes error:(NSError * __autoreleasing *)error {
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
        _lock = MTILockCreate();
    }
    return self;
#else
    if (error) {
        *error = [MTICVMetalTextureCache coreVideoDoesNotSupportMetalError];
    }
    return nil;
#endif
}

- (id<MTICVMetalTexture>)newTextureWithCVImageBuffer:(CVImageBufferRef)imageBuffer textureDescriptor:(MTLTextureDescriptor *)textureDescriptor planeIndex:(size_t)planeIndex error:(NSError * __autoreleasing *)error {
#if COREVIDEO_SUPPORTS_METAL
    [_lock lock];
    CVMetalTextureRef textureRef = NULL;
    NSDictionary *textureAttributes = nil;
    if (@available(iOS 13.0, macOS 10.15, *)) {
        textureAttributes = @{
            (id)kCVMetalTextureUsage: @(textureDescriptor.usage),
            (id)kCVMetalTextureStorageMode: @(textureDescriptor.storageMode)
        };
    } else {
        textureAttributes = @{
            (id)kCVMetalTextureUsage: @(textureDescriptor.usage),
        };
    }
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _cache, imageBuffer, (__bridge CFDictionaryRef)textureAttributes, textureDescriptor.pixelFormat, textureDescriptor.width, textureDescriptor.height, planeIndex, &textureRef);
    [_lock unlock];
    if (status != kCVReturnSuccess || textureRef == NULL) {
        if (error) {
            *error = [NSError errorWithDomain:MTICVMetalTextureCacheErrorDomain code:MTICVMetalTextureCacheErrorFailedToCreateTexture userInfo:@{NSUnderlyingErrorKey: [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:@{}]}];
        }
        [self flushCache];
        return nil;
    }
    MTICVMetalTextureCacheTexture *texture = [[MTICVMetalTextureCacheTexture alloc] initWithCVMetalTexture:textureRef];
    CFRelease(textureRef);
    return texture;
#else
    if (error) {
        *error = [MTICVMetalTextureCache coreVideoDoesNotSupportMetalError];
    }
    return nil;
#endif
}

- (void)flushCache {
#if COREVIDEO_SUPPORTS_METAL
    [_lock lock];
    CVMetalTextureCacheFlush(_cache, 0);
    [_lock unlock];
#endif
}

@end
