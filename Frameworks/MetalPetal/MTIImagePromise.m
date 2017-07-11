//
//  MTIImagePromise.m
//  Pods
//
//  Created by YuAo on 27/06/2017.
//
//

#import "MTIImagePromise.h"
#import "MTIImageRenderingContext.h"
#import "MTIFilterFunctionDescriptor.h"
#import "MTIImage.h"
#import "MTIContext.h"
#import "MTITextureDescriptor.h"
#import "MTITexturePool.h"

@interface MTICGImagePromise ()

@property (nonatomic) CGImageRef image;

@end

@implementation MTICGImagePromise

- (instancetype)initWithCGImage:(CGImageRef)cgImage {
    if (self = [super init]) {
        _image = CGImageRetain(cgImage);
        _textureDescriptor = [[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm_sRGB width:CGImageGetWidth(cgImage) height:CGImageGetHeight(cgImage) mipmapped:NO] newMTITextureDescriptor];
    }
    return self;
}

- (void)dealloc {
    CGImageRelease(_image);
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id<MTLTexture>)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)error {
    CFAbsoluteTime loadStart = CFAbsoluteTimeGetCurrent();
    id<MTLTexture> texture = [renderingContext.context.textureLoader newTextureWithCGImage:self.image options:@{MTKTextureLoaderOptionSRGB: @(YES)} error:error];
    NSLog(@"%@ load time: %@", self, @(CFAbsoluteTimeGetCurrent() - loadStart));
    return texture;
}

@end

@interface MTITexturePromise ()

@property (nonatomic,strong) id<MTLTexture> texture;

@end

@implementation MTITexturePromise

- (instancetype)initWithTexture:(id<MTLTexture>)texture {
    if (self = [super init]) {
        MTLTextureDescriptor *descriptor = [[MTLTextureDescriptor alloc] init];
        descriptor.textureType = texture.textureType;
        descriptor.pixelFormat = texture.pixelFormat;
        descriptor.width = texture.width;
        descriptor.height = texture.height;
        descriptor.depth = texture.depth;
        descriptor.mipmapLevelCount = texture.mipmapLevelCount;
        descriptor.sampleCount = texture.sampleCount;
        descriptor.arrayLength = texture.arrayLength;
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_8_x_Max) {
            descriptor.usage = texture.usage;
        }
        _textureDescriptor = [descriptor newMTITextureDescriptor];
        _texture = texture;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id<MTLTexture>)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)error {
    return self.texture;
}

@end

@interface MTICIImagePromise ()

@property (nonatomic,strong) CIImage *image;

@end

@implementation MTICIImagePromise

- (instancetype)initWithCIImage:(CIImage *)ciImage {
    if (self = [super init]) {
        _image = ciImage;
        _textureDescriptor = [[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm_sRGB width:ciImage.extent.size.width height:ciImage.extent.size.height mipmapped:NO] newMTITextureDescriptor];
    }
    return self;
}

- (id<MTLTexture>)resolveWithContext:(MTIImageRenderingContext *)renderingContext error:(NSError * _Nullable __autoreleasing *)error {
    id<MTLTexture> texture = [renderingContext.context.texturePool newRenderTargetForPromise:self];
    [renderingContext.context.coreImageContext render:self.image toMTLTexture:texture commandBuffer:renderingContext.commandBuffer bounds:self.image.extent colorSpace:(CGColorSpaceRef)CFAutorelease(CGColorSpaceCreateDeviceRGB())];
    return texture;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end
