//
//  MTICVMetalIOSurfaceBridge.m
//  MetalPetal
//
//  Created by Yu Ao on 2018/10/10.
//

#import "MTICVMetalIOSurfaceBridge.h"

NSString * const MTICVMetalIOSurfaceBridgeErrorDomain = @"MTICVMetalIOSurfaceBridgeErrorDomain";

@interface MTICVMetalIOSurfaceBridgeTexture : NSObject <MTICVMetalTexture>

@end

@implementation MTICVMetalIOSurfaceBridgeTexture
@synthesize texture = _texture;

- (instancetype)initWithTexture:(id<MTLTexture>)texture {
    if (self = [super init]) {
        _texture = texture;
    }
    return self;
}

@end

@interface MTICVMetalIOSurfaceBridge ()

@property (nonatomic, readonly, strong) id<MTLDevice> device;

@end

@implementation MTICVMetalIOSurfaceBridge

+ (instancetype)newCoreVideoMetalTextureBridgeWithDevice:(id<MTLDevice>)device error:(NSError * __autoreleasing *)error {
    return [[self alloc] initWithDevice:device];
}

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
            return [[MTICVMetalIOSurfaceBridgeTexture alloc] initWithTexture:texture];
        } else {
            if (error) {
                *error = [NSError errorWithDomain:MTICVMetalIOSurfaceBridgeErrorDomain code:MTICVMetalIOSurfaceBridgeErrorFailedToCreateTexture userInfo:@{}];
            }
            return nil;
        }
    } else {
        if (error) {
            *error = [NSError errorWithDomain:MTICVMetalIOSurfaceBridgeErrorDomain code:MTICVMetalIOSurfaceBridgeErrorImageBufferIsNotBackedByIOSurface userInfo:@{}];
        }
        return nil;
    }
#else
    if (error) {
        *error = [NSError errorWithDomain:MTICVMetalIOSurfaceBridgeErrorDomain code:MTICVMetalIOSurfaceBridgeErrorCoreVideoDoesNotSupportIOSurface userInfo:@{}];
    }
    return nil;
#endif
}

- (void)flushCache {
    
}

@end
