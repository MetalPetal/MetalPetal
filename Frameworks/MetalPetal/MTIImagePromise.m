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

@interface MTIPixelBufferImagePromise ()

@property (nonatomic) CVPixelBufferRef pixelBuffer;

@end

@implementation MTIPixelBufferImagePromise

- (instancetype)initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (self = [super init]) {
        _pixelBuffer = CVPixelBufferRetain(pixelBuffer);
        _textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm_sRGB width:CVPixelBufferGetWidth(pixelBuffer) height:CVPixelBufferGetHeight(pixelBuffer) mipmapped:NO];
    }
    return self;
}

- (void)dealloc {
    CVPixelBufferRelease(_pixelBuffer);
}

- (id<MTLTexture>)resolveWithContext:(MTIImageRenderingContext *)context error:(NSError * _Nullable __autoreleasing *)error {
    CIImage *image = [[CIImage alloc] initWithCVPixelBuffer:self.pixelBuffer];
    id<MTLTexture> texture = [context.context.device newTextureWithDescriptor:self.textureDescriptor];
    [context.context.coreImageContext render:image toMTLTexture:texture commandBuffer:context.commandBuffer bounds:image.extent colorSpace:(CGColorSpaceRef)CFAutorelease(CGColorSpaceCreateDeviceRGB())];
    return texture;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end

@interface MTICGImagePromise ()

@property (nonatomic) CGImageRef image;

@end

@implementation MTICGImagePromise

- (instancetype)initWithCGImage:(CGImageRef)cgImage {
    if (self = [super init]) {
        _image = CGImageRetain(cgImage);
        _textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm_sRGB width:CGImageGetWidth(cgImage) height:CGImageGetHeight(cgImage) mipmapped:NO];
    }
    return self;
}

- (void)dealloc {
    CGImageRelease(_image);
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id<MTLTexture>)resolveWithContext:(MTIImageRenderingContext *)context error:(NSError * _Nullable __autoreleasing *)error {
    CFAbsoluteTime loadStart = CFAbsoluteTimeGetCurrent();
    id<MTLTexture> texture = [context.context.textureLoader newTextureWithCGImage:self.image options:@{MTKTextureLoaderOptionSRGB: @(YES)} error:error];
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
        _textureDescriptor = descriptor;
        _texture = texture;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id<MTLTexture>)resolveWithContext:(MTIImageRenderingContext *)context error:(NSError * _Nullable __autoreleasing *)error {
    return self.texture;
}

@end

