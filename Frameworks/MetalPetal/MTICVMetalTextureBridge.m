//
//  MTICVMetalTextureBridge.m
//  MetalPetal
//
//  Created by Yu Ao on 2018/10/10.
//

#import "MTICVMetalTextureBridge.h"

NSString * const MTICVMetalTextureBridgeErrorDomain = @"MTICVMetalTextureBridgeErrorDomain";

@interface MTICVMetalTextureBridgeTexture : NSObject <MTICVMetalTexture>

@end

@implementation MTICVMetalTextureBridgeTexture
@synthesize texture = _texture;

- (instancetype)initWithTexture:(id<MTLTexture>)texture {
    if (self = [super init]) {
        _texture = texture;
    }
    return self;
}

@end

@interface MTICVMetalTextureBridge ()

@property (nonatomic, readonly, strong) id<MTLDevice> device;

@end

@implementation MTICVMetalTextureBridge

- (instancetype)initWithDevice:(id<MTLDevice>)device {
    if (self = [super init]) {
        NSParameterAssert(device);
        _device = device;
    }
    return self;
}

- (id<MTICVMetalTexture>)newTextureWithCVImageBuffer:(CVImageBufferRef)imageBuffer textureDescriptor:(MTLTextureDescriptor *)textureDescriptor planeIndex:(size_t)planeIndex error:(NSError * __autoreleasing *)error {
    NSParameterAssert(imageBuffer);
#if COREVIDEO_SUPPORTS_IOSURFACE
    IOSurfaceRef ioSurface = CVPixelBufferGetIOSurface(imageBuffer);
    if (ioSurface) {
        id<MTLTexture> texture = [self.device newTextureWithDescriptor:textureDescriptor iosurface:ioSurface plane:planeIndex];
        if (texture) {
            return [[MTICVMetalTextureBridgeTexture alloc] initWithTexture:texture];
        } else {
            if (error) {
                *error = [NSError errorWithDomain:MTICVMetalTextureBridgeErrorDomain code:MTICVMetalTextureBridgeErrorFailedToCreateTexture userInfo:@{}];
            }
            return nil;
        }
    } else {
        if (error) {
            *error = [NSError errorWithDomain:MTICVMetalTextureBridgeErrorDomain code:MTICVMetalTextureBridgeErrorImageBufferIsNotBackedByIOSurface userInfo:@{}];
        }
        return nil;
    }
#else
    if (error) {
        *error = [NSError errorWithDomain:MTICVMetalTextureBridgeErrorDomain code:MTICVMetalTextureBridgeErrorCoreVideoDoesNotSupportIOSurface userInfo:@{}];
    }
    return nil;
#endif
}

- (void)flushCache {
    
}

@end
